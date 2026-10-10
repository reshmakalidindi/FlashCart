import time
import uuid
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.cart import Cart
from app.models.payment import PaymentRecord
from app.schemas.order import OrderCreateRequest
from app.services.cart_service import CartService


class OrderService:
    @staticmethod
    def create_order(db: Session, order_in: OrderCreateRequest) -> Order:
        if not order_in.items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot place order with an empty cart."
            )

        # 1. Authoritative calculation from server catalog
        revalidated = CartService.revalidate_cart(
            db=db,
            items=order_in.items,
            coupon_code=order_in.coupon_code,
            persist=False
        )

        order_id = order_in.order_id or f"ORD-{int(time.time())}-{uuid.uuid4().hex[:6].upper()}"
        is_paid = (order_in.payment_status or "").upper() == "PAID"
        exit_token = f"EXIT_{order_id}_{uuid.uuid4().hex[:8]}" if is_paid else None
        payment_id = f"PAY_INIT_{uuid.uuid4().hex[:6]}" if is_paid else None

        existing_order = db.query(Order).filter(Order.order_id == order_id).first()
        if existing_order:
            existing_order.payment_status = "PAID" if is_paid else (order_in.payment_status or "UNPAID")
            existing_order.status = "PAID" if is_paid else "PENDING"
            existing_order.exit_verified = False
            existing_order.verified_by = None
            existing_order.verified_at = None
            if is_paid and not existing_order.exit_token:
                existing_order.exit_token = exit_token
            if is_paid and not existing_order.payment_id:
                existing_order.payment_id = payment_id

            # Ensure payment record exists if paid
            if is_paid and not db.query(PaymentRecord).filter(PaymentRecord.order_id == order_id).first():
                db.add(PaymentRecord(
                    payment_id=existing_order.payment_id or payment_id or f"PAY_{uuid.uuid4().hex[:8]}",
                    order_id=order_id,
                    user_id=existing_order.user_id,
                    amount=existing_order.grand_total,
                    currency="INR",
                    payment_method=existing_order.payment_method,
                    payment_status="SUCCESS",
                    exit_token=existing_order.exit_token,
                ))

            db.commit()
            db.refresh(existing_order)
            return existing_order

        order = Order(
            order_id=order_id,
            user_id=order_in.user_id,
            store_id=order_in.store_id or "STORE_FLASHCART_001",
            status="PAID" if is_paid else "PENDING",
            payment_method=order_in.payment_method,
            payment_status="PAID" if is_paid else "UNPAID",
            payment_id=payment_id,
            exit_token=exit_token,
            subtotal=revalidated.subtotal,
            tax_amount=revalidated.tax_amount,
            discount_amount=revalidated.discount_amount,
            grand_total=revalidated.grand_total,
            total_items=revalidated.total_items,
            exit_verified=False,
        )
        db.add(order)
        db.flush()

        for item in revalidated.items:
            order_item = OrderItem(
                order_id=order_id,
                product_id=item.product_id,
                barcode=item.barcode,
                product_name=item.name,
                unit_price=item.unit_price,
                quantity=item.quantity,
                tax_rate=item.tax_rate,
                tax_amount=item.tax_amount,
                total_price=item.total_price,
            )
            db.add(order_item)

        # Record payment if created as paid
        if is_paid:
            db.add(PaymentRecord(
                payment_id=payment_id or f"PAY_{uuid.uuid4().hex[:8]}",
                order_id=order_id,
                user_id=order_in.user_id,
                amount=revalidated.grand_total,
                currency="INR",
                payment_method=order_in.payment_method,
                payment_status="SUCCESS",
                exit_token=exit_token,
            ))

        # Convert active shopping cart in MySQL if one exists for user
        active_cart = db.query(Cart).filter(
            Cart.user_id == order_in.user_id,
            Cart.status == "ACTIVE"
        ).first()
        if active_cart:
            active_cart.status = "CONVERTED"

        db.commit()
        db.refresh(order)
        return order

    @staticmethod
    def get_order_by_id(db: Session, order_id: str) -> Optional[Order]:
        return db.query(Order).filter(Order.order_id == order_id).first()

    @staticmethod
    def get_user_orders(db: Session, user_id: str, limit: int = 50) -> List[Order]:
        return db.query(Order).filter(
            Order.user_id == user_id
        ).order_by(Order.created_at.desc()).limit(limit).all()

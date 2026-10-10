from typing import List, Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.models.product import Product
from app.schemas.cart import CartItemIn, CartRevalidateResponse, RevalidatedItem


class CartService:
    @staticmethod
    def evaluate_coupon(coupon_code: Optional[str], subtotal: float) -> Tuple[float, Optional[str]]:
        """
        Server-side authoritative coupon discount evaluation.
        """
        if not coupon_code:
            return 0.0, None
        
        code = coupon_code.strip().upper()
        if code == "FLASH50":
            if subtotal >= 300.0:
                return 50.0, "FLASH50 applied: ₹50 discount on orders over ₹300"
            return 0.0, "FLASH50 requires minimum subtotal of ₹300"
        elif code == "FLASH10":
            if subtotal >= 100.0:
                discount = min(100.0, subtotal * 0.10)
                return round(discount, 2), "FLASH10 applied: 10% discount"
            return 0.0, "FLASH10 requires minimum subtotal of ₹100"
        elif code == "WELCOME":
            return 25.0, "WELCOME applied: ₹25 discount"
        
        return 0.0, f"Coupon '{code}' is invalid or expired"

    @classmethod
    def revalidate_cart(
        cls, 
        db: Session, 
        items: List[CartItemIn], 
        coupon_code: Optional[str] = None
    ) -> CartRevalidateResponse:
        """
        Authoritatively calculates pricing, tax, discounts, and totals from the database.
        NEVER relies on prices sent from the client.
        """
        if not items:
            return CartRevalidateResponse(
                items=[],
                subtotal=0.0,
                tax_amount=0.0,
                discount_amount=0.0,
                grand_total=0.0,
                total_items=0,
                coupon_applied=None,
                message="Cart is empty"
            )

        revalidated_items: List[RevalidatedItem] = []
        raw_subtotal = 0.0
        raw_tax = 0.0
        total_quantity = 0

        for item_in in items:
            product = db.query(Product).filter(
                Product.barcode == item_in.barcode.strip(),
                Product.is_active == True
            ).first()

            if not product:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Product with barcode '{item_in.barcode}' not found in supermarket database."
                )

            qty = item_in.quantity
            item_subtotal = round(product.price * qty, 2)
            # GST is applied on product selling price
            item_tax = round(item_subtotal * product.tax_rate, 2)

            raw_subtotal += item_subtotal
            raw_tax += item_tax
            total_quantity += qty

            revalidated_items.append(
                RevalidatedItem(
                    product_id=product.product_id,
                    barcode=product.barcode,
                    name=product.name,
                    brand=product.brand,
                    category=product.category,
                    unit_price=product.price,
                    mrp=product.mrp,
                    weight=product.weight,
                    quantity=qty,
                    tax_rate=product.tax_rate,
                    tax_amount=item_tax,
                    total_price=item_subtotal,
                    image_url=product.image_url,
                )
            )

        subtotal = round(raw_subtotal, 2)
        tax_amount = round(raw_tax, 2)
        discount_amount, coupon_msg = cls.evaluate_coupon(coupon_code, subtotal)
        grand_total = max(0.0, round(subtotal + tax_amount - discount_amount, 2))

        return CartRevalidateResponse(
            items=revalidated_items,
            subtotal=subtotal,
            tax_amount=tax_amount,
            discount_amount=discount_amount,
            grand_total=grand_total,
            total_items=total_quantity,
            coupon_applied=coupon_msg if discount_amount > 0 else None,
            message="Cart verified authoritatively with supermarket database."
        )

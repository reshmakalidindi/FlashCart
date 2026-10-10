import hashlib
import time
import uuid
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.models.order import Order
from app.models.payment import PaymentRecord
from app.schemas.order import MockPaymentRequest, MockPaymentResponse


class PaymentService:
    @staticmethod
    def process_mock_payment(db: Session, payment_in: MockPaymentRequest) -> MockPaymentResponse:
        """
        Authorizes payment and stores authoritative PaymentRecord in MySQL,
        marks Order as PAID, and generates the exit verification token.
        """
        order = db.query(Order).filter(Order.order_id == payment_in.order_id).first()
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Order '{payment_in.order_id}' not found."
            )

        if order.payment_status == "PAID" and order.exit_token:
            return MockPaymentResponse(
                order_id=order.order_id,
                payment_id=order.payment_id or "PREV_PAYMENT",
                status="ALREADY_PAID",
                grand_total=order.grand_total,
                exit_token=order.exit_token,
                message="Order is already paid and exit QR is active."
            )

        payment_id = f"PAY-MOCK-{int(time.time())}-{uuid.uuid4().hex[:6].upper()}"
        
        # Cryptographic exit pass token
        token_seed = f"{order.order_id}:{order.grand_total}:{time.time()}:FLASHCART_SECRET"
        sig = hashlib.sha256(token_seed.encode()).hexdigest()[:16]
        exit_token = f"EXIT_{order.order_id}_{sig}"

        order.payment_status = "PAID"
        order.status = "PAID"
        order.payment_id = payment_id
        order.payment_method = payment_in.payment_method
        order.exit_token = exit_token

        # Persist payment transaction record in MySQL payments table
        payment_record = PaymentRecord(
            payment_id=payment_id,
            order_id=order.order_id,
            user_id=order.user_id,
            amount=order.grand_total,
            currency="INR",
            payment_method=payment_in.payment_method,
            payment_status="SUCCESS",
            exit_token=exit_token,
            gateway_reference=f"GW_{uuid.uuid4().hex[:8].upper()}",
        )
        db.add(payment_record)

        db.commit()
        db.refresh(order)

        return MockPaymentResponse(
            order_id=order.order_id,
            payment_id=payment_id,
            status="SUCCESS",
            grand_total=order.grand_total,
            exit_token=exit_token,
            message="Payment successful! Store exit pass generated."
        )

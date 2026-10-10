from datetime import datetime, timezone
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.models.order import Order
from app.models.exit_verification import ExitVerificationLog
from app.schemas.order import ExitVerifyRequest, ExitVerifyResponse, OrderItemResponse


class VerificationService:
    @staticmethod
    def verify_order_exit(db: Session, request: ExitVerifyRequest) -> ExitVerifyResponse:
        code = request.order_id_or_token.strip()
        staff = request.staff_id.strip()

        order = db.query(Order).filter(
            or_(
                Order.exit_token == code,
                Order.order_id == code
            )
        ).first()

        if not order:
            log_entry = ExitVerificationLog(
                order_id=code,
                staff_id=staff,
                result="NOT_FOUND",
                notes="Scanned code does not match any valid order in system."
            )
            db.add(log_entry)
            db.commit()

            return ExitVerifyResponse(
                success=False,
                status="NOT_FOUND",
                message="Exit Denied: Unrecognized or invalid receipt QR code."
            )

        # Check Payment Status
        if order.payment_status != "PAID":
            log_entry = ExitVerificationLog(
                order_id=order.order_id,
                staff_id=staff,
                result="UNPAID",
                notes=f"Order {order.order_id} has payment status {order.payment_status}."
            )
            db.add(log_entry)
            db.commit()

            return ExitVerifyResponse(
                success=False,
                status="UNPAID",
                message=f"Exit Denied: Payment has not been completed (Status: {order.payment_status}).",
                order_id=order.order_id,
                grand_total=order.grand_total,
                total_items=order.total_items
            )

        # Check Duplicate Exit
        if order.exit_verified:
            log_entry = ExitVerificationLog(
                order_id=order.order_id,
                staff_id=staff,
                result="ALREADY_VERIFIED",
                notes=f"Order {order.order_id} was already verified by {order.verified_by} at {order.verified_at}."
            )
            db.add(log_entry)
            db.commit()

            return ExitVerifyResponse(
                success=False,
                status="ALREADY_VERIFIED",
                message="SECURITY ALERT: This receipt has already been verified and used to exit!",
                order_id=order.order_id,
                grand_total=order.grand_total,
                total_items=order.total_items,
                verified_at=order.verified_at,
                verified_by=order.verified_by
            )

        # Atomic Verification Approval
        now = datetime.now(timezone.utc)
        order.exit_verified = True
        order.verified_by = staff
        order.verified_at = now
        order.status = "COMPLETED"

        log_entry = ExitVerificationLog(
            order_id=order.order_id,
            staff_id=staff,
            result="SUCCESS",
            notes="Exit pass approved and marked verified."
        )
        db.add(log_entry)
        db.commit()
        db.refresh(order)

        item_responses = [
            OrderItemResponse.model_validate(it) for it in order.items
        ]

        return ExitVerifyResponse(
            success=True,
            status="SUCCESS",
            message="Exit Approved: Digital receipt verified. Customer cleared to exit.",
            order_id=order.order_id,
            total_items=order.total_items,
            grand_total=order.grand_total,
            verified_at=order.verified_at,
            verified_by=order.verified_by,
            items=item_responses
        )

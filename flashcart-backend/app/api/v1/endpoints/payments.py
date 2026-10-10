from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.order import MockPaymentRequest, MockPaymentResponse
from app.services.payment_service import PaymentService

router = APIRouter()


@router.post("/mock-verify", response_model=MockPaymentResponse)
def mock_verify_payment(request: MockPaymentRequest, db: Session = Depends(get_db)):
    """
    Mock payment processing endpoint:
    Authorizes the payment server-side, transitions order to PAID,
    and issues the cryptographic QR exit token.
    """
    return PaymentService.process_mock_payment(db=db, payment_in=request)

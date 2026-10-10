from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.order import ExitVerifyRequest, ExitVerifyResponse
from app.services.verification_service import VerificationService

router = APIRouter()


@router.post("/verify-exit", response_model=ExitVerifyResponse)
def verify_exit(request: ExitVerifyRequest, db: Session = Depends(get_db)):
    """
    Staff Security Scanner exit verification endpoint:
    Performs atomic check on digital receipt token:
    - Rejects invalid tokens (NOT_FOUND)
    - Rejects unpaid orders (UNPAID)
    - Rejects already-scanned orders (ALREADY_VERIFIED duplicate prevention)
    - Approves verified order and stamps staff ID and timestamp.
    """
    return VerificationService.verify_order_exit(db=db, request=request)

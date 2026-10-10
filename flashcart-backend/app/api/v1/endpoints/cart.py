from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.cart import CartRevalidateRequest, CartRevalidateResponse
from app.services.cart_service import CartService

router = APIRouter()


@router.post("/revalidate", response_model=CartRevalidateResponse)
def revalidate_cart(request: CartRevalidateRequest, db: Session = Depends(get_db)):
    """
    Authoritative server calculation:
    Takes barcodes and quantities from Flutter app, queries authoritative database prices,
    computes item totals, tax (GST), coupon discount, and returns certified grand total.
    """
    return CartService.revalidate_cart(
        db=db,
        items=request.items,
        coupon_code=request.coupon_code
    )

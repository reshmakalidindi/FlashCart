from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.cart import CartRevalidateRequest, CartRevalidateResponse, CartResponse
from app.services.cart_service import CartService

router = APIRouter()


@router.post("/revalidate", response_model=CartRevalidateResponse)
def revalidate_cart(request: CartRevalidateRequest, db: Session = Depends(get_db)):
    """
    Authoritative server calculation:
    Takes barcodes and quantities from Flutter app, queries authoritative database prices,
    computes item totals, tax (GST), coupon discount, and returns certified grand total.
    Persists cart state in MySQL carts and cart_items tables.
    """
    return CartService.revalidate_cart(
        db=db,
        items=request.items,
        coupon_code=request.coupon_code,
        user_id=request.user_id,
        cart_id=request.cart_id,
        persist=True
    )


@router.get("/user/{user_id}", response_model=CartResponse)
def get_user_cart(user_id: str, db: Session = Depends(get_db)):
    """Fetches the active customer cart stored in MySQL."""
    cart = CartService.get_user_active_cart(db=db, user_id=user_id)
    if not cart:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No active cart found for user '{user_id}'."
        )
    return cart

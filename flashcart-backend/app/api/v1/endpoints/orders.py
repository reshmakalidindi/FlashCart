from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.order import OrderCreateRequest, OrderResponse
from app.services.order_service import OrderService

router = APIRouter()


@router.post("/", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
def create_order(order_in: OrderCreateRequest, db: Session = Depends(get_db)):
    """
    Creates order with authoritative prices calculated server-side.
    Client cannot manipulate unit price, taxes, or final payable amount.
    """
    return OrderService.create_order(db=db, order_in=order_in)


@router.get("/{order_id}", response_model=OrderResponse)
def get_order(order_id: str, db: Session = Depends(get_db)):
    order = OrderService.get_order_by_id(db=db, order_id=order_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Order '{order_id}' not found."
        )
    return order


@router.get("/user/{user_id}", response_model=List[OrderResponse])
def get_user_orders(user_id: str, db: Session = Depends(get_db)):
    return OrderService.get_user_orders(db=db, user_id=user_id)

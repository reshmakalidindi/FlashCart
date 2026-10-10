from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict


class CartItemIn(BaseModel):
    barcode: str
    quantity: int = Field(default=1, ge=1, le=99)


class CartRevalidateRequest(BaseModel):
    items: List[CartItemIn]
    coupon_code: Optional[str] = None
    store_id: Optional[str] = "STORE_FLASHCART_001"
    user_id: Optional[str] = None
    cart_id: Optional[str] = None


class RevalidatedItem(BaseModel):
    product_id: str
    barcode: str
    name: str
    brand: Optional[str] = None
    category: str
    unit_price: float
    mrp: float
    weight: Optional[str] = None
    quantity: int
    tax_rate: float
    tax_amount: float
    total_price: float
    image_url: Optional[str] = None


class CartRevalidateResponse(BaseModel):
    items: List[RevalidatedItem]
    subtotal: float
    tax_amount: float
    discount_amount: float
    grand_total: float
    total_items: int
    coupon_applied: Optional[str] = None
    message: Optional[str] = None
    cart_id: Optional[str] = None


class CartItemResponse(BaseModel):
    id: int
    cart_id: str
    product_id: str
    barcode: str
    product_name: str
    unit_price: float
    quantity: int
    tax_rate: float
    tax_amount: float
    total_price: float

    model_config = ConfigDict(from_attributes=True)


class CartResponse(BaseModel):
    cart_id: str
    user_id: Optional[str] = None
    store_id: str
    coupon_code: Optional[str] = None
    status: str
    subtotal: float
    tax_amount: float
    discount_amount: float
    grand_total: float
    total_items: int
    created_at: datetime
    items: List[CartItemResponse] = []

    model_config = ConfigDict(from_attributes=True)

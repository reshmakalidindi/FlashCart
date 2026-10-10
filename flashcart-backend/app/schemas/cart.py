from typing import List, Optional
from pydantic import BaseModel, Field


class CartItemIn(BaseModel):
    barcode: str
    quantity: int = Field(default=1, ge=1, le=99)


class CartRevalidateRequest(BaseModel):
    items: List[CartItemIn]
    coupon_code: Optional[str] = None
    store_id: Optional[str] = "STORE_DMART_001"


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

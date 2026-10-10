from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict
from app.schemas.cart import CartItemIn


class OrderCreateRequest(BaseModel):
    order_id: Optional[str] = None
    user_id: str
    items: List[CartItemIn]
    payment_method: str = "MOCK_UPI"  # MOCK_UPI, UPI, CARD, CASH
    payment_status: Optional[str] = "UNPAID"
    coupon_code: Optional[str] = None
    store_id: str = "STORE_DMART_001"


class OrderItemResponse(BaseModel):
    product_id: str
    barcode: str
    product_name: str
    unit_price: float
    quantity: int
    tax_rate: float
    tax_amount: float
    total_price: float

    model_config = ConfigDict(from_attributes=True)


class OrderResponse(BaseModel):
    order_id: str
    user_id: str
    store_id: str
    status: str
    payment_method: str
    payment_status: str
    payment_id: Optional[str] = None
    subtotal: float
    tax_amount: float
    discount_amount: float
    grand_total: float
    total_items: int
    exit_verified: bool
    verified_by: Optional[str] = None
    verified_at: Optional[datetime] = None
    exit_token: Optional[str] = None
    created_at: datetime
    items: List[OrderItemResponse] = []

    model_config = ConfigDict(from_attributes=True)


class MockPaymentRequest(BaseModel):
    order_id: str
    payment_method: str = "MOCK_UPI"


class MockPaymentResponse(BaseModel):
    order_id: str
    payment_id: str
    status: str
    grand_total: float
    exit_token: str
    message: str


class ExitVerifyRequest(BaseModel):
    order_id_or_token: str
    staff_id: str = "staff_gate_01"


class ExitVerifyResponse(BaseModel):
    success: bool
    status: str  # SUCCESS, ALREADY_VERIFIED, UNPAID, NOT_FOUND
    message: str
    order_id: Optional[str] = None
    total_items: Optional[int] = None
    grand_total: Optional[float] = None
    verified_at: Optional[datetime] = None
    verified_by: Optional[str] = None
    items: Optional[List[OrderItemResponse]] = None

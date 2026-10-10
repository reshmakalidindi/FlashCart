from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth,
    products,
    cart,
    orders,
    payments,
    verification,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(products.router, prefix="/products", tags=["Products"])
api_router.include_router(cart.router, prefix="/cart", tags=["Cart & Pricing"])
api_router.include_router(orders.router, prefix="/orders", tags=["Orders"])
api_router.include_router(payments.router, prefix="/payments", tags=["Payments"])
api_router.include_router(verification.router, prefix="/orders", tags=["Exit Verification"])
api_router.include_router(verification.router, prefix="/verification", tags=["Exit Verification"])

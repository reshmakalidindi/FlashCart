from sqlalchemy import Column, Integer, String, Float, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin


class Cart(Base, TimestampMixin):
    """
    Authoritative MySQL persistence for active customer shopping carts.
    Stores cart state, totals, and coupon application.
    """
    __tablename__ = "carts"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    cart_id = Column(String(64), unique=True, index=True, nullable=False)
    user_id = Column(String(64), index=True, nullable=True)
    store_id = Column(String(64), default="STORE_FLASHCART_001", nullable=False)
    coupon_code = Column(String(32), nullable=True)
    status = Column(String(32), default="ACTIVE", nullable=False)  # ACTIVE, CONVERTED, ABANDONED

    subtotal = Column(Float, default=0.0, nullable=False)
    tax_amount = Column(Float, default=0.0, nullable=False)
    discount_amount = Column(Float, default=0.0, nullable=False)
    grand_total = Column(Float, default=0.0, nullable=False)
    total_items = Column(Integer, default=0, nullable=False)

    items = relationship("CartItem", back_populates="cart", cascade="all, delete-orphan")


class CartItem(Base, TimestampMixin):
    """
    Line items stored inside an active customer cart.
    """
    __tablename__ = "cart_items"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    cart_id = Column(String(64), ForeignKey("carts.cart_id", ondelete="CASCADE"), nullable=False, index=True)
    product_id = Column(String(64), nullable=False, index=True)
    barcode = Column(String(64), nullable=False, index=True)
    product_name = Column(String(255), nullable=False)
    unit_price = Column(Float, nullable=False)
    quantity = Column(Integer, default=1, nullable=False)
    tax_rate = Column(Float, default=0.0, nullable=False)
    tax_amount = Column(Float, default=0.0, nullable=False)
    total_price = Column(Float, nullable=False)

    cart = relationship("Cart", back_populates="items")

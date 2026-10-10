from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin


class Order(Base, TimestampMixin):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    order_id = Column(String(64), unique=True, index=True, nullable=False)
    user_id = Column(String(64), index=True, nullable=False)
    store_id = Column(String(64), default="STORE_FLASHCART_001", nullable=False)
    status = Column(String(32), default="PENDING", nullable=False)  # PENDING, PAID, CANCELLED, COMPLETED
    payment_method = Column(String(32), default="MOCK_UPI", nullable=False)
    payment_status = Column(String(32), default="UNPAID", nullable=False)  # UNPAID, PAID, FAILED
    payment_id = Column(String(128), nullable=True)
    
    # Authoritative billing figures computed ONLY on the backend
    subtotal = Column(Float, nullable=False)
    tax_amount = Column(Float, nullable=False)
    discount_amount = Column(Float, default=0.0, nullable=False)
    grand_total = Column(Float, nullable=False)
    total_items = Column(Integer, default=0, nullable=False)
    
    # Staff Exit Verification fields
    exit_verified = Column(Boolean, default=False, nullable=False)
    verified_by = Column(String(64), nullable=True)
    verified_at = Column(DateTime, nullable=True)
    exit_token = Column(String(255), unique=True, index=True, nullable=True)

    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    payments = relationship("PaymentRecord", back_populates="order", cascade="all, delete-orphan")

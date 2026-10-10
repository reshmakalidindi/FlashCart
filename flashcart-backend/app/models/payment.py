from sqlalchemy import Column, Integer, String, Float, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin


class PaymentRecord(Base, TimestampMixin):
    """
    Authoritative MySQL persistence for all transaction payments,
    gateway responses, and security exit pass tokens.
    """
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    payment_id = Column(String(128), unique=True, index=True, nullable=False)
    order_id = Column(String(64), ForeignKey("orders.order_id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String(64), index=True, nullable=True)
    amount = Column(Float, nullable=False)
    currency = Column(String(8), default="INR", nullable=False)
    payment_method = Column(String(32), default="MOCK_UPI", nullable=False)  # MOCK_UPI, UPI, CARD, CASH
    payment_status = Column(String(32), default="SUCCESS", nullable=False)  # PENDING, SUCCESS, FAILED
    exit_token = Column(String(255), nullable=True)
    gateway_reference = Column(String(128), nullable=True)
    error_message = Column(Text, nullable=True)

    order = relationship("Order", back_populates="payments")

from sqlalchemy import Column, Integer, String, Float, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    order_id = Column(String(64), ForeignKey("orders.order_id", ondelete="CASCADE"), nullable=False, index=True)
    product_id = Column(String(64), nullable=False)
    barcode = Column(String(64), nullable=False)
    product_name = Column(String(255), nullable=False)
    unit_price = Column(Float, nullable=False)
    quantity = Column(Integer, default=1, nullable=False)
    tax_rate = Column(Float, default=0.18, nullable=False)
    tax_amount = Column(Float, default=0.0, nullable=False)
    total_price = Column(Float, nullable=False)

    order = relationship("Order", back_populates="items")

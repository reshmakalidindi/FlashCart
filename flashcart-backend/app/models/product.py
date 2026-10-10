from sqlalchemy import Column, Integer, String, Float, Boolean, Text
from app.core.database import Base
from app.models.base import TimestampMixin


class Product(Base, TimestampMixin):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    product_id = Column(String(64), unique=True, index=True, nullable=False)
    barcode = Column(String(64), unique=True, index=True, nullable=False)
    name = Column(String(255), index=True, nullable=False)
    brand = Column(String(128), index=True, nullable=True)
    category = Column(String(64), index=True, nullable=False)
    price = Column(Float, nullable=False)  # Selling price
    mrp = Column(Float, nullable=False)    # Max retail price
    weight = Column(String(64), nullable=True)
    stock = Column(Integer, default=100, nullable=False)
    tax_rate = Column(Float, default=0.18, nullable=False)  # e.g., 0.05, 0.12, 0.18, 0.28
    hsn_code = Column(String(32), nullable=True)
    image_url = Column(Text, nullable=True)
    store_id = Column(String(64), default="STORE_DMART_001", index=True, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


class ProductBase(BaseModel):
    product_id: str
    barcode: str
    name: str
    brand: Optional[str] = None
    category: str
    price: float = Field(..., gt=0)
    mrp: float = Field(..., gt=0)
    weight: Optional[str] = None
    stock: int = Field(default=100, ge=0)
    tax_rate: float = Field(default=0.18, ge=0, le=1.0)
    hsn_code: Optional[str] = None
    image_url: Optional[str] = None
    store_id: str = "STORE_DMART_001"
    is_active: bool = True


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    brand: Optional[str] = None
    category: Optional[str] = None
    price: Optional[float] = None
    mrp: Optional[float] = None
    weight: Optional[str] = None
    stock: Optional[int] = None
    tax_rate: Optional[float] = None
    image_url: Optional[str] = None
    is_active: Optional[bool] = None


class ProductResponse(ProductBase):
    id: int

    model_config = ConfigDict(from_attributes=True)


class BarcodeLookupResponse(BaseModel):
    found: bool
    product: Optional[ProductResponse] = None
    message: Optional[str] = None


class CategoryListResponse(BaseModel):
    categories: List[str]

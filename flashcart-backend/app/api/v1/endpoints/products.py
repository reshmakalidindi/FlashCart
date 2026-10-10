from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.product import (
    ProductResponse, 
    ProductCreate, 
    BarcodeLookupResponse,
    CategoryListResponse
)
from app.services.product_service import ProductService

router = APIRouter()


@router.get("/", response_model=List[ProductResponse])
def get_products(
    category: Optional[str] = Query(None, description="Filter by category"),
    search: Optional[str] = Query(None, description="Search by name, brand, or barcode"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    return ProductService.list_products(
        db=db, category=category, search=search, limit=limit, offset=offset
    )


@router.get("/categories", response_model=CategoryListResponse)
def get_categories(db: Session = Depends(get_db)):
    categories = ProductService.get_distinct_categories(db)
    return CategoryListResponse(categories=categories)


@router.get("/barcode/{barcode}", response_model=BarcodeLookupResponse)
def lookup_by_barcode(barcode: str, db: Session = Depends(get_db)):
    product = ProductService.get_by_barcode(db, barcode=barcode)
    if not product:
        return BarcodeLookupResponse(
            found=False,
            product=None,
            message=f"Product with barcode '{barcode}' was not found in catalog."
        )
    return BarcodeLookupResponse(
        found=True,
        product=ProductResponse.model_validate(product),
        message="Product located successfully."
    )


@router.get("/{product_id}", response_model=ProductResponse)
def get_product(product_id: str, db: Session = Depends(get_db)):
    product = ProductService.get_by_id(db, product_id=product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with ID '{product_id}' not found."
        )
    return product


@router.post("/", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def create_product(product_in: ProductCreate, db: Session = Depends(get_db)):
    return ProductService.create_or_update(db, product_in)

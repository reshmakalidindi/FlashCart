from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.models.product import Product
from app.schemas.product import ProductCreate, ProductUpdate


class ProductService:
    @staticmethod
    def get_by_barcode(db: Session, barcode: str) -> Optional[Product]:
        return db.query(Product).filter(
            Product.barcode == barcode.strip(), 
            Product.is_active == True
        ).first()

    @staticmethod
    def get_by_id(db: Session, product_id: str) -> Optional[Product]:
        return db.query(Product).filter(
            Product.product_id == product_id, 
            Product.is_active == True
        ).first()

    @staticmethod
    def list_products(
        db: Session, 
        category: Optional[str] = None, 
        search: Optional[str] = None,
        limit: int = 100, 
        offset: int = 0
    ) -> List[Product]:
        query = db.query(Product).filter(Product.is_active == True)
        if category and category.lower() != "all":
            query = query.filter(Product.category.ilike(category))
        if search:
            search_term = f"%{search.strip()}%"
            query = query.filter(
                or_(
                    Product.name.ilike(search_term),
                    Product.brand.ilike(search_term),
                    Product.barcode.ilike(search_term)
                )
            )
        return query.offset(offset).limit(limit).all()

    @staticmethod
    def get_distinct_categories(db: Session) -> List[str]:
        rows = db.query(Product.category).filter(Product.is_active == True).distinct().all()
        categories = ["All"] + sorted([r[0] for r in rows if r[0]])
        return categories

    @staticmethod
    def create_or_update(db: Session, product_in: ProductCreate) -> Product:
        existing = db.query(Product).filter(
            or_(
                Product.barcode == product_in.barcode,
                Product.product_id == product_in.product_id
            )
        ).first()
        if existing:
            for field, val in product_in.model_dump().items():
                setattr(existing, field, val)
            db.commit()
            db.refresh(existing)
            return existing
        else:
            new_prod = Product(**product_in.model_dump())
            db.add(new_prod)
            db.commit()
            db.refresh(new_prod)
            return new_prod

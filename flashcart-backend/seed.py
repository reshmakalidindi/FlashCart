import sys
import os

# Add parent directory to path so imports work cleanly
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import or_
from app.core.database import SessionLocal, Base, engine
from app.models.user import User
from app.models.product import Product
from app.core.security import get_password_hash

# 10 Authoritative Supermarket Products with User-Supplied Selling Prices & QR Identifiers
QR_PRODUCTS = [
    {
        "product_id": "P001",
        "barcode": "FLASHCART-P001",
        "name": "Maggi",
        "brand": "Nestle",
        "category": "Instant Food",
        "price": 20.0,
        "mrp": 22.0,
        "weight": "70 g",
        "tax_rate": 0.05,
        "hsn_code": "1902",
        "stock": 100,
        "image_url": "assets/product_qrs/P001.png",
        "store_id": "STORE_FLASHCART_001",
        "is_active": True,
    },
    {
        "product_id": "P002",
        "barcode": "FLASHCART-P002",
        "name": "Biscuit packets",
        "brand": "Parle",
        "category": "Biscuits & Snacks",
        "price": 15.0,
        "mrp": 18.0,
        "weight": "100 g",
        "tax_rate": 0.05,
        "hsn_code": "1905",
        "stock": 150,
        "image_url": "assets/product_qrs/P002.png",
        "store_id": "STORE_FLASHCART_001",
        "is_active": True,
    },
    {
        "product_id": "P003",
        "barcode": "FLASHCART-P003",
        "name": "Surf Excel",
        "brand": "Surf Excel",
        "category": "Household & Cleaning",
        "price": 70.0,
        "mrp": 80.0,
        "weight": "500 g",
        "tax_rate": 0.18,
        "hsn_code": "3402",
        "stock": 80,
        "image_url": "assets/product_qrs/P003.png",
        "store_id": "STORE_FLASHCART_001",
        "is_active": True,
    },
    {
        "product_id": "P004",
        "barcode": "FLASHCART-P004",
        "name": "Stationery",
        "brand": "Classmate",
        "category": "Stationery",
        "price": 200.0,
        "mrp": 220.0,
        "weight": "1 Set",
        "tax_rate": 0.12,
        "hsn_code": "4820",
        "stock": 60,
        "image_url": "assets/product_qrs/P004.png",
        "store_id": "STORE_FLASHCART_001",
        "is_active": True,
    },
    {
        "product_id": "P005",
        "barcode": "FLASHCART-P005",
        "name": "College bag",
        "brand": "American Tourister",
        "category": "Luggage & Bags",
        "price": 699.0,
        "mrp": 999.0,
        "weight": "1 pc",
        "tax_rate": 0.18,
        "hsn_code": "4202",
        "stock": 40,
        "image_url": "assets/product_qrs/P005.png",
        "store_id": "STORE_FLASHCART_001",
        "is_active": True,
    },
    {
        "product_id": "P006",
        "barcode": "FLASHCART-P006",
        "name": "Water bottle",
        "brand": "Milton",
        "category": "Home & Kitchen",
        "price": 288.0,
        "mrp": 350.0,
        "weight": "1 L",
        "tax_rate": 0.12,
        "hsn_code": "3924",
        "stock": 75,
        "image_url": "assets/product_qrs/P006.png",
        "store_id": "STORE_FLASHCART_001",
        "is_active": True,
    },
    {
        "product_id": "P007",
        "barcode": "FLASHCART-P007",
        "name": "Sonpapidi (sweet)",
        "brand": "Haldiram's",
        "category": "Sweets",
        "price": 154.0,
        "mrp": 170.0,
        "weight": "250 g",
        "tax_rate": 0.05,
        "hsn_code": "2106",
        "stock": 90,
        "image_url": "assets/product_qrs/P007.png",
        "store_id": "STORE_FLASHCART_001",
        "is_active": True,
    },
    {
        "product_id": "P008",
        "barcode": "FLASHCART-P008",
        "name": "Paneer",
        "brand": "Amul",
        "category": "Dairy",
        "price": 299.0,
        "mrp": 320.0,
        "weight": "500 g",
        "tax_rate": 0.05,
        "hsn_code": "0406",
        "stock": 50,
        "image_url": "assets/product_qrs/P008.png",
        "store_id": "STORE_FLASHCART_001",
        "is_active": True,
    },
    {
        "product_id": "P009",
        "barcode": "FLASHCART-P009",
        "name": "Cool drinks",
        "brand": "Coca-Cola",
        "category": "Beverages",
        "price": 40.0,
        "mrp": 45.0,
        "weight": "600 ml",
        "tax_rate": 0.12,
        "hsn_code": "2202",
        "stock": 120,
        "image_url": "assets/product_qrs/P009.png",
        "store_id": "STORE_FLASHCART_001",
        "is_active": True,
    },
    {
        "product_id": "P0010",
        "barcode": "FLASHCART-P0010",
        "name": "Lays packet",
        "brand": "Lay's",
        "category": "Biscuits & Snacks",
        "price": 50.0,
        "mrp": 50.0,
        "weight": "115 g",
        "tax_rate": 0.12,
        "hsn_code": "1905",
        "stock": 110,
        "image_url": "assets/product_qrs/P0010.png",
        "store_id": "STORE_FLASHCART_001",
        "is_active": True,
    },
]


def seed_database():
    print("Initializing database tables...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # 1. Seed demo user accounts
        demo_users = [
            {
                "user_id": "usr_demo_customer",
                "email": "user@example.com",
                "hashed_password": get_password_hash("password123"),
                "full_name": "Demo Shopper",
                "phone_number": "+91 9876543210",
                "role": "customer",
                "is_active": True,
            },
            {
                "user_id": "usr_staff_guard",
                "email": "staff@flashcart.com",
                "hashed_password": get_password_hash("staff123"),
                "full_name": "Security Officer Gate 1",
                "phone_number": "+91 9876500001",
                "role": "staff",
                "is_active": True,
            },
        ]

        for u in demo_users:
            existing = db.query(User).filter(User.email == u["email"]).first()
            if not existing:
                user_obj = User(**u)
                db.add(user_obj)
                print(f"Created user: {u['email']} ({u['role']})")

        # 2. Safely deactivate old sample/development products (preserves existing orders & foreign keys)
        old_deactivated = db.query(Product).filter(
            Product.product_id.like("prod_%"),
            Product.is_active == True
        ).update({"is_active": False}, synchronize_session=False)
        if old_deactivated > 0:
            print(f"Safely deactivated {old_deactivated} old sample products (preserved in DB for foreign keys).")

        # 3. Upsert the 10 Authoritative QR Products
        seeded_count = 0
        updated_count = 0
        for p_data in QR_PRODUCTS:
            existing = db.query(Product).filter(
                or_(
                    Product.product_id == p_data["product_id"],
                    Product.barcode == p_data["barcode"]
                )
            ).first()
            if existing:
                for k, v in p_data.items():
                    setattr(existing, k, v)
                updated_count += 1
            else:
                p_obj = Product(**p_data)
                db.add(p_obj)
                seeded_count += 1

        db.commit()
        print(f"Successfully processed QR products: {seeded_count} newly created, {updated_count} updated. Total active: {len(QR_PRODUCTS)} products.")
    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_database()

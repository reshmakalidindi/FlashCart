import sys
import os

# Add parent directory to path so imports work cleanly
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal, Base, engine
from app.models.user import User
from app.models.product import Product
from app.core.security import get_password_hash

SAMPLE_PRODUCTS = [
    {
        "product_id": "prod_001",
        "barcode": "8901234567890",
        "name": "Amul Taaza Toned Milk",
        "brand": "Amul",
        "category": "Dairy",
        "price": 68.0,
        "mrp": 72.0,
        "weight": "1 L",
        "tax_rate": 0.0,
        "hsn_code": "0401",
        "stock": 100,
        "image_url": "https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_002",
        "barcode": "8901234567891",
        "name": "Parle-G Glucose Biscuits",
        "brand": "Parle",
        "category": "Biscuits & Snacks",
        "price": 20.0,
        "mrp": 25.0,
        "weight": "250 g",
        "tax_rate": 0.05,
        "hsn_code": "1905",
        "stock": 250,
        "image_url": "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_003",
        "barcode": "8901234567892",
        "name": "Dove Beauty Moisture Bar",
        "brand": "Dove",
        "category": "Personal Care",
        "price": 55.0,
        "mrp": 65.0,
        "weight": "100 g",
        "tax_rate": 0.18,
        "hsn_code": "3401",
        "stock": 80,
        "image_url": "https://images.unsplash.com/photo-1607006482602-76ca0fd2f47d?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_004",
        "barcode": "8901234567893",
        "name": "Aashirvaad Shuddh Chakki Atta",
        "brand": "Aashirvaad",
        "category": "Staples",
        "price": 345.0,
        "mrp": 380.0,
        "weight": "5 kg",
        "tax_rate": 0.0,
        "hsn_code": "1101",
        "stock": 50,
        "image_url": "https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_005",
        "barcode": "8901234567894",
        "name": "Tata Salt Vacuum Evaporated",
        "brand": "Tata",
        "category": "Staples",
        "price": 28.0,
        "mrp": 30.0,
        "weight": "1 kg",
        "tax_rate": 0.0,
        "hsn_code": "2501",
        "stock": 200,
        "image_url": "https://images.unsplash.com/photo-1518110168401-f2877ee2c88c?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_006",
        "barcode": "8901234567895",
        "name": "Fortune Sunlite Sunflower Oil",
        "brand": "Fortune",
        "category": "Edible Oils",
        "price": 145.0,
        "mrp": 170.0,
        "weight": "1 L",
        "tax_rate": 0.05,
        "hsn_code": "1512",
        "stock": 75,
        "image_url": "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_007",
        "barcode": "8901234567896",
        "name": "Maggi 2-Minute Masala Noodles",
        "brand": "Nestle",
        "category": "Instant Food",
        "price": 56.0,
        "mrp": 60.0,
        "weight": "280 g (Pack of 4)",
        "tax_rate": 0.12,
        "hsn_code": "1902",
        "stock": 120,
        "image_url": "https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_008",
        "barcode": "8901234567897",
        "name": "Cadbury Dairy Milk Silk",
        "brand": "Cadbury",
        "category": "Chocolates & Sweets",
        "price": 175.0,
        "mrp": 190.0,
        "weight": "150 g",
        "tax_rate": 0.18,
        "hsn_code": "1806",
        "stock": 90,
        "image_url": "https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_009",
        "barcode": "8901234567898",
        "name": "Colgate Total Dental Cream",
        "brand": "Colgate",
        "category": "Personal Care",
        "price": 120.0,
        "mrp": 140.0,
        "weight": "150 g",
        "tax_rate": 0.18,
        "hsn_code": "3306",
        "stock": 60,
        "image_url": "https://images.unsplash.com/photo-1559598467-f8b76c8155d0?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_010",
        "barcode": "8901234567899",
        "name": "Surf Excel Easy Wash Liquid",
        "brand": "Surf Excel",
        "category": "Household & Cleaning",
        "price": 230.0,
        "mrp": 260.0,
        "weight": "1 L",
        "tax_rate": 0.18,
        "hsn_code": "3402",
        "stock": 40,
        "image_url": "https://images.unsplash.com/photo-1585832770485-e68a5fc88280?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_011",
        "barcode": "8901234567800",
        "name": "Tata Tea Premium Masala Chai",
        "brand": "Tata Tea",
        "category": "Beverages",
        "price": 160.0,
        "mrp": 180.0,
        "weight": "500 g",
        "tax_rate": 0.05,
        "hsn_code": "0902",
        "stock": 110,
        "image_url": "https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_012",
        "barcode": "8901234567801",
        "name": "Haldiram's Nagpur Aloo Bhujia",
        "brand": "Haldiram",
        "category": "Biscuits & Snacks",
        "price": 85.0,
        "mrp": 100.0,
        "weight": "400 g",
        "tax_rate": 0.12,
        "hsn_code": "1905",
        "stock": 140,
        "image_url": "https://images.unsplash.com/photo-1621996346565-e3d5d628859e?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_013",
        "barcode": "8901234567802",
        "name": "Coca-Cola Original Taste",
        "brand": "Coca-Cola",
        "category": "Beverages",
        "price": 65.0,
        "mrp": 70.0,
        "weight": "1.25 L",
        "tax_rate": 0.28,
        "hsn_code": "2202",
        "stock": 100,
        "image_url": "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_014",
        "barcode": "8901234567803",
        "name": "Amul Pasteurized Butter",
        "brand": "Amul",
        "category": "Dairy",
        "price": 275.0,
        "mrp": 290.0,
        "weight": "500 g",
        "tax_rate": 0.12,
        "hsn_code": "0405",
        "stock": 65,
        "image_url": "https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_015",
        "barcode": "8901234567804",
        "name": "Nescafe Classic Instant Coffee",
        "brand": "Nescafe",
        "category": "Beverages",
        "price": 195.0,
        "mrp": 220.0,
        "weight": "100 g",
        "tax_rate": 0.18,
        "hsn_code": "2101",
        "stock": 85,
        "image_url": "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_016",
        "barcode": "8901234567805",
        "name": "Dettol Original Liquid Handwash",
        "brand": "Dettol",
        "category": "Personal Care",
        "price": 99.0,
        "mrp": 115.0,
        "weight": "200 ml",
        "tax_rate": 0.18,
        "hsn_code": "3401",
        "stock": 95,
        "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_017",
        "barcode": "8901234567806",
        "name": "Kellogg's Corn Flakes Original",
        "brand": "Kellogg's",
        "category": "Packaged Foods",
        "price": 185.0,
        "mrp": 210.0,
        "weight": "475 g",
        "tax_rate": 0.12,
        "hsn_code": "1904",
        "stock": 60,
        "image_url": "https://images.unsplash.com/photo-1521483451569-e33803c0330c?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_018",
        "barcode": "8901234567807",
        "name": "Daawat Rozana Gold Basmati Rice",
        "brand": "Daawat",
        "category": "Staples",
        "price": 399.0,
        "mrp": 450.0,
        "weight": "5 kg",
        "tax_rate": 0.0,
        "hsn_code": "1006",
        "stock": 45,
        "image_url": "https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_019",
        "barcode": "8901234567808",
        "name": "Saffola Gold Pro Healthy Oil",
        "brand": "Saffola",
        "category": "Edible Oils",
        "price": 180.0,
        "mrp": 210.0,
        "weight": "1 L",
        "tax_rate": 0.05,
        "hsn_code": "1517",
        "stock": 70,
        "image_url": "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_020",
        "barcode": "8901234567809",
        "name": "Head & Shoulders Cool Menthol Shampoo",
        "brand": "Head & Shoulders",
        "category": "Personal Care",
        "price": 240.0,
        "mrp": 280.0,
        "weight": "340 ml",
        "tax_rate": 0.18,
        "hsn_code": "3305",
        "stock": 55,
        "image_url": "https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_021",
        "barcode": "8901234567810",
        "name": "Vim Lemon Dishwash Gel",
        "brand": "Vim",
        "category": "Household & Cleaning",
        "price": 110.0,
        "mrp": 125.0,
        "weight": "500 ml",
        "tax_rate": 0.18,
        "hsn_code": "3402",
        "stock": 85,
        "image_url": "https://images.unsplash.com/photo-1585832770485-e68a5fc88280?auto=format&fit=crop&w=400&q=80",
    },
    {
        "product_id": "prod_022",
        "barcode": "8901234567811",
        "name": "Kissan Fresh Tomato Ketchup",
        "brand": "Kissan",
        "category": "Packaged Foods",
        "price": 130.0,
        "mrp": 150.0,
        "weight": "950 g",
        "tax_rate": 0.12,
        "hsn_code": "2103",
        "stock": 75,
        "image_url": "https://images.unsplash.com/photo-1589118949245-7d38baf380d6?auto=format&fit=crop&w=400&q=80",
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
                "email": "staff@dmart.com",
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

        # 2. Seed 22 supermarket products
        seeded_count = 0
        updated_count = 0
        for p_data in SAMPLE_PRODUCTS:
            existing = db.query(Product).filter(Product.barcode == p_data["barcode"]).first()
            if existing:
                for k, v in p_data.items():
                    setattr(existing, k, v)
                updated_count += 1
            else:
                p_obj = Product(**p_data, store_id="STORE_DMART_001", is_active=True)
                db.add(p_obj)
                seeded_count += 1

        db.commit()
        print(f"Successfully seeded {seeded_count} products (updated {updated_count}). Total: {len(SAMPLE_PRODUCTS)} products.")
    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_database()

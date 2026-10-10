import os
import sys
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ensure backend root is on Python path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.database import Base, get_db
from app.core.config import settings
from app.main import app
from app.models.product import Product
from app.models.user import User
from app.core.security import get_password_hash

TEST_DB_URL = "sqlite:///./test_flashcart.db"
test_engine = create_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture(scope="session", autouse=True)
def setup_test_database():
    # Remove old test db file if exists
    if os.path.exists("./test_flashcart.db"):
        os.remove("./test_flashcart.db")

    Base.metadata.create_all(bind=test_engine)
    app.dependency_overrides[get_db] = override_get_db

    db = TestingSessionLocal()
    # Seed minimal test data
    db.add(User(
        user_id="usr_test_shopper",
        email="testshopper@example.com",
        hashed_password=get_password_hash("password123"),
        full_name="Test Shopper",
        role="customer",
        is_active=True
    ))

    # Add 3 representative products for testing
    products = [
        Product(
            product_id="prod_001",
            barcode="8901234567890",
            name="Amul Taaza Toned Milk",
            brand="Amul",
            category="Dairy",
            price=68.0,
            mrp=72.0,
            weight="1 L",
            tax_rate=0.0,
            stock=100,
            store_id="STORE_DMART_001",
            is_active=True
        ),
        Product(
            product_id="prod_002",
            barcode="8901234567891",
            name="Parle-G Glucose Biscuits",
            brand="Parle",
            category="Biscuits & Snacks",
            price=20.0,
            mrp=25.0,
            weight="250 g",
            tax_rate=0.05,
            stock=250,
            store_id="STORE_DMART_001",
            is_active=True
        ),
        Product(
            product_id="prod_003",
            barcode="8901234567892",
            name="Dove Beauty Moisture Bar",
            brand="Dove",
            category="Personal Care",
            price=55.0,
            mrp=65.0,
            weight="100 g",
            tax_rate=0.18,
            stock=80,
            store_id="STORE_DMART_001",
            is_active=True
        ),
    ]
    for p in products:
        db.add(p)
    db.commit()
    db.close()

    yield

    # Teardown
    Base.metadata.drop_all(bind=test_engine)
    if os.path.exists("./test_flashcart.db"):
        os.remove("./test_flashcart.db")


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c

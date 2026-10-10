import pytest
from app.core.config import Settings
from app.core.database import get_engine, Base
from app.models.cart import Cart, CartItem
from app.models.payment import PaymentRecord
from app.models.order import Order


def test_mysql_is_single_primary_database():
    """Verify that FlashCart is configured strictly for MySQL without SQLite fallback."""
    cfg = Settings(
        MYSQL_USER="testuser",
        MYSQL_PASSWORD="testpassword",
        MYSQL_HOST="127.0.0.1",
        MYSQL_PORT=3306,
        MYSQL_DATABASE="flashcart_test",
    )
    url = cfg.sqlalchemy_database_url
    assert url.startswith("mysql+pymysql://")
    assert "testuser:testpassword@127.0.0.1:3306/flashcart_test" in url

    # Test with unix socket
    cfg_sock = Settings(
        MYSQL_USER="testuser",
        MYSQL_PASSWORD="",
        MYSQL_DATABASE="flashcart_sock",
        MYSQL_UNIX_SOCKET="/tmp/mysql.sock"
    )
    sock_url = cfg_sock.sqlalchemy_database_url
    assert "unix_socket=/tmp/mysql.sock" in sock_url


def test_sqlite_fallback_is_completely_disabled():
    """Verify that get_engine raises RuntimeError when non-MySQL protocol is requested."""
    with pytest.raises(RuntimeError) as exc_info:
        get_engine("sqlite:///./fallback.db")
    
    assert "Automatic SQLite fallback is disabled" in str(exc_info.value)
    assert "strictly configured to use MySQL" in str(exc_info.value)


def test_all_models_registered_in_metadata():
    """Verify that products, users, carts, cart_items, orders, order_items, payments, and exit_verifications exist."""
    table_names = Base.metadata.tables.keys()
    required_tables = [
        "users",
        "products",
        "carts",
        "cart_items",
        "orders",
        "order_items",
        "payments",
        "exit_verifications"
    ]
    for table in required_tables:
        assert table in table_names, f"Table '{table}' missing from Base.metadata"


def test_cart_persistence_in_database(client, db_session):
    """Verify that revalidating cart with user_id persists Cart and CartItems in the database."""
    user_id = "usr_test_shopper"
    payload = {
        "user_id": user_id,
        "items": [
            {"barcode": "8901234567890", "quantity": 2},
            {"barcode": "8901234567891", "quantity": 1}
        ],
        "coupon_code": "WELCOME"
    }
    res = client.post("/api/v1/cart/revalidate", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["cart_id"] is not None
    cart_id = data["cart_id"]

    # Verify directly in database via db_session
    db_cart = db_session.query(Cart).filter(Cart.cart_id == cart_id).first()
    assert db_cart is not None
    assert db_cart.user_id == user_id
    assert db_cart.status == "ACTIVE"
    assert db_cart.coupon_code == "WELCOME"
    assert len(db_cart.items) == 2

    # Verify retrieval endpoint
    get_res = client.get(f"/api/v1/cart/user/{user_id}")
    assert get_res.status_code == 200
    cart_data = get_res.json()
    assert cart_data["cart_id"] == cart_id
    assert len(cart_data["items"]) == 2


def test_payment_record_persisted_in_database(client, db_session):
    """Verify that processing payment records PaymentRecord in MySQL payments table."""
    # 1. Create order
    order_res = client.post("/api/v1/orders/", json={
        "user_id": "usr_test_shopper",
        "items": [{"barcode": "8901234567891", "quantity": 2}],
        "payment_method": "MOCK_UPI"
    })
    assert order_res.status_code == 201
    order_id = order_res.json()["order_id"]

    # 2. Pay order
    pay_res = client.post("/api/v1/payments/mock-verify", json={
        "order_id": order_id,
        "payment_method": "MOCK_UPI"
    })
    assert pay_res.status_code == 200
    pay_data = pay_res.json()
    payment_id = pay_data["payment_id"]

    # 3. Assert PaymentRecord exists in database
    payment_record = db_session.query(PaymentRecord).filter(PaymentRecord.payment_id == payment_id).first()
    assert payment_record is not None
    assert payment_record.order_id == order_id
    assert payment_record.payment_status == "SUCCESS"
    assert payment_record.amount == pay_data["grand_total"]
    assert payment_record.exit_token == pay_data["exit_token"]

    # 4. Check order's relationship with payments
    order_obj = db_session.query(Order).filter(Order.order_id == order_id).first()
    assert len(order_obj.payments) >= 1
    assert order_obj.payments[0].payment_id == payment_id


def test_cart_converted_when_order_placed(client, db_session):
    """Verify that placing an order automatically converts any active cart for that user."""
    user_id = "usr_test_shopper"
    
    # 1. Save an active cart
    client.post("/api/v1/cart/revalidate", json={
        "user_id": user_id,
        "items": [{"barcode": "8901234567891", "quantity": 1}]
    })
    active_cart_before = db_session.query(Cart).filter(Cart.user_id == user_id, Cart.status == "ACTIVE").first()
    assert active_cart_before is not None

    # 2. Place an order for this user
    client.post("/api/v1/orders/", json={
        "user_id": user_id,
        "items": [{"barcode": "8901234567891", "quantity": 1}],
        "payment_method": "MOCK_UPI"
    })

    # 3. Verify cart status changed to CONVERTED
    db_session.refresh(active_cart_before)
    assert active_cart_before.status == "CONVERTED"

def test_create_order_authoritatively(client):
    payload = {
        "user_id": "usr_test_shopper",
        "items": [
            {"barcode": "8901234567891", "quantity": 3}  # Parle-G: 20 * 3 = 60, GST 5% = 3.00, total = 63.00
        ],
        "payment_method": "MOCK_UPI",
        "store_id": "STORE_DMART_001"
    }
    response = client.post("/api/v1/orders/", json=payload)
    assert response.status_code == 201
    order = response.json()
    assert order["order_id"].startswith("ORD-")
    assert order["subtotal"] == 60.0
    assert order["tax_amount"] == 3.0
    assert order["grand_total"] == 63.0
    assert order["payment_status"] == "UNPAID"
    assert order["exit_verified"] is False
    assert len(order["items"]) == 1


def test_get_order_by_id(client):
    # First create an order
    payload = {
        "user_id": "usr_test_shopper",
        "items": [{"barcode": "8901234567890", "quantity": 1}],
        "payment_method": "MOCK_UPI"
    }
    created = client.post("/api/v1/orders/", json=payload).json()
    order_id = created["order_id"]

    response = client.get(f"/api/v1/orders/{order_id}")
    assert response.status_code == 200
    retrieved = response.json()
    assert retrieved["order_id"] == order_id
    assert retrieved["grand_total"] == 68.0


def test_get_user_orders(client):
    response = client.get("/api/v1/orders/user/usr_test_shopper")
    assert response.status_code == 200
    orders = response.json()
    assert len(orders) >= 1
    assert all(o["user_id"] == "usr_test_shopper" for o in orders)

def test_mock_payment_success(client):
    # 1. Create order
    payload = {
        "user_id": "usr_test_shopper",
        "items": [{"barcode": "8901234567891", "quantity": 1}],
        "payment_method": "MOCK_UPI"
    }
    order = client.post("/api/v1/orders/", json=payload).json()
    order_id = order["order_id"]

    # 2. Pay order
    pay_res = client.post("/api/v1/payments/mock-verify", json={
        "order_id": order_id,
        "payment_method": "MOCK_UPI"
    })
    assert pay_res.status_code == 200
    pay_data = pay_res.json()
    assert pay_data["status"] == "SUCCESS"
    assert pay_data["payment_id"].startswith("PAY-MOCK-")
    assert pay_data["exit_token"].startswith(f"EXIT_{order_id}")

    # 3. Check order is updated in DB
    updated_order = client.get(f"/api/v1/orders/{order_id}").json()
    assert updated_order["payment_status"] == "PAID"
    assert updated_order["exit_token"] == pay_data["exit_token"]


def test_duplicate_payment_returns_existing_token(client):
    # Create and pay
    payload = {
        "user_id": "usr_test_shopper",
        "items": [{"barcode": "8901234567891", "quantity": 1}],
        "payment_method": "MOCK_UPI"
    }
    order = client.post("/api/v1/orders/", json=payload).json()
    order_id = order["order_id"]

    first_pay = client.post("/api/v1/payments/mock-verify", json={
        "order_id": order_id,
        "payment_method": "MOCK_UPI"
    }).json()

    # Second pay call
    second_pay = client.post("/api/v1/payments/mock-verify", json={
        "order_id": order_id,
        "payment_method": "MOCK_UPI"
    }).json()

    assert second_pay["status"] == "ALREADY_PAID"
    assert second_pay["exit_token"] == first_pay["exit_token"]

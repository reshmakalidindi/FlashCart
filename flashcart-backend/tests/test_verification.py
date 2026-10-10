def test_verify_unpaid_order_fails(client):
    # Create order without paying
    order = client.post("/api/v1/orders/", json={
        "user_id": "usr_test_shopper",
        "items": [{"barcode": "8901234567890", "quantity": 1}]
    }).json()

    verify_res = client.post("/api/v1/orders/verify-exit", json={
        "order_id_or_token": order["order_id"],
        "staff_id": "staff_gate_01"
    })
    assert verify_res.status_code == 200
    data = verify_res.json()
    assert data["success"] is False
    assert data["status"] == "UNPAID"


def test_verify_paid_order_succeeds(client):
    # 1. Create and pay order
    order = client.post("/api/v1/orders/", json={
        "user_id": "usr_test_shopper",
        "items": [{"barcode": "8901234567890", "quantity": 1}]
    }).json()
    order_id = order["order_id"]

    pay_res = client.post("/api/v1/payments/mock-verify", json={
        "order_id": order_id
    }).json()
    exit_token = pay_res["exit_token"]

    # 2. Staff scans QR exit token
    verify_res = client.post("/api/v1/orders/verify-exit", json={
        "order_id_or_token": exit_token,
        "staff_id": "staff_guard_alpha"
    })
    assert verify_res.status_code == 200
    data = verify_res.json()
    assert data["success"] is True
    assert data["status"] == "SUCCESS"
    assert data["verified_by"] == "staff_guard_alpha"
    assert data["order_id"] == order_id


def test_duplicate_exit_verification_blocked(client):
    # 1. Create and pay order
    order = client.post("/api/v1/orders/", json={
        "user_id": "usr_test_shopper",
        "items": [{"barcode": "8901234567890", "quantity": 1}]
    }).json()
    order_id = order["order_id"]

    pay_res = client.post("/api/v1/payments/mock-verify", json={
        "order_id": order_id
    }).json()
    exit_token = pay_res["exit_token"]

    # 2. First exit verification
    first_res = client.post("/api/v1/orders/verify-exit", json={
        "order_id_or_token": exit_token,
        "staff_id": "staff_gate_01"
    }).json()
    assert first_res["success"] is True

    # 3. Duplicate exit verification (same token scanned again)
    second_res = client.post("/api/v1/orders/verify-exit", json={
        "order_id_or_token": exit_token,
        "staff_id": "staff_gate_02"
    }).json()
    assert second_res["success"] is False
    assert second_res["status"] == "ALREADY_VERIFIED"
    assert "already been verified" in second_res["message"]


def test_verify_non_existent_token_fails(client):
    res = client.post("/api/v1/orders/verify-exit", json={
        "order_id_or_token": "NON_EXISTENT_QR_CODE",
        "staff_id": "staff_gate_01"
    }).json()
    assert res["success"] is False
    assert res["status"] == "NOT_FOUND"

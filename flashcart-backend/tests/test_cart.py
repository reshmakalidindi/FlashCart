def test_cart_empty_revalidation(client):
    response = client.post("/api/v1/cart/revalidate", json={"items": []})
    assert response.status_code == 200
    data = response.json()
    assert data["grand_total"] == 0.0
    assert data["total_items"] == 0
    assert len(data["items"]) == 0


def test_cart_authoritative_calculation(client):
    # Request with 2 milk (68 each, 0% GST) and 1 soap (55, 18% GST = 9.90)
    payload = {
        "items": [
            {"barcode": "8901234567890", "quantity": 2},
            {"barcode": "8901234567892", "quantity": 1}
        ]
    }
    response = client.post("/api/v1/cart/revalidate", json=payload)
    assert response.status_code == 200
    data = response.json()
    # Subtotal = 2 * 68 + 1 * 55 = 136 + 55 = 191.0
    assert data["subtotal"] == 191.0
    # Tax = 0 + 55 * 0.18 = 9.90
    assert data["tax_amount"] == 9.90
    # Grand total = 191 + 9.90 = 200.90
    assert data["grand_total"] == 200.90
    assert data["total_items"] == 3


def test_cart_coupon_application(client):
    # 5 milk = 5 * 68 = 340.0 (subtotal >= 300, qualifies for FLASH50)
    payload = {
        "items": [
            {"barcode": "8901234567890", "quantity": 5}
        ],
        "coupon_code": "FLASH50"
    }
    response = client.post("/api/v1/cart/revalidate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["subtotal"] == 340.0
    assert data["discount_amount"] == 50.0
    assert data["grand_total"] == 290.0
    assert "FLASH50" in data["coupon_applied"]


def test_cart_invalid_barcode_rejected(client):
    payload = {
        "items": [
            {"barcode": "0000000000000", "quantity": 1}
        ]
    }
    response = client.post("/api/v1/cart/revalidate", json=payload)
    assert response.status_code == 404

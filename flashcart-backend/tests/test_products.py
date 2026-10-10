def test_get_products(client):
    response = client.get("/api/v1/products/")
    assert response.status_code == 200
    products = response.json()
    assert len(products) >= 3
    assert any(p["barcode"] == "8901234567890" for p in products)


def test_get_categories(client):
    response = client.get("/api/v1/products/categories")
    assert response.status_code == 200
    data = response.json()
    assert "categories" in data
    assert "Dairy" in data["categories"]
    assert "Biscuits & Snacks" in data["categories"]


def test_barcode_lookup_success(client):
    response = client.get("/api/v1/products/barcode/8901234567890")
    assert response.status_code == 200
    data = response.json()
    assert data["found"] is True
    assert data["product"]["name"] == "Amul Taaza Toned Milk"
    assert data["product"]["price"] == 68.0


def test_barcode_lookup_not_found(client):
    response = client.get("/api/v1/products/barcode/9999999999999")
    assert response.status_code == 200
    data = response.json()
    assert data["found"] is False
    assert data["product"] is None


def test_get_product_by_id_success(client):
    response = client.get("/api/v1/products/prod_001")
    assert response.status_code == 200
    data = response.json()
    assert data["product_id"] == "prod_001"
    assert data["name"] == "Amul Taaza Toned Milk"


def test_get_product_by_id_not_found(client):
    response = client.get("/api/v1/products/non_existent_id")
    assert response.status_code == 404


def test_all_10_qr_products_lookup_and_prices(client):
    expected_products = [
        ("P001", "FLASHCART-P001", "Maggi", 20.0),
        ("P002", "FLASHCART-P002", "Biscuit packets", 15.0),
        ("P003", "FLASHCART-P003", "Surf Excel", 70.0),
        ("P004", "FLASHCART-P004", "Stationery", 200.0),
        ("P005", "FLASHCART-P005", "College bag", 699.0),
        ("P006", "FLASHCART-P006", "Water bottle", 288.0),
        ("P007", "FLASHCART-P007", "Sonpapidi (sweet)", 154.0),
        ("P008", "FLASHCART-P008", "Paneer", 299.0),
        ("P009", "FLASHCART-P009", "Cool drinks", 40.0),
        ("P0010", "FLASHCART-P0010", "Lays packet", 50.0),
    ]

    for pid, barcode, name, price in expected_products:
        # 1. Lookup by full scanned QR payload (FLASHCART-Pxxx)
        resp1 = client.get(f"/api/v1/products/barcode/{barcode}")
        assert resp1.status_code == 200
        data1 = resp1.json()
        assert data1["found"] is True, f"Failed to locate {barcode}"
        assert data1["product"]["product_id"] == pid
        assert data1["product"]["name"] == name
        assert data1["product"]["price"] == price

        # 2. Lookup by raw product_id in barcode endpoint
        resp2 = client.get(f"/api/v1/products/barcode/{pid}")
        assert resp2.status_code == 200
        data2 = resp2.json()
        assert data2["found"] is True
        assert data2["product"]["product_id"] == pid

        # 3. Lookup by direct product_id endpoint
        resp3 = client.get(f"/api/v1/products/{pid}")
        assert resp3.status_code == 200
        data3 = resp3.json()
        assert data3["name"] == name
        assert data3["price"] == price


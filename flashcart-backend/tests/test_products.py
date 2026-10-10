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

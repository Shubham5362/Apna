import io
import pytest
from sqlalchemy.orm import Session
from fastapi.testclient import TestClient

from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.shop import Shop
from app.models.product import Product
from app.core.security import create_access_token

client = TestClient(app)


@pytest.fixture(name="db")
def db_fixture():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def get_auth_token(db: Session, phone_number: str = "+917777777777", full_name: str = "Product Tester") -> str:
    user = db.query(User).filter(User.phone_number == phone_number).first()
    if not user:
        user = User(phone_number=phone_number, full_name=full_name, is_active=True)
        db.add(user)
        db.commit()
        db.refresh(user)
    return create_access_token(subject=user.id)


def test_create_product_unauthenticated():
    response = client.post(
        "/api/v1/products",
        json={"name": "Apple", "price": 2.5, "stock": 50, "shop_id": 1},
    )
    assert response.status_code == 401


def test_create_product_success(db: Session):
    db.query(Product).delete()
    db.query(Shop).delete()
    db.commit()

    token = get_auth_token(db, "+917777777777", "Shop Owner")
    owner = db.query(User).filter(User.phone_number == "+917777777777").first()

    shop = Shop(name="Fresh Fruits", description="Daily fresh fruits shop", owner_id=owner.id)
    db.add(shop)
    db.commit()
    db.refresh(shop)

    response = client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "name": "Apple Organic",
            "description": "Sweet red apples",
            "category": "Fruits",
            "brand": "AppleBrand",
            "price": 3.99,
            "mrp": 4.99,
            "stock": 100,
            "shop_id": shop.id,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Apple Organic"
    assert data["price"] == 3.99
    assert data["mrp"] == 4.99
    assert data["brand"] == "AppleBrand"
    assert data["category"] == "Fruits"
    assert data["stock"] == 100


def test_create_product_unauthorized(db: Session):
    shop = db.query(Shop).first()
    assert shop is not None

    token = get_auth_token(db, "+911111111111", "Another User")
    response = client.post(
        "/api/v1/products",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "name": "Hacker Apple",
            "price": 100.0,
            "stock": 1,
            "shop_id": shop.id,
        },
    )
    assert response.status_code == 403


def test_get_products_list_and_search(db: Session):
    shop = db.query(Shop).first()
    assert shop is not None

    p2 = Product(
        name="Banana Yellow",
        description="Fresh yellow bananas",
        category="Fruits",
        brand="BananaBrand",
        price=1.49,
        mrp=1.99,
        stock=200,
        shop_id=shop.id,
    )
    db.add(p2)
    db.commit()

    # 1. Get all products
    response = client.get("/api/v1/products")
    assert response.status_code == 200
    assert len(response.json()) >= 2

    # 2. Search by name "Banana"
    response = client.get("/api/v1/products?search=Banana")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["name"] == "Banana Yellow"

    # 3. Filter by category "Fruits"
    response = client.get("/api/v1/products?category=Fruits")
    assert response.status_code == 200
    assert len(response.json()) >= 2

    # 4. Sorting price low-high
    response = client.get("/api/v1/products?sort_by=price+low-high")
    assert response.status_code == 200
    data = response.json()
    assert data[0]["price"] == 1.49

    # 5. Sorting oldest
    response = client.get("/api/v1/products?sort_by=oldest")
    assert response.status_code == 200
    data = response.json()
    assert data[0]["name"] == "Apple Organic"


def test_get_product_by_id_success(db: Session):
    product = db.query(Product).filter(Product.name == "Apple Organic").first()
    assert product is not None

    response = client.get(f"/api/v1/products/{product.id}")
    assert response.status_code == 200
    assert response.json()["name"] == "Apple Organic"


def test_get_product_by_id_not_found():
    response = client.get("/api/v1/products/99999")
    assert response.status_code == 404


def test_update_product_success(db: Session):
    product = db.query(Product).filter(Product.name == "Apple Organic").first()
    assert product is not None
    shop = db.query(Shop).filter(Shop.id == product.shop_id).first()
    owner = db.query(User).filter(User.id == shop.owner_id).first()

    token = create_access_token(subject=owner.id)
    response = client.put(
        f"/api/v1/products/{product.id}",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Apple Premium Organic", "price": 4.5, "mrp": 5.5, "brand": "SuperApple"},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Apple Premium Organic"
    assert response.json()["price"] == 4.5
    assert response.json()["mrp"] == 5.5
    assert response.json()["brand"] == "SuperApple"


def test_update_product_unauthorized(db: Session):
    product = db.query(Product).first()
    assert product is not None

    token = get_auth_token(db, "+911111111111", "Another User")
    response = client.put(
        f"/api/v1/products/{product.id}",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Hacked Product Name"},
    )
    assert response.status_code == 403


def test_upload_product_photo_success(db: Session):
    product = db.query(Product).first()
    assert product is not None
    shop = db.query(Shop).filter(Shop.id == product.shop_id).first()
    owner = db.query(User).filter(User.id == shop.owner_id).first()

    token = create_access_token(subject=owner.id)
    dummy_image = io.BytesIO(b"product image bytes")
    response = client.post(
        f"/api/v1/products/{product.id}/photo",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("product.jpg", dummy_image, "image/jpeg")},
    )
    assert response.status_code == 200
    assert response.json()["image_url"] is not None


def test_delete_product_unauthorized(db: Session):
    product = db.query(Product).first()
    assert product is not None

    token = get_auth_token(db, "+911111111111", "Another User")
    response = client.delete(
        f"/api/v1/products/{product.id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 403


def test_delete_product_success(db: Session):
    product = db.query(Product).filter(Product.name == "Apple Premium Organic").first()
    assert product is not None
    shop = db.query(Shop).filter(Shop.id == product.shop_id).first()
    owner = db.query(User).filter(User.id == shop.owner_id).first()

    token = create_access_token(subject=owner.id)
    response = client.delete(
        f"/api/v1/products/{product.id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200

    deleted = db.query(Product).filter(Product.id == product.id).first()
    assert deleted is None

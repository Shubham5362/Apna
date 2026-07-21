import pytest
from sqlalchemy.orm import Session
from fastapi.testclient import TestClient

from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.shop import Shop
from app.models.product import Product
from app.models.cart import CartItem
from app.models.order import Order
from app.core.security import create_access_token

client = TestClient(app)


@pytest.fixture(name="db")
def db_fixture():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def get_auth_token(db: Session, phone_number: str = "+916666666666", full_name: str = "Cart Tester") -> str:
    user = db.query(User).filter(User.phone_number == phone_number).first()
    if not user:
        user = User(phone_number=phone_number, full_name=full_name, is_active=True)
        db.add(user)
        db.commit()
        db.refresh(user)
    return create_access_token(subject=user.id)


def test_cart_operations_success(db: Session):
    # Setup: clean cart, products, shops
    db.query(CartItem).delete()
    db.query(Product).delete()
    db.query(Shop).delete()
    db.commit()

    token = get_auth_token(db, "+916666666666", "Cart Owner")
    owner = db.query(User).filter(User.phone_number == "+916666666666").first()

    # Create a shop and product
    shop = Shop(name="Cart Shop", description="Shop for cart tests", owner_id=owner.id)
    db.add(shop)
    db.commit()
    db.refresh(shop)

    product = Product(
        name="Cart Banana",
        price=1.20,
        stock=50,
        shop_id=shop.id,
        is_active=True,
    )
    db.add(product)
    db.commit()
    db.refresh(product)

    # 1. Add to cart
    response = client.post(
        "/api/v1/cart",
        headers={"Authorization": f"Bearer {token}"},
        json={"product_id": product.id, "quantity": 2},
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) == 1
    assert data["items"][0]["product_id"] == product.id
    assert data["items"][0]["quantity"] == 2
    assert data["total_price"] == 2.40

    cart_item_id = data["items"][0]["id"]

    # 2. Update quantity
    response = client.put(
        f"/api/v1/cart/{cart_item_id}",
        headers={"Authorization": f"Bearer {token}"},
        json={"quantity": 5},
    )
    assert response.status_code == 200
    assert response.json()["items"][0]["quantity"] == 5
    assert response.json()["total_price"] == 6.00

    # 3. Add same product again (increments quantity)
    response = client.post(
        "/api/v1/cart",
        headers={"Authorization": f"Bearer {token}"},
        json={"product_id": product.id, "quantity": 10},
    )
    assert response.status_code == 200
    assert response.json()["items"][0]["quantity"] == 15
    assert response.json()["total_price"] == 18.00


def test_add_to_cart_exceeds_stock(db: Session):
    token = get_auth_token(db, "+916666666666")
    product = db.query(Product).first()
    assert product is not None

    response = client.post(
        "/api/v1/cart",
        headers={"Authorization": f"Bearer {token}"},
        json={"product_id": product.id, "quantity": 1000},
    )
    assert response.status_code == 400
    assert "are available in stock" in response.json()["error"]["message"]


def test_create_order_success(db: Session):
    token = get_auth_token(db, "+916666666666")
    product = db.query(Product).first()
    assert product is not None
    initial_stock = product.stock

    # Cart should currently have 15 bananas (from previous test)
    # Let's create an order
    response = client.post(
        "/api/v1/orders",
        headers={"Authorization": f"Bearer {token}"},
        json={"delivery_address": "123 Green Boulevard, Mumbai"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "Pending"
    assert data["total_price"] == 18.00
    assert data["delivery_address"] == "123 Green Boulevard, Mumbai"
    assert len(data["items"]) == 1
    assert data["items"][0]["product_id"] == product.id
    assert data["items"][0]["quantity"] == 15

    # Check stock deduction
    db.refresh(product)
    assert product.stock == initial_stock - 15

    # Check cart is cleared
    response = client.get("/api/v1/cart", headers={"Authorization": f"Bearer {token}"})
    assert len(response.json()["items"]) == 0


def test_get_orders_list(db: Session):
    token = get_auth_token(db, "+916666666666")
    response = client.get("/api/v1/orders", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    assert len(response.json()) >= 1


def test_update_order_status_success(db: Session):
    token = get_auth_token(db, "+916666666666")
    order = db.query(Order).first()
    assert order is not None

    response = client.put(
        f"/api/v1/orders/{order.id}/status",
        headers={"Authorization": f"Bearer {token}"},
        json={"status": "Confirmed"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "Confirmed"


def test_update_order_status_validation_error(db: Session):
    token = get_auth_token(db, "+916666666666")
    order = db.query(Order).first()
    assert order is not None

    response = client.put(
        f"/api/v1/orders/{order.id}/status",
        headers={"Authorization": f"Bearer {token}"},
        json={"status": "InvalidStatusLabel"},
    )
    assert response.status_code == 422

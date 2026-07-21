import pytest
from sqlalchemy.orm import Session
from fastapi.testclient import TestClient

from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.shop import Shop
from app.models.product import Product
from app.models.order import Order, OrderItem
from app.models.payment import Payment
from app.core.security import create_access_token

client = TestClient(app)


@pytest.fixture(name="db")
def db_fixture():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def get_auth_token(db: Session, phone_number: str = "+918888888888", full_name: str = "Payment Tester") -> str:
    user = db.query(User).filter(User.phone_number == phone_number).first()
    if not user:
        user = User(phone_number=phone_number, full_name=full_name, is_active=True)
        db.add(user)
        db.commit()
        db.refresh(user)
    return create_access_token(subject=user.id)


def test_payment_flow_success(db: Session):
    # Setup
    db.query(Payment).delete()
    db.query(OrderItem).delete()
    db.query(Order).delete()
    db.query(Product).delete()
    db.query(Shop).delete()
    db.commit()

    token = get_auth_token(db, "+918888888888", "Payment Owner")
    owner = db.query(User).filter(User.phone_number == "+918888888888").first()

    # Create shop & product
    shop = Shop(name="Payment Shop", description="Shop for payment tests", owner_id=owner.id)
    db.add(shop)
    db.commit()
    db.refresh(shop)

    product = Product(
        name="Payment Apple",
        price=2.50,
        stock=100,
        shop_id=shop.id,
        is_active=True,
    )
    db.add(product)
    db.commit()
    db.refresh(product)

    # 1. Create Order
    order = Order(
        user_id=owner.id,
        status="Pending",
        total_price=5.00,
        delivery_address="456 Flower St, Delhi",
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    # 2. Create Payment API
    response = client.post(
        "/api/v1/payments/create",
        headers={"Authorization": f"Bearer {token}"},
        json={"order_id": order.id, "payment_method": "UPI"},
    )
    assert response.status_code == 201
    payment_data = response.json()
    assert payment_data["status"] == "Pending"
    assert payment_data["payment_method"] == "UPI"
    assert payment_data["amount"] == 5.00
    assert payment_data["razorpay_order_id"] is not None

    razorpay_order_id = payment_data["razorpay_order_id"]

    # Verify Order Response now contains "Pending" payment_status
    order_response = client.get(
        f"/api/v1/orders/{order.id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert order_response.status_code == 200
    assert order_response.json()["payment_status"] == "Pending"

    # 3. Verify Payment API (using mock_sig)
    response = client.post(
        "/api/v1/payments/verify",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "razorpay_order_id": razorpay_order_id,
            "razorpay_payment_id": "pay_mock123456",
            "razorpay_signature": "mock_sig",
        },
    )
    assert response.status_code == 200
    verified_data = response.json()
    assert verified_data["status"] == "Success"

    # Verify Order Status became "Confirmed" and Order payment_status became "Success"
    db.refresh(order)
    assert order.status == "Confirmed"

    order_response = client.get(
        f"/api/v1/orders/{order.id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert order_response.status_code == 200
    assert order_response.json()["payment_status"] == "Success"
    assert order_response.json()["status"] == "Confirmed"


def test_payment_history(db: Session):
    token = get_auth_token(db, "+918888888888")
    response = client.get(
        "/api/v1/payments/history",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    history = response.json()
    assert len(history) >= 1
    assert history[0]["status"] == "Success"
    assert history[0]["payment_method"] == "UPI"


def test_payment_webhook_captured(db: Session):
    # Setup another order
    owner = db.query(User).filter(User.phone_number == "+918888888888").first()
    order = Order(
        user_id=owner.id,
        status="Pending",
        total_price=10.00,
        delivery_address="789 Webhook St, Delhi",
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    payment = Payment(
        order_id=order.id,
        razorpay_order_id="order_webhook_pending_123",
        payment_method="Card",
        status="Pending",
        amount=10.00,
    )
    db.add(payment)
    db.commit()

    # Post simulated Webhook Event
    response = client.post(
        "/api/v1/payments/webhook",
        json={
            "event": "payment.captured",
            "payload": {
                "payment": {
                    "entity": {
                        "id": "pay_captured123",
                        "order_id": "order_webhook_pending_123",
                        "amount": 1000,
                    }
                }
            }
        },
    )
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

    db.refresh(payment)
    assert payment.status == "Success"
    assert payment.razorpay_payment_id == "pay_captured123"

    db.refresh(order)
    assert order.status == "Confirmed"

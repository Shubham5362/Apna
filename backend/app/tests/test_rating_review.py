import pytest
from sqlalchemy.orm import Session
from fastapi.testclient import TestClient

from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.shop import Shop
from app.models.product import Product
from app.models.rating_review import Rating, Review
from app.core.security import create_access_token

client = TestClient(app)


@pytest.fixture(name="db")
def db_fixture():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def get_auth_token(db: Session, phone_number: str = "+915555555555", full_name: str = "Review Tester") -> str:
    user = db.query(User).filter(User.phone_number == phone_number).first()
    if not user:
        user = User(phone_number=phone_number, full_name=full_name, is_active=True)
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        user.full_name = full_name
        db.commit()
        db.refresh(user)
    return create_access_token(subject=user.id)


def test_rating_review_lifecycle_success(db: Session):
    # Setup
    db.query(Review).delete()
    db.query(Rating).delete()
    db.query(Product).delete()
    db.query(Shop).delete()
    db.commit()

    token = get_auth_token(db, "+915555555555", "Alice Reviewer")
    owner_token = get_auth_token(db, "+915555555556", "Shop Owner")

    alice = db.query(User).filter(User.phone_number == "+915555555555").first()
    owner = db.query(User).filter(User.phone_number == "+915555555556").first()

    # Create shop and product
    shop = Shop(name="Review Shop", description="Shop for review tests", owner_id=owner.id)
    db.add(shop)
    db.commit()
    db.refresh(shop)

    product = Product(
        name="Review Mango",
        price=3.50,
        stock=50,
        shop_id=shop.id,
        is_active=True,
    )
    db.add(product)
    db.commit()
    db.refresh(product)

    # 1. Create a Review (Product)
    response = client.post(
        "/api/v1/reviews",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "product_id": product.id,
            "rating_value": 5,
            "comment": "Incredibly sweet and delicious mangoes!"
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["comment"] == "Incredibly sweet and delicious mangoes!"
    assert data["rating_value"] == 5
    assert data["product_id"] == product.id
    assert data["user_name"] == "Alice Reviewer"

    review_id = data["id"]

    # 2. Enforce one review per user per product
    response = client.post(
        "/api/v1/reviews",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "product_id": product.id,
            "rating_value": 4,
            "comment": "Another review attempt."
        },
    )
    assert response.status_code == 400
    assert "already reviewed" in response.json()["error"]["message"]

    # 3. Read Reviews (Product) with filters
    response = client.get(
        f"/api/v1/reviews?product_id={product.id}",
    )
    assert response.status_code == 200
    reviews_list = response.json()
    assert len(reviews_list) == 1
    assert reviews_list[0]["comment"] == "Incredibly sweet and delicious mangoes!"

    # 4. Get Rating Summary (Product)
    response = client.get(
        f"/api/v1/reviews/summary?product_id={product.id}",
    )
    assert response.status_code == 200
    summary = response.json()
    assert summary["average_rating"] == 5.00
    assert summary["total_ratings"] == 1
    assert summary["star_counts"]["5"] == 1

    # 5. Update Review
    response = client.put(
        f"/api/v1/reviews/{review_id}",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "rating_value": 4,
            "comment": "Slightly less sweet this time, but still great."
        },
    )
    assert response.status_code == 200
    updated_data = response.json()
    assert updated_data["comment"] == "Slightly less sweet this time, but still great."
    assert updated_data["rating_value"] == 4

    # Verify summary updated
    response = client.get(
        f"/api/v1/reviews/summary?product_id={product.id}",
    )
    assert response.json()["average_rating"] == 4.00

    # 6. Delete Review
    response = client.delete(
        f"/api/v1/reviews/{review_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    assert response.json()["success"] is True

    # Verify no reviews left
    response = client.get(
        f"/api/v1/reviews?product_id={product.id}",
    )
    assert len(response.json()) == 0

    # Check that rating is cascade deleted
    assert db.query(Rating).count() == 0

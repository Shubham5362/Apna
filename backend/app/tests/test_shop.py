import io
import pytest
from sqlalchemy.orm import Session
from fastapi.testclient import TestClient

from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.shop import Shop
from app.core.security import create_access_token

client = TestClient(app)


@pytest.fixture(name="db")
def db_fixture():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def get_auth_token(db: Session, phone_number: str = "+918888888888", full_name: str = "Shop Test User") -> str:
    user = db.query(User).filter(User.phone_number == phone_number).first()
    if not user:
        user = User(phone_number=phone_number, full_name=full_name, is_active=True)
        db.add(user)
        db.commit()
        db.refresh(user)
    return create_access_token(subject=user.id)


def test_create_shop_unauthenticated():
    response = client.post(
        "/api/v1/shops",
        json={"name": "My Shop", "description": "Beautiful organic grocery store"},
    )
    assert response.status_code == 401


def test_create_shop_success(db: Session):
    # Clean previous shops first to avoid 1-to-1 violation
    db.query(Shop).delete()
    db.commit()

    token = get_auth_token(db, "+918888888888", "Owner User")
    response = client.post(
        "/api/v1/shops",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Organica Store", "description": "Organic fresh food"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Organica Store"
    assert data["description"] == "Organic fresh food"
    assert "id" in data


def test_create_shop_duplicate_limit(db: Session):
    token = get_auth_token(db, "+918888888888", "Owner User")
    response = client.post(
        "/api/v1/shops",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Second Shop", "description": "Another shop"},
    )
    assert response.status_code == 400
    assert "already own a shop" in response.json()["error"]["message"]


def test_get_shops():
    response = client.get("/api/v1/shops")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_get_shop_by_id_success(db: Session):
    shop = db.query(Shop).first()
    assert shop is not None
    response = client.get(f"/api/v1/shops/{shop.id}")
    assert response.status_code == 200
    assert response.json()["name"] == shop.name


def test_get_shop_by_id_not_found():
    response = client.get("/api/v1/shops/99999")
    assert response.status_code == 404


def test_update_shop_success(db: Session):
    shop = db.query(Shop).first()
    assert shop is not None
    owner = db.query(User).filter(User.id == shop.owner_id).first()
    assert owner is not None

    token = create_access_token(subject=owner.id)
    response = client.put(
        "/api/v1/shops/{id}".format(id=shop.id),
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Organica Fresh Store", "description": "Super fresh organic food"},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Organica Fresh Store"


def test_update_shop_unauthorized(db: Session):
    shop = db.query(Shop).first()
    assert shop is not None

    # Another user who is not the owner
    token = get_auth_token(db, "+911234567890", "Other User")
    response = client.put(
        "/api/v1/shops/{id}".format(id=shop.id),
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Stolen Shop"},
    )
    assert response.status_code == 403


def test_upload_shop_photo_success(db: Session):
    shop = db.query(Shop).first()
    assert shop is not None
    owner = db.query(User).filter(User.id == shop.owner_id).first()
    assert owner is not None

    token = create_access_token(subject=owner.id)
    dummy_image = io.BytesIO(b"shop image data")
    response = client.post(
        "/api/v1/shops/{id}/photo".format(id=shop.id),
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("shop.png", dummy_image, "image/png")},
    )
    assert response.status_code == 200
    assert response.json()["image_url"] is not None


def test_delete_shop_unauthorized(db: Session):
    shop = db.query(Shop).first()
    assert shop is not None

    token = get_auth_token(db, "+911234567890", "Other User")
    response = client.delete(
        "/api/v1/shops/{id}".format(id=shop.id),
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 403


def test_delete_shop_success(db: Session):
    shop = db.query(Shop).first()
    assert shop is not None
    owner = db.query(User).filter(User.id == shop.owner_id).first()
    assert owner is not None

    token = create_access_token(subject=owner.id)
    response = client.delete(
        "/api/v1/shops/{id}".format(id=shop.id),
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200

    deleted_shop = db.query(Shop).filter(Shop.id == shop.id).first()
    assert deleted_shop is None

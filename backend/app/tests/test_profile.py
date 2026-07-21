import io
import pytest
from sqlalchemy.orm import Session
from fastapi.testclient import TestClient

from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.user_profile import UserProfile
from app.core.security import create_access_token

client = TestClient(app)


@pytest.fixture(name="db")
def db_fixture():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def get_auth_token(db: Session, phone_number: str = "+919999999999", full_name: str = "Profile Test User") -> str:
    # Check if user already exists
    user = db.query(User).filter(User.phone_number == phone_number).first()
    if not user:
        user = User(phone_number=phone_number, full_name=full_name, is_active=True)
        db.add(user)
        db.commit()
        db.refresh(user)
    return create_access_token(subject=user.id)


def test_get_profile_unauthenticated():
    response = client.get("/api/v1/profile")
    assert response.status_code == 401


def test_get_profile_success(db: Session):
    token = get_auth_token(db, "+919999999999")
    response = client.get(
        "/api/v1/profile",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "user_id" in data
    assert data["phone_number"] == "+919999999999"
    assert data["full_name"] == "Profile Test User"
    assert data["completion_percentage"] == 8  # Only 1 field filled: full_name (1/12 ≈ 8%)


def test_update_profile_success(db: Session):
    token = get_auth_token(db, "+919999999999")
    update_data = {
        "full_name": "Updated Name",
        "email": "test@example.com",
        "gender": "Male",
        "date_of_birth": "1990-01-01",
        "address": "123 Main St",
        "city": "Mumbai",
        "state": "Maharashtra",
        "pincode": "400001",
        "country": "India",
        "preferred_language": "English",
        "timezone": "Asia/Kolkata",
    }
    response = client.put(
        "/api/v1/profile",
        headers={"Authorization": f"Bearer {token}"},
        json=update_data,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["full_name"] == "Updated Name"
    assert data["email"] == "test@example.com"
    assert data["gender"] == "Male"
    assert data["date_of_birth"] == "1990-01-01"
    assert data["address"] == "123 Main St"
    assert data["city"] == "Mumbai"
    assert data["state"] == "Maharashtra"
    assert data["pincode"] == "400001"
    assert data["country"] == "India"
    assert data["preferred_language"] == "English"
    assert data["timezone"] == "Asia/Kolkata"
    # 11 fields filled (all except profile_photo_path) -> 11/12 ≈ 92%
    assert data["completion_percentage"] == 92


def test_update_profile_validation_invalid_email(db: Session):
    token = get_auth_token(db, "+919999999999")
    update_data = {
        "email": "invalid-email-format",
    }
    response = client.put(
        "/api/v1/profile",
        headers={"Authorization": f"Bearer {token}"},
        json=update_data,
    )
    assert response.status_code == 422


def test_upload_profile_photo_unauthenticated():
    response = client.post(
        "/api/v1/profile/photo",
        files={"file": ("test.png", b"fake_data", "image/png")},
    )
    assert response.status_code == 401


def test_upload_profile_photo_invalid_type(db: Session):
    token = get_auth_token(db, "+919999999999")
    response = client.post(
        "/api/v1/profile/photo",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("test.txt", b"fake_text", "text/plain")},
    )
    assert response.status_code == 400
    assert "File must be an image" in response.json()["error"]["message"]


def test_upload_profile_photo_success(db: Session):
    token = get_auth_token(db, "+919999999999")
    dummy_image = io.BytesIO(b"fake image data")
    response = client.post(
        "/api/v1/profile/photo",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("test_avatar.png", dummy_image, "image/png")},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["profile_photo_url"] is not None
    assert "/static/profile_photos/" in data["profile_photo_url"]

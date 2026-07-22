from datetime import datetime, timedelta, timezone
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.main import app
from app.core.deps import get_db
from app.core.security import get_password_hash
from app.models.user import User
from app.models.otp import OTPVerification

client = TestClient(app)


def test_registration_success(db: Session = next(get_db())):
    # Clean database first
    db.query(OTPVerification).delete()
    db.query(User).delete()
    db.commit()

    # Success case
    response = client.post(
        "/api/v1/auth/register",
        json={"phone_number": "+919876543210", "full_name": "Test User"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert "Verification OTP sent successfully" in data["message"]

    # Verify database state
    user = db.query(User).filter(User.phone_number == "+919876543210").first()
    assert user is not None
    assert user.full_name == "Test User"

    otp = db.query(OTPVerification).filter(OTPVerification.phone_number == "+919876543210").first()
    assert otp is not None
    assert otp.is_verified is False


def test_registration_validation():
    # Invalid format - too short
    response = client.post(
        "/api/v1/auth/register",
        json={"phone_number": "1234", "full_name": "Test User"},
    )
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"


def test_registration_duplicate():
    # Attempting to register same phone number again
    response = client.post(
        "/api/v1/auth/register",
        json={"phone_number": "+919876543210", "full_name": "Duplicate User"},
    )
    assert response.status_code == 400
    assert "already registered" in response.json()["error"]["message"]


def test_login_init_success():
    # Existing registered user
    response = client.post(
        "/api/v1/auth/login-init",
        json={"phone_number": "+919876543210"},
    )
    assert response.status_code == 200
    assert response.json()["success"] is True


def test_login_init_not_found():
    # Unregistered user
    response = client.post(
        "/api/v1/auth/login-init",
        json={"phone_number": "+911111111111"},
    )
    assert response.status_code == 404
    assert "not registered" in response.json()["error"]["message"]


def test_otp_verification_flow(db: Session = next(get_db())):
    # 1. Fetch current OTP generated for "+919876543210" during login_init
    otp_entry = (
        db.query(OTPVerification)
        .filter(OTPVerification.phone_number == "+919876543210")
        .order_by(OTPVerification.created_at.desc())
        .first()
    )
    assert otp_entry is not None

    # 2. Test incorrect OTP value
    response = client.post(
        "/api/v1/auth/verify-otp",
        json={"phone_number": "+919876543210", "otp": "000000"},
    )
    assert response.status_code == 400
    assert "Invalid OTP code" in response.json()["error"]["message"]

    # 3. Test correct OTP value
    response = client.post(
        "/api/v1/auth/verify-otp",
        json={"phone_number": "+919876543210", "otp": otp_entry.otp},
    )
    assert response.status_code == 200
    tokens = response.json()
    assert "access_token" in tokens
    assert "refresh_token" in tokens
    assert tokens["token_type"] == "bearer"


def test_otp_verification_retry_limit(db: Session = next(get_db())):
    # Initialize a new user and generate an OTP
    user = User(phone_number="+918888888888", full_name="Retry User")
    db.add(user)
    db.commit()

    otp_entry = OTPVerification(
        phone_number="+918888888888",
        otp="123456",
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=5),
        attempts=0,
    )
    db.add(otp_entry)
    db.commit()

    # Fail 3 times
    for _ in range(3):
        response = client.post(
            "/api/v1/auth/verify-otp",
            json={"phone_number": "+918888888888", "otp": "000000"},
        )
        assert response.status_code == 400

    # 4th failure triggers too many attempts
    response = client.post(
        "/api/v1/auth/verify-otp",
        json={"phone_number": "+918888888888", "otp": "000000"},
    )
    assert response.status_code == 400
    assert "Too many failed attempts" in response.json()["error"]["message"]


def test_otp_verification_expired(db: Session = next(get_db())):
    # Generate an already expired OTP
    user = User(phone_number="+917777777777", full_name="Expired User")
    db.add(user)
    db.commit()

    otp_entry = OTPVerification(
        phone_number="+917777777777",
        otp="123456",
        expires_at=datetime.now(timezone.utc) - timedelta(minutes=1),
        attempts=0,
    )
    db.add(otp_entry)
    db.commit()

    response = client.post(
        "/api/v1/auth/verify-otp",
        json={"phone_number": "+917777777777", "otp": "123456"},
    )
    assert response.status_code == 400
    assert "expired" in response.json()["error"]["message"]


def test_me_protected_endpoint(db: Session = next(get_db())):
    # Resolve valid tokens
    otp_entry = (
        db.query(OTPVerification)
        .filter(OTPVerification.phone_number == "+919876543210")
        .order_by(OTPVerification.created_at.desc())
        .first()
    )
    # Generate new login init + verify
    client.post("/api/v1/auth/login-init", json={"phone_number": "+919876543210"})
    latest_otp = (
        db.query(OTPVerification)
        .filter(OTPVerification.phone_number == "+919876543210")
        .order_by(OTPVerification.created_at.desc())
        .first()
    )

    verify_resp = client.post(
        "/api/v1/auth/verify-otp",
        json={"phone_number": "+919876543210", "otp": latest_otp.otp},
    )
    tokens = verify_resp.json()
    access_token = tokens["access_token"]
    refresh_token = tokens["refresh_token"]

    # 1. Access without authorization header -> 401
    response = client.get("/api/v1/auth/me")
    assert response.status_code == 401

    # 2. Access with invalid token -> 401
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer invalidtoken"},
    )
    assert response.status_code == 401

    # 3. Access with valid token -> 200
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert response.status_code == 200
    assert response.json()["phone_number"] == "+919876543210"

    # 4. Token Refresh -> 200
    refresh_resp = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert refresh_resp.status_code == 200
    new_tokens = refresh_resp.json()
    assert "access_token" in new_tokens

    # 5. Logout -> 200
    logout_resp = client.post(
        "/api/v1/auth/logout",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert logout_resp.status_code == 200
    assert logout_resp.json()["success"] is True

    # 6. Try accessing /me again with same access token -> 401 (blacklisted!)
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert response.status_code == 401


def test_password_auth_lifecycle(db: Session = next(get_db())):
    # 1. Signup Init
    response = client.post(
        "/api/v1/auth/signup-init",
        json={"phone_number": "+919999999991"},
    )
    assert response.status_code == 200
    assert response.json()["success"] is True

    # Get latest OTP verification record
    otp_entry = (
        db.query(OTPVerification)
        .filter(OTPVerification.phone_number == "+919999999991")
        .order_by(OTPVerification.created_at.desc())
        .first()
    )
    assert otp_entry is not None

    # 2. Signup Complete
    response = client.post(
        "/api/v1/auth/signup-complete",
        json={
            "phone_number": "+919999999991",
            "full_name": "Premium User",
            "password": "secretpassword",
            "otp": otp_entry.otp,
        },
    )
    assert response.status_code == 201
    tokens = response.json()
    assert "access_token" in tokens
    assert "refresh_token" in tokens

    # 3. Password Login Success
    response = client.post(
        "/api/v1/auth/login-password",
        json={
            "phone_number": "+919999999991",
            "password": "secretpassword",
        },
    )
    assert response.status_code == 200
    assert "access_token" in response.json()

    # 4. Password Login Failure
    response = client.post(
        "/api/v1/auth/login-password",
        json={
            "phone_number": "+919999999991",
            "password": "wrongpassword",
        },
    )
    assert response.status_code == 400
    assert "Incorrect password" in response.json()["error"]["message"]


def test_forgot_password_and_reset_flow(db: Session = next(get_db())):
    # Clear any leftover records first to avoid UniqueViolation
    db.query(OTPVerification).filter(OTPVerification.phone_number == "+919999999991").delete()
    db.query(User).filter(User.phone_number == "+919999999991").delete()
    db.commit()

    # Create the user first inside this test so they exist
    user = User(
        phone_number="+919999999991",
        full_name="Premium User",
        password_hash=get_password_hash("oldpassword"),
        is_active=True,
    )
    db.add(user)
    db.commit()

    # 1. Forgot password request
    response = client.post(
        "/api/v1/auth/forgot-password",
        json={"phone_number": "+919999999991"},
    )
    assert response.status_code == 200
    assert response.json()["success"] is True

    otp_entry = (
        db.query(OTPVerification)
        .filter(OTPVerification.phone_number == "+919999999991")
        .order_by(OTPVerification.created_at.desc())
        .first()
    )
    assert otp_entry is not None

    # 2. Verify OTP
    response = client.post(
        "/api/v1/auth/forgot-password/verify",
        json={"phone_number": "+919999999991", "otp": otp_entry.otp},
    )
    assert response.status_code == 200
    assert response.json()["success"] is True

    # 3. Reset password
    response = client.post(
        "/api/v1/auth/reset-password",
        json={
            "phone_number": "+919999999991",
            "otp": otp_entry.otp,
            "new_password": "newsecurepassword",
        },
    )
    assert response.status_code == 200
    assert response.json()["success"] is True

    # 4. Login with new password
    response = client.post(
        "/api/v1/auth/login-password",
        json={
            "phone_number": "+919999999991",
            "password": "newsecurepassword",
        },
    )
    assert response.status_code == 200
    assert "access_token" in response.json()

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Header
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.deps import get_db, get_redis, get_current_user
from app.core.security import (
    generate_otp,
    create_access_token,
    create_refresh_token,
    decode_token,
    blacklist_token,
    check_rate_limit,
)
from app.models.user import User
from app.models.otp import OTPVerification
from app.schemas.auth import (
    UserRegistration,
    UserLoginInit,
    OTPVerify,
    Token,
    TokenRefresh,
    UserResponse,
    MessageResponse,
)

logger = logging.getLogger(__name__)
router = APIRouter()

# Constants
OTP_EXPIRY_MINUTES = 5
MAX_OTP_ATTEMPTS = 3


@router.post(
    "/register",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Auth"],
)
def register(
    user_in: UserRegistration, db: Session = Depends(get_db)
) -> Any:
    """
    Register a new user with mobile number and optional full name.
    Generates and triggers OTP verification.
    """
    # Rate limit check (max 5 requests per 10 minutes)
    if not check_rate_limit(user_in.phone_number):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many requests. Please try again in a few minutes.",
        )

    # 1. Check if user already exists
    existing_user = db.query(User).filter(User.phone_number == user_in.phone_number).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already registered. Please login instead.",
        )

    # 2. Create the user
    new_user = User(
        phone_number=user_in.phone_number,
        full_name=user_in.full_name,
        is_active=True,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # 3. Generate and store OTP
    otp_code = generate_otp()
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=OTP_EXPIRY_MINUTES)

    otp_entry = OTPVerification(
        phone_number=user_in.phone_number,
        otp=otp_code,
        expires_at=expires_at,
        attempts=0,
        is_verified=False,
    )
    db.add(otp_entry)
    db.commit()

    # Log/Print the OTP to mock SMS delivery
    logger.info(f"--- MOCK SMS GATEWAY --- Sent OTP '{otp_code}' to mobile {user_in.phone_number}")
    print(f"--- MOCK SMS GATEWAY --- Sent OTP '{otp_code}' to mobile {user_in.phone_number}")

    return MessageResponse(
        success=True,
        message="Registration successful. Verification OTP sent successfully.",
    )


@router.post("/login-init", response_model=MessageResponse, tags=["Auth"])
def login_init(
    login_in: UserLoginInit, db: Session = Depends(get_db)
) -> Any:
    """
    Initialize login. Sends an OTP code to registered mobile number.
    """
    # Rate limit check (max 5 requests per 10 minutes)
    if not check_rate_limit(login_in.phone_number):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many requests. Please try again in a few minutes.",
        )

    # 1. Check if user exists
    user = db.query(User).filter(User.phone_number == login_in.phone_number).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mobile number is not registered. Please register first.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User account is inactive.",
        )

    # 2. Generate and store OTP
    otp_code = generate_otp()
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=OTP_EXPIRY_MINUTES)

    otp_entry = OTPVerification(
        phone_number=login_in.phone_number,
        otp=otp_code,
        expires_at=expires_at,
        attempts=0,
        is_verified=False,
    )
    db.add(otp_entry)
    db.commit()

    # Log/Print the OTP to mock SMS delivery
    logger.info(f"--- MOCK SMS GATEWAY --- Sent OTP '{otp_code}' to mobile {login_in.phone_number}")
    print(f"--- MOCK SMS GATEWAY --- Sent OTP '{otp_code}' to mobile {login_in.phone_number}")

    return MessageResponse(
        success=True,
        message="Verification OTP sent successfully.",
    )


@router.post("/verify-otp", response_model=Token, tags=["Auth"])
def verify_otp(
    verify_in: OTPVerify, db: Session = Depends(get_db)
) -> Any:
    """
    Verify OTP code and return valid access and refresh tokens.
    """
    # Find latest unverified OTP entry for this mobile number
    otp_entry = (
        db.query(OTPVerification)
        .filter(
            OTPVerification.phone_number == verify_in.phone_number,
            OTPVerification.is_verified == False,
        )
        .order_by(OTPVerification.created_at.desc())
        .first()
    )

    if not otp_entry:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No pending OTP request found for this mobile number.",
        )

    # Increment and check retry/attempt limits
    otp_entry.attempts += 1
    db.commit()

    if otp_entry.attempts > MAX_OTP_ATTEMPTS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Too many failed attempts. Please request a new OTP.",
        )

    # Check expiration
    now_utc = datetime.now(timezone.utc)
    # Ensure database datetime is timezone-aware
    expires_aware = otp_entry.expires_at.replace(tzinfo=timezone.utc) if otp_entry.expires_at.tzinfo is None else otp_entry.expires_at
    if now_utc > expires_aware:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="OTP has expired. Please request a new OTP.",
        )

    # Validate OTP value
    if otp_entry.otp != verify_in.otp:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid OTP code. {MAX_OTP_ATTEMPTS - otp_entry.attempts} attempts remaining.",
        )

    # OTP is valid!
    otp_entry.is_verified = True
    db.commit()

    # Find User ID
    user = db.query(User).filter(User.phone_number == verify_in.phone_number).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found.",
        )

    # Create tokens
    access_token = create_access_token(subject=user.id)
    refresh_token = create_refresh_token(subject=user.id)

    return Token(
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post("/refresh", response_model=Token, tags=["Auth"])
def refresh_token_endpoint(
    refresh_in: TokenRefresh, db: Session = Depends(get_db)
) -> Any:
    """
    Refresh a JWT access token using a valid refresh token.
    """
    payload = decode_token(refresh_in.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token.",
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token payload.",
        )

    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User is inactive or not found.",
        )

    # Create new access and refresh tokens
    new_access_token = create_access_token(subject=user.id)
    new_refresh_token = create_refresh_token(subject=user.id)

    return Token(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
    )


@router.post("/logout", response_model=MessageResponse, tags=["Auth"])
def logout(
    current_user: User = Depends(get_current_user),
    authorization: Optional[str] = Header(None)
) -> Any:
    """
    Log out the current user by blacklisting their access token.
    """
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        # Blacklist token for access token expiry window (default access token expire is settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        blacklist_token(token, expires_in_seconds=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60)

    return MessageResponse(
        success=True,
        message="Logged out successfully. Token blacklisted.",
    )


@router.get("/me", response_model=UserResponse, tags=["Auth"])
def read_current_user(current_user: User = Depends(get_current_user)) -> Any:
    """
    Get profile of the currently logged-in user.
    """
    return current_user


# Helper endpoint for Swagger OAuth2 login compatibility
@router.post("/login-swagger", response_model=Token, tags=["Auth"], include_in_schema=False)
def login_swagger(
    form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)
) -> Any:
    """
    Swagger-compatible endpoint allowing testing of protected routes directly in Docs.
    Expects phone_number in 'username' field, and OTP code in 'password' field.
    """
    # 1. Verify user exists
    user = db.query(User).filter(User.phone_number == form_data.username).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mobile number not registered.",
        )

    # 2. Check and verify OTP
    otp_entry = (
        db.query(OTPVerification)
        .filter(
            OTPVerification.phone_number == form_data.username,
            OTPVerification.is_verified == False,
        )
        .order_by(OTPVerification.created_at.desc())
        .first()
    )

    if not otp_entry or otp_entry.otp != form_data.password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid OTP code.",
        )

    otp_entry.is_verified = True
    db.commit()

    access_token = create_access_token(subject=user.id)
    refresh_token = create_refresh_token(subject=user.id)

    return Token(
        access_token=access_token,
        refresh_token=refresh_token,
    )

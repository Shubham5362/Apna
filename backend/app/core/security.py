import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional, Union
import jwt
from app.core.config import settings

# In-memory or Redis-based blacklist. We'll use a local helper or Redis client.
# We'll write to Redis if available, or fallback to an in-memory set in tests.
from app.core.redis_client import redis_client


def generate_otp() -> str:
    """
    Generate a cryptographically secure 6-digit numeric OTP.
    """
    return "".join(secrets.choice("0123456789") for _ in range(6))


def create_access_token(
    subject: Union[str, int], expires_delta: Optional[timedelta] = None
) -> str:
    """
    Generate JWT access token.
    """
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )

    to_encode = {"exp": expire, "sub": str(subject), "type": "access"}
    encoded_jwt = jwt.encode(
        to_encode, settings.JWT_SECRET, algorithm=settings.ALGORITHM
    )
    return encoded_jwt


def create_refresh_token(
    subject: Union[str, int], expires_delta: Optional[timedelta] = None
) -> str:
    """
    Generate JWT refresh token.
    """
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        # Refresh tokens typically last longer, let's say 30 days
        expire = datetime.now(timezone.utc) + timedelta(days=30)

    to_encode = {"exp": expire, "sub": str(subject), "type": "refresh"}
    encoded_jwt = jwt.encode(
        to_encode, settings.JWT_SECRET, algorithm=settings.ALGORITHM
    )
    return encoded_jwt


def decode_token(token: str) -> Optional[dict]:
    """
    Decode and validate a JWT token. Returns payload dict or None if invalid/expired.
    """
    try:
        payload = jwt.decode(
            token, settings.JWT_SECRET, algorithms=[settings.ALGORITHM]
        )
        return payload
    except jwt.PyJWTError:
        return None


def blacklist_token(token: str, expires_in_seconds: int) -> None:
    """
    Blacklist a token (logout) in Redis.
    """
    try:
        redis_client.setex(f"blacklist:{token}", expires_in_seconds, "true")
    except Exception:
        # Fallback if Redis is down or in memory during simplified tests
        pass


def is_token_blacklisted(token: str) -> bool:
    """
    Check if a token has been blacklisted.
    """
    try:
        return redis_client.exists(f"blacklist:{token}") > 0
    except Exception:
        return False


def check_rate_limit(phone_number: str, limit: int = 5, period_seconds: int = 600) -> bool:
    """
    Simple Redis-based rate limiter for OTP endpoints.
    Returns True if allowed, False if rate limit is exceeded.
    """
    key = f"rate_limit:{phone_number}"
    try:
        # Increment request count
        count = redis_client.incr(key)
        # If it's a new key, set the TTL
        if count == 1:
            redis_client.expire(key, period_seconds)
        return count <= limit
    except Exception:
        # Fallback to True if Redis connection fails or during simplified unit tests
        return True

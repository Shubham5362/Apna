from typing import Generator, Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
import redis

from app.core.database import SessionLocal
from app.core.redis_client import redis_client
from app.core.security import decode_token, is_token_blacklisted
from app.models.user import User

# OAuth2 scheme configures Swagger's Authorization button automatically
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/api/v1/login-swagger",  # Will define a helper route for Swagger login if needed, or point to standard token endpoint
    auto_error=False
)


def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_redis() -> redis.Redis:
    return redis_client


def get_current_user(
    db: Session = Depends(get_db),
    token: Optional[str] = Depends(oauth2_scheme)
) -> User:
    """
    Dependency to resolve the current active user from the JWT access token.
    """
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated. Access token missing.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Check blacklist (logout status)
    if is_token_blacklisted(token):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been blacklisted (logged out).",
            headers={"WWW-Authenticate": "Bearer"},
        )

    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials or token has expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id_str = payload.get("sub")
    if not user_id_str:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        user_id = int(user_id_str)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user ID format in token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is inactive.",
        )

    return user

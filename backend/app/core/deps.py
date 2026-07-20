from typing import Generator
from app.core.database import SessionLocal
from app.core.redis_client import redis_client
import redis


def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_redis() -> redis.Redis:
    return redis_client

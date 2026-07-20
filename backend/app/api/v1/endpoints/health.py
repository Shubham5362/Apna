from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
import redis

from app.core.deps import get_db, get_redis
from app.schemas.health import HealthResponse
from app.core.config import settings

router = APIRouter()


@router.get("/health", response_model=HealthResponse, tags=["Health"])
def health_check(
    db: Session = Depends(get_db),
    redis_conn: redis.Redis = Depends(get_redis)
) -> HealthResponse:
    """
    Check system health by validating DB and Redis connectivity.
    """
    # 1. DB connection check
    db_status = "healthy"
    try:
        db.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    # 2. Redis connection check
    redis_status = "healthy"
    try:
        redis_conn.ping()
    except Exception as e:
        redis_status = f"unhealthy: {str(e)}"

    status = "healthy"
    if db_status != "healthy" or redis_status != "healthy":
        status = "unhealthy"

    return HealthResponse(
        status=status,
        database=db_status,
        redis=redis_status,
        version=settings.VERSION,
    )

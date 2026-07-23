import redis
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)


class DummyRedis:
    """
    A graceful in-memory fallback client used when Redis is unavailable.
    """
    is_dummy = True

    def __init__(self):
        self._store = {}

    def ping(self) -> bool:
        return True

    def setex(self, name: str, time: int, value: str) -> bool:
        self._store[name] = value
        return True

    def get(self, name: str) -> str | None:
        return self._store.get(name)

    def delete(self, *names: str) -> int:
        count = 0
        for name in names:
            if name in self._store:
                del self._store[name]
                count += 1
        return count

    def exists(self, *names: str) -> int:
        return sum(1 for name in names if name in self._store)

    def incr(self, name: str, amount: int = 1) -> int:
        val = int(self._store.get(name, 0)) + amount
        self._store[name] = str(val)
        return val

    def expire(self, name: str, time: int) -> bool:
        return True


# Initialize Redis connection with fallback support
redis_client = None

try:
    if settings.REDIS_URL:
        logger.info("Initializing Redis connection using REDIS_URL")
        redis_client = redis.from_url(
            settings.REDIS_URL,
            decode_responses=True,
            socket_timeout=5,
        )
    else:
        logger.info(
            f"Initializing Redis connection using host settings: {settings.REDIS_HOST}:{settings.REDIS_PORT}"
        )
        redis_client = redis.Redis(
            host=settings.REDIS_HOST,
            port=settings.REDIS_PORT,
            db=settings.REDIS_DB,
            password=settings.REDIS_PASSWORD,
            decode_responses=True,
            socket_timeout=5.0,
        )
    # Test connection immediately to ensure it works
    redis_client.ping()
    logger.info("Successfully connected to Redis server.")
except Exception as e:
    logger.error(
        f"Redis connection failed or offline: {str(e)}. "
        "Falling back to DummyRedis in-memory store for safety and production resilience."
    )
    redis_client = DummyRedis()

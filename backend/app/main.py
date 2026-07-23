import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
import redis

from alembic.config import Config
from alembic import command

from app.core.config import settings
from app.core.logging import setup_logging
from app.core.exceptions import register_exception_handlers
from app.api.v1.router import api_router
from app.core.deps import get_db, get_redis
from app.schemas.health import HealthResponse
from app.api.v1.endpoints.health import health_check as v1_health_check

# 1. Initialize Logging
setup_logging()
logger = logging.getLogger(__name__)

# Function to recursively find and print all routes
def log_all_routes(router, prefix=''):
    for route in router.routes:
        if type(route).__name__ == '_IncludedRouter':
            p = prefix
            if hasattr(route.include_context, 'prefix'):
                p += route.include_context.prefix
            log_all_routes(route.original_router, prefix=p)
        else:
            path = prefix + getattr(route, 'path', '')
            methods = list(getattr(route, 'methods', []))
            logger.info(f"Registered Route: {path} - Methods: {methods}")


# Resolve alembic.ini path relative to main.py
app_dir = os.path.dirname(os.path.abspath(__file__))
backend_root = os.path.dirname(app_dir)
alembic_ini_path = os.path.join(backend_root, "alembic.ini")


def run_db_migrations():
    """
    Programmatically run database migrations using Alembic on application startup.
    This ensures that Render deployments never suffer from missing tables/schemas.
    """
    try:
        logger.info(f"Checking and running database migrations using {alembic_ini_path}...")
        alembic_cfg = Config(alembic_ini_path)
        command.upgrade(alembic_cfg, "head")
        logger.info("Database migrations executed successfully.")
    except Exception as e:
        logger.error(f"Failed to run database migrations on startup: {str(e)}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 1. Execute DB migrations programmatically
    run_db_migrations()

    # 2. Log all registered routes on startup
    logger.info("Initializing application and logging registered routes...")
    try:
        log_all_routes(app)
    except Exception as e:
        logger.error(f"Error logging routes on startup: {str(e)}")
    yield

# 2. Create FastAPI Application
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url="/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# 3. Configure CORS
if settings.BACKEND_CORS_ORIGINS:
    # Ensure allow_credentials is FALSE if there is a wildcard origin to prevent Starlette ValueError
    has_wildcard = "*" in settings.BACKEND_CORS_ORIGINS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.BACKEND_CORS_ORIGINS,
        allow_credentials=not has_wildcard,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# 4. Global Exception Handlers
register_exception_handlers(app)

# 5. Register APIRouters
os.makedirs("uploads/profile_photos", exist_ok=True)
os.makedirs("uploads/shops", exist_ok=True)
os.makedirs("uploads/products", exist_ok=True)
app.mount("/static", StaticFiles(directory="uploads"), name="static")

app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/", operation_id="read_root_get")
def read_root():
    return {
        "message": f"Welcome to {settings.PROJECT_NAME}",
        "version": settings.VERSION,
        "docs_url": "/docs"
    }


@app.head("/", include_in_schema=False)
def read_root_head():
    return None


@app.get("/health", response_model=HealthResponse, tags=["Health"], operation_id="health_check_get")
def health_check(
    db: Session = Depends(get_db),
    redis_conn: redis.Redis = Depends(get_redis)
) -> HealthResponse:
    """
    Check system health by validating DB and Redis connectivity by reusing V1 endpoint logic.
    """
    return v1_health_check(db=db, redis_conn=redis_conn)


@app.head("/health", include_in_schema=False)
def health_check_head(
    db: Session = Depends(get_db),
    redis_conn: redis.Redis = Depends(get_redis)
):
    # Perform same connectivity checks as health_check but return None for HEAD response body
    v1_health_check(db=db, redis_conn=redis_conn)
    return None

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.core.logging import setup_logging
from app.core.exceptions import register_exception_handlers
from app.api.v1.router import api_router
from app.api.v1.endpoints.health import router as health_router

# 1. Initialize Logging
setup_logging()

# 2. Create FastAPI Application
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url="/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
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

app.include_router(health_router, prefix="")
app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/")
def read_root():
    return {
        "message": f"Welcome to {settings.PROJECT_NAME}",
        "version": settings.VERSION,
        "docs_url": "/docs"
    }

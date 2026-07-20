from fastapi import APIRouter
from app.api.v1.endpoints.health import router as health_router
from app.api.v1.endpoints.auth import router as auth_router

api_router = APIRouter()

# Include routes
api_router.include_router(health_router, prefix="", tags=["Health"])
api_router.include_router(auth_router, prefix="/auth", tags=["Auth"])

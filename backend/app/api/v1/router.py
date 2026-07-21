from fastapi import APIRouter
from app.api.v1.endpoints.health import router as health_router
from app.api.v1.endpoints.auth import router as auth_router
from app.api.v1.endpoints.user_profile import router as user_profile_router
from app.api.v1.endpoints.shop import router as shop_router

api_router = APIRouter()

# Include routes
api_router.include_router(health_router, prefix="", tags=["Health"])
api_router.include_router(auth_router, prefix="/auth", tags=["Auth"])
api_router.include_router(user_profile_router, prefix="/profile", tags=["Profile"])
api_router.include_router(shop_router, prefix="/shops", tags=["Shops"])

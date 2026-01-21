from fastapi import APIRouter

from app.api.v1.endpoints import air_quality

api_router = APIRouter()

# Include air quality endpoints
api_router.include_router(
    air_quality.router,
    prefix="/air-quality",
    tags=["air-quality"]
)

# Future endpoints will be added here:
# api_router.include_router(prediction.router, prefix="/predictions", tags=["predictions"])
# api_router.include_router(photos.router, prefix="/photos", tags=["photos"])
# api_router.include_router(users.router, prefix="/users", tags=["users"])
# api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
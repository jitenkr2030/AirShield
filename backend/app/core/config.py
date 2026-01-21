import os
from typing import List, Optional
from pydantic import AnyHttpUrl
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings"""
    
    # Environment
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    
    # API
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "AIRSHIELD API"
    VERSION: str = "1.0.0"
    
    # CORS
    ALLOWED_HOSTS: List[str] = ["*"]
    
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://user:password@localhost/airshield"
    DATABASE_URL_TEST: str = "postgresql+asyncpg://user:password@localhost/airshield_test"
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # Security
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # External APIs
    OPENWEATHER_API_KEY: Optional[str] = None
    NASA_SATELLITE_API_KEY: Optional[str] = None
    GOOGLE_MAPS_API_KEY: Optional[str] = None
    
    # ML Models
    ML_MODEL_PATH: str = "models/"
    IMAGE_MODEL_PATH: str = "models/image_to_pm25_model.tflite"
    PREDICTION_MODEL_PATH: str = "models/prediction_model.pkl"
    
    # File uploads
    UPLOAD_DIR: str = "uploads/"
    MAX_FILE_SIZE: int = 10485760  # 10MB
    ALLOWED_IMAGE_TYPES: List[str] = ["image/jpeg", "image/png", "image/webp"]
    
    # Location services
    DEFAULT_LOCATION_LAT: float = 28.6139  # Delhi coordinates as default
    DEFAULT_LOCATION_LON: float = 77.2090
    LOCATION_UPDATE_INTERVAL: int = 300  # 5 minutes
    
    # Air quality thresholds
    AQI_THRESHOLDS: dict = {
        "good": 50,
        "moderate": 100,
        "unhealthy_sensitive": 150,
        "unhealthy": 200,
        "very_unhealthy": 300,
        "hazardous": 500
    }
    
    # Sensor settings
    SENSOR_TIMEOUT: int = 30  # seconds
    MAX_RETRIES: int = 3
    
    # Notification settings
    NOTIFICATION_SOUND: bool = True
    NOTIFICATION_VIBRATION: bool = True
    
    # Business model
    FREE_TIER_LIMITS: dict = {
        "daily_queries": 100,
        "photo_uploads": 10,
        "predictions": 50,
        "sensor_connections": 1
    }
    
    PRO_TIER_LIMITS: dict = {
        "daily_queries": 1000,
        "photo_uploads": 100,
        "predictions": 500,
        "sensor_connections": 5
    }
    
    # Cache settings
    CACHE_TTL: int = 300  # 5 minutes
    PREDICTION_CACHE_TTL: int = 900  # 15 minutes
    
    class Config:
        case_sensitive = True


# Create settings instance
settings = Settings()
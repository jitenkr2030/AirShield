from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, Text, JSON, ForeignKey, Index
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import uuid

Base = declarative_base()

def generate_uuid():
    return str(uuid.uuid4())

class AirQualityReading(Base):
    """Air quality reading model"""
    __tablename__ = "air_quality_readings"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    
    # Pollutant concentrations (µg/m³)
    pm25 = Column(Float, nullable=True)  # PM2.5
    pm10 = Column(Float, nullable=True)  # PM10
    no2 = Column(Float, nullable=True)   # Nitrogen dioxide
    so2 = Column(Float, nullable=True)   # Sulfur dioxide
    co = Column(Float, nullable=True)    # Carbon monoxide
    o3 = Column(Float, nullable=True)    # Ozone
    
    # Calculated values
    aqi = Column(Integer, nullable=True)  # Air Quality Index
    aqi_category = Column(String, nullable=True)
    lung_safety_score = Column(Float, nullable=True)  # 0-100 scale
    
    # Metadata
    source = Column(String, default="mobile")  # mobile, sensor, api
    sensor_id = Column(String, nullable=True)
    user_id = Column(String, nullable=True)
    
    # Timestamps
    reading_time = Column(DateTime, nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # GPS accuracy
    gps_accuracy = Column(Float, nullable=True)
    
    # Weather data
    temperature = Column(Float, nullable=True)
    humidity = Column(Float, nullable=True)
    pressure = Column(Float, nullable=True)
    wind_speed = Column(Float, nullable=True)
    wind_direction = Column(Float, nullable=True)
    
    # Additional metadata
    location_name = Column(String, nullable=True)
    city = Column(String, nullable=True)
    country = Column(String, nullable=True)
    
    # Quality indicators
    confidence_score = Column(Float, default=1.0)
    calibration_factor = Column(Float, default=1.0)
    
    def __repr__(self):
        return f"<AirQualityReading(id='{self.id}', aqi={self.aqi}, location=({self.latitude}, {self.longitude}))>"

class UserProfile(Base):
    """User profile model"""
    __tablename__ = "user_profiles"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    email = Column(String, unique=True, nullable=False, index=True)
    username = Column(String, unique=True, nullable=True)
    
    # Personal info
    full_name = Column(String, nullable=True)
    age = Column(Integer, nullable=True)
    gender = Column(String, nullable=True)
    
    # Location preferences
    home_location_lat = Column(Float, nullable=True)
    home_location_lon = Column(Float, nullable=True)
    home_location_name = Column(String, nullable=True)
    work_location_lat = Column(Float, nullable=True)
    work_location_lon = Column(Float, nullable=True)
    work_location_name = Column(String, nullable=True)
    
    # Health profile
    has_respiratory_conditions = Column(Boolean, default=False)
    has_cardiovascular_conditions = Column(Boolean, default=False)
    is_smoker = Column(Boolean, default=False)
    exercise_frequency = Column(String, nullable=True)  # daily, weekly, monthly, rarely
    
    # Preferences
    notification_preferences = Column(JSON, default={})
    unit_preference = Column(String, default="metric")  # metric, imperial
    language = Column(String, default="en")
    
    # Subscription
    subscription_tier = Column(String, default="free")  # free, pro, enterprise
    subscription_expires_at = Column(DateTime, nullable=True)
    
    # Usage tracking
    daily_queries_count = Column(Integer, default=0)
    daily_photos_count = Column(Integer, default=0)
    daily_predictions_count = Column(Integer, default=0)
    last_query_reset = Column(DateTime, default=func.now())
    
    # Timestamps
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    last_login = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True)
    
    # Relationships
    readings = relationship("AirQualityReading", backref="user")
    predictions = relationship("PredictionData", backref="user")

class PredictionData(Base):
    """Pollution prediction model"""
    __tablename__ = "prediction_data"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    
    # Location
    latitude = Column(Float, nullable=False, index=True)
    longitude = Column(Float, nullable=False, index=True)
    prediction_horizon = Column(Integer, nullable=False)  # hours from now
    
    # Predicted values
    predicted_pm25 = Column(Float, nullable=True)
    predicted_pm10 = Column(Float, nullable=True)
    predicted_aqi = Column(Integer, nullable=True)
    predicted_aqi_category = Column(String, nullable=True)
    confidence_score = Column(Float, nullable=True)
    
    # Model information
    model_version = Column(String, nullable=True)
    model_type = Column(String, nullable=True)  # lstm, xgboost, ensemble
    
    # Input features used for prediction
    weather_data = Column(JSON, nullable=True)
    traffic_data = Column(JSON, nullable=True)
    historical_data = Column(JSON, nullable=True)
    
    # User context
    user_id = Column(String, nullable=True)
    zone_id = Column(String, nullable=True)
    
    # Timestamps
    prediction_time = Column(DateTime, nullable=False, index=True)
    created_at = Column(DateTime, server_default=func.now())
    
    # Metadata
    data_quality = Column(Float, default=1.0)
    location_name = Column(String, nullable=True)

class PhotoSubmission(Base):
    """Photo submission for air quality analysis"""
    __tablename__ = "photo_submissions"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, nullable=True, index=True)
    
    # Photo data
    filename = Column(String, nullable=False)
    file_path = Column(String, nullable=False)
    file_size = Column(Integer, nullable=True)
    image_format = Column(String, nullable=True)
    
    # Location data
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    location_name = Column(String, nullable=True)
    
    # AI Analysis results
    ai_pm25_estimate = Column(Float, nullable=True)
    ai_confidence = Column(Float, nullable=True)
    ai_model_version = Column(String, nullable=True)
    
    # Verification
    is_verified = Column(Boolean, default=False)
    verified_by = Column(String, nullable=True)
    verification_score = Column(Float, nullable=True)
    
    # Gamification
    points_awarded = Column(Integer, default=0)
    contribution_count = Column(Integer, default=1)
    
    # Status
    status = Column(String, default="processing")  # processing, completed, failed, flagged
    processing_time = Column(Float, nullable=True)
    
    # Timestamps
    taken_at = Column(DateTime, nullable=False)
    submitted_at = Column(DateTime, server_default=func.now())
    processed_at = Column(DateTime, nullable=True)
    
    # Metadata
    device_info = Column(JSON, nullable=True)
    weather_conditions = Column(JSON, nullable=True)
    quality_indicators = Column(JSON, nullable=True)

class SensorDevice(Base):
    """Bluetooth sensor device model"""
    __tablename__ = "sensor_devices"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, nullable=True, index=True)
    
    # Device information
    device_name = Column(String, nullable=False)
    device_type = Column(String, default="pm25")  # pm25, pm10, multi-sensor
    manufacturer = Column(String, nullable=True)
    model = Column(String, nullable=True)
    
    # Bluetooth details
    mac_address = Column(String, nullable=True, unique=True)
    uuid = Column(String, nullable=True)
    
    # Connection status
    is_connected = Column(Boolean, default=False)
    last_seen = Column(DateTime, nullable=True)
    battery_level = Column(Integer, nullable=True)
    signal_strength = Column(Float, nullable=True)
    
    # Calibration
    calibration_factor = Column(Float, default=1.0)
    last_calibration = Column(DateTime, nullable=True)
    calibration_needed = Column(Boolean, default=False)
    
    # Settings
    auto_connect = Column(Boolean, default=True)
    update_interval = Column(Integer, default=60)  # seconds
    alert_thresholds = Column(JSON, default={})
    
    # Timestamps
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    is_active = Column(Boolean, default=True)

class HotspotAlert(Base):
    """Pollution hotspot alerts"""
    __tablename__ = "hotspot_alerts"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    
    # Location and severity
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    alert_level = Column(String, nullable=False)  # low, medium, high, critical
    aqi_threshold = Column(Integer, nullable=False)
    
    # Alert details
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    recommended_actions = Column(JSON, nullable=True)
    
    # Coverage
    radius = Column(Float, default=1000)  # meters
    affected_area = Column(JSON, nullable=True)
    estimated_population = Column(Integer, nullable=True)
    
    # Timing
    detected_at = Column(DateTime, nullable=False)
    expires_at = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True)
    
    # Metadata
    source = Column(String, default="system")  # system, user_report, sensor_network
    confidence_score = Column(Float, default=1.0)
    
    created_at = Column(DateTime, server_default=func.now())

# Indexes for performance
Index('idx_air_quality_location_time', AirQualityReading.latitude, AirQualityReading.longitude, AirQualityReading.reading_time)
Index('idx_air_quality_aqi', AirQualityReading.aqi)
Index('idx_air_quality_source', AirQualityReading.source)
Index('idx_prediction_location_time', PredictionData.latitude, PredictionData.longitude, PredictionData.prediction_time)
Index('idx_photo_submissions_location', PhotoSubmission.latitude, PhotoSubmission.longitude)
Index('idx_photo_submissions_user_time', PhotoSubmission.user_id, PhotoSubmission.submitted_at)
Index('idx_sensor_devices_user', SensorDevice.user_id)
Index('idx_hotspot_alerts_location_active', HotspotAlert.latitude, HotspotAlert.longitude, HotspotAlert.is_active)
from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


class AQICategory(str, Enum):
    GOOD = "good"
    MODERATE = "moderate"
    UNHEALTHY_FOR_SENSITIVE = "unhealthy_for_sensitive"
    UNHEALTHY = "unhealthy"
    VERY_UNHEALTHY = "very_unhealthy"
    HAZARDOUS = "hazardous"


class SubscriptionTier(str, Enum):
    FREE = "free"
    PRO = "pro"
    ENTERPRISE = "enterprise"


class AirQualityBase(BaseModel):
    latitude: float = Field(..., ge=-90, le=90, description="Latitude coordinate")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude coordinate")
    pm25: Optional[float] = Field(None, ge=0, le=500, description="PM2.5 concentration (µg/m³)")
    pm10: Optional[float] = Field(None, ge=0, le=500, description="PM10 concentration (µg/m³)")
    no2: Optional[float] = Field(None, ge=0, le=200, description="NO2 concentration (µg/m³)")
    so2: Optional[float] = Field(None, ge=0, le=350, description="SO2 concentration (µg/m³)")
    co: Optional[float] = Field(None, ge=0, le=50, description="CO concentration (mg/m³)")
    o3: Optional[float] = Field(None, ge=0, le=300, description="O3 concentration (µg/m³)")
    source: Optional[str] = Field("mobile", description="Source of the reading")
    sensor_id: Optional[str] = Field(None, description="Sensor device ID")
    temperature: Optional[float] = Field(None, ge=-50, le=60, description="Temperature (°C)")
    humidity: Optional[float] = Field(None, ge=0, le=100, description="Humidity (%)")
    pressure: Optional[float] = Field(None, ge=800, le=1200, description="Atmospheric pressure (hPa)")
    wind_speed: Optional[float] = Field(None, ge=0, le=150, description="Wind speed (m/s)")
    wind_direction: Optional[float] = Field(None, ge=0, le=360, description="Wind direction (degrees)")


class AirQualityReading(AirQualityBase):
    id: str
    aqi: Optional[int] = Field(None, ge=0, le=500)
    aqi_category: Optional[AQICategory]
    lung_safety_score: Optional[float] = Field(None, ge=0, le=100)
    reading_time: datetime
    created_at: datetime
    updated_at: datetime
    gps_accuracy: Optional[float] = Field(None, ge=0, le=1000)
    location_name: Optional[str]
    city: Optional[str]
    country: Optional[str]
    confidence_score: float = 1.0
    calibration_factor: float = 1.0

    class Config:
        from_attributes = True


class AirQualityReadingCreate(AirQualityBase):
    reading_time: datetime


class AirQualityReadingUpdate(BaseModel):
    pm25: Optional[float] = Field(None, ge=0, le=500)
    pm10: Optional[float] = Field(None, ge=0, le=500)
    aqi: Optional[int] = Field(None, ge=0, le=500)
    confidence_score: Optional[float] = Field(None, ge=0, le=1)
    calibration_factor: Optional[float] = Field(None, ge=0.1, le=10)


class AQISummary(BaseModel):
    current_aqi: Optional[int]
    category: Optional[AQICategory]
    health_recommendation: str
    sensitive_groups_advice: str
    general_population_advice: str
    primary_pollutant: Optional[str]
    time_updated: datetime


class LocationStats(BaseModel):
    location_name: str
    latitude: float
    longitude: float
    recent_aqi: Optional[int]
    trend: Optional[str]  # improving, worsening, stable
    data_points_count: int
    last_updated: datetime


class AirQualityResponse(BaseModel):
    current: AQISummary
    nearby_readings: List[AirQualityReading]
    location_stats: LocationStats


class HistoricalDataRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    start_date: datetime
    end_date: datetime
    aggregation: Optional[str] = Field("hourly", pattern="^(hourly|daily|weekly)$")


class HistoricalDataResponse(BaseModel):
    location: Dict[str, float]
    period: Dict[str, datetime]
    data_points: List[AirQualityReading]
    statistics: Dict[str, Any]


class PredictionRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    hours_ahead: int = Field(..., ge=1, le=72)
    include_weather: bool = True
    include_traffic: bool = True


class PredictionData(BaseModel):
    prediction_time: datetime
    predicted_pm25: Optional[float]
    predicted_pm10: Optional[float]
    predicted_aqi: Optional[int]
    predicted_category: Optional[AQICategory]
    confidence_score: float
    model_version: str


class PredictionResponse(BaseModel):
    location: Dict[str, float]
    prediction_horizon: int
    predictions: List[PredictionData]
    model_info: Dict[str, Any]
    location_name: Optional[str]


class BulkAirQualityRequest(BaseModel):
    locations: List[Dict[str, float]]  # [{"lat": 0.0, "lon": 0.0}, ...]
    include_historical: bool = False
    hours_back: int = Field(default=24, ge=1, le=168)


class BulkAirQualityResponse(BaseModel):
    readings: List[AirQualityReading]
    summary: Dict[str, Any]


class AQICalculationRequest(BaseModel):
    pm25: Optional[float] = None
    pm10: Optional[float] = None
    no2: Optional[float] = None
    so2: Optional[float] = None
    co: Optional[float] = None
    o3: Optional[float] = None


class AQICalculationResponse(BaseModel):
    aqi: int
    category: AQICategory
    primary_pollutant: Optional[str]
    health_recommendations: Dict[str, str]
    calculation_details: Dict[str, Any]


class SensorReading(BaseModel):
    sensor_id: str
    pm25: Optional[float] = None
    pm10: Optional[float] = None
    battery_level: Optional[int] = Field(None, ge=0, le=100)
    signal_strength: Optional[float] = Field(None, ge=-100, le=0)
    temperature: Optional[float] = None
    humidity: Optional[float] = None


class SensorReadingResponse(BaseModel):
    sensor_id: str
    latest_reading: Optional[AirQualityReading]
    connection_status: str
    last_seen: Optional[datetime]
    battery_level: Optional[int]
    data_quality: float


class LocationQuery(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    radius: float = Field(default=1000, ge=100, le=50000)  # meters
    limit: int = Field(default=50, ge=1, le=200)
    source_filter: Optional[List[str]] = None
    time_filter_hours: Optional[int] = Field(None, ge=1, le=720)  # hours


class NearbySensorsResponse(BaseModel):
    location: Dict[str, float]
    radius: float
    sensors_found: int
    readings: List[AirQualityReading]
    sensor_summary: List[SensorReadingResponse]


class CalibrationRequest(BaseModel):
    reading_id: str
    sensor_id: str
    reference_pm25: float
    reference_pm10: Optional[float] = None
    conditions: Optional[Dict[str, Any]] = None


class CalibrationResponse(BaseModel):
    reading_id: str
    sensor_id: str
    previous_factor: float
    new_factor: float
    calibration_quality: float
    recommendations: List[str]


class HealthRecommendations(BaseModel):
    general_advice: str
    sensitive_groups: str
    outdoor_activities: Dict[str, str]
    indoor_measures: List[str]
    travel_recommendations: Dict[str, str]


class RealTimeAlert(BaseModel):
    alert_id: str
    location: Dict[str, float]
    alert_level: str
    aqi_threshold: int
    title: str
    description: str
    recommended_actions: List[str]
    expires_at: Optional[datetime]
    created_at: datetime
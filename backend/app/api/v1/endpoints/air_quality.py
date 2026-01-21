from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from math import radians, sin, cos, sqrt, atan2
import asyncio
import logging

from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_, desc, asc
from sqlalchemy.orm import selectinload

from app.core.database import get_database
from app.core.auth import get_current_user, get_optional_user, check_rate_limit, increment_usage_count
from app.models import AirQualityReading, UserProfile, PredictionData, SensorDevice
from app.schemas.air_quality import (
    AirQualityReading as AirQualityReadingSchema,
    AirQualityReadingCreate,
    AirQualityReadingUpdate,
    AirQualityResponse,
    AQISummary,
    LocationStats,
    HistoricalDataRequest,
    HistoricalDataResponse,
    PredictionRequest,
    PredictionResponse,
    PredictionData as PredictionDataSchema,
    BulkAirQualityRequest,
    BulkAirQualityResponse,
    AQICalculationRequest,
    AQICalculationResponse,
    SensorReading,
    SensorReadingResponse,
    LocationQuery,
    NearbySensorsResponse,
    CalibrationRequest,
    CalibrationResponse,
    HealthRecommendations,
    RealTimeAlert,
    AQICategory
)
from app.core.config import settings
from app.services.external_api_service import ExternalAPIService
from app.services.cache_service import CacheService

router = APIRouter()
logger = logging.getLogger(__name__)

# Initialize services
external_api_service = ExternalAPIService()
cache_service = CacheService()

def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two points using Haversine formula"""
    R = 6371  # Earth's radius in kilometers
    
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    
    return R * c * 1000  # Convert to meters

def calculate_aqi(pm25: Optional[float], pm10: Optional[float], 
                  no2: Optional[float], so2: Optional[float],
                  co: Optional[float], o3: Optional[float]) -> tuple[int, AQICategory, Optional[str]]:
    """
    Calculate Air Quality Index and category
    Returns: (aqi_value, category, primary_pollutant)
    """
    aqi_values = []
    
    # PM2.5 breakpoints
    if pm25 is not None:
        if pm25 <= 12.0:
            aqi_pm25 = int((50/12.0) * pm25)
        elif pm25 <= 35.4:
            aqi_pm25 = int(((100-51)/(35.4-12.1)) * (pm25 - 12.1) + 51)
        elif pm25 <= 55.4:
            aqi_pm25 = int(((150-101)/(55.5-35.5)) * (pm25 - 35.5) + 101)
        elif pm25 <= 150.4:
            aqi_pm25 = int(((200-151)/(150.5-55.6)) * (pm25 - 55.6) + 151)
        elif pm25 <= 250.4:
            aqi_pm25 = int(((300-201)/(250.5-150.5)) * (pm25 - 150.5) + 201)
        else:
            aqi_pm25 = int(((500-301)/(500.4-250.5)) * (pm25 - 250.5) + 301)
        aqi_values.append(("PM2.5", aqi_pm25))
    
    # PM10 breakpoints
    if pm10 is not None:
        if pm10 <= 54:
            aqi_pm10 = int((50/54) * pm10)
        elif pm10 <= 154:
            aqi_pm10 = int(((100-51)/(154-55)) * (pm10 - 55) + 51)
        elif pm10 <= 254:
            aqi_pm10 = int(((150-101)/(254-155)) * (pm10 - 155) + 101)
        elif pm10 <= 354:
            aqi_pm10 = int(((200-151)/(354-255)) * (pm10 - 255) + 151)
        elif pm10 <= 424:
            aqi_pm10 = int(((300-201)/(424-355)) * (pm10 - 355) + 201)
        else:
            aqi_pm10 = int(((500-301)/(604-425)) * (pm10 - 425) + 301)
        aqi_values.append(("PM10", aqi_pm10))
    
    # Return the highest AQI value
    if not aqi_values:
        return 0, AQICategory.GOOD, None
    
    primary_pollutant, max_aqi = max(aqi_values, key=lambda x: x[1])
    
    # Determine category
    if max_aqi <= 50:
        category = AQICategory.GOOD
    elif max_aqi <= 100:
        category = AQICategory.MODERATE
    elif max_aqi <= 150:
        category = AQICategory.UNHEALTHY_FOR_SENSITIVE
    elif max_aqi <= 200:
        category = AQICategory.UNHEALTHY
    elif max_aqi <= 300:
        category = AQICategory.VERY_UNHEALTHY
    else:
        category = AQICategory.HAZARDOUS
    
    return max_aqi, category, primary_pollutant

def calculate_lung_safety_score(aqi: int, health_conditions: Optional[List[str]] = None) -> float:
    """Calculate lung safety score (0-100, higher is safer)"""
    if health_conditions is None:
        health_conditions = []
    
    # Base score calculation
    if aqi <= 50:
        base_score = 95.0
    elif aqi <= 100:
        base_score = 80.0 - ((aqi - 50) * 0.3)
    elif aqi <= 150:
        base_score = 65.0 - ((aqi - 100) * 0.5)
    elif aqi <= 200:
        base_score = 45.0 - ((aqi - 150) * 0.4)
    elif aqi <= 300:
        base_score = 25.0 - ((aqi - 200) * 0.2)
    else:
        base_score = max(5.0, 15.0 - ((aqi - 300) * 0.1))
    
    # Adjust for health conditions
    conditions_multiplier = 1.0
    if "respiratory" in health_conditions:
        conditions_multiplier *= 0.85
    if "cardiovascular" in health_conditions:
        conditions_multiplier *= 0.9
    if "smoker" in health_conditions:
        conditions_multiplier *= 0.9
    
    return max(0.0, min(100.0, base_score * conditions_multiplier))

@router.post("/readings", response_model=AirQualityReadingSchema, status_code=status.HTTP_201_CREATED)
async def create_air_quality_reading(
    reading: AirQualityReadingCreate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_database),
    current_user: Optional[UserProfile] = Depends(get_optional_user)
):
    """Create a new air quality reading"""
    try:
        # Calculate AQI and lung safety score
        aqi, category, primary_pollutant = calculate_aqi(
            reading.pm25, reading.pm10, reading.no2, reading.so2, reading.co, reading.o3
        )
        
        # Calculate lung safety score if user has health profile
        lung_safety_score = None
        if current_user:
            health_conditions = []
            if current_user.has_respiratory_conditions:
                health_conditions.append("respiratory")
            if current_user.has_cardiovascular_conditions:
                health_conditions.append("cardiovascular")
            if current_user.is_smoker:
                health_conditions.append("smoker")
            
            lung_safety_score = calculate_lung_safety_score(aqi, health_conditions)
        
        # Create reading record
        db_reading = AirQualityReading(
            **reading.dict(),
            user_id=current_user.id if current_user else None,
            aqi=aqi,
            aqi_category=category.value if category else None,
            lung_safety_score=lung_safety_score
        )
        
        db.add(db_reading)
        await db.commit()
        await db.refresh(db_reading)
        
        # Cache the reading for quick access
        cache_key = f"reading_{db_reading.latitude}_{db_reading.longitude}_{int(reading.reading_time.timestamp())}"
        await cache_service.set(cache_key, db_reading, ttl=settings.CACHE_TTL)
        
        # Update user's daily count
        if current_user:
            await increment_usage_count(current_user, "query")
            db.add(current_user)
            await db.commit()
        
        return AirQualityReadingSchema.from_orm(db_reading)
        
    except Exception as e:
        await db.rollback()
        logger.error(f"Error creating air quality reading: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create air quality reading"
        )

@router.get("/readings/nearby", response_model=AirQualityResponse)
async def get_nearby_air_quality(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    radius: int = Query(default=1000, ge=100, le=50000),
    limit: int = Query(default=50, ge=1, le=200),
    db: AsyncSession = Depends(get_database),
    current_user: Optional[UserProfile] = Depends(get_optional_user)
):
    """Get air quality readings near a location"""
    try:
        # Check rate limit for non-authenticated users
        if not current_user:
            # For anonymous users, implement global rate limiting
            cache_key = f"anon_queries_{datetime.utcnow().strftime('%Y%m%d')}"
            current_count = await cache_service.get(cache_key, default=0)
            if current_count >= settings.FREE_TIER_LIMITS["daily_queries"]:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Daily query limit reached. Please sign up for free account to continue."
                )
            await cache_service.increment(cache_key)
        
        # Get recent readings within radius
        readings_query = select(AirQualityReading).where(
            and_(
                AirQualityReading.latitude >= latitude - (radius / 111000),
                AirQualityReading.latitude <= latitude + (radius / 111000),
                AirQualityReading.longitude >= longitude - (radius / (111000 * cos(radians(latitude)))),
                AirQualityReading.longitude <= longitude + (radius / (111000 * cos(radians(latitude)))),
                AirQualityReading.reading_time >= datetime.utcnow() - timedelta(hours=24)
            )
        ).order_by(desc(AirQualityReading.reading_time)).limit(limit)
        
        result = await db.execute(readings_query)
        readings = result.scalars().all()
        
        if not readings:
            # Try to fetch from external APIs
            external_data = await external_api_service.get_air_quality_data(latitude, longitude)
            if external_data:
                # Create reading from external data
                external_reading = AirQualityReading(
                    latitude=latitude,
                    longitude=longitude,
                    source="external_api",
                    **external_data
                )
                db.add(external_reading)
                await db.commit()
                await db.refresh(external_reading)
                readings = [external_reading]
        
        if not readings:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No air quality readings found in the specified area"
            )
        
        # Calculate current AQI summary
        latest_reading = max(readings, key=lambda x: x.reading_time)
        current_summary = AQISummary(
            current_aqi=latest_reading.aqi,
            category=AQICategory(latest_reading.aqi_category) if latest_reading.aqi_category else None,
            health_recommendation=get_health_recommendation(latest_reading.aqi),
            sensitive_groups_advice=get_sensitive_groups_advice(latest_reading.aqi),
            general_population_advice=get_general_population_advice(latest_reading.aqi),
            primary_pollutant=determine_primary_pollutant(latest_reading),
            time_updated=latest_reading.reading_time
        )
        
        # Calculate location statistics
        aqi_values = [r.aqi for r in readings if r.aqi is not None]
        if aqi_values:
            avg_aqi = sum(aqi_values) / len(aqi_values)
            trend = calculate_trend(aqi_values)
        else:
            avg_aqi = None
            trend = None
        
        location_stats = LocationStats(
            location_name=f"Lat {latitude:.4f}, Lon {longitude:.4f}",
            latitude=latitude,
            longitude=longitude,
            recent_aqi=latest_reading.aqi,
            trend=trend,
            data_points_count=len(readings),
            last_updated=latest_reading.reading_time
        )
        
        # Update user usage
        if current_user:
            await increment_usage_count(current_user, "query")
            db.add(current_user)
            await db.commit()
        
        return AirQualityResponse(
            current=current_summary,
            nearby_readings=[AirQualityReadingSchema.from_orm(r) for r in readings],
            location_stats=location_stats
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching nearby air quality: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch air quality data"
        )

@router.post("/readings/bulk", response_model=BulkAirQualityResponse)
async def get_bulk_air_quality(
    request: BulkAirQualityRequest,
    db: AsyncSession = Depends(get_database),
    current_user: UserProfile = Depends(get_current_user)
):
    """Get air quality data for multiple locations (Pro feature)"""
    try:
        # Check if user has pro subscription
        if current_user.subscription_tier != "pro" and current_user.subscription_tier != "enterprise":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bulk queries require Pro subscription or higher"
            )
        
        # Check rate limit
        if not check_rate_limit(current_user, "query"):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Daily query limit exceeded"
            )
        
        readings = []
        
        # Process each location
        for loc in request.locations:
            lat = loc["lat"]
            lon = loc["lon"]
            
            # Get recent reading for this location
            reading_query = select(AirQualityReading).where(
                and_(
                    AirQualityReading.latitude.between(lat - 0.001, lat + 0.001),
                    AirQualityReading.longitude.between(lon - 0.001, lon + 0.001),
                    AirQualityReading.reading_time >= datetime.utcnow() - timedelta(hours=1)
                )
            ).order_by(desc(AirQualityReading.reading_time)).limit(1)
            
            result = await db.execute(reading_query)
            reading = result.scalar_one_or_none()
            
            if reading:
                readings.append(reading)
            else:
                # Try external API
                external_data = await external_api_service.get_air_quality_data(lat, lon)
                if external_data:
                    new_reading = AirQualityReading(
                        latitude=lat,
                        longitude=lon,
                        source="external_api",
                        **external_data
                    )
                    readings.append(new_reading)
        
        # Update usage
        await increment_usage_count(current_user, "query")
        db.add(current_user)
        await db.commit()
        
        return BulkAirQualityResponse(
            readings=[AirQualityReadingSchema.from_orm(r) for r in readings],
            summary={
                "locations_requested": len(request.locations),
                "readings_found": len(readings),
                "coverage_percentage": len(readings) / len(request.locations) * 100 if request.locations else 0
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in bulk air quality query: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process bulk air quality query"
        )

@router.get("/readings/historical", response_model=HistoricalDataResponse)
async def get_historical_data(
    request: HistoricalDataRequest = Depends(),
    aggregation: str = Query(default="hourly", regex="^(hourly|daily|weekly)$"),
    db: AsyncSession = Depends(get_database)
):
    """Get historical air quality data for a location"""
    try:
        # Get readings for the specified period
        readings_query = select(AirQualityReading).where(
            and_(
                AirQualityReading.latitude.between(request.latitude - 0.01, request.latitude + 0.01),
                AirQualityReading.longitude.between(request.longitude - 0.01, request.longitude + 0.01),
                AirQualityReading.reading_time >= request.start_date,
                AirQualityReading.reading_time <= request.end_date
            )
        ).order_by(asc(AirQualityReading.reading_time))
        
        result = await db.execute(readings_query)
        readings = result.scalars().all()
        
        if not readings:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No historical data found for the specified location and time period"
            )
        
        # Aggregate data based on requested timeframe
        if aggregation == "daily":
            aggregated_data = aggregate_daily_data(readings)
        elif aggregation == "weekly":
            aggregated_data = aggregate_weekly_data(readings)
        else:
            aggregated_data = readings
        
        # Calculate statistics
        statistics = calculate_statistics(readings)
        
        return HistoricalDataResponse(
            location={"latitude": request.latitude, "longitude": request.longitude},
            period={"start": request.start_date, "end": request.end_date},
            data_points=[AirQualityReadingSchema.from_orm(r) for r in aggregated_data],
            statistics=statistics
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching historical data: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch historical air quality data"
        )

@router.post("/calculate-aqi", response_model=AQICalculationResponse)
async def calculate_aqi_endpoint(request: AQICalculationRequest):
    """Calculate AQI from pollutant concentrations"""
    try:
        aqi, category, primary_pollutant = calculate_aqi(
            request.pm25, request.pm10, request.no2, request.so2, request.co, request.o3
        )
        
        recommendations = get_health_recommendations(aqi)
        
        calculation_details = {
            "pm25_contribution": request.pm25,
            "pm10_contribution": request.pm10,
            "aqi_breakdown": calculate_aqi_breakdown(request)
        }
        
        return AQICalculationResponse(
            aqi=aqi,
            category=category,
            primary_pollutant=primary_pollutant,
            health_recommendations=recommendations,
            calculation_details=calculation_details
        )
        
    except Exception as e:
        logger.error(f"Error calculating AQI: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to calculate AQI"
        )

@router.get("/sensors/nearby", response_model=NearbySensorsResponse)
async def get_nearby_sensors(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    radius: float = Query(default=5000, ge=100, le=50000),
    limit: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_database)
):
    """Get nearby sensor devices and their latest readings"""
    try:
        # Get sensors within radius
        sensors_query = select(SensorDevice).where(
            and_(
                SensorDevice.is_active == True,
                SensorDevice.is_connected == True
            )
        ).limit(limit)
        
        result = await db.execute(sensors_query)
        sensors = result.scalars().all()
        
        # Filter sensors by distance and get their latest readings
        nearby_sensors = []
        readings = []
        
        for sensor in sensors:
            # This would require more complex location storage for sensors
            # For now, we'll return all active sensors
            nearby_sensors.append(sensor)
            
            # Get latest reading from this sensor
            reading_query = select(AirQualityReading).where(
                AirQualityReading.sensor_id == sensor.id
            ).order_by(desc(AirQualityReading.reading_time)).limit(1)
            
            reading_result = await db.execute(reading_query)
            latest_reading = reading_result.scalar_one_or_none()
            
            if latest_reading:
                readings.append(latest_reading)
        
        return NearbySensorsResponse(
            location={"latitude": latitude, "longitude": longitude},
            radius=radius,
            sensors_found=len(nearby_sensors),
            readings=[AirQualityReadingSchema.from_orm(r) for r in readings],
            sensor_summary=[
                SensorReadingResponse(
                    sensor_id=sensor.id,
                    latest_reading=None,  # Would need to map from readings
                    connection_status="connected" if sensor.is_connected else "disconnected",
                    last_seen=sensor.last_seen,
                    battery_level=sensor.battery_level
                ) for sensor in nearby_sensors
            ]
        )
        
    except Exception as e:
        logger.error(f"Error fetching nearby sensors: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch nearby sensors"
        )

@router.post("/calibrate", response_model=CalibrationResponse)
async def calibrate_sensor(
    request: CalibrationRequest,
    db: AsyncSession = Depends(get_database),
    current_user: UserProfile = Depends(get_current_user)
):
    """Calibrate a sensor device with reference measurements"""
    try:
        # Get the reading and sensor
        reading_result = await db.execute(
            select(AirQualityReading).where(AirQualityReading.id == request.reading_id)
        )
        reading = reading_result.scalar_one_or_none()
        
        if not reading:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reading not found"
            )
        
        sensor_result = await db.execute(
            select(SensorDevice).where(SensorDevice.id == request.sensor_id)
        )
        sensor = sensor_result.scalar_one_or_none()
        
        if not sensor:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Sensor not found"
            )
        
        # Calculate calibration factor
        old_factor = sensor.calibration_factor
        
        if reading.pm25 and request.reference_pm25:
            old_reading = reading.pm25 / old_factor if old_factor != 1.0 else reading.pm25
            new_factor = request.reference_pm25 / old_reading if old_reading > 0 else 1.0
            
            # Apply bounds checking
            new_factor = max(0.1, min(10.0, new_factor))
        else:
            new_factor = old_factor
        
        # Update sensor calibration
        sensor.calibration_factor = new_factor
        sensor.last_calibration = datetime.utcnow()
        sensor.calibration_needed = False
        
        # Update the reading with calibrated value
        if reading.pm25:
            reading.pm25 = reading.pm25 * new_factor
        if reading.pm10 and request.reference_pm10:
            reading.pm10 = reading.pm10 * new_factor
        
        # Recalculate AQI
        aqi, category, primary_pollutant = calculate_aqi(
            reading.pm25, reading.pm10, reading.no2, reading.so2, reading.co, reading.o3
        )
        reading.aqi = aqi
        reading.aqi_category = category.value if category else None
        
        db.add(sensor)
        db.add(reading)
        await db.commit()
        
        # Determine calibration quality
        quality_score = min(1.0, abs(new_factor - 1.0) / 0.5)
        
        recommendations = []
        if quality_score < 0.3:
            recommendations.append("Calibration appears accurate")
        elif quality_score < 0.7:
            recommendations.append("Consider additional reference measurements")
        else:
            recommendations.append("Sensor may need recalibration or replacement")
        
        return CalibrationResponse(
            reading_id=request.reading_id,
            sensor_id=request.sensor_id,
            previous_factor=old_factor,
            new_factor=new_factor,
            calibration_quality=quality_score,
            recommendations=recommendations
        )
        
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        logger.error(f"Error calibrating sensor: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to calibrate sensor"
        )

# Helper functions
def get_health_recommendation(aqi: int) -> str:
    """Get general health recommendation based on AQI"""
    if aqi <= 50:
        return "Air quality is satisfactory for most people."
    elif aqi <= 100:
        return "Air quality is acceptable for most people."
    elif aqi <= 150:
        return "Members of sensitive groups may experience health effects."
    elif aqi <= 200:
        return "Everyone may begin to experience health effects."
    elif aqi <= 300:
        return "Health alert: everyone may experience serious effects."
    else:
        return "Health warnings of emergency conditions."

def get_sensitive_groups_advice(aqi: int) -> str:
    """Get advice for sensitive groups"""
    if aqi <= 50:
        return "Sensitive groups can participate in outdoor activities as normal."
    elif aqi <= 100:
        return "Sensitive groups should consider reducing prolonged outdoor exertion."
    elif aqi <= 150:
        return "Sensitive groups should limit prolonged outdoor exertion."
    elif aqi <= 200:
        return "Sensitive groups should avoid outdoor exertion."
    elif aqi <= 300:
        return "Sensitive groups should remain indoors and avoid outdoor activities."
    else:
        return "All sensitive groups should remain indoors and avoid all outdoor activities."

def get_general_population_advice(aqi: int) -> str:
    """Get advice for general population"""
    if aqi <= 100:
        return "Normal outdoor activities are safe for most people."
    elif aqi <= 150:
        return "Unusually sensitive people should consider reducing outdoor activities."
    elif aqi <= 200:
        return "Limit outdoor activities, especially for prolonged periods."
    elif aqi <= 300:
        return "Reduce or reschedule outdoor activities."
    else:
        return "Avoid all outdoor activities. Stay indoors with air filtration if possible."

def determine_primary_pollutant(reading: AirQualityReading) -> Optional[str]:
    """Determine the primary pollutant based on concentrations"""
    pollutants = {}
    if reading.pm25:
        pollutants["PM2.5"] = reading.pm25
    if reading.pm10:
        pollutants["PM10"] = reading.pm10
    if reading.no2:
        pollutants["NO2"] = reading.no2
    if reading.so2:
        pollutants["SO2"] = reading.so2
    if reading.co:
        pollutants["CO"] = reading.co
    if reading.o3:
        pollutants["O3"] = reading.o3
    
    if not pollutants:
        return None
    
    return max(pollutants, key=pollutants.get)

def calculate_trend(aqi_values: List[int]) -> Optional[str]:
    """Calculate AQI trend (improving, worsening, stable)"""
    if len(aqi_values) < 3:
        return None
    
    recent_avg = sum(aqi_values[-3:]) / 3
    earlier_avg = sum(aqi_values[:-3]) / len(aqi_values[:-3])
    
    difference = recent_avg - earlier_avg
    if abs(difference) < 5:  # Threshold for "stable"
        return "stable"
    elif difference < 0:
        return "improving"
    else:
        return "worsening"

def aggregate_daily_data(readings: List[AirQualityReading]) -> List[AirQualityReading]:
    """Aggregate readings into daily averages"""
    # This would implement daily aggregation logic
    # For now, return all readings
    return readings

def aggregate_weekly_data(readings: List[AirQualityReading]) -> List[AirQualityReading]:
    """Aggregate readings into weekly averages"""
    # This would implement weekly aggregation logic
    # For now, return all readings
    return readings

def calculate_statistics(readings: List[AirQualityReading]) -> Dict[str, Any]:
    """Calculate statistical summaries of readings"""
    if not readings:
        return {}
    
    aqi_values = [r.aqi for r in readings if r.aqi is not None]
    pm25_values = [r.pm25 for r in readings if r.pm25 is not None]
    
    if not aqi_values:
        return {}
    
    return {
        "count": len(readings),
        "aqi_min": min(aqi_values),
        "aqi_max": max(aqi_values),
        "aqi_avg": sum(aqi_values) / len(aqi_values),
        "aqi_median": sorted(aqi_values)[len(aqi_values) // 2],
        "pm25_avg": sum(pm25_values) / len(pm25_values) if pm25_values else None,
        "date_range": {
            "start": min(r.reading_time for r in readings),
            "end": max(r.reading_time for r in readings)
        }
    }

def get_health_recommendations(aqi: int) -> Dict[str, str]:
    """Get detailed health recommendations"""
    if aqi <= 50:
        return {
            "general": "Air quality is satisfactory for most people.",
            "sensitive": "No precautions needed for sensitive groups.",
            "activities": "All outdoor activities are safe."
        }
    elif aqi <= 100:
        return {
            "general": "Air quality is acceptable for most people.",
            "sensitive": "Unusually sensitive people should consider reducing prolonged outdoor exertion.",
            "activities": "Normal outdoor activities are safe for most people."
        }
    elif aqi <= 150:
        return {
            "general": "Members of sensitive groups may experience health effects.",
            "sensitive": "Sensitive groups should limit prolonged outdoor exertion.",
            "activities": "Consider reducing prolonged or heavy exertion outdoors."
        }
    elif aqi <= 200:
        return {
            "general": "Everyone may begin to experience health effects.",
            "sensitive": "Sensitive groups should avoid outdoor exertion.",
            "activities": "Reduce or reschedule strenuous outdoor activities."
        }
    elif aqi <= 300:
        return {
            "general": "Health alert: everyone may experience serious effects.",
            "sensitive": "Sensitive groups should remain indoors and avoid outdoor activities.",
            "activities": "Avoid all outdoor strenuous activities."
        }
    else:
        return {
            "general": "Health warnings of emergency conditions.",
            "sensitive": "All sensitive groups should remain indoors and avoid all outdoor activities.",
            "activities": "Avoid all outdoor activities. Stay indoors with air filtration if possible."
        }

def calculate_aqi_breakdown(request: AQICalculationRequest) -> Dict[str, Any]:
    """Calculate detailed AQI breakdown by pollutant"""
    # This would provide detailed breakdown of how each pollutant contributes to AQI
    return {
        "calculation_method": "EPA AQI calculation",
        "primary_pollutant_consideration": "Highest AQI value among all pollutants determines overall AQI"
    }
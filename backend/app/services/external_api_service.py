import aiohttp
import asyncio
import logging
from typing import Dict, Any, Optional
from datetime import datetime, timedelta

from app.core.config import settings

logger = logging.getLogger(__name__)

class ExternalAPIService:
    """Service for external API integrations (weather, air quality APIs, etc.)"""
    
    def __init__(self):
        self.session: Optional[aiohttp.ClientSession] = None
        self.cache = {}
    
    async def initialize(self):
        """Initialize the service"""
        timeout = aiohttp.ClientTimeout(total=30)
        self.session = aiohttp.ClientSession(timeout=timeout)
        logger.info("External API service initialized")
    
    async def shutdown(self):
        """Shutdown the service"""
        if self.session:
            await self.session.close()
            logger.info("External API service shutdown complete")
    
    async def get_air_quality_data(self, latitude: float, longitude: float) -> Optional[Dict[str, Any]]:
        """Get air quality data from external APIs"""
        cache_key = f"aqi_{latitude:.4f}_{longitude:.4f}"
        
        # Check cache first
        if cache_key in self.cache:
            cached_data, timestamp = self.cache[cache_key]
            if datetime.utcnow() - timestamp < timedelta(minutes=30):
                return cached_data
        
        try:
            # Try OpenWeatherMap API first
            if settings.OPENWEATHER_API_KEY:
                owm_data = await self._get_openweather_aqi(latitude, longitude)
                if owm_data:
                    self.cache[cache_key] = (owm_data, datetime.utcnow())
                    return owm_data
            
            # Fallback to other APIs
            # This would implement other air quality API integrations
            
            return None
            
        except Exception as e:
            logger.error(f"Error fetching external air quality data: {e}")
            return None
    
    async def _get_openweather_aqi(self, latitude: float, longitude: float) -> Optional[Dict[str, Any]]:
        """Get air quality data from OpenWeatherMap"""
        try:
            url = f"http://api.openweathermap.org/data/2.5/air_pollution"
            params = {
                "lat": latitude,
                "lon": longitude,
                "appid": settings.OPENWEATHER_API_KEY
            }
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    
                    if "list" in data and len(data["list"]) > 0:
                        air_data = data["list"][0]
                        components = air_data.get("components", {})
                        
                        # Convert OpenWeatherMap format to our format
                        return {
                            "pm25": components.get("pm2_5"),
                            "pm10": components.get("pm10"),
                            "no2": components.get("no2"),
                            "so2": components.get("so2"),
                            "co": components.get("co") / 1000,  # Convert µg/m³ to mg/m³
                            "o3": components.get("o3"),
                            "reading_time": datetime.utcfromtimestamp(air_data["dt"]),
                            "source": "openweathermap"
                        }
                
                logger.warning(f"OpenWeatherMap API returned status {response.status}")
                return None
                
        except Exception as e:
            logger.error(f"Error fetching OpenWeatherMap data: {e}")
            return None
    
    async def get_weather_data(self, latitude: float, longitude: float) -> Optional[Dict[str, Any]]:
        """Get weather data from external APIs"""
        cache_key = f"weather_{latitude:.4f}_{longitude:.4f}"
        
        # Check cache first
        if cache_key in self.cache:
            cached_data, timestamp = self.cache[cache_key]
            if datetime.utcnow() - timestamp < timedelta(hours=1):
                return cached_data
        
        try:
            if settings.OPENWEATHER_API_KEY:
                weather_data = await self._get_openweather_weather(latitude, longitude)
                if weather_data:
                    self.cache[cache_key] = (weather_data, datetime.utcnow())
                    return weather_data
            
            return None
            
        except Exception as e:
            logger.error(f"Error fetching weather data: {e}")
            return None
    
    async def _get_openweather_weather(self, latitude: float, longitude: float) -> Optional[Dict[str, Any]]:
        """Get weather data from OpenWeatherMap"""
        try:
            url = f"http://api.openweathermap.org/data/2.5/weather"
            params = {
                "lat": latitude,
                "lon": longitude,
                "appid": settings.OPENWEATHER_API_KEY,
                "units": "metric"
            }
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    
                    return {
                        "temperature": data["main"]["temp"],
                        "humidity": data["main"]["humidity"],
                        "pressure": data["main"]["pressure"],
                        "wind_speed": data.get("wind", {}).get("speed", 0),
                        "wind_direction": data.get("wind", {}).get("deg", 0),
                        "conditions": data["weather"][0]["description"],
                        "source": "openweathermap"
                    }
                
                return None
                
        except Exception as e:
            logger.error(f"Error fetching OpenWeatherMap weather: {e}")
            return None
    
    async def get_traffic_data(self, latitude: float, longitude: float) -> Optional[Dict[str, Any]]:
        """Get traffic data (placeholder for future implementation)"""
        # This would integrate with traffic APIs like Google Maps Traffic API
        # For now, return None
        return None
    
    async def get_satellite_data(self, latitude: float, longitude: float) -> Optional[Dict[str, Any]]:
        """Get satellite data for air quality analysis"""
        # This would integrate with NASA or other satellite APIs
        # For now, return None
        return None
    
    async def get_geocoding_data(self, latitude: float, longitude: float) -> Optional[Dict[str, Any]]:
        """Get location name from coordinates"""
        cache_key = f"geo_{latitude:.4f}_{longitude:.4f}"
        
        # Check cache first
        if cache_key in self.cache:
            cached_data, timestamp = self.cache[cache_key]
            if datetime.utcnow() - timestamp < timedelta(days=1):
                return cached_data
        
        try:
            if settings.GOOGLE_MAPS_API_KEY:
                geo_data = await self._get_google_geocoding(latitude, longitude)
                if geo_data:
                    self.cache[cache_key] = (geo_data, datetime.utcnow())
                    return geo_data
            
            return None
            
        except Exception as e:
            logger.error(f"Error fetching geocoding data: {e}")
            return None
    
    async def _get_google_geocoding(self, latitude: float, longitude: float) -> Optional[Dict[str, Any]]:
        """Get location data from Google Geocoding API"""
        try:
            url = f"https://maps.googleapis.com/maps/api/geocode/json"
            params = {
                "latlng": f"{latitude},{longitude}",
                "key": settings.GOOGLE_MAPS_API_KEY
            }
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    
                    if "results" in data and len(data["results"]) > 0:
                        result = data["results"][0]
                        address_components = result.get("address_components", [])
                        
                        # Extract location information
                        location_data = {
                            "formatted_address": result["formatted_address"],
                            "location_name": result.get("formatted_address", ""),
                            "place_id": result.get("place_id", ""),
                            "types": result.get("types", [])
                        }
                        
                        # Extract city and country
                        for component in address_components:
                            types = component.get("types", [])
                            if "locality" in types or "administrative_area_level_2" in types:
                                location_data["city"] = component.get("long_name")
                            elif "country" in types:
                                location_data["country"] = component.get("long_name")
                            elif "administrative_area_level_1" in types:
                                location_data["state"] = component.get("long_name")
                        
                        return location_data
                
                return None
                
        except Exception as e:
            logger.error(f"Error fetching Google Geocoding: {e}")
            return None
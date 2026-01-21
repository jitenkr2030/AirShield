import asyncio
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from enum import Enum

from app.core.config import settings

logger = logging.getLogger(__name__)

class NotificationPriority(Enum):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    URGENT = "urgent"

class NotificationType(Enum):
    AIR_QUALITY_ALERT = "air_quality_alert"
    PREDICTION_UPDATE = "prediction_update"
    SENSOR_STATUS = "sensor_status"
    HEALTH_RECOMMENDATION = "health_recommendation"
    SYSTEM_UPDATE = "system_update"

class NotificationService:
    """Push notification service for alerts and updates"""
    
    def __init__(self):
        self.subscribers: Dict[str, List[str]] = {}  # user_id -> list of device tokens
        self.notification_queue: List[Dict[str, Any]] = []
        self.is_initialized = False
    
    async def initialize(self):
        """Initialize notification service"""
        try:
            # Initialize Firebase or other push notification service
            # This would set up actual push notification infrastructure
            self.is_initialized = True
            logger.info("Notification service initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize notification service: {e}")
            self.is_initialized = False
    
    async def shutdown(self):
        """Shutdown notification service"""
        self.is_initialized = False
        logger.info("Notification service shutdown complete")
    
    async def send_notification(
        self,
        user_id: str,
        title: str,
        message: str,
        notification_type: NotificationType,
        priority: NotificationPriority = NotificationPriority.NORMAL,
        data: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Send push notification to user"""
        if not self.is_initialized:
            logger.warning("Notification service not initialized")
            return False
        
        try:
            notification = {
                "user_id": user_id,
                "title": title,
                "message": message,
                "type": notification_type.value,
                "priority": priority.value,
                "data": data or {},
                "timestamp": datetime.utcnow(),
                "status": "pending"
            }
            
            # Add to queue
            self.notification_queue.append(notification)
            
            # Process notification immediately for urgent items
            if priority == NotificationPriority.URGENT:
                await self._process_notification(notification)
            
            logger.info(f"Notification queued for user {user_id}: {title}")
            return True
            
        except Exception as e:
            logger.error(f"Error sending notification: {e}")
            return False
    
    async def send_bulk_notification(
        self,
        user_ids: List[str],
        title: str,
        message: str,
        notification_type: NotificationType,
        priority: NotificationPriority = NotificationPriority.NORMAL,
        data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, bool]:
        """Send notification to multiple users"""
        results = {}
        
        for user_id in user_ids:
            results[user_id] = await self.send_notification(
                user_id, title, message, notification_type, priority, data
            )
        
        return results
    
    async def send_air_quality_alert(
        self,
        user_id: str,
        aqi: int,
        location_name: str,
        recommendations: List[str]
    ) -> bool:
        """Send air quality alert notification"""
        title = f"Air Quality Alert - {location_name}"
        message = f"AQI: {aqi}. " + " ".join(recommendations[:2])  # First 2 recommendations
        
        notification_data = {
            "aqi": aqi,
            "location": location_name,
            "recommendations": recommendations,
            "alert_type": "air_quality"
        }
        
        return await self.send_notification(
            user_id, title, message, NotificationType.AIR_QUALITY_ALERT,
            NotificationPriority.HIGH if aqi > 150 else NotificationPriority.NORMAL,
            notification_data
        )
    
    async def send_prediction_update(
        self,
        user_id: str,
        location: str,
        hours_ahead: int,
        predicted_aqi: int
    ) -> bool:
        """Send pollution prediction update"""
        title = f"Air Quality Forecast - {location}"
        message = f"Next {hours_ahead}h: AQI {predicted_aqi}"
        
        notification_data = {
            "location": location,
            "hours_ahead": hours_ahead,
            "predicted_aqi": predicted_aqi,
            "alert_type": "prediction"
        }
        
        return await self.send_notification(
            user_id, title, message, NotificationType.PREDICTION_UPDATE,
            NotificationPriority.NORMAL, notification_data
        )
    
    async def send_sensor_alert(
        self,
        user_id: str,
        sensor_id: str,
        alert_type: str,
        message: str
    ) -> bool:
        """Send sensor status alert"""
        title = f"Sensor Alert - {sensor_id}"
        
        notification_data = {
            "sensor_id": sensor_id,
            "alert_type": alert_type,
            "alert_type_enum": NotificationType.SENSOR_STATUS.value
        }
        
        priority = NotificationPriority.URGENT if alert_type in ["disconnected", "low_battery"] else NotificationPriority.NORMAL
        
        return await self.send_notification(
            user_id, title, message, NotificationType.SENSOR_STATUS, priority, notification_data
        )
    
    async def schedule_notification(
        self,
        user_id: str,
        title: str,
        message: str,
        send_time: datetime,
        notification_type: NotificationType,
        recurring: Optional[Dict[str, Any]] = None
    ) -> str:
        """Schedule a notification for later delivery"""
        try:
            schedule_id = f"schedule_{user_id}_{int(datetime.utcnow().timestamp())}"
            
            scheduled_notification = {
                "id": schedule_id,
                "user_id": user_id,
                "title": title,
                "message": message,
                "type": notification_type.value,
                "send_time": send_time,
                "recurring": recurring,
                "status": "scheduled",
                "created_at": datetime.utcnow()
            }
            
            # Store in scheduled notifications database
            # This would be stored in the actual database
            logger.info(f"Notification scheduled for {send_time}: {title}")
            
            return schedule_id
            
        except Exception as e:
            logger.error(f"Error scheduling notification: {e}")
            return ""
    
    async def cancel_scheduled_notification(self, schedule_id: str) -> bool:
        """Cancel a scheduled notification"""
        try:
            # Remove from scheduled notifications database
            logger.info(f"Scheduled notification cancelled: {schedule_id}")
            return True
        except Exception as e:
            logger.error(f"Error cancelling scheduled notification: {e}")
            return False
    
    async def register_device(self, user_id: str, device_token: str) -> bool:
        """Register device for push notifications"""
        try:
            if user_id not in self.subscribers:
                self.subscribers[user_id] = []
            
            if device_token not in self.subscribers[user_id]:
                self.subscribers[user_id].append(device_token)
                logger.info(f"Device registered for user {user_id}: {device_token[:10]}...")
                return True
            
            return False
        except Exception as e:
            logger.error(f"Error registering device: {e}")
            return False
    
    async def unregister_device(self, user_id: str, device_token: str) -> bool:
        """Unregister device from push notifications"""
        try:
            if user_id in self.subscribers and device_token in self.subscribers[user_id]:
                self.subscribers[user_id].remove(device_token)
                logger.info(f"Device unregistered for user {user_id}: {device_token[:10]}...")
                return True
            
            return False
        except Exception as e:
            logger.error(f"Error unregistering device: {e}")
            return False
    
    async def _process_notification(self, notification: Dict[str, Any]) -> bool:
        """Process and send notification"""
        try:
            user_id = notification["user_id"]
            
            # Get user's device tokens
            device_tokens = self.subscribers.get(user_id, [])
            
            if not device_tokens:
                logger.warning(f"No device tokens found for user {user_id}")
                notification["status"] = "failed"
                return False
            
            # Send to all user's devices
            success_count = 0
            for token in device_tokens:
                if await self._send_to_device(token, notification):
                    success_count += 1
            
            if success_count > 0:
                notification["status"] = "sent"
                notification["sent_count"] = success_count
                logger.info(f"Notification sent successfully to {success_count} devices")
                return True
            else:
                notification["status"] = "failed"
                return False
                
        except Exception as e:
            logger.error(f"Error processing notification: {e}")
            notification["status"] = "error"
            return False
    
    async def _send_to_device(self, device_token: str, notification: Dict[str, Any]) -> bool:
        """Send notification to specific device"""
        try:
            # This would implement actual push notification sending
            # Using Firebase Cloud Messaging or other service
            
            payload = {
                "token": device_token,
                "notification": {
                    "title": notification["title"],
                    "body": notification["message"]
                },
                "data": notification["data"],
                "android": {
                    "priority": notification["priority"]
                },
                "apns": {
                    "headers": {
                        "apns-priority": "10" if notification["priority"] == "urgent" else "5"
                    }
                }
            }
            
            # Simulate successful send
            logger.info(f"Push notification sent to device {device_token[:10]}...")
            return True
            
        except Exception as e:
            logger.error(f"Error sending to device {device_token[:10]}: {e}")
            return False
    
    async def cleanup_old_notifications(self, days_old: int = 30) -> int:
        """Clean up old notifications from queue"""
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=days_old)
            
            initial_count = len(self.notification_queue)
            self.notification_queue = [
                n for n in self.notification_queue 
                if n["timestamp"] > cutoff_date
            ]
            
            cleaned_count = initial_count - len(self.notification_queue)
            logger.info(f"Cleaned up {cleaned_count} old notifications")
            
            return cleaned_count
            
        except Exception as e:
            logger.error(f"Error cleaning up notifications: {e}")
            return 0
    
    async def get_notification_stats(self, user_id: str) -> Dict[str, Any]:
        """Get notification statistics for user"""
        try:
            user_notifications = [
                n for n in self.notification_queue 
                if n["user_id"] == user_id
            ]
            
            return {
                "total_sent": len([n for n in user_notifications if n["status"] == "sent"]),
                "total_failed": len([n for n in user_notifications if n["status"] == "failed"]),
                "pending": len([n for n in user_notifications if n["status"] == "pending"]),
                "registered_devices": len(self.subscribers.get(user_id, []))
            }
            
        except Exception as e:
            logger.error(f"Error getting notification stats: {e}")
            return {}
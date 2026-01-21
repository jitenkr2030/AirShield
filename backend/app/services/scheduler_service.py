import asyncio
import logging
from typing import Dict, Any, List, Optional, Callable
from datetime import datetime, timedelta
from enum import Enum

from app.core.config import settings

logger = logging.getLogger(__name__)

class TaskStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

class TaskPriority(Enum):
    LOW = 1
    NORMAL = 2
    HIGH = 3
    URGENT = 4

class SchedulerService:
    """Background task scheduler for periodic jobs and notifications"""
    
    def __init__(self):
        self.tasks: Dict[str, Dict[str, Any]] = {}
        self.task_handlers: Dict[str, Callable] = {}
        self.is_running = False
        self.scheduler_task: Optional[asyncio.Task] = None
    
    async def initialize(self):
        """Initialize scheduler service"""
        try:
            self.is_running = True
            self.scheduler_task = asyncio.create_task(self._scheduler_loop())
            await self._schedule_default_tasks()
            logger.info("Scheduler service initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize scheduler service: {e}")
            self.is_running = False
    
    async def shutdown(self):
        """Shutdown scheduler service"""
        self.is_running = False
        
        if self.scheduler_task:
            self.scheduler_task.cancel()
            try:
                await self.scheduler_task
            except asyncio.CancelledError:
                pass
        
        # Cancel all pending tasks
        for task_id in list(self.tasks.keys()):
            await self.cancel_task(task_id)
        
        logger.info("Scheduler service shutdown complete")
    
    async def _scheduler_loop(self):
        """Main scheduler loop"""
        while self.is_running:
            try:
                current_time = datetime.utcnow()
                
                # Check for due tasks
                for task_id, task in list(self.tasks.items()):
                    if task["status"] == TaskStatus.PENDING and task["next_run"] <= current_time:
                        await self._execute_task(task_id, task)
                
                # Sleep for a short interval
                await asyncio.sleep(30)  # Check every 30 seconds
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in scheduler loop: {e}")
                await asyncio.sleep(60)  # Wait longer on error
    
    async def schedule_task(
        self,
        task_id: str,
        task_handler: Callable,
        start_time: datetime,
        interval_seconds: Optional[int] = None,
        max_runs: Optional[int] = None,
        priority: TaskPriority = TaskPriority.NORMAL
    ) -> bool:
        """Schedule a recurring task"""
        try:
            if task_id in self.tasks:
                logger.warning(f"Task {task_id} already exists")
                return False
            
            task = {
                "id": task_id,
                "handler": task_handler,
                "next_run": start_time,
                "interval_seconds": interval_seconds,
                "max_runs": max_runs,
                "run_count": 0,
                "priority": priority,
                "status": TaskStatus.PENDING,
                "created_at": datetime.utcnow(),
                "last_run": None,
                "last_result": None
            }
            
            self.tasks[task_id] = task
            self.task_handlers[task_id] = task_handler
            
            logger.info(f"Task scheduled: {task_id} at {start_time}")
            return True
            
        except Exception as e:
            logger.error(f"Error scheduling task {task_id}: {e}")
            return False
    
    async def cancel_task(self, task_id: str) -> bool:
        """Cancel a scheduled task"""
        try:
            if task_id not in self.tasks:
                return False
            
            task = self.tasks[task_id]
            task["status"] = TaskStatus.CANCELLED
            
            # Remove from handlers
            if task_id in self.task_handlers:
                del self.task_handlers[task_id]
            
            logger.info(f"Task cancelled: {task_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error cancelling task {task_id}: {e}")
            return False
    
    async def pause_task(self, task_id: str) -> bool:
        """Pause a scheduled task"""
        try:
            if task_id not in self.tasks:
                return False
            
            task = self.tasks[task_id]
            if task["status"] == TaskStatus.PENDING:
                task["status"] = TaskStatus.CANCELLED
                logger.info(f"Task paused: {task_id}")
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"Error pausing task {task_id}: {e}")
            return False
    
    async def resume_task(self, task_id: str, new_start_time: Optional[datetime] = None) -> bool:
        """Resume a paused task"""
        try:
            if task_id not in self.tasks:
                return False
            
            task = self.tasks[task_id]
            
            if task["status"] == TaskStatus.CANCELLED:
                task["status"] = TaskStatus.PENDING
                task["next_run"] = new_start_time or datetime.utcnow() + timedelta(minutes=5)
                logger.info(f"Task resumed: {task_id}")
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"Error resuming task {task_id}: {e}")
            return False
    
    async def _execute_task(self, task_id: str, task: Dict[str, Any]):
        """Execute a scheduled task"""
        try:
            logger.info(f"Executing task: {task_id}")
            task["status"] = TaskStatus.RUNNING
            task["last_run"] = datetime.utcnow()
            
            # Execute task handler
            result = await task["handler"]()
            
            task["last_result"] = result
            task["run_count"] += 1
            
            # Check if task should continue
            if task["max_runs"] and task["run_count"] >= task["max_runs"]:
                task["status"] = TaskStatus.COMPLETED
                logger.info(f"Task completed (max runs reached): {task_id}")
            elif task["interval_seconds"]:
                # Schedule next run
                task["next_run"] = datetime.utcnow() + timedelta(seconds=task["interval_seconds"])
                task["status"] = TaskStatus.PENDING
                logger.info(f"Task rescheduled: {task_id} for {task['next_run']}")
            else:
                task["status"] = TaskStatus.COMPLETED
                logger.info(f"Task completed: {task_id}")
                
        except asyncio.CancelledError:
            task["status"] = TaskStatus.CANCELLED
            logger.info(f"Task cancelled during execution: {task_id}")
        except Exception as e:
            task["status"] = TaskStatus.FAILED
            task["last_error"] = str(e)
            logger.error(f"Task failed: {task_id} - {e}")
    
    async def _schedule_default_tasks(self):
        """Schedule default system tasks"""
        try:
            # Air quality data cleanup (daily)
            await self.schedule_task(
                task_id="cleanup_old_data",
                task_handler=self._cleanup_old_data,
                start_time=datetime.utcnow() + timedelta(hours=1),
                interval_seconds=86400,  # 24 hours
                priority=TaskPriority.LOW
            )
            
            # Prediction model retraining (weekly)
            await self.schedule_task(
                task_id="retrain_models",
                task_handler=self._retrain_prediction_models,
                start_time=datetime.utcnow() + timedelta(hours=2),
                interval_seconds=604800,  # 7 days
                priority=TaskPriority.NORMAL
            )
            
            # Sensor status check (every 5 minutes)
            await self.schedule_task(
                task_id="check_sensor_status",
                task_handler=self._check_sensor_status,
                start_time=datetime.utcnow() + timedelta(minutes=5),
                interval_seconds=300,  # 5 minutes
                priority=TaskPriority.HIGH
            )
            
            # Notification cleanup (daily)
            await self.schedule_task(
                task_id="cleanup_notifications",
                task_handler=self._cleanup_notifications,
                start_time=datetime.utcnow() + timedelta(hours=6),
                interval_seconds=86400,  # 24 hours
                priority=TaskPriority.LOW
            )
            
            logger.info("Default tasks scheduled successfully")
            
        except Exception as e:
            logger.error(f"Error scheduling default tasks: {e}")
    
    async def _cleanup_old_data(self) -> Dict[str, Any]:
        """Clean up old air quality data"""
        try:
            from app.models import AirQualityReading
            from app.core.database import AsyncSessionLocal
            
            cutoff_date = datetime.utcnow() - timedelta(days=90)  # Keep 90 days
            
            async with AsyncSessionLocal() as session:
                # This would implement actual database cleanup
                # result = await session.execute(
                #     delete(AirQualityReading).where(AirQualityReading.created_at < cutoff_date)
                # )
                # deleted_count = result.rowcount
                
                deleted_count = 0  # Placeholder
                
            logger.info(f"Cleaned up {deleted_count} old air quality readings")
            return {"deleted_records": deleted_count}
            
        except Exception as e:
            logger.error(f"Error cleaning up old data: {e}")
            return {"error": str(e)}
    
    async def _retrain_prediction_models(self) -> Dict[str, Any]:
        """Retrain prediction models"""
        try:
            from app.services.ml_service import MLService
            
            ml_service = MLService()
            await ml_service.initialize()
            
            # This would implement actual model retraining
            # training_data = await self._collect_training_data()
            # result = await ml_service.retrain_model(training_data)
            
            result = {"status": "initiated"}  # Placeholder
            
            logger.info("Model retraining initiated")
            return result
            
        except Exception as e:
            logger.error(f"Error retraining models: {e}")
            return {"error": str(e)}
    
    async def _check_sensor_status(self) -> Dict[str, Any]:
        """Check sensor device status"""
        try:
            from app.models import SensorDevice
            from app.core.database import AsyncSessionLocal
            
            async with AsyncSessionLocal() as session:
                # Get sensors that haven't reported in a while
                cutoff_time = datetime.utcnow() - timedelta(minutes=10)
                
                # result = await session.execute(
                #     select(SensorDevice).where(
                #         SensorDevice.last_seen < cutoff_time
                #     )
                # )
                # offline_sensors = result.scalars().all()
                
                offline_sensors = []  # Placeholder
                
            # Process offline sensors
            for sensor in offline_sensors:
                # Trigger reconnection attempts
                logger.warning(f"Sensor {sensor.id} appears to be offline")
            
            return {"offline_sensors": len(offline_sensors)}
            
        except Exception as e:
            logger.error(f"Error checking sensor status: {e}")
            return {"error": str(e)}
    
    async def _cleanup_notifications(self) -> Dict[str, Any]:
        """Clean up old notifications"""
        try:
            from app.services.notification_service import NotificationService
            
            notification_service = NotificationService()
            await notification_service.initialize()
            
            # This would clean up old notifications
            # cleaned_count = await notification_service.cleanup_old_notifications(30)
            
            cleaned_count = 0  # Placeholder
            
            return {"cleaned_notifications": cleaned_count}
            
        except Exception as e:
            logger.error(f"Error cleaning up notifications: {e}")
            return {"error": str(e)}
    
    def get_task_status(self, task_id: str) -> Optional[Dict[str, Any]]:
        """Get status of a specific task"""
        if task_id in self.tasks:
            task = self.tasks[task_id].copy()
            # Remove handler to avoid serialization issues
            if "handler" in task:
                del task["handler"]
            return task
        return None
    
    def get_all_tasks(self) -> List[Dict[str, Any]]:
        """Get status of all tasks"""
        tasks = []
        for task_id, task in self.tasks.items():
            task_info = task.copy()
            if "handler" in task_info:
                del task_info["handler"]
            tasks.append(task_info)
        return tasks
    
    async def force_run_task(self, task_id: str) -> bool:
        """Force run a task immediately"""
        try:
            if task_id not in self.tasks:
                return False
            
            task = self.tasks[task_id]
            await self._execute_task(task_id, task)
            return True
            
        except Exception as e:
            logger.error(f"Error forcing task run {task_id}: {e}")
            return False
    
    async def reschedule_task(
        self,
        task_id: str,
        new_start_time: datetime,
        new_interval: Optional[int] = None
    ) -> bool:
        """Reschedule a task"""
        try:
            if task_id not in self.tasks:
                return False
            
            task = self.tasks[task_id]
            task["next_run"] = new_start_time
            if new_interval:
                task["interval_seconds"] = new_interval
            task["status"] = TaskStatus.PENDING
            
            logger.info(f"Task rescheduled: {task_id} for {new_start_time}")
            return True
            
        except Exception as e:
            logger.error(f"Error rescheduling task {task_id}: {e}")
            return False
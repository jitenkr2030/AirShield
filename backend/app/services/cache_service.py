import redis.asyncio as redis
import json
import logging
from typing import Any, Optional, Dict
from datetime import timedelta

from app.core.config import settings

logger = logging.getLogger(__name__)

class CacheService:
    """Redis-based cache service"""
    
    def __init__(self):
        self.redis_client: Optional[redis.Redis] = None
    
    async def initialize(self):
        """Initialize Redis connection"""
        try:
            self.redis_client = redis.from_url(settings.REDIS_URL, encoding="utf-8", decode_responses=True)
            await self.redis_client.ping()
            logger.info("Cache service initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize cache service: {e}")
            # Fallback to in-memory cache
            self.redis_client = None
            self._memory_cache = {}
    
    async def shutdown(self):
        """Shutdown Redis connection"""
        if self.redis_client:
            await self.redis_client.close()
            logger.info("Cache service shutdown complete")
    
    async def get(self, key: str, default: Any = None) -> Any:
        """Get value from cache"""
        try:
            if self.redis_client:
                value = await self.redis_client.get(key)
                if value is None:
                    return default
                return json.loads(value)
            else:
                # Fallback to memory cache
                return self._memory_cache.get(key, default)
        except Exception as e:
            logger.error(f"Cache get error for key {key}: {e}")
            return default
    
    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Set value in cache"""
        try:
            serialized_value = json.dumps(value, default=str)
            
            if self.redis_client:
                if ttl:
                    await self.redis_client.setex(key, ttl, serialized_value)
                else:
                    await self.redis_client.set(key, serialized_value)
                return True
            else:
                # Fallback to memory cache
                self._memory_cache[key] = value
                return True
        except Exception as e:
            logger.error(f"Cache set error for key {key}: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        """Delete key from cache"""
        try:
            if self.redis_client:
                result = await self.redis_client.delete(key)
                return result > 0
            else:
                # Fallback to memory cache
                if key in self._memory_cache:
                    del self._memory_cache[key]
                    return True
                return False
        except Exception as e:
            logger.error(f"Cache delete error for key {key}: {e}")
            return False
    
    async def exists(self, key: str) -> bool:
        """Check if key exists in cache"""
        try:
            if self.redis_client:
                result = await self.redis_client.exists(key)
                return result > 0
            else:
                return key in self._memory_cache
        except Exception as e:
            logger.error(f"Cache exists error for key {key}: {e}")
            return False
    
    async def increment(self, key: str, amount: int = 1) -> Optional[int]:
        """Increment numeric value in cache"""
        try:
            if self.redis_client:
                result = await self.redis_client.incrby(key, amount)
                return result
            else:
                # Fallback to memory cache
                if key not in self._memory_cache:
                    self._memory_cache[key] = 0
                self._memory_cache[key] += amount
                return self._memory_cache[key]
        except Exception as e:
            logger.error(f"Cache increment error for key {key}: {e}")
            return None
    
    async def expire(self, key: str, seconds: int) -> bool:
        """Set expiration time for key"""
        try:
            if self.redis_client:
                result = await self.redis_client.expire(key, seconds)
                return result
            else:
                # Memory cache doesn't support expiration
                return True
        except Exception as e:
            logger.error(f"Cache expire error for key {key}: {e}")
            return False
    
    async def flush_db(self) -> bool:
        """Clear all keys in current database"""
        try:
            if self.redis_client:
                await self.redis_client.flushdb()
                return True
            else:
                # Memory cache
                self._memory_cache.clear()
                return True
        except Exception as e:
            logger.error(f"Cache flush error: {e}")
            return False
    
    async def get_pattern(self, pattern: str) -> list:
        """Get all keys matching pattern"""
        try:
            if self.redis_client:
                keys = await self.redis_client.keys(pattern)
                return keys
            else:
                # Memory cache - simple pattern matching
                import fnmatch
                return [key for key in self._memory_cache.keys() if fnmatch.fnmatch(key, pattern)]
        except Exception as e:
            logger.error(f"Cache pattern error for pattern {pattern}: {e}")
            return []
    
    async def delete_pattern(self, pattern: str) -> int:
        """Delete all keys matching pattern"""
        try:
            if self.redis_client:
                keys = await self.get_pattern(pattern)
                if keys:
                    result = await self.redis_client.delete(*keys)
                    return result
                return 0
            else:
                # Memory cache
                keys_to_delete = await self.get_pattern(pattern)
                for key in keys_to_delete:
                    del self._memory_cache[key]
                return len(keys_to_delete)
        except Exception as e:
            logger.error(f"Cache pattern delete error for pattern {pattern}: {e}")
            return 0
from datetime import datetime, timedelta
from typing import Optional, List
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.config import settings
from app.models import UserProfile
from app.core.database import get_database

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Generate password hash"""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> Optional[dict]:
    """Verify JWT token"""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            return None
        return payload
    except JWTError:
        return None

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_database)
) -> UserProfile:
    """Get current authenticated user"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = verify_token(token)
        if payload is None:
            raise credentials_exception
        
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
            
    except JWTError:
        raise credentials_exception
    
    # Get user from database
    result = await db.execute(select(UserProfile).where(UserProfile.id == user_id))
    user = result.scalar_one_or_none()
    
    if user is None:
        raise credentials_exception
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    return user

async def get_current_active_user(current_user: UserProfile = Depends(get_current_user)) -> UserProfile:
    """Get current active user"""
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

async def get_optional_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_database)
) -> Optional[UserProfile]:
    """Get current user if authenticated, return None otherwise"""
    try:
        payload = verify_token(token)
        if payload is None:
            return None
        
        user_id: str = payload.get("sub")
        if user_id is None:
            return None
            
        result = await db.execute(select(UserProfile).where(UserProfile.id == user_id))
        user = result.scalar_one_or_none()
        
        if user is None or not user.is_active:
            return None
        
        return user
    except Exception:
        return None

def require_subscription(required_tier: str = "free"):
    """Decorator to require specific subscription tier"""
    def subscription_checker(current_user: UserProfile = Depends(get_current_active_user)):
        tier_hierarchy = {"free": 0, "pro": 1, "enterprise": 2}
        user_tier_level = tier_hierarchy.get(current_user.subscription_tier, 0)
        required_tier_level = tier_hierarchy.get(required_tier, 0)
        
        if user_tier_level < required_tier_level:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"This feature requires {required_tier} subscription or higher"
            )
        return current_user
    
    return subscription_checker

def check_rate_limit(user: UserProfile, feature: str) -> bool:
    """Check if user has exceeded rate limits"""
    # Reset daily counters if needed
    now = datetime.utcnow()
    if (now - user.last_query_reset).days >= 1:
        user.daily_queries_count = 0
        user.daily_photos_count = 0
        user.daily_predictions_count = 0
        user.last_query_reset = now
    
    # Check limits based on subscription tier
    if user.subscription_tier == "free":
        limits = settings.FREE_TIER_LIMITS
    else:
        limits = settings.PRO_TIER_LIMITS
    
    # Check specific feature limits
    if feature == "query" and user.daily_queries_count >= limits["daily_queries"]:
        return False
    elif feature == "photo" and user.daily_photos_count >= limits["photo_uploads"]:
        return False
    elif feature == "prediction" and user.daily_predictions_count >= limits["predictions"]:
        return False
    
    return True

def increment_usage_count(user: UserProfile, feature: str):
    """Increment user's usage count"""
    if feature == "query":
        user.daily_queries_count += 1
    elif feature == "photo":
        user.daily_photos_count += 1
    elif feature == "prediction":
        user.daily_predictions_count += 1
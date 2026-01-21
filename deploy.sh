#!/bin/bash

# AIRSHIELD Deployment Script
# This script sets up the complete AIRSHIELD application for development or production

set -e

echo "🚀 Setting up AIRSHIELD - Your Personal Pollution Defense System"
echo "================================================================"

# Check prerequisites
echo "📋 Checking prerequisites..."

command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Aborting." >&2; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose is required but not installed. Aborting." >&2; exit 1; }

echo "✅ Prerequisites check passed"

# Setup environment
echo "🔧 Setting up environment..."

if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cat > .env << EOL
# Database Configuration
DB_PASSWORD=airshield123
DATABASE_URL=postgresql+asyncpg://airshield:airshield123@postgres:5432/airshield_db

# Security
SECRET_KEY=$(openssl rand -hex 32)
JWT_SECRET_KEY=$(openssl rand -hex 32)

# Application Configuration
ENVIRONMENT=development
ALLOWED_HOSTS=*
CORS_ORIGINS=*

# External APIs (Add your API keys)
OPENWEATHER_API_KEY=your_openweather_api_key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
SENTINEL_API_KEY=your_sentinel_api_key

# File Storage
UPLOAD_PATH=./uploads
MAX_FILE_SIZE=10MB

# Monitoring
GRAFANA_PASSWORD=admin123

# Feature Flags
ENABLE_BLUETOOTH_SENSORS=true
ENABLE_PHOTO_ANALYSIS=true
ENABLE_COMMUNITY_FEATURES=true
ENABLE_PUSH_NOTIFICATIONS=true
EOL
    echo "✅ .env file created with default values"
    echo "⚠️  Please update API keys in .env file before production deployment"
else
    echo "✅ .env file already exists"
fi

# Setup database
echo "🗄️ Setting up database..."

if ! docker-compose exec postgres pg_isready -U airshield >/dev/null 2>&1; then
    echo "📊 Starting database..."
    docker-compose up -d postgres redis
    echo "⏳ Waiting for database to be ready..."
    sleep 10
fi

# Backend setup
echo "🔙 Setting up backend..."

if [ -d "./backend" ]; then
    echo "📦 Installing backend dependencies..."
    docker-compose run --rm backend pip install -r requirements.txt
    
    echo "🏗️ Running database migrations..."
    docker-compose run --rm backend python -c "
import asyncio
from app.core.database import engine, Base
from app.models import *

async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print('✅ Database initialized')

asyncio.run(init_db())
"
    echo "✅ Backend setup complete"
else
    echo "⚠️ Backend directory not found, skipping backend setup"
fi

# Build and start services
echo "🏃 Starting services..."

docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."

sleep 15

# Health check
echo "🏥 Performing health checks..."

if curl -f http://localhost:8000/health >/dev/null 2>&1; then
    echo "✅ Backend API is running"
else
    echo "❌ Backend API health check failed"
fi

if docker-compose exec postgres pg_isready -U airshield >/dev/null 2>&1; then
    echo "✅ Database is running"
else
    echo "❌ Database health check failed"
fi

if docker-compose exec redis redis-cli ping >/dev/null 2>&1; then
    echo "✅ Redis is running"
else
    echo "❌ Redis health check failed"
fi

# Mobile app setup
echo "📱 Mobile app setup..."

if [ -d "./mobile_app" ]; then
    echo "📦 Mobile app dependencies installed via Flutter"
    echo "🔧 Configure API endpoint in mobile_app/lib/core/config/app_config.dart"
    echo "   Change baseUrl to 'http://localhost:8000'"
    echo ""
    echo "📲 To run the mobile app:"
    echo "   cd mobile_app"
    echo "   flutter pub get"
    echo "   flutter run"
else
    echo "⚠️ Mobile app directory not found"
fi

# Summary
echo ""
echo "🎉 AIRSHIELD Deployment Complete!"
echo "================================"
echo ""
echo "🌐 Services:"
echo "   • Backend API: http://localhost:8000"
echo "   • API Documentation: http://localhost:8000/docs"
echo "   • Database: localhost:5432 (airshield/airshield123)"
echo "   • Redis: localhost:6379"
echo ""
echo "📱 Next Steps:"
echo "   1. Update API keys in .env file"
echo "   2. Run mobile app: cd mobile_app && flutter run"
echo "   3. Test the application"
echo ""
echo "📊 Monitoring (Optional):"
echo "   • Prometheus: http://localhost:9090"
echo "   • Grafana: http://localhost:3000 (admin/admin123)"
echo ""
echo "🛠️ Useful Commands:"
echo "   • View logs: docker-compose logs -f [service_name]"
echo "   • Stop services: docker-compose down"
echo "   • Restart services: docker-compose restart"
echo "   • Update services: docker-compose up -d --force-recreate"
echo ""
echo "📚 Documentation:"
echo "   • API Docs: http://localhost:8000/docs"
echo "   • Project Guide: ./IMPLEMENTATION_GUIDE.md"
echo ""
echo "🚨 Production Deployment:"
echo "   1. Update .env with production values"
echo "   2. Set up SSL certificates"
echo "   3. Configure domain name"
echo "   4. Enable monitoring profiles"
echo "   5. Run with: docker-compose --profile monitoring up -d"
echo ""
echo "Happy coding! 🌟"
# AIRSHIELD - Your Personal Pollution Defense System

A comprehensive mobile application for air quality monitoring, prediction, and citizen science.

## Project Structure

```
airshield/
├── mobile_app/                 # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/              # Core utilities, themes, constants
│   │   ├── features/          # Feature modules
│   │   │   ├── paqg/          # Personal Air Quality Guardian
│   │   │   ├── prediction/    # Hyperlocal Pollution Prediction
│   │   │   ├── capture/       # Capture the Smog - Citizen Science
│   │   │   ├── map/           # Interactive map components
│   │   │   ├── health/        # Health and exposure tracking
│   │   │   └── community/     # Community features
│   │   ├── models/            # Data models
│   │   ├── services/          # API services, Bluetooth, location
│   │   └── widgets/           # Reusable UI components
│   ├── android/               # Android specific code
│   ├── ios/                   # iOS specific code
│   ├── pubspec.yaml
│   └── build.gradle
├── backend/                   # Python FastAPI backend
│   ├── app/
│   │   ├── api/              # API routes
│   │   ├── core/             # Configuration, database
│   │   ├── models/           # Database models
│   │   ├── services/         # Business logic
│   │   └── ml/               # AI/ML models
│   ├── requirements.txt
│   └── Dockerfile
├── ml_models/                # AI/ML models and training
│   ├── image_analysis/       # CNN for image-to-PM2.5
│   ├── prediction/           # Hyperlocal prediction models
│   ├── health_scoring/       # Personal health scoring
│   └── data_processing/      # Data preprocessing
├── database/                 # Database schemas and migrations
└── docs/                     # Documentation
```

## Features

### 1. Personal Air Quality Guardian (PAQG)
- Real-time air quality monitoring
- Personal health score calculation
- Smart alerts and notifications
- External sensor integration via Bluetooth
- GPS-based location tracking

### 2. Hyperlocal Pollution Prediction
- 12-hour pollution forecasting
- Micro-zone air quality mapping
- Interactive pollution heatmaps
- Traffic and weather integration
- Safe route planning

### 3. Capture the Smog - Citizen Science
- Photo-based pollution estimation
- AI-powered image analysis
- Community pollution mapping
- Gamification and rewards
- Data crowdsourcing

## Tech Stack

### Mobile App
- **Framework**: Flutter
- **State Management**: Provider/Riverpod
- **Maps**: Google Maps/Mapbox
- **Bluetooth**: flutter_blue
- **Camera**: camera package
- **AI/ML**: TensorFlow Lite

### Backend
- **Framework**: FastAPI (Python)
- **Database**: PostgreSQL
- **Cache**: Redis
- **File Storage**: AWS S3/Local Storage
- **Authentication**: JWT
- **API Documentation**: OpenAPI/Swagger

### AI/ML
- **Framework**: TensorFlow/PyTorch
- **Computer Vision**: OpenCV
- **Prediction Models**: LightGBM/XGBoost
- **Image Processing**: PIL/OpenCV
- **Data Processing**: Pandas/NumPy

### Infrastructure
- **Containerization**: Docker
- **API Gateway**: Nginx
- **Monitoring**: Prometheus/Grafana
- **Deployment**: Docker Compose

## Installation

### Mobile App
```bash
cd mobile_app
flutter pub get
flutter run
```

### Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## API Endpoints

### Air Quality Data
- `GET /api/v1/aqi/current` - Current AQI data
- `GET /api/v1/aqi/history/{location}` - Historical data
- `POST /api/v1/aqi/measurements` - Submit sensor data

### Prediction
- `GET /api/v1/prediction/forecast/{location}` - 12-hour forecast
- `GET /api/v1/prediction/microzone/{coords}` - Micro-zone data
- `GET /api/v1/prediction/routes` - Safe route planning

### Image Analysis
- `POST /api/v1/capture/analyze` - Analyze pollution photo
- `GET /api/v1/capture/community` - Community photos
- `POST /api/v1/capture/submit` - Submit photo for mapping

### Health & Alerts
- `GET /api/v1/health/score` - Personal health score
- `POST /api/v1/alerts/subscribe` - Subscribe to alerts
- `GET /api/v1/alerts/active` - Active alerts

## Database Schema

### Core Tables
- `users` - User profiles and preferences
- `measurements` - Air quality measurements
- `predictions` - Pollution predictions
- `photos` - User-submitted photos
- `sensors` - External sensor data
- `health_scores` - Personal health tracking
- `alerts` - Alert management
- `routes` - Safe route recommendations

## AI Models

### 1. Image-to-PM2.5 Estimation
- **Architecture**: ResNet50-based CNN
- **Input**: Sky photos with metadata
- **Output**: PM2.5 concentration estimates
- **Accuracy**: ~85% correlation with ground truth

### 2. Hyperlocal Prediction
- **Model**: Ensemble (XGBoost + LSTM)
- **Features**: Satellite AOD, weather, traffic, ground sensors
- **Output**: 15-minute interval predictions
- **Horizon**: 12 hours ahead

### 3. Personal Health Scoring
- **Model**: Gradient Boosting
- **Features**: Exposure time, PM2.5 levels, age, health profile
- **Output**: 0-100 health score
- **Update**: Real-time based on location and activity

## Business Model

### Free Tier
- Basic AQI monitoring
- Simple alerts
- Photo capture (limited)
- Basic map view

### Pro Tier (₹99/month)
- 12-hour pollution forecast
- Advanced health insights
- Clean route navigation
- Unlimited photo analysis
- Custom alerts
- Export reports

### Hardware Add-on
- Low-cost PM2.5 sensor (₹1200)
- Bluetooth connectivity
- Enhanced accuracy
- App + hardware bundle

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Contact

For support and questions:
- Email: support@airshield.app
- Website: https://airshield.app
- Documentation: https://docs.airshield.app
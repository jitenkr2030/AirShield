class AppConfig {
  static const String appName = 'AIRSHIELD';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'https://api.airshield.app';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Google Maps
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // Firebase Configuration
  static const String firebaseProjectId = 'airshield-app';
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';
  
  // AI/ML Model Paths
  static const String imageAnalysisModelPath = 'assets/ml_models/image_to_pm25.tflite';
  static const String predictionModelPath = 'assets/ml_models/pollution_predictor.tflite';
  static const String healthScoreModelPath = 'assets/ml_models/health_scorer.tflite';
  
  // Feature Flags
  static const bool enableBluetoothSensors = true;
  static const bool enablePhotoAnalysis = true;
  static const bool enableCommunityFeatures = true;
  static const bool enablePushNotifications = true;
  
  // Update Intervals
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  static const Duration sensorUpdateInterval = Duration(seconds: 10);
  static const Duration predictionUpdateInterval = Duration(minutes: 15);
  static const Duration healthScoreUpdateInterval = Duration(minutes: 5);
  
  // AQI Thresholds
  static const Map<String, int> aqiThresholds = {
    'good': 50,
    'moderate': 100,
    'unhealthy_sensitive': 150,
    'unhealthy': 200,
    'very_unhealthy': 300,
    'hazardous': 500,
  };
  
  // Default Settings
  static const Map<String, dynamic> defaultSettings = {
    'notifications_enabled': true,
    'location_tracking': true,
    'bluetooth_sensors': true,
    'photo_privacy': 'public',
    'units': 'metric',
    'language': 'en',
    'theme': 'system',
    'alerts_threshold': 150,
    'auto_route_planning': false,
    'data_sharing': true,
  };
  
  static late SharedPreferences _prefs;
  static SharedPreferences get prefs => _prefs;
  
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Set default values if not already set
    for (final entry in defaultSettings.entries) {
      if (!_prefs.containsKey(entry.key)) {
        await _prefs.setString(entry.key, entry.value.toString());
      }
    }
  }
  
  static String getSetting(String key, [String? defaultValue]) {
    return _prefs.getString(key) ?? defaultValue ?? '';
  }
  
  static bool getBoolSetting(String key, [bool defaultValue = false]) {
    final value = _prefs.getString(key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }
  
  static int getIntSetting(String key, [int defaultValue = 0]) {
    return _prefs.getInt(key) ?? defaultValue;
  }
  
  static double getDoubleSetting(String key, [double defaultValue = 0.0]) {
    return _prefs.getDouble(key) ?? defaultValue;
  }
  
  static Future<void> setSetting(String key, dynamic value) async {
    if (value is bool) {
      await _prefs.setString(key, value.toString());
    } else {
      await _prefs.setString(key, value.toString());
    }
  }
  
  // API URLs
  static String get aqiCurrentUrl => '$baseUrl/api/$apiVersion/aqi/current';
  static String get aqiHistoryUrl => '$baseUrl/api/$apiVersion/aqi/history';
  static String get predictionForecastUrl => '$baseUrl/api/$apiVersion/prediction/forecast';
  static String get predictionMicrozoneUrl => '$baseUrl/api/$apiVersion/prediction/microzone';
  static String get captureAnalyzeUrl => '$baseUrl/api/$apiVersion/capture/analyze';
  static String get healthScoreUrl => '$baseUrl/api/$apiVersion/health/score';
  static String get communityUrl => '$baseUrl/api/$apiVersion/community';
  static String get alertsUrl => '$baseUrl/api/$apiVersion/alerts';
}
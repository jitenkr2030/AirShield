part of 'prediction_bloc.dart';

abstract class PredictionState extends Equatable {
  const PredictionState();

  @override
  List<Object> get props => [];
}

class PredictionInitial extends PredictionState {}

class PredictionLoading extends PredictionState {}

class PredictionLoaded extends PredictionState {
  final Position currentLocation;
  final List<PredictionData> predictions;
  final MicroZoneForecast? microZoneData;
  final AirQualityData currentAQIData;
  final List<SafeRoute> safeRoutes;
  final List<AirQualityData> historicalData;
  final bool isRealTimeEnabled;
  final DateTime lastUpdateTime;
  final Duration updateInterval;
  final double predictionRadius;
  final Map<String, dynamic> predictionSettings;
  final bool isLoadingMicroZone;
  final bool isCalculatingRoutes;
  final bool isLoadingHistorical;
  final bool isExporting;
  final bool exportSuccess;
  final String? error;
  final String? selectedPredictionType;
  final double confidenceThreshold;
  final int predictionHorizon;
  
  const PredictionLoaded({
    required this.currentLocation,
    required this.predictions,
    this.microZoneData,
    required this.currentAQIData,
    this.safeRoutes = const [],
    this.historicalData = const [],
    this.isRealTimeEnabled = false,
    this.lastUpdateTime = const DateTime.fromMillisecondsSinceEpoch(0),
    this.updateInterval = const Duration(minutes: 15),
    this.predictionRadius = 2.0,
    this.predictionSettings = const {
      'confidence_threshold': 0.7,
      'include_weather': true,
      'include_traffic': true,
      'include_satellite': true,
    },
    this.isLoadingMicroZone = false,
    this.isCalculatingRoutes = false,
    this.isLoadingHistorical = false,
    this.isExporting = false,
    this.exportSuccess = false,
    this.error,
    this.selectedPredictionType,
    this.confidenceThreshold = 0.7,
    this.predictionHorizon = 12,
  });
  
  @override
  List<Object> get props => [
    currentLocation,
    predictions,
    microZoneData ?? '',
    currentAQIData,
    safeRoutes,
    historicalData,
    isRealTimeEnabled,
    lastUpdateTime,
    updateInterval,
    predictionRadius,
    predictionSettings,
    isLoadingMicroZone,
    isCalculatingRoutes,
    isLoadingHistorical,
    isExporting,
    exportSuccess,
    error ?? '',
    selectedPredictionType ?? '',
    confidenceThreshold,
    predictionHorizon,
  ];
  
  PredictionLoaded copyWith({
    Position? currentLocation,
    List<PredictionData>? predictions,
    MicroZoneForecast? microZoneData,
    AirQualityData? currentAQIData,
    List<SafeRoute>? safeRoutes,
    List<AirQualityData>? historicalData,
    bool? isRealTimeEnabled,
    DateTime? lastUpdateTime,
    Duration? updateInterval,
    double? predictionRadius,
    Map<String, dynamic>? predictionSettings,
    bool? isLoadingMicroZone,
    bool? isCalculatingRoutes,
    bool? isLoadingHistorical,
    bool? isExporting,
    bool? exportSuccess,
    String? error,
    String? selectedPredictionType,
    double? confidenceThreshold,
    int? predictionHorizon,
  }) {
    return PredictionLoaded(
      currentLocation: currentLocation ?? this.currentLocation,
      predictions: predictions ?? this.predictions,
      microZoneData: microZoneData ?? this.microZoneData,
      currentAQIData: currentAQIData ?? this.currentAQIData,
      safeRoutes: safeRoutes ?? this.safeRoutes,
      historicalData: historicalData ?? this.historicalData,
      isRealTimeEnabled: isRealTimeEnabled ?? this.isRealTimeEnabled,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      updateInterval: updateInterval ?? this.updateInterval,
      predictionRadius: predictionRadius ?? this.predictionRadius,
      predictionSettings: predictionSettings ?? this.predictionSettings,
      isLoadingMicroZone: isLoadingMicroZone ?? this.isLoadingMicroZone,
      isCalculatingRoutes: isCalculatingRoutes ?? this.isCalculatingRoutes,
      isLoadingHistorical: isLoadingHistorical ?? this.isLoadingHistorical,
      isExporting: isExporting ?? this.isExporting,
      exportSuccess: exportSuccess ?? this.exportSuccess,
      error: error,
      selectedPredictionType: selectedPredictionType ?? this.selectedPredictionType,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      predictionHorizon: predictionHorizon ?? this.predictionHorizon,
    );
  }
  
  // Helper methods
  PredictionData? get currentPrediction {
    if (predictions.isEmpty) return null;
    return predictions.first;
  }
  
  List<PredictionData> get nextHourPredictions {
    final now = DateTime.now();
    return predictions
        .where((p) => p.predictionTime.isAfter(now) && 
                    p.predictionTime.isBefore(now.add(const Duration(hours: 1))))
        .toList();
  }
  
  List<PredictionData> get nextThreeHourPredictions {
    final now = DateTime.now();
    return predictions
        .where((p) => p.predictionTime.isAfter(now) && 
                    p.predictionTime.isBefore(now.add(const Duration(hours: 3))))
        .toList();
  }
  
  String get locationString {
    return '${currentLocation.latitude.toStringAsFixed(4)}, ${currentLocation.longitude.toStringAsFixed(4)}';
  }
  
  double get averagePredictedAQI {
    if (predictions.isEmpty) return 0;
    return predictions
        .map((p) => p.predictedAQI)
        .reduce((a, b) => a + b) / predictions.length;
  }
  
  double get maxPredictedAQI {
    if (predictions.isEmpty) return 0;
    return predictions.map((p) => p.predictedAQI).reduce((a, b) => a > b ? a : b);
  }
  
  String get predictionTrend {
    if (predictions.length < 2) return 'Unknown';
    
    final currentAQIAverage = predictions
        .take(3)
        .map((p) => p.predictedAQI)
        .reduce((a, b) => a + b) / 3;
    
    final futureAQIAverage = predictions
        .skip(3)
        .take(3)
        .map((p) => p.predictedAQI)
        .reduce((a, b) => a + b) / 3;
    
    final difference = futureAQIAverage - currentAQIAverage;
    
    if (difference > 10) return 'Worsening';
    if (difference < -10) return 'Improving';
    return 'Stable';
  }
  
  bool get hasHighPollutionPrediction {
    return predictions.any((p) => p.predictedAQI > 150);
  }
  
  List<SafeRoute> get bestRoutes {
    return safeRoutes
        .where((route) => route.safetyScore >= 70)
        .toList()
        ..sort((a, b) => b.safetyScore.compareTo(a.safetyScore));
  }
  
  String get lastUpdateString {
    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
  
  bool get isDataStale {
    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime);
    return difference.inMinutes > 30; // Consider stale after 30 minutes
  }
}

class PredictionError extends PredictionState {
  final String message;
  final String? details;
  
  const PredictionError(this.message, {this.details});
  
  @override
  List<Object> get props => [message, details ?? ''];
}

class PredictionNoData extends PredictionState {
  final String reason;
  
  const PredictionNoData(this.reason);
  
  @override
  List<Object> get props => [reason];
}

class PredictionServiceUnavailable extends PredictionState {
  final DateTime? estimatedRecovery;
  final String message;
  
  const PredictionServiceUnavailable({
    this.estimatedRecovery,
    this.message = 'Prediction service is temporarily unavailable',
  });
  
  @override
  List<Object> get props => [estimatedRecovery ?? DateTime(0), message];
}
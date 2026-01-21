part of 'paqg_bloc.dart';

abstract class PAQGState extends Equatable {
  const PAQGState();

  @override
  List<Object> get props => [];
}

class PAQGInitial extends PAQGState {}

class PAQGLoading extends PAQGState {}

class PAQGLoaded extends PAQGState {
  final Position currentLocation;
  final AirQualityData airQualityData;
  final double healthScore;
  final bool isTracking;
  final bool isSensorConnected;
  final BluetoothDevice? connectedSensor;
  final bool isLoading;
  final String? error;
  final Duration monitoringInterval;
  final List<AirQualityData> recentMeasurements;
  final Map<String, double> alertSettings;
  final bool isMonitoring;
  final DateTime lastUpdate;
  final String currentStatus;
  
  const PAQGLoaded({
    required this.currentLocation,
    required this.airQualityData,
    required this.healthScore,
    required this.isTracking,
    required this.connectedSensor,
    this.isSensorConnected = false,
    this.isLoading = false,
    this.error,
    this.monitoringInterval = const Duration(seconds: 30),
    this.recentMeasurements = const [],
    this.alertSettings = const {
      'aqi_threshold': 150.0,
      'push_notifications': true,
      'sound_alerts': true,
      'vibration': true,
    },
    this.isMonitoring = false,
    this.lastUpdate = const DateTime.fromMillisecondsSinceEpoch(0),
    this.currentStatus = 'active',
  });
  
  @override
  List<Object> get props => [
    currentLocation,
    airQualityData,
    healthScore,
    isTracking,
    connectedSensor ?? '',
    isSensorConnected,
    isLoading,
    error ?? '',
    monitoringInterval,
    recentMeasurements,
    alertSettings,
    isMonitoring,
    lastUpdate,
    currentStatus,
  ];
  
  PAQGLoaded copyWith({
    Position? currentLocation,
    AirQualityData? airQualityData,
    double? healthScore,
    bool? isTracking,
    BluetoothDevice? connectedSensor,
    bool? isSensorConnected,
    bool? isLoading,
    String? error,
    Duration? monitoringInterval,
    List<AirQualityData>? recentMeasurements,
    Map<String, double>? alertSettings,
    bool? isMonitoring,
    DateTime? lastUpdate,
    String? currentStatus,
    bool? isConnectingSensor,
  }) {
    return PAQGLoaded(
      currentLocation: currentLocation ?? this.currentLocation,
      airQualityData: airQualityData ?? this.airQualityData,
      healthScore: healthScore ?? this.healthScore,
      isTracking: isTracking ?? this.isTracking,
      connectedSensor: connectedSensor ?? this.connectedSensor,
      isSensorConnected: isSensorConnected ?? this.isSensorConnected,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      monitoringInterval: monitoringInterval ?? this.monitoringInterval,
      recentMeasurements: recentMeasurements ?? this.recentMeasurements,
      alertSettings: alertSettings ?? this.alertSettings,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }
  
  // Helper methods
  bool get hasValidLocation => currentLocation.latitude != 0 && currentLocation.longitude != 0;
  
  String get locationString {
    if (hasValidLocation) {
      return '${currentLocation.latitude.toStringAsFixed(4)}, ${currentLocation.longitude.toStringAsFixed(4)}';
    }
    return 'Unknown Location';
  }
  
  String get healthScoreCategory {
    if (healthScore >= 90) return 'Excellent';
    if (healthScore >= 80) return 'Good';
    if (healthScore >= 70) return 'Fair';
    if (healthScore >= 60) return 'Poor';
    return 'Very Poor';
  }
  
  String get aqiCategory {
    final aqi = airQualityData.aqi;
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }
  
  Color get aqiColor {
    final aqi = airQualityData.aqi;
    if (aqi <= 50) return const Color(0xFF28A745);
    if (aqi <= 100) return const Color(0xFFFFC107);
    if (aqi <= 150) return const Color(0xFFFF9800);
    if (aqi <= 200) return const Color(0xFFFF5722);
    if (aqi <= 300) return const Color(0xFF9C27B0);
    return const Color(0xFFDC3545);
  }
  
  Color get healthScoreColor {
    if (healthScore >= 90) return const Color(0xFF28A745);
    if (healthScore >= 80) return const Color(0xFF90EE90);
    if (healthScore >= 70) return const Color(0xFFFFC107);
    if (healthScore >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFDC3545);
  }
  
  bool get hasAlerts {
    return airQualityData.aqi > alertSettings['aqi_threshold']!;
  }
  
  String get lastUpdateString {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
  
  bool get isDataStale {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference.inMinutes > 5; // Consider stale after 5 minutes
  }
  
  double get exposureTimeMinutes {
    if (recentMeasurements.isEmpty) return 0;
    return recentMeasurements.length * (monitoringInterval.inMinutes);
  }
}

class PAQGError extends PAQGState {
  final String message;
  final String? details;
  
  const PAQGError(this.message, {this.details});
  
  @override
  List<Object> get props => [message, details ?? ''];
}

class PAQGDisconnected extends PAQGState {
  final String message;
  
  const PAQGDisconnected(this.message);
  
  @override
  List<Object> get props => [message];
}

class PAQGCalibrated extends PAQGState {
  final double referenceValue;
  
  const PAQGCalibrated(this.referenceValue);
  
  @override
  List<Object> get props => [referenceValue];
}

class PAQGSensorConnected extends PAQGState {
  final BluetoothDevice device;
  final BatteryLevel batteryLevel;
  
  const PAQGSensorConnected({
    required this.device,
    required this.batteryLevel,
  });
  
  @override
  List<Object> get props => [device, batteryLevel];
}

class PAQGSensorDisconnected extends PAQGState {
  final String deviceName;
  final String reason;
  
  const PAQGSensorDisconnected({
    required this.deviceName,
    required this.reason,
  });
  
  @override
  List<Object> get props => [deviceName, reason];
}

class PAQGAlert extends PAQGState {
  final String title;
  final String message;
  final String type; // 'warning', 'critical', 'info'
  final double aqiValue;
  final String location;
  final DateTime timestamp;
  
  const PAQGAlert({
    required this.title,
    required this.message,
    required this.type,
    required this.aqiValue,
    required this.location,
    required this.timestamp,
  });
  
  @override
  List<Object> get props => [
    title,
    message,
    type,
    aqiValue,
    location,
    timestamp,
  ];
  
  bool get isCritical => type == 'critical';
  bool get isWarning => type == 'warning';
  bool get isInfo => type == 'info';
}

class PAQGPermissionDenied extends PAQGState {
  final List<String> permissions;
  final String message;
  
  const PAQGPermissionDenied({
    required this.permissions,
    required this.message,
  });
  
  @override
  List<Object> get props => [permissions, message];
}

class PAQGMaintenanceMode extends PAQGState {
  final String reason;
  final DateTime? estimatedCompletion;
  final List<String> affectedServices;
  
  const PAQGMaintenanceMode({
    required this.reason,
    this.estimatedCompletion,
    this.affectedServices = const [],
  });
  
  @override
  List<Object> get props => [
    reason,
    estimatedCompletion ?? '',
    affectedServices,
  ];
}

class PAQGDataSync extends PAQGState {
  final List<AirQualityData> pendingData;
  final int totalCount;
  final int syncedCount;
  final double progress;
  
  const PAQGDataSync({
    required this.pendingData,
    required this.totalCount,
    required this.syncedCount,
    required this.progress,
  });
  
  @override
  List<Object> get props => [
    pendingData,
    totalCount,
    syncedCount,
    progress,
  ];
  
  bool get isComplete => syncedCount >= totalCount;
  bool get hasData => pendingData.isNotEmpty;
}
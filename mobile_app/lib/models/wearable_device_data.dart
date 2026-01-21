import 'package:json_annotation/json_annotation.dart';

part 'wearable_device_data.g.dart';

@JsonSerializable()
class WearableDevice {
  final String deviceId;
  final String name;
  final DeviceType type;
  final DevicePlatform platform;
  final String manufacturer;
  final String model;
  final String firmwareVersion;
  final bool isConnected;
  final DateTime? lastSyncTime;
  final List<DeviceCapability> capabilities;
  final DeviceStatus status;
  final String? pairingCode;

  const WearableDevice({
    required this.deviceId,
    required this.name,
    required this.type,
    required this.platform,
    required this.manufacturer,
    required this.model,
    required this.firmwareVersion,
    this.isConnected = false,
    this.lastSyncTime,
    required this.capabilities,
    this.status = DeviceStatus.disconnected,
    this.pairingCode,
  });

  factory WearableDevice.fromJson(Map<String, dynamic> json) =>
      _$WearableDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$WearableDeviceToJson(this);
}

enum DeviceType {
  @JsonValue('smartwatch')
  smartwatch,
  @JsonValue('fitness_tracker')
  fitnessTracker,
  @JsonValue('smart_band')
  smartBand,
  @JsonValue('heart_rate_monitor')
  heartRateMonitor,
  @JsonValue('health_monitor')
  healthMonitor,
  @JsonValue('air_quality_sensor')
  airQualitySensor,
}

enum DevicePlatform {
  @JsonValue('apple_watch')
  appleWatch,
  @JsonValue('android_wear')
  androidWear,
  @JsonValue('fitbit')
  fitbit,
  @JsonValue('garmin')
  garmin,
  @JsonValue('samsung_watch')
  samsungWatch,
  @JsonValue('huawei_watch')
  huaweiWatch,
  @JsonValue('other')
  other,
}

enum DeviceStatus {
  @JsonValue('connected')
  connected,
  @JsonValue('connecting')
  connecting,
  @JsonValue('disconnected')
  disconnected,
  @JsonValue('pairing_required')
  pairingRequired,
  @JsonValue('low_battery')
  lowBattery,
  @JsonValue('error')
  error,
}

enum DeviceCapability {
  @JsonValue('heart_rate')
  heartRate,
  @JsonValue('steps')
  steps,
  @JsonValue('sleep_tracking')
  sleepTracking,
  @JsonValue('notifications')
  notifications,
  @JsonValue('weather')
  weather,
  @JsonValue('location')
  location,
  @JsonValue('stress_level')
  stressLevel,
  @JsonValue('breathing_rate')
  breathingRate,
  @JsonValue('blood_oxygen')
  bloodOxygen,
  @JsonValue('air_quality')
  airQuality,
  @JsonValue('gps_tracking')
  gpsTracking,
  @JsonValue('voice_assistant')
  voiceAssistant,
}

@JsonSerializable()
class DeviceData {
  final String deviceId;
  final DateTime timestamp;
  final Map<String, dynamic> rawData;
  final ProcessedMetrics? processedMetrics;
  final List<Alert> alerts;
  final QualityScore dataQuality;

  const DeviceData({
    required this.deviceId,
    required this.timestamp,
    required this.rawData,
    this.processedMetrics,
    this.alerts = const [],
    this.dataQuality = QualityScore.good,
  });

  factory DeviceData.fromJson(Map<String, dynamic> json) =>
      _$DeviceDataFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceDataToJson(this);
}

@JsonSerializable()
class ProcessedMetrics {
  final double? heartRate;
  final int? steps;
  final double? distance; // in meters
  final double? calories;
  final double? breathingRate;
  final double? stressLevel;
  final double? bloodOxygen; // percentage
  final double? airQualityExposure;
  final int? sleepMinutes;
  final int? activeMinutes;
  final double? temperature; // body temperature
  final Map<String, double> locationData;

  const ProcessedMetrics({
    this.heartRate,
    this.steps,
    this.distance,
    this.calories,
    this.breathingRate,
    this.stressLevel,
    this.bloodOxygen,
    this.airQualityExposure,
    this.sleepMinutes,
    this.activeMinutes,
    this.temperature,
    this.locationData = const {},
  });

  factory ProcessedMetrics.fromJson(Map<String, dynamic> json) =>
      _$ProcessedMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$ProcessedMetricsToJson(this);
}

enum QualityScore {
  @JsonValue('excellent')
  excellent,
  @JsonValue('good')
  good,
  @JsonValue('fair')
  fair,
  @JsonValue('poor')
  poor,
}

@JsonSerializable()
class HealthCorrelation {
  final String correlationId;
  final DateTime timestamp;
  final double airQualityIndex;
  final double heartRateChange; // percentage change from baseline
  final double stressChange; // percentage change from baseline
  final double breathingRateChange; // percentage change from baseline
  final List<String> symptoms;
  final List<String> contributingFactors;
  final String analysis;

  const HealthCorrelation({
    required this.correlationId,
    required this.timestamp,
    required this.airQualityIndex,
    required this.heartRateChange,
    required this.stressChange,
    required this.breathingRateChange,
    this.symptoms = const [],
    this.contributingFactors = const [],
    required this.analysis,
  });

  factory HealthCorrelation.fromJson(Map<String, dynamic> json) =>
      _$HealthCorrelationFromJson(json);

  Map<String, dynamic> toJson() => _$HealthCorrelationToJson(this);
}

@JsonSerializable()
class Alert {
  final String alertId;
  final AlertType type;
  final String title;
  final String message;
  final Priority priority;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final bool isRead;
  final List<String> actions;
  final String? source;

  const Alert({
    required this.alertId,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    required this.timestamp,
    this.expiresAt,
    this.isRead = false,
    this.actions = const [],
    this.source,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);

  Map<String, dynamic> toJson() => _$AlertToJson(this);
}

enum AlertType {
  @JsonValue('air_quality')
  airQuality,
  @JsonValue('health_metric')
  healthMetric,
  @JsonValue('device_status')
  deviceStatus,
  @JsonValue('emergency')
  emergency,
  @JsonValue('reminder')
  reminder,
  @JsonValue('achievement')
  achievement,
}

@JsonSerializable()
class WearableSettings {
  final String deviceId;
  final bool enableRealTimeSync;
  final bool enableNotifications;
  final bool enableHealthAlerts;
  final List<AlertType> notificationTypes;
  final bool enableDataExport;
  final bool enableVibration;
  final double syncInterval; // in minutes
  final Map<String, dynamic> customSettings;

  const WearableSettings({
    required this.deviceId,
    this.enableRealTimeSync = true,
    this.enableNotifications = true,
    this.enableHealthAlerts = true,
    this.notificationTypes = const [],
    this.enableDataExport = false,
    this.enableVibration = true,
    this.syncInterval = 5.0,
    this.customSettings = const {},
  });

  factory WearableSettings.fromJson(Map<String, dynamic> json) =>
      _$WearableSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$WearableSettingsToJson(this);
}

@JsonSerializable()
class SyncSchedule {
  final String scheduleId;
  final String deviceId;
  final DateTime lastSync;
  final DateTime nextSync;
  final int syncFrequency; // in minutes
  final bool isActive;
  final List<String> dataTypes;
  final String? syncError;

  const SyncSchedule({
    required this.scheduleId,
    required this.deviceId,
    required this.lastSync,
    required this.nextSync,
    required this.syncFrequency,
    this.isActive = true,
    this.dataTypes = const [],
    this.syncError,
  });

  factory SyncSchedule.fromJson(Map<String, dynamic> json) =>
      _$SyncScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$SyncScheduleToJson(this);
}

@JsonSerializable()
class DeviceIntegration {
  final String integrationId;
  final String deviceId;
  final IntegrationType type;
  final Map<String, dynamic> configuration;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastUsed;

  const DeviceIntegration({
    required this.integrationId,
    required this.deviceId,
    required this.type,
    required this.configuration,
    this.isActive = true,
    required this.createdAt,
    this.lastUsed,
  });

  factory DeviceIntegration.fromJson(Map<String, dynamic> json) =>
      _$DeviceIntegrationFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceIntegrationToJson(this);
}

enum IntegrationType {
  @JsonValue('air_quality_correlation')
  airQualityCorrelation,
  @JsonValue('health_monitoring')
  healthMonitoring,
  @JsonValue('activity_tracking')
  activityTracking,
  @JsonValue('emergency_response')
  emergencyResponse,
  @JsonValue('lifestyle_recommendations')
  lifestyleRecommendations,
}

@JsonSerializable()
class WearableAnalytics {
  final String analyticsId;
  final String deviceId;
  final DateTime period;
  final HealthTrend healthTrend;
  final AirQualityImpact airQualityImpact;
  final List<Recommendation> recommendations;
  final Map<String, double> metricsSummary;

  const WearableAnalytics({
    required this.analyticsId,
    required this.deviceId,
    required this.period,
    required this.healthTrend,
    required this.airQualityImpact,
    this.recommendations = const [],
    this.metricsSummary = const {},
  });

  factory WearableAnalytics.fromJson(Map<String, dynamic> json) =>
      _$WearableAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$WearableAnalyticsToJson(this);
}

@JsonSerializable()
class HealthTrend {
  final TrendDirection overall;
  final double improvementScore; // 0-100
  final List<TrendMetric> metrics;

  const HealthTrend({
    required this.overall,
    required this.improvementScore,
    this.metrics = const [],
  });

  factory HealthTrend.fromJson(Map<String, dynamic> json) =>
      _$HealthTrendFromJson(json);

  Map<String, dynamic> toJson() => _$HealthTrendToJson(this);
}

enum TrendDirection {
  @JsonValue('improving')
  improving,
  @JsonValue('stable')
  stable,
  @JsonValue('declining')
  declining,
  @JsonValue('unknown')
  unknown,
}

@JsonSerializable()
class TrendMetric {
  final String metricName;
  final TrendDirection direction;
  final double changePercentage;
  final String description;

  const TrendMetric({
    required this.metricName,
    required this.direction,
    required this.changePercentage,
    required this.description,
  });

  factory TrendMetric.fromJson(Map<String, dynamic> json) =>
      _$TrendMetricFromJson(json);

  Map<String, dynamic> toJson() => _$TrendMetricToJson(this);
}

@JsonSerializable()
class AirQualityImpact {
  final double exposureScore; // total exposure
  final ImpactLevel impactLevel;
  final List<String> affectedMetrics;
  final List<String> mitigationActions;

  const AirQualityImpact({
    required this.exposureScore,
    required this.impactLevel,
    this.affectedMetrics = const [],
    this.mitigationActions = const [],
  });

  factory AirQualityImpact.fromJson(Map<String, dynamic> json) =>
      _$AirQualityImpactFromJson(json);

  Map<String, dynamic> toJson() => _$AirQualityImpactToJson(this);
}

enum ImpactLevel {
  @JsonValue('minimal')
  minimal,
  @JsonValue('low')
  low,
  @JsonValue('moderate')
  moderate,
  @JsonValue('high')
  high,
  @JsonValue('severe')
  severe,
}

@JsonSerializable()
class Recommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationCategory category;
  final Priority priority;
  final List<String> actions;
  final String? reasoning;

  const Recommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.actions = const [],
    this.reasoning,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) =>
      _$RecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationToJson(this);
}

enum RecommendationCategory {
  @JsonValue('lifestyle')
  lifestyle,
  @JsonValue('health')
  health,
  @JsonValue('environmental')
  environmental,
  @JsonValue('activity')
  activity,
  @JsonValue('medical')
  medical,
}
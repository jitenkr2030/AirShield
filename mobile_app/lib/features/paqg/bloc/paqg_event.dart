part of 'paqg_bloc.dart';

abstract class PAQGEvent extends Equatable {
  const PAQGEvent();

  @override
  List<Object> get props => [];
}

class InitializePAQG extends PAQGEvent {}

class LoadCurrentAQIData extends PAQGEvent {
  final double? latitude;
  final double? longitude;
  
  const LoadCurrentAQIData({
    this.latitude,
    this.longitude,
  });
  
  @override
  List<Object> get props => [latitude ?? 0, longitude ?? 0];
}

class StartLocationTracking extends PAQGEvent {
  final LocationAccuracy accuracy;
  final Duration distanceFilter;
  final Duration timeFilter;
  
  const StartLocationTracking({
    this.accuracy = LocationAccuracy.high,
    this.distanceFilter = const Duration(seconds: 30),
    this.timeFilter = const Duration(seconds: 30),
  });
  
  @override
  List<Object> get props => [accuracy, distanceFilter, timeFilter];
}

class StopLocationTracking extends PAQGEvent {}

class UpdateLocation extends PAQGEvent {
  final Position position;
  
  const UpdateLocation(this.position);
  
  @override
  List<Object> get props => [position];
}

class UpdateAirQualityData extends PAQGEvent {
  final AirQualityData airQualityData;
  
  const UpdateAirQualityData(this.airQualityData);
  
  @override
  List<Object> get props => [airQualityData];
}

class ConnectSensor extends PAQGEvent {
  final Duration timeout;
  
  const ConnectSensor({
    this.timeout = const Duration(seconds: 15),
  });
  
  @override
  List<Object> get props => [timeout];
}

class DisconnectSensor extends PAQGEvent {}

class SensorDataReceived extends PAQGEvent {
  final AirQualityData data;
  
  const SensorDataReceived(this.data);
  
  @override
  List<Object> get props => [data];
}

class UpdateHealthScore extends PAQGEvent {
  final List<AirQualityData> exposureHistory;
  final Map<String, dynamic>? userProfile;
  final List<double>? heartRateData;
  
  const UpdateHealthScore({
    required this.exposureHistory,
    this.userProfile,
    this.heartRateData,
  });
  
  @override
  List<Object> get props => [
    exposureHistory,
    userProfile ?? const {},
    heartRateData ?? const [],
  ];
}

class SubmitSensorData extends PAQGEvent {
  final AirQualityData data;
  
  const SubmitSensorData(this.data);
  
  @override
  List<Object> get props => [data];
}

class RefreshData extends PAQGEvent {
  final bool forceRefresh;
  
  const RefreshData({
    this.forceRefresh = false,
  });
  
  @override
  List<Object> get props => [forceRefresh];
}

class SetSensorThreshold extends PAQGEvent {
  final double threshold;
  
  const SetSensorThreshold(this.threshold);
  
  @override
  List<Object> get props => [threshold];
}

class CalibrateSensor extends PAQGEvent {
  final double referenceValue;
  
  const CalibrateSensor(this.referenceValue);
  
  @override
  List<Object> get props => [referenceValue];
}

class RequestPermissions extends PAQGEvent {}

class PermissionGranted extends PAQGEvent {}

class PermissionDenied extends PAQGEvent {
  final String message;
  
  const PermissionDenied(this.message);
  
  @override
  List<Object> get props => [message];
}

class SetMonitoringInterval extends PAQGEvent {
  final Duration interval;
  
  const SetMonitoringInterval(this.interval);
  
  @override
  List<Object> get props => [interval];
}

class SetAlertSettings extends PAQGEvent {
  final double aqiThreshold;
  final bool enablePushNotifications;
  final bool enableSoundAlerts;
  final bool enableVibration;
  
  const SetAlertSettings({
    required this.aqiThreshold,
    required this.enablePushNotifications,
    required this.enableSoundAlerts,
    required this.enableVibration,
  });
  
  @override
  List<Object> get props => [
    aqiThreshold,
    enablePushNotifications,
    enableSoundAlerts,
    enableVibration,
  ];
}
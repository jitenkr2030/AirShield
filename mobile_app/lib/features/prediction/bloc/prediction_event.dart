part of 'prediction_bloc.dart';

abstract class PredictionEvent extends Equatable {
  const PredictionEvent();

  @override
  List<Object> get props => [];
}

class LoadPredictions extends PredictionEvent {
  final double? latitude;
  final double? longitude;
  final int hours;
  final bool enableRealTime;
  
  const LoadPredictions({
    this.latitude,
    this.longitude,
    this.hours = 12,
    this.enableRealTime = false,
  });
  
  @override
  List<Object> get props => [
    latitude ?? 0,
    longitude ?? 0,
    hours,
    enableRealTime,
  ];
}

class UpdateLocation extends PredictionEvent {
  final Position position;
  
  const UpdateLocation(this.position);
  
  @override
  List<Object> get props => [position];
}

class LoadMicroZoneForecast extends PredictionEvent {
  final double latitude;
  final double longitude;
  final double radius;
  
  const LoadMicroZoneForecast({
    required this.latitude,
    required this.longitude,
    this.radius = 2.0,
  });
  
  @override
  List<Object> get props => [latitude, longitude, radius];
}

class CalculateSafeRoutes extends PredictionEvent {
  final String from;
  final String to;
  final String routeType;
  final int alternatives;
  
  const CalculateSafeRoutes({
    required this.from,
    required this.to,
    this.routeType = 'walking',
    this.alternatives = 3,
  });
  
  @override
  List<Object> get props => [from, to, routeType, alternatives];
}

class RefreshPredictions extends PredictionEvent {
  final bool forceRefresh;
  
  const RefreshPredictions({
    this.forceRefresh = false,
  });
  
  @override
  List<Object> get props => [forceRefresh];
}

class UpdatePredictionSettings extends PredictionEvent {
  final Map<String, dynamic> settings;
  
  const UpdatePredictionSettings(this.settings);
  
  @override
  List<Object> get props => [settings];
}

class SetPredictionRadius extends PredictionEvent {
  final double radius;
  
  const SetPredictionRadius(this.radius);
  
  @override
  List<Object> get props => [radius];
}

class EnableRealTimeUpdates extends PredictionEvent {}

class DisableRealTimeUpdates extends PredictionEvent {}

class LoadHistoricalData extends PredictionEvent {
  final double latitude;
  final double longitude;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  
  const LoadHistoricalData({
    required this.latitude,
    required this.longitude,
    this.startDate,
    this.endDate,
    this.limit = 100,
  });
  
  @override
  List<Object> get props => [
    latitude,
    longitude,
    startDate ?? DateTime(0),
    endDate ?? DateTime(0),
    limit,
  ];
}

class ExportPredictionData extends PredictionEvent {
  final String format;
  final bool includeHistorical;
  
  const ExportPredictionData({
    this.format = 'json',
    this.includeHistorical = false,
  });
  
  @override
  List<Object> get props => [format, includeHistorical];
}

class SetUpdateInterval extends PredictionEvent {
  final Duration interval;
  
  const SetUpdateInterval(this.interval);
  
  @override
  List<Object> get props => [interval];
}

class AddPredictionAlerts extends PredictionEvent {
  final List<double> thresholds;
  final bool enablePushNotifications;
  
  const AddPredictionAlerts({
    required this.thresholds,
    this.enablePushNotifications = true,
  });
  
  @override
  List<Object> get props => [thresholds, enablePushNotifications];
}
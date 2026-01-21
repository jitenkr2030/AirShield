import 'package:json_annotation/json_annotation.dart';
import 'air_quality_data.dart';

part 'prediction_data.g.dart';

@JsonSerializable()
class PredictionData {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime predictionTime;
  final double predictedPM25;
  final double predictedAQI;
  final double confidence;
  final String modelVersion;
  final Map<String, double> additionalPollutants;
  final List<PredictionFactor> factors;
  final DateTime generatedAt;

  const PredictionData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.predictionTime,
    required this.predictedPM25,
    required this.predictedAQI,
    required this.confidence,
    required this.modelVersion,
    this.additionalPollutants = const {},
    this.factors = const [],
    required this.generatedAt,
  });

  factory PredictionData.fromJson(Map<String, dynamic> json) =>
      _$PredictionDataFromJson(json);

  Map<String, dynamic> toJson() => _$PredictionDataToJson(this);

  PredictionData copyWith({
    String? id,
    double? latitude,
    double? longitude,
    DateTime? predictionTime,
    double? predictedPM25,
    double? predictedAQI,
    double? confidence,
    String? modelVersion,
    Map<String, double>? additionalPollutants,
    List<PredictionFactor>? factors,
    DateTime? generatedAt,
  }) {
    return PredictionData(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      predictionTime: predictionTime ?? this.predictionTime,
      predictedPM25: predictedPM25 ?? this.predictedPM25,
      predictedAQI: predictedAQI ?? this.predictedAQI,
      confidence: confidence ?? this.confidence,
      modelVersion: modelVersion ?? this.modelVersion,
      additionalPollutants: additionalPollutants ?? this.additionalPollutants,
      factors: factors ?? this.factors,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  AQILevel get aqiLevel => AQILevelExtension.fromValue(predictedAQI);

  @override
  String toString() {
    return 'PredictionData(lat: $latitude, lng: $longitude, predictedPM25: $predictedPM25, confidence: $confidence, predictionTime: $predictionTime)';
  }
}

@JsonSerializable()
class PredictionFactor {
  final String type;
  final String name;
  final double impact;
  final String description;
  final String unit;

  const PredictionFactor({
    required this.type,
    required this.name,
    required this.impact,
    required this.description,
    required this.unit,
  });

  factory PredictionFactor.fromJson(Map<String, dynamic> json) =>
      _$PredictionFactorFromJson(json);

  Map<String, dynamic> toJson() => _$PredictionFactorToJson(this);

  double get impactPercentage => (impact * 100).roundToDouble();
}

@JsonSerializable()
class MicroZoneForecast {
  final String zoneId;
  final String zoneName;
  final LatLngBounds bounds;
  final double centerLatitude;
  final double centerLongitude;
  final double averagePredictedPM25;
  final double averagePredictedAQI;
  final List<PredictionData> hourlyPredictions;
  final Map<String, double> pollutantHeatmap;
  final List<Hotspot> hotspots;
  final String overallRiskLevel;
  final DateTime generatedAt;
  final int gridResolution; // in meters

  const MicroZoneForecast({
    required this.zoneId,
    required this.zoneName,
    required this.bounds,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.averagePredictedPM25,
    required this.averagePredictedAQI,
    this.hourlyPredictions = const [],
    this.pollutantHeatmap = const {},
    this.hotspots = const [],
    this.overallRiskLevel = 'low',
    required this.generatedAt,
    this.gridResolution = 200,
  });

  factory MicroZoneForecast.fromJson(Map<String, dynamic> json) =>
      _$MicroZoneForecastFromJson(json);

  Map<String, dynamic> toJson() => _$MicroZoneForecastToJson(this);
}

@JsonSerializable()
class SafeRoute {
  final String id;
  final String startLocation;
  final String endLocation;
  final List<LatLng> waypoints;
  final double totalDistance;
  final Duration estimatedTime;
  final double averageAQIExposure;
  final double safetyScore; // 0-100
  final String routeType; // walking, driving, cycling, public_transport
  final List<RouteSegment> segments;
  final List<String> warnings;
  final List<AlternativeRoute> alternatives;
  final DateTime calculatedAt;

  const SafeRoute({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.waypoints,
    required this.totalDistance,
    required this.estimatedTime,
    required this.averageAQIExposure,
    required this.safetyScore,
    required this.routeType,
    this.segments = const [],
    this.warnings = const [],
    this.alternatives = const [],
    required this.calculatedAt,
  });

  factory SafeRoute.fromJson(Map<String, dynamic> json) =>
      _$SafeRouteFromJson(json);

  Map<String, dynamic> toJson() => _$SafeRouteToJson(this);

  String get safetyLevel {
    if (safetyScore >= 80) return 'Excellent';
    if (safetyScore >= 60) return 'Good';
    if (safetyScore >= 40) return 'Fair';
    if (safetyScore >= 20) return 'Poor';
    return 'Very Poor';
  }

  Color get safetyColor {
    if (safetyScore >= 80) return const Color(0xFF28A745);
    if (safetyScore >= 60) return const Color(0xFFFFC107);
    if (safetyScore >= 40) return const Color(0xFFFF9800);
    if (safetyScore >= 20) return const Color(0xFFFF5722);
    return const Color(0xFFDC3545);
  }
}

@JsonSerializable()
class RouteSegment {
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final double distance;
  final Duration duration;
  final double averageAQI;
  final String riskLevel;
  final List<String> landmarks;
  final String description;

  const RouteSegment({
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    required this.distance,
    required this.duration,
    required this.averageAQI,
    required this.riskLevel,
    this.landmarks = const [],
    required this.description,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) =>
      _$RouteSegmentFromJson(json);

  Map<String, dynamic> toJson() => _$RouteSegmentToJson(this);
}

@JsonSerializable()
class AlternativeRoute {
  final String id;
  final String description;
  final double distance;
  final Duration duration;
  final double averageAQIExposure;
  final double safetyScore;
  final List<LatLng> waypoints;
  final String routeType;

  const AlternativeRoute({
    required this.id,
    required this.description,
    required this.distance,
    required this.duration,
    required this.averageAQIExposure,
    required this.safetyScore,
    required this.waypoints,
    required this.routeType,
  });

  factory AlternativeRoute.fromJson(Map<String, dynamic> json) =>
      _$AlternativeRouteFromJson(json);

  Map<String, dynamic> toJson() => _$AlternativeRouteToJson(this);
}

@JsonSerializable()
class Hotspot {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double predictedPM25;
  final double predictedAQI;
  final String sourceType;
  final List<String> potentialSources;
  final String riskLevel;
  final double radius; // in meters
  final DateTime expectedPeakTime;
  final List<MitigationRecommendation> recommendations;

  const Hotspot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.predictedPM25,
    required this.predictedAQI,
    required this.sourceType,
    this.potentialSources = const [],
    required this.riskLevel,
    required this.radius,
    required this.expectedPeakTime,
    this.recommendations = const [],
  });

  factory Hotspot.fromJson(Map<String, dynamic> json) =>
      _$HotspotFromJson(json);

  Map<String, dynamic> toJson() => _$HotspotToJson(this);
}

@JsonSerializable()
class MitigationRecommendation {
  final String type;
  final String title;
  final String description;
  final String urgency;
  final List<String> actions;
  final double effectivenessScore;

  const MitigationRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.urgency,
    this.actions = const [],
    required this.effectivenessScore,
  });

  factory MitigationRecommendation.fromJson(Map<String, dynamic> json) =>
      _$MitigationRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$MitigationRecommendationToJson(this);
}

@JsonSerializable()
class LatLngBounds {
  final double north;
  final double south;
  final double east;
  final double west;

  const LatLngBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  factory LatLngBounds.fromJson(Map<String, dynamic> json) =>
      _$LatLngBoundsFromJson(json);

  Map<String, dynamic> toJson() => _$LatLngBoundsToJson(this);

  List<double> get northeast => [north, east];
  List<double> get southwest => [south, west];
}

enum RouteType {
  walking,
  driving,
  cycling,
  publicTransport,
  combined,
}

extension RouteTypeExtension on RouteType {
  String get displayName {
    switch (this) {
      case RouteType.walking:
        return 'Walking';
      case RouteType.driving:
        return 'Driving';
      case RouteType.cycling:
        return 'Cycling';
      case RouteType.publicTransport:
        return 'Public Transport';
      case RouteType.combined:
        return 'Combined';
    }
  }
}
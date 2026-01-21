import 'package:json_annotation/json_annotation.dart';

part 'route_planning_data.g.dart';

@JsonSerializable()
class RouteRequest {
  final String origin;
  final String destination;
  final RouteMode mode;
  final DateTime departureTime;
  final bool avoidHighPollution;
  final double maxDetourDistance;
  final List<String> waypoints;

  const RouteRequest({
    required this.origin,
    required this.destination,
    required this.mode,
    required this.departureTime,
    this.avoidHighPollution = true,
    this.maxDetourDistance = 5.0,
    this.waypoints = const [],
  });

  factory RouteRequest.fromJson(Map<String, dynamic> json) =>
      _$RouteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RouteRequestToJson(this);

  RouteRequest copyWith({
    String? origin,
    String? destination,
    RouteMode? mode,
    DateTime? departureTime,
    bool? avoidHighPollution,
    double? maxDetourDistance,
    List<String>? waypoints,
  }) {
    return RouteRequest(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      mode: mode ?? this.mode,
      departureTime: departureTime ?? this.departureTime,
      avoidHighPollution: avoidHighPollution ?? this.avoidHighPollution,
      maxDetourDistance: maxDetourDistance ?? this.maxDetourDistance,
      waypoints: waypoints ?? this.waypoints,
    );
  }
}

enum RouteMode {
  @JsonValue('driving')
  driving,
  @JsonValue('walking')
  walking,
  @JsonValue('transit')
  transit,
  @JsonValue('cycling')
  cycling,
  @JsonValue('mixed')
  mixed,
}

@JsonSerializable()
class RouteOption {
  final String routeId;
  final String name;
  final double distance; // in kilometers
  final int duration; // in minutes
  final double airQualityScore; // 0-100, higher is better
  final List<RouteSegment> segments;
  final RouteMetrics metrics;
  final List<String> warnings;
  final String? estimatedCost;

  const RouteOption({
    required this.routeId,
    required this.name,
    required this.distance,
    required this.duration,
    required this.airQualityScore,
    required this.segments,
    required this.metrics,
    this.warnings = const [],
    this.estimatedCost,
  });

  factory RouteOption.fromJson(Map<String, dynamic> json) =>
      _$RouteOptionFromJson(json);

  Map<String, dynamic> toJson() => _$RouteOptionToJson(this);
}

@JsonSerializable()
class RouteSegment {
  final String segmentId;
  final String startAddress;
  final String endAddress;
  final double distance;
  final int duration;
  final RouteMode mode;
  final AirQualitySegment airQuality;
  final List<String> instructions;

  const RouteSegment({
    required this.segmentId,
    required this.startAddress,
    required this.endAddress,
    required this.distance,
    required this.duration,
    required this.mode,
    required this.airQuality,
    required this.instructions,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) =>
      _$RouteSegmentFromJson(json);

  Map<String, dynamic> toJson() => _$RouteSegmentToJson(this);
}

@JsonSerializable()
class AirQualitySegment {
  final double avgAQI;
  final double maxAQI;
  final double minAQI;
  final List<AirQualityZone> zones;
  final double healthRisk; // 0-1 scale
  final List<String> pollutants;

  const AirQualitySegment({
    required this.avgAQI,
    required this.maxAQI,
    required this.minAQI,
    required this.zones,
    required this.healthRisk,
    required this.pollutants,
  });

  factory AirQualitySegment.fromJson(Map<String, dynamic> json) =>
      _$AirQualitySegmentFromJson(json);

  Map<String, dynamic> toJson() => _$AirQualitySegmentToJson(this);
}

@JsonSerializable()
class AirQualityZone {
  final String zoneId;
  final String name;
  final double aqi;
  final double lat;
  final double lng;
  final DateTime timestamp;

  const AirQualityZone({
    required this.zoneId,
    required this.name,
    required this.aqi,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  factory AirQualityZone.fromJson(Map<String, dynamic> json) =>
      _$AirQualityZoneFromJson(json);

  Map<String, dynamic> toJson() => _$AirQualityZoneToJson(this);
}

@JsonSerializable()
class RouteMetrics {
  final double pollutionExposure; // total exposure score
  final int healthImpactPoints; // calculated health impact
  final double carbonFootprint; // in kg CO2
  final double timeEfficiency; // 0-1 scale
  final double convenienceScore; // 0-1 scale
  final List<HealthRecommendation> healthRecommendations;

  const RouteMetrics({
    required this.pollutionExposure,
    required this.healthImpactPoints,
    required this.carbonFootprint,
    required this.timeEfficiency,
    required this.convenienceScore,
    this.healthRecommendations = const [],
  });

  factory RouteMetrics.fromJson(Map<String, dynamic> json) =>
      _$RouteMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$RouteMetricsToJson(this);
}

@JsonSerializable()
class HealthRecommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationType type;
  final Priority priority;
  final List<String> actions;

  const HealthRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.actions = const [],
  });

  factory HealthRecommendation.fromJson(Map<String, dynamic> json) =>
      _$HealthRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$HealthRecommendationToJson(this);
}

enum RecommendationType {
  @JsonValue('prevention')
  prevention,
  @JsonValue('route_modification')
  routeModification,
  @JsonValue('health_precaution')
  healthPrecaution,
  @JsonValue('transport_alternative')
  transportAlternative,
  @JsonValue('timing_adjustment')
  timingAdjustment,
}

enum Priority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

@JsonSerializable()
class RouteComparison {
  final String comparisonId;
  final List<RouteOption> routes;
  final RouteOption? recommendedRoute;
  final Map<String, dynamic> comparisonMatrix;
  final String reasoning;

  const RouteComparison({
    required this.comparisonId,
    required this.routes,
    this.recommendedRoute,
    required this.comparisonMatrix,
    required this.reasoning,
  });

  factory RouteComparison.fromJson(Map<String, dynamic> json) =>
      _$RouteComparisonFromJson(json);

  Map<String, dynamic> toJson() => _$RouteComparisonToJson(this);
}

@JsonSerializable()
class RouteHistory {
  final String routeId;
  final RouteRequest originalRequest;
  final RouteOption selectedRoute;
  final DateTime startTime;
  final DateTime? endTime;
  final bool wasCompleted;
  final double actualDistance;
  final int actualDuration;
  final List<String> userFeedback;

  const RouteHistory({
    required this.routeId,
    required this.originalRequest,
    required this.selectedRoute,
    required this.startTime,
    this.endTime,
    this.wasCompleted = false,
    this.actualDistance = 0.0,
    this.actualDuration = 0,
    this.userFeedback = const [],
  });

  factory RouteHistory.fromJson(Map<String, dynamic> json) =>
      _$RouteHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$RouteHistoryToJson(this);
}

@JsonSerializable()
class RoutePreferences {
  final bool prioritizeAirQuality;
  final bool prioritizeSpeed;
  final bool prioritizeCost;
  final bool prioritizeHealth;
  final Set<RouteMode> preferredModes;
  final double maxTravelTime;
  final double maxPollutionExposure;

  const RoutePreferences({
    this.prioritizeAirQuality = true,
    this.prioritizeSpeed = false,
    this.prioritizeCost = false,
    this.prioritizeHealth = true,
    this.preferredModes = const {},
    this.maxTravelTime = 120.0, // minutes
    this.maxPollutionExposure = 50.0,
  });

  factory RoutePreferences.fromJson(Map<String, dynamic> json) =>
      _$RoutePreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$RoutePreferencesToJson(this);
}
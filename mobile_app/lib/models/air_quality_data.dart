import 'package:json_annotation/json_annotation.dart';

part 'air_quality_data.g.dart';

@JsonSerializable()
class AirQualityData {
  final String id;
  final double latitude;
  final double longitude;
  final double pm25;
  final double pm10;
  final double aqi;
  final double co2;
  final double no2;
  final double so2;
  final double o3;
  final double humidity;
  final double temperature;
  final double windSpeed;
  final double windDirection;
  final String source;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const AirQualityData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.pm25,
    required this.pm10,
    required this.aqi,
    this.co2 = 0.0,
    this.no2 = 0.0,
    this.so2 = 0.0,
    this.o3 = 0.0,
    this.humidity = 0.0,
    this.temperature = 0.0,
    this.windSpeed = 0.0,
    this.windDirection = 0.0,
    required this.source,
    required this.timestamp,
    this.metadata,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) =>
      _$AirQualityDataFromJson(json);

  Map<String, dynamic> toJson() => _$AirQualityDataToJson(this);

  AirQualityData copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? pm25,
    double? pm10,
    double? aqi,
    double? co2,
    double? no2,
    double? so2,
    double? o3,
    double? humidity,
    double? temperature,
    double? windSpeed,
    double? windDirection,
    String? source,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AirQualityData(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      aqi: aqi ?? this.aqi,
      co2: co2 ?? this.co2,
      no2: no2 ?? this.no2,
      so2: so2 ?? this.so2,
      o3: o3 ?? this.o3,
      humidity: humidity ?? this.humidity,
      temperature: temperature ?? this.temperature,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'AirQualityData(id: $id, pm25: $pm25, aqi: $aqi, source: $source, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AirQualityData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp;

  @override
  int get hashCode => id.hashCode ^ timestamp.hashCode;
}

@JsonSerializable()
class AQISeasonalTrend {
  final String season;
  final double averagePM25;
  final double averageAQI;
  final List<double> monthlyValues;
  final DateTime lastUpdated;

  const AQISeasonalTrend({
    required this.season,
    required this.averagePM25,
    required this.averageAQI,
    required this.monthlyValues,
    required this.lastUpdated,
  });

  factory AQISeasonalTrend.fromJson(Map<String, dynamic> json) =>
      _$AQISeasonalTrendFromJson(json);

  Map<String, dynamic> toJson() => _$AQISeasonalTrendToJson(this);
}

@JsonSerializable()
class AQIHotspot {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double pm25;
  final double aqi;
  final String category;
  final List<String> sources;
  final DateTime lastUpdated;
  final Map<String, double>? additionalPollutants;

  const AQIHotspot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.pm25,
    required this.aqi,
    required this.category,
    required this.sources,
    required this.lastUpdated,
    this.additionalPollutants,
  });

  factory AQIHotspot.fromJson(Map<String, dynamic> json) =>
      _$AQIHotspotFromJson(json);

  Map<String, dynamic> toJson() => _$AQIHotspotToJson(this);
}

enum PollutantType {
  pm25,
  pm10,
  co2,
  no2,
  so2,
  o3,
  aqi,
}

enum AQILevel {
  good,
  moderate,
  unhealthyForSensitive,
  unhealthy,
  veryUnhealthy,
  hazardous,
}

extension AQILevelExtension on AQILevel {
  static AQILevel fromValue(double aqi) {
    if (aqi <= 50) return AQILevel.good;
    if (aqi <= 100) return AQILevel.moderate;
    if (aqi <= 150) return AQILevel.unhealthyForSensitive;
    if (aqi <= 200) return AQILevel.unhealthy;
    if (aqi <= 300) return AQILevel.veryUnhealthy;
    return AQILevel.hazardous;
  }
  
  String get displayName {
    switch (this) {
      case AQILevel.good:
        return 'Good';
      case AQILevel.moderate:
        return 'Moderate';
      case AQILevel.unhealthyForSensitive:
        return 'Unhealthy for Sensitive';
      case AQILevel.unhealthy:
        return 'Unhealthy';
      case AQILevel.veryUnhealthy:
        return 'Very Unhealthy';
      case AQILevel.hazardous:
        return 'Hazardous';
    }
  }
  
  Color get color {
    switch (this) {
      case AQILevel.good:
        return const Color(0xFF28A745);
      case AQILevel.moderate:
        return const Color(0xFFFFC107);
      case AQILevel.unhealthyForSensitive:
        return const Color(0xFFFF9800);
      case AQILevel.unhealthy:
        return const Color(0xFFFF5722);
      case AQILevel.veryUnhealthy:
        return const Color(0xFF9C27B0);
      case AQILevel.hazardous:
        return const Color(0xFFDC3545);
    }
  }
}
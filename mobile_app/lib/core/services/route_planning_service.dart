import 'dart:math';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_planning_data.dart';
import '../models/air_quality_data.dart';
import '../models/user_profile.dart';
import 'air_quality_data.dart'; // Assuming this exists
import 'location_service.dart'; // Assuming this exists

class RoutePlanningService {
  late final Dio _dio;
  late final AirQualityDataService _airQualityService;
  late final LocationService _locationService;

  RoutePlanningService() {
    _dio = Dio();
    _airQualityService = AirQualityDataService();
    _locationService = LocationService();
  }

  Future<List<RouteOption>> calculateRoutes(RouteRequest request) async {
    try {
      final routes = <RouteOption>[];
      
      // Generate multiple route options based on preferences
      final baseRoutes = await _generateBaseRoutes(request);
      
      for (final baseRoute in baseRoutes) {
        final airQualityAnalysis = await _analyzeAirQualityAlongRoute(baseRoute);
        final metrics = await _calculateRouteMetrics(baseRoute, airQualityAnalysis, request);
        final routeOption = RouteOption(
          routeId: _generateRouteId(),
          name: _generateRouteName(baseRoute.mode),
          distance: baseRoute.distance,
          duration: baseRoute.duration,
          airQualityScore: airQualityAnalysis.score,
          segments: airQualityAnalysis.segments,
          metrics: metrics,
          warnings: _generateWarnings(airQualityAnalysis),
          estimatedCost: _estimateCost(baseRoute, request),
        );
        routes.add(routeOption);
      }
      
      // Sort by user preferences
      return _sortRoutesByPreferences(routes, request);
    } catch (e) {
      throw Exception('Failed to calculate routes: $e');
    }
  }

  Future<List<BaseRoute>> _generateBaseRoutes(RouteRequest request) async {
    final routes = <BaseRoute>[];
    
    try {
      // Fastest route
      routes.add(await _getFastestRoute(request));
      
    } catch (e) {
      // Handle error but continue with other routes
    }
    
    try {
      // Cleanest route (if user prefers air quality)
      routes.add(await _getCleanestRoute(request));
    } catch (e) {
      // Handle error but continue
    }
    
    try {
      // Direct route
      routes.add(await _getDirectRoute(request));
    } catch (e) {
      // Handle error but continue
    }
    
    // If no routes found, create a fallback
    if (routes.isEmpty) {
      routes.add(await _createFallbackRoute(request));
    }
    
    return routes;
  }

  Future<BaseRoute> _getFastestRoute(RouteRequest request) async {
    // Simulate API call to Google Directions API
    // In real implementation, use Google Directions API
    return BaseRoute(
      routeId: 'fastest_${DateTime.now().millisecondsSinceEpoch}',
      mode: request.mode,
      distance: _calculateDistance(request.origin, request.destination),
      duration: _estimateDuration(request.mode),
      polyline: _generatePolyline(),
      startPoint: _getCoordinates(request.origin),
      endPoint: _getCoordinates(request.destination),
    );
  }

  Future<BaseRoute> _getCleanestRoute(RouteRequest request) async {
    // Algorithm to find route with minimal pollution exposure
    final alternativePoints = await _generateAlternativePoints(
      request.origin, 
      request.destination, 
      5, // number of alternative points
    );
    
    BaseRoute? cleanestRoute;
    double minPollutionExposure = double.infinity;
    
    for (final alternative in alternativePoints) {
      try {
        final route = await _getRouteBetweenPoints(alternative.start, alternative.end);
        final pollutionExposure = await _calculatePollutionExposure(route);
        
        if (pollutionExposure < minPollutionExposure) {
          minPollutionExposure = pollutionExposure;
          cleanestRoute = route;
        }
      } catch (e) {
        continue;
      }
    }
    
    return cleanestRoute ?? await _createFallbackRoute(request);
  }

  Future<BaseRoute> _getDirectRoute(RouteRequest request) async {
    // Direct route without optimization
    final distance = _calculateDistance(request.origin, request.destination);
    final duration = _estimateDuration(request.mode);
    
    return BaseRoute(
      routeId: 'direct_${DateTime.now().millisecondsSinceEpoch}',
      mode: RouteMode.driving, // Direct route often uses driving mode
      distance: distance,
      duration: duration,
      polyline: _generateDirectPolyline(),
      startPoint: _getCoordinates(request.origin),
      endPoint: _getCoordinates(request.destination),
    );
  }

  Future<BaseRoute> _createFallbackRoute(RouteRequest request) async {
    // Simple fallback route
    final distance = _calculateDistance(request.origin, request.destination);
    final duration = _estimateDuration(request.mode);
    
    return BaseRoute(
      routeId: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      mode: RouteMode.driving,
      distance: distance,
      duration: duration,
      polyline: _generateDirectPolyline(),
      startPoint: _getCoordinates(request.origin),
      endPoint: _getCoordinates(request.destination),
    );
  }

  Future<AirQualityAnalysis> _analyzeAirQualityAlongRoute(BaseRoute route) async {
    final segments = <RouteSegment>[];
    double totalPollutionExposure = 0.0;
    
    // Break route into segments and analyze air quality for each
    final segmentPoints = _breakRouteIntoSegments(route.polyline);
    
    for (int i = 0; i < segmentPoints.length - 1; i++) {
      final segmentStart = segmentPoints[i];
      final segmentEnd = segmentPoints[i + 1];
      
      final segmentAirQuality = await _analyzeSegmentAirQuality(
        segmentStart, 
        segmentEnd, 
        route.mode,
      );
      
      final segment = RouteSegment(
        segmentId: 'segment_${i}_${DateTime.now().millisecondsSinceEpoch}',
        startAddress: segmentStart.address,
        endAddress: segmentEnd.address,
        distance: _calculateSegmentDistance(segmentStart, segmentEnd),
        duration: _estimateSegmentDuration(segmentStart, segmentEnd, route.mode),
        mode: route.mode,
        airQuality: segmentAirQuality,
        instructions: _generateSegmentInstructions(segmentStart, segmentEnd, route.mode),
      );
      
      segments.add(segment);
      totalPollutionExposure += segmentAirQuality.healthRisk * segment.distance;
    }
    
    final averageAQI = segments.isNotEmpty 
        ? segments.map((s) => s.airQuality.avgAQI).reduce((a, b) => a + b) / segments.length
        : 50.0;
    
    final score = max(0, 100 - averageAQI); // Higher score for better air quality
    
    return AirQualityAnalysis(
      score: score,
      segments: segments,
      totalExposure: totalPollutionExposure,
      averageAQI: averageAQI,
    );
  }

  Future<AirQualitySegment> _analyzeSegmentAirQuality(
    LatLng start, 
    LatLng end, 
    RouteMode mode,
  ) async {
    try {
      // Get air quality data for the segment
      final airQualityData = await _airQualityService.getAirQualityAtLocation(
        start.latitude, 
        start.longitude,
      );
      
      final zones = <AirQualityZone>[];
      double totalAQI = 0.0;
      double maxAQI = 0.0;
      double minAQI = 1000.0;
      
      // Sample multiple points along the segment
      final samplePoints = _generateSamplePoints(start, end, 5);
      
      for (final point in samplePoints) {
        final pointAQI = await _airQualityService.getAirQualityAtLocation(
          point.latitude, 
          point.longitude,
        );
        
        final zone = AirQualityZone(
          zoneId: 'zone_${point.latitude.toStringAsFixed(4)}_${point.longitude.toStringAsFixed(4)}',
          name: 'Zone ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
          aqi: pointAQI.aqi,
          lat: point.latitude,
          lng: point.longitude,
          timestamp: DateTime.now(),
        );
        
        zones.add(zone);
        totalAQI += pointAQI.aqi;
        maxAQI = max(maxAQI, pointAQI.aqi);
        minAQI = min(minAQI, pointAQI.aqi);
      }
      
      final avgAQI = zones.isNotEmpty ? totalAQI / zones.length : 50.0;
      final healthRisk = _calculateHealthRisk(avgAQI, mode);
      final pollutants = _identifyPollutants(avgAQI);
      
      return AirQualitySegment(
        avgAQI: avgAQI,
        maxAQI: maxAQI,
        minAQI: minAQI,
        zones: zones,
        healthRisk: healthRisk,
        pollutants: pollutants,
      );
    } catch (e) {
      // Return default values on error
      return AirQualitySegment(
        avgAQI: 50.0,
        maxAQI: 50.0,
        minAQI: 50.0,
        zones: [],
        healthRisk: 0.1,
        pollutants: ['PM2.5', 'NO2'],
      );
    }
  }

  Future<RouteMetrics> _calculateRouteMetrics(
    BaseRoute route, 
    AirQualityAnalysis airQualityAnalysis,
    RouteRequest request,
  ) async {
    // Calculate pollution exposure
    final pollutionExposure = airQualityAnalysis.totalExposure;
    
    // Calculate health impact points
    final healthImpactPoints = _calculateHealthImpactPoints(
      airQualityAnalysis, 
      request,
    );
    
    // Calculate carbon footprint
    final carbonFootprint = _calculateCarbonFootprint(route);
    
    // Calculate time efficiency
    final timeEfficiency = _calculateTimeEfficiency(route, request);
    
    // Calculate convenience score
    final convenienceScore = _calculateConvenienceScore(route, request);
    
    // Generate health recommendations
    final healthRecommendations = _generateHealthRecommendations(
      airQualityAnalysis, 
      route.mode,
    );
    
    return RouteMetrics(
      pollutionExposure: pollutionExposure,
      healthImpactPoints: healthImpactPoints,
      carbonFootprint: carbonFootprint,
      timeEfficiency: timeEfficiency,
      convenienceScore: convenienceScore,
      healthRecommendations: healthRecommendations,
    );
  }

  List<String> _generateWarnings(AirQualityAnalysis analysis) {
    final warnings = <String>[];
    
    if (analysis.score < 30) {
      warnings.add('High pollution levels detected on this route');
      warnings.add('Consider taking protective measures');
    }
    
    if (analysis.totalExposure > 100) {
      warnings.add('Significant pollution exposure risk');
    }
    
    if (analysis.averageAQI > 150) {
      warnings.add('Unhealthy air quality - limit outdoor activities');
    }
    
    return warnings;
  }

  String? _estimateCost(BaseRoute route, RouteRequest request) {
    switch (route.mode) {
      case RouteMode.driving:
        final fuelCost = route.distance * 0.8; // $0.80 per km
        return '\$${fuelCost.toStringAsFixed(2)}';
      case RouteMode.transit:
        return 'Transit fare applies';
      case RouteMode.cycling:
      case RouteMode.walking:
        return 'Free';
      default:
        return null;
    }
  }

  List<RouteOption> _sortRoutesByPreferences(List<RouteOption> routes, RouteRequest request) {
    routes.sort((a, b) {
      // Sort based on user preferences
      if (request.avoidHighPollution) {
        final comparison = b.airQualityScore.compareTo(a.airQualityScore);
        if (comparison != 0) return comparison;
      }
      
      return a.duration.compareTo(b.duration);
    });
    
    return routes;
  }

  // Helper methods for calculations and conversions
  String _generateRouteId() => 'route_${DateTime.now().millisecondsSinceEpoch}';
  
  String _generateRouteName(RouteMode mode) {
    switch (mode) {
      case RouteMode.driving:
        return 'Fast Driving Route';
      case RouteMode.walking:
        return 'Walking Route';
      case RouteMode.cycling:
        return 'Cycling Route';
      case RouteMode.transit:
        return 'Public Transit Route';
      case RouteMode.mixed:
        return 'Multi-modal Route';
    }
  }

  double _calculateDistance(String origin, String destination) {
    // Simplified distance calculation
    return 10.0 + Random().nextDouble() * 20.0; // 10-30 km range
  }

  int _estimateDuration(RouteMode mode) {
    final random = Random();
    final baseMinutes = 30 + random.nextInt(60); // 30-90 minutes
    
    switch (mode) {
      case RouteMode.driving:
        return baseMinutes;
      case RouteMode.walking:
        return (baseMinutes * 4).round(); // Walking is 4x slower
      case RouteMode.cycling:
        return (baseMinutes * 2).round(); // Cycling is 2x slower
      case RouteMode.transit:
        return (baseMinutes * 1.5).round(); // Transit includes waiting
      case RouteMode.mixed:
        return baseMinutes;
    }
  }

  String _generatePolyline() {
    // Simplified polyline generation
    return 'encoded_polyline_string';
  }

  String _generateDirectPolyline() {
    return 'encoded_direct_polyline_string';
  }

  LatLng _getCoordinates(String address) {
    // In real implementation, use geocoding service
    return LatLng(40.7128, -74.0060); // Default to NYC
  }

  Future<List<AlternativePoint>> _generateAlternativePoints(
    String origin, 
    String destination, 
    int count,
  ) async {
    final start = _getCoordinates(origin);
    final end = _getCoordinates(destination);
    
    final alternatives = <AlternativePoint>[];
    
    for (int i = 0; i < count; i++) {
      final deviation = (i + 1) * 0.1; // 10% deviation for each alternative
      final altStart = LatLng(
        start.latitude + (Random().nextDouble() - 0.5) * deviation,
        start.longitude + (Random().nextDouble() - 0.5) * deviation,
      );
      final altEnd = LatLng(
        end.latitude + (Random().nextDouble() - 0.5) * deviation,
        end.longitude + (Random().nextDouble() - 0.5) * deviation,
      );
      
      alternatives.add(AlternativePoint(start: altStart, end: altEnd));
    }
    
    return alternatives;
  }

  Future<BaseRoute> _getRouteBetweenPoints(LatLng start, LatLng end) async {
    // Simplified route between two points
    return BaseRoute(
      routeId: 'alt_${DateTime.now().millisecondsSinceEpoch}',
      mode: RouteMode.driving,
      distance: _calculatePointDistance(start, end),
      duration: _estimateDuration(RouteMode.driving),
      polyline: _generatePolyline(),
      startPoint: start,
      endPoint: end,
    );
  }

  double _calculatePointDistance(LatLng start, LatLng end) {
    // Haversine formula for distance calculation
    const double R = 6371; // Earth's radius in km
    final dLat = _toRadians(end.latitude - start.latitude);
    final dLng = _toRadians(end.longitude - start.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(start.latitude)) * cos(_toRadians(end.latitude)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  Future<double> _calculatePollutionExposure(BaseRoute route) async {
    // Simplified pollution exposure calculation
    return route.distance * 2.0; // Assume 2 units of exposure per km
  }

  List<LatLng> _breakRouteIntoSegments(String polyline) {
    // Simplified segment generation
    return [
      LatLng(40.7128, -74.0060),
      LatLng(40.7589, -73.9851),
      LatLng(40.7831, -73.9712),
      LatLng(40.7505, -73.9934),
      LatLng(40.7282, -74.0776),
    ];
  }

  List<SegmentPoint> _generateSamplePoints(LatLng start, LatLng end, int count) {
    final points = <SegmentPoint>[];
    final stepLat = (end.latitude - start.latitude) / count;
    final stepLng = (end.longitude - start.longitude) / count;
    
    for (int i = 0; i <= count; i++) {
      points.add(SegmentPoint(
        latitude: start.latitude + (stepLat * i),
        longitude: start.longitude + (stepLng * i),
        address: 'Sample Point ${i + 1}',
      ));
    }
    
    return points;
  }

  double _calculateSegmentDistance(SegmentPoint start, SegmentPoint end) {
    final startLatLng = LatLng(start.latitude, start.longitude);
    final endLatLng = LatLng(end.latitude, end.longitude);
    return _calculatePointDistance(startLatLng, endLatLng);
  }

  int _estimateSegmentDuration(SegmentPoint start, SegmentPoint end, RouteMode mode) {
    final distance = _calculateSegmentDistance(start, end);
    final baseSpeed = _getSpeedForMode(mode);
    return ((distance / baseSpeed) * 60).round(); // Convert to minutes
  }

  double _getSpeedForMode(RouteMode mode) {
    switch (mode) {
      case RouteMode.driving:
        return 50.0; // km/h
      case RouteMode.walking:
        return 5.0; // km/h
      case RouteMode.cycling:
        return 20.0; // km/h
      case RouteMode.transit:
        return 25.0; // km/h (including stops)
      case RouteMode.mixed:
        return 30.0; // km/h average
    }
  }

  List<String> _generateSegmentInstructions(SegmentPoint start, SegmentPoint end, RouteMode mode) {
    return [
      'Head ${_getDirection(start, end)} for ${_calculateSegmentDistance(start, end).toStringAsFixed(1)} km',
      'Continue for ${_estimateSegmentDuration(start, end, mode)} minutes',
    ];
  }

  String _getDirection(SegmentPoint start, SegmentPoint end) {
    final latDiff = end.latitude - start.latitude;
    final lngDiff = end.longitude - start.longitude;
    
    if (latDiff.abs() > lngDiff.abs()) {
      return latDiff > 0 ? 'north' : 'south';
    } else {
      return lngDiff > 0 ? 'east' : 'west';
    }
  }

  double _calculateHealthRisk(double aqi, RouteMode mode) {
    // Risk calculation based on AQI and transportation mode
    double baseRisk = aqi / 500.0; // Normalize to 0-1 range
    
    switch (mode) {
      case RouteMode.walking:
      case RouteMode.cycling:
        return baseRisk * 1.2; // Higher exposure while walking/cycling
      case RouteMode.driving:
        return baseRisk * 0.8; // Lower exposure in enclosed vehicle
      case RouteMode.transit:
        return baseRisk * 0.9; // Moderate exposure
      case RouteMode.mixed:
        return baseRisk * 1.0; // Average exposure
    }
  }

  List<String> _identifyPollutants(double aqi) {
    if (aqi < 50) return ['PM2.5', 'O3'];
    if (aqi < 100) return ['PM2.5', 'NO2', 'O3'];
    if (aqi < 150) return ['PM2.5', 'PM10', 'NO2', 'SO2', 'O3'];
    if (aqi < 200) return ['PM2.5', 'PM10', 'NO2', 'SO2', 'CO', 'O3'];
    return ['PM2.5', 'PM10', 'NO2', 'SO2', 'CO', 'O3']; // High pollution
  }

  int _calculateHealthImpactPoints(AirQualityAnalysis analysis, RouteRequest request) {
    // Convert pollution exposure to health impact points
    return (analysis.totalExposure * 10).round(); // Scale factor
  }

  double _calculateCarbonFootprint(BaseRoute route) {
    // Carbon footprint calculation based on route and mode
    switch (route.mode) {
      case RouteMode.driving:
        return route.distance * 0.2; // kg CO2 per km
      case RouteMode.transit:
        return route.distance * 0.05; // Lower carbon footprint
      case RouteMode.cycling:
      case RouteMode.walking:
        return 0.0; // No direct emissions
      case RouteMode.mixed:
        return route.distance * 0.1; // Average
    }
  }

  double _calculateTimeEfficiency(BaseRoute route, RouteRequest request) {
    // Time efficiency based on actual vs expected duration
    final expectedDuration = request.maxTravelTime;
    final actualDuration = route.duration;
    
    if (actualDuration <= expectedDuration) {
      return 1.0; // Excellent
    } else if (actualDuration <= expectedDuration * 1.2) {
      return 0.8; // Good
    } else if (actualDuration <= expectedDuration * 1.5) {
      return 0.6; // Fair
    } else {
      return 0.3; // Poor
    }
  }

  double _calculateConvenienceScore(BaseRoute route, RouteRequest request) {
    // Convenience based on route complexity and user preferences
    double score = 0.5; // Base score
    
    // Bonus for simple routes
    if (route.mode == RouteMode.driving || route.mode == RouteMode.walking) {
      score += 0.3;
    }
    
    // Penalty for very long routes
    if (route.distance > 50) {
      score -= 0.2;
    }
    
    return score.clamp(0.0, 1.0);
  }

  List<HealthRecommendation> _generateHealthRecommendations(
    AirQualityAnalysis analysis, 
    RouteMode mode,
  ) {
    final recommendations = <HealthRecommendation>[];
    
    if (analysis.score < 30) {
      recommendations.add(HealthRecommendation(
        id: 'protective_measures_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Take Protective Measures',
        description: 'Air quality is poor on this route. Consider wearing a mask or taking an alternative route.',
        type: RecommendationType.healthPrecaution,
        priority: Priority.high,
        actions: ['Wear N95 mask', 'Consider alternative route', 'Limit outdoor exposure time'],
      ));
    }
    
    if (mode == RouteMode.walking || mode == RouteMode.cycling) {
      recommendations.add(HealthRecommendation(
        id: 'exercise_caution_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Exercise Caution',
        description: 'Heavy breathing during exercise increases pollution intake. Monitor your breathing.',
        type: RecommendationType.healthPrecaution,
        priority: Priority.medium,
        actions: ['Monitor breathing patterns', 'Consider shorter route', 'Time travel for better air quality'],
      ));
    }
    
    return recommendations;
  }

  Future<RouteComparison> compareRoutes(
    List<RouteOption> routes, 
    RoutePreferences preferences,
  ) async {
    final comparisonMatrix = <String, dynamic>{};
    
    for (final route in routes) {
      comparisonMatrix[route.routeId] = {
        'airQualityScore': route.airQualityScore,
        'duration': route.duration,
        'distance': route.distance,
        'healthImpact': route.metrics.healthImpactPoints,
        'pollutionExposure': route.metrics.pollutionExposure,
        'convenienceScore': route.metrics.convenienceScore,
        'timeEfficiency': route.metrics.timeEfficiency,
        'carbonFootprint': route.metrics.carbonFootprint,
      };
    }
    
    // Find recommended route based on preferences
    final recommendedRoute = _findRecommendedRoute(routes, preferences);
    final reasoning = _generateComparisonReasoning(recommendedRoute, preferences);
    
    return RouteComparison(
      comparisonId: 'comparison_${DateTime.now().millisecondsSinceEpoch}',
      routes: routes,
      recommendedRoute: recommendedRoute,
      comparisonMatrix: comparisonMatrix,
      reasoning: reasoning,
    );
  }

  RouteOption? _findRecommendedRoute(List<RouteOption> routes, RoutePreferences preferences) {
    if (routes.isEmpty) return null;
    
    RouteOption? bestRoute;
    double bestScore = -1;
    
    for (final route in routes) {
      double score = 0;
      
      if (preferences.prioritizeAirQuality) {
        score += route.airQualityScore * 0.3;
      }
      
      if (preferences.prioritizeSpeed) {
        score += (100 - (route.duration / routes.first.duration * 100)) * 0.2;
      }
      
      if (preferences.prioritizeHealth) {
        score += (100 - route.metrics.healthImpactPoints) * 0.3;
      }
      
      if (preferences.prioritizeCost) {
        final costScore = route.estimatedCost == 'Free' ? 100 : 50;
        score += costScore * 0.2;
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestRoute = route;
      }
    }
    
    return bestRoute;
  }

  String _generateComparisonReasoning(RouteOption? recommendedRoute, RoutePreferences preferences) {
    if (recommendedRoute == null) {
      return 'No suitable route found based on your preferences.';
    }
    
    final reasons = <String>[];
    
    if (preferences.prioritizeAirQuality && recommendedRoute.airQualityScore > 70) {
      reasons.add('Best air quality among all options');
    }
    
    if (preferences.prioritizeSpeed && recommendedRoute.duration <= 60) {
      reasons.add('Fastest route within acceptable time');
    }
    
    if (preferences.prioritizeHealth && recommendedRoute.metrics.healthImpactPoints < 50) {
      reasons.add('Lowest health impact potential');
    }
    
    return reasons.isNotEmpty 
        ? reasons.join('. ') 
        : 'Recommended based on your overall preferences.';
  }
}

// Supporting classes for route calculations
class BaseRoute {
  final String routeId;
  final RouteMode mode;
  final double distance;
  final int duration;
  final String polyline;
  final LatLng startPoint;
  final LatLng endPoint;

  const BaseRoute({
    required this.routeId,
    required this.mode,
    required this.distance,
    required this.duration,
    required this.polyline,
    required this.startPoint,
    required this.endPoint,
  });
}

class AirQualityAnalysis {
  final double score;
  final List<RouteSegment> segments;
  final double totalExposure;
  final double averageAQI;

  const AirQualityAnalysis({
    required this.score,
    required this.segments,
    required this.totalExposure,
    required this.averageAQI,
  });
}

class AlternativePoint {
  final LatLng start;
  final LatLng end;

  const AlternativePoint({
    required this.start,
    required this.end,
  });
}

class SegmentPoint {
  final double latitude;
  final double longitude;
  final String address;

  const SegmentPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}
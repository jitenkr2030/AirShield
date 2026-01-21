import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart';
import '../models/health_profile.dart';
import '../models/air_quality_data.dart';
import '../../models/health_score_data.dart';
import 'air_quality_service.dart';

/// Core service for calculating personalized health scores based on
/// air quality exposure, user vulnerability factors, and activity patterns
class HealthScoreService {
  static const Uuid _uuid = Uuid();
  
  // Score calculation constants
  static const double _aqiWeight = 0.35; // 35% weight to air quality
  static const double _userVulnerabilityWeight = 0.30; // 30% weight to user factors
  static const double _exposureTimeWeight = 0.20; // 20% weight to exposure time
  static const double _activityLevelWeight = 0.15; // 15% weight to activity patterns

  /// Calculate comprehensive health score for user
  Future<HealthScoreData> calculateHealthScore({
    required String userId,
    required UserProfile user,
    required HealthProfile healthProfile,
    required AirQualityData currentAirQuality,
    List<AirQualityData>? historicalData,
    Map<String, dynamic>? locationPatterns,
  }) async {
    
    // Calculate individual score components
    final respiratoryScore = await _calculateRespiratoryScore(
      user, healthProfile, currentAirQuality, historicalData,
    );
    
    final cardiovascularScore = await _calculateCardiovascularScore(
      user, healthProfile, currentAirQuality, historicalData,
    );
    
    final immuneScore = await _calculateImmuneScore(
      user, healthProfile, currentAirQuality, historicalData,
    );
    
    final activityImpactScore = await _calculateActivityImpactScore(
      user, healthProfile, currentAirQuality, historicalData,
    );

    // Calculate overall weighted score
    final overallScore = _calculateOverallScore(
      respiratoryScore,
      cardiovascularScore,
      immuneScore,
      activityImpactScore,
      currentAirQuality,
    );

    // Determine risk level and category
    final riskLevel = _calculateRiskLevel(overallScore, healthProfile);
    final riskCategory = _determineRiskCategory(riskLevel);

    // Generate contributing factors breakdown
    final contributingFactors = _analyzeContributingFactors(
      user, healthProfile, currentAirQuality, overallScore,
    );

    // Generate personalized recommendations
    final recommendations = await _generateRecommendations(
      overallScore,
      riskCategory,
      respiratoryScore,
      cardiovascularScore,
      immuneScore,
      activityImpactScore,
      user,
      healthProfile,
      currentAirQuality,
    );

    return HealthScoreData(
      id: _uuid.v4(),
      userId: userId,
      overallScore: overallScore.round(),
      respiratoryScore: respiratoryScore.round(),
      cardiovascularScore: cardiovascularScore.round(),
      immuneScore: immuneScore.round(),
      activityImpactScore: activityImpactScore.round(),
      riskLevel: riskLevel,
      riskCategory: riskCategory,
      contributingFactors: contributingFactors,
      recommendations: recommendations,
      timestamp: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 2)), // Expires in 2 hours
    );
  }

  /// Calculate respiratory health impact score
  Future<double> _calculateRespiratoryScore(
    UserProfile user,
    HealthProfile healthProfile,
    AirQualityData airQuality,
    List<AirQualityData>? historicalData,
  ) async {
    
    // Base score starts at 100
    double score = 100.0;

    // PM2.5 impact (primary respiratory pollutant)
    final pm25Impact = _calculatePM25Impact(airQuality.pm25);
    score -= pm25Impact * 30; // Up to 30 point deduction

    // AQI impact
    final aqiImpact = _calculateAQIImpact(airQuality.aqi);
    score -= aqiImpact * 25; // Up to 25 point deduction

    // User vulnerability factors
    final ageVulnerability = _calculateAgeVulnerability(user.age);
    final conditionVulnerability = _calculateRespiratoryConditionVulnerability(
      healthProfile.respiratoryConditions,
    );
    final activityVulnerability = _calculateActivityVulnerability(user.activityLevel);

    score -= (ageVulnerability + conditionVulnerability + activityVulnerability) * 20;

    // Exposure time factor
    if (historicalData != null) {
      final exposureTimeImpact = _calculateExposureTimeImpact(historicalData, 24);
      score -= exposureTimeImpact * 15;
    }

    return math.max(0.0, math.min(100.0, score));
  }

  /// Calculate cardiovascular health impact score  
  Future<double> _calculateCardiovascularScore(
    UserProfile user,
    HealthProfile healthProfile,
    AirQualityData airQuality,
    List<AirQualityData>? historicalData,
  ) async {
    
    double score = 100.0;

    // PM2.5 cardiovascular impact (stronger than other pollutants)
    final pm25CardiovascularImpact = airQuality.pm25 * 1.2; // 20% higher impact
    final pm25Impact = _calculatePM25Impact(pm25CardiovascularImpact);
    score -= pm25Impact * 35; // Higher deduction for cardiovascular

    // NO2 impact (particularly affects cardiovascular health)
    final no2Impact = _calculateNO2Impact(airQuality.no2);
    score -= no2Impact * 20;

    // Age factor (cardiovascular risk increases significantly with age)
    final ageCardiovascularRisk = _calculateAgeVulnerability(user.age, isCardiovascular: true);
    score -= ageCardiovascularRisk * 25;

    // BMI impact on cardiovascular health
    final bmiImpact = _calculateBMIImpact(user.bmi);
    score -= bmiImpact * 15;

    // Cardiovascular conditions
    final cardiovascularConditionImpact = _calculateCardiovascularConditionVulnerability(
      healthProfile.cardiovascularConditions,
    );
    score -= cardiovascularConditionImpact * 20;

    return math.max(0.0, math.min(100.0, score));
  }

  /// Calculate immune system impact score
  Future<double> _calculateImmuneScore(
    UserProfile user,
    HealthProfile healthProfile,
    AirQualityData airQuality,
    List<AirQualityData>? historicalData,
  ) async {
    
    double score = 100.0;

    // Multiple pollutant impact on immune system
    final pollutantLoad = (airQuality.pm25 + airQuality.pm10 + airQuality.no2 + airQuality.o3) / 4;
    final immuneImpact = _calculatePollutantImpact(pollutantLoad);
    score -= immuneImpact * 25;

    // Age immune system factor
    final ageImmuneImpact = _calculateAgeVulnerability(user.age, isImmune: true);
    score -= ageImmuneImpact * 30;

    // Overall health conditions impact
    final generalConditionImpact = _calculateGeneralHealthImpact(healthProfile);
    score -= generalConditionImpact * 20;

    // Activity level (exercise boosts immune system)
    final activityImmuneImpact = _calculateActivityImmuneImpact(user.activityLevel);
    score -= activityImmuneImpact * 15;

    // Historical exposure (long-term immune system impact)
    if (historicalData != null) {
      final longTermExposureImpact = _calculateLongTermExposureImpact(historicalData);
      score -= longTermExposureImpact * 20;
    }

    return math.max(0.0, math.min(100.0, score));
  }

  /// Calculate impact on daily activities score
  Future<double> _calculateActivityImpactScore(
    UserProfile user,
    HealthProfile healthProfile,
    AirQualityData airQuality,
    List<AirQualityData>? historicalData,
  ) async {
    
    double score = 100.0;

    // Current air quality impact on outdoor activities
    final outdoorActivityImpact = _calculateOutdoorActivityImpact(airQuality.aqi);
    score -= outdoorActivityImpact * 40;

    // Air quality impact on exercise capacity
    final exerciseImpact = _calculateExerciseImpact(airQuality.aqi, user.activityLevel);
    score -= exerciseImpact * 30;

    // Sensitivity to air quality changes
    final sensitivityScore = _calculateSensitivityScore(user, healthProfile);
    score -= sensitivityScore * 20;

    // Location-based activity restrictions
    final locationRestrictionImpact = _calculateLocationRestrictionImpact(airQuality);
    score -= locationRestrictionImpact * 15;

    return math.max(0.0, math.min(100.0, score));
  }

  /// Calculate overall weighted health score
  double _calculateOverallScore(
    double respiratoryScore,
    double cardiovascularScore,
    double immuneScore,
    double activityImpactScore,
    AirQualityData airQuality,
  ) {
    
    // Base score calculation with equal weighting
    double baseScore = (respiratoryScore + cardiovascularScore + immuneScore + activityImpactScore) / 4;

    // Adjust for real-time air quality severity
    final aqiSeverityAdjustment = _calculateRealTimeAdjustment(airQuality.aqi);
    final adjustedScore = baseScore * (1.0 + aqiSeverityAdjustment);

    return math.max(0.0, math.min(100.0, adjustedScore));
  }

  // Helper methods for specific impact calculations

  double _calculatePM25Impact(double pm25) {
    if (pm25 <= 12) return 0.0; // WHO guideline
    if (pm25 <= 35) return (pm25 - 12) * 0.5;
    if (pm25 <= 55) return 12.0 + (pm25 - 35) * 1.0;
    if (pm25 <= 150) return 32.0 + (pm25 - 55) * 0.8;
    return 120.0 + math.min(pm25 - 150, 100) * 0.5;
  }

  double _calculateAQIImpact(double aqi) {
    if (aqi <= 50) return 0.0; // Good
    if (aqi <= 100) return (aqi - 50) * 0.3; // Moderate
    if (aqi <= 150) return 15.0 + (aqi - 100) * 0.5; // Unhealthy for sensitive
    if (aqi <= 200) return 40.0 + (aqi - 150) * 0.8; // Unhealthy
    if (aqi <= 300) return 80.0 + (aqi - 200) * 1.0; // Very unhealthy
    return 180.0 + math.min(aqi - 300, 100) * 0.5; // Hazardous
  }

  double _calculateNO2Impact(double no2) {
    if (no2 <= 40) return 0.0;
    return (no2 - 40) * 0.8;
  }

  double _calculateAgeVulnerability(int age, {bool? isCardiovascular, bool? isImmune}) {
    double multiplier = 1.0;
    
    if (isCardiovascular == true) {
      multiplier = 1.5; // Higher cardiovascular risk with age
    } else if (isImmune == true) {
      multiplier = 1.3; // Higher immune system impact
    }

    if (age < 18) return 5.0 * multiplier; // Children more vulnerable
    if (age < 30) return 2.0 * multiplier;
    if (age < 50) return 5.0 * multiplier;
    if (age < 65) return 10.0 * multiplier;
    return 20.0 * multiplier; // Elderly most vulnerable
  }

  double _calculateRespiratoryConditionVulnerability(String conditions) {
    final conditionLower = conditions.toLowerCase();
    if (conditionLower.contains('asthma')) return 25.0;
    if (conditionLower.contains('copd')) return 30.0;
    if (conditionLower.contains('bronchitis')) return 20.0;
    if (conditionLower.contains('pneumonia')) return 15.0;
    return 0.0;
  }

  double _calculateCardiovascularConditionVulnerability(String conditions) {
    final conditionLower = conditions.toLowerCase();
    if (conditionLower.contains('hypertension')) return 20.0;
    if (conditionLower.contains('heart disease')) return 30.0;
    if (conditionLower.contains('stroke')) return 25.0;
    if (conditionLower.contains('arrhythmia')) return 15.0;
    return 0.0;
  }

  double _calculateActivityVulnerability(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 10.0;
      case 'light':
        return 5.0;
      case 'moderate':
        return 2.0;
      case 'active':
        return 0.0;
      case 'very active':
        return -5.0; // Protective factor
      default:
        return 0.0;
    }
  }

  double _calculateBMIImpact(double bmi) {
    if (bmi < 18.5) return 5.0; // Underweight
    if (bmi <= 24.9) return 0.0; // Normal
    if (bmi <= 29.9) return 8.0; // Overweight
    return 15.0; // Obese
  }

  double _calculateGeneralHealthImpact(HealthProfile healthProfile) {
    double impact = 0.0;
    
    if (healthProfile.riskLevel.toLowerCase() == 'high') impact += 15.0;
    else if (healthProfile.riskLevel.toLowerCase() == 'medium') impact += 8.0;
    else if (healthProfile.riskLevel.toLowerCase() == 'low') impact += 3.0;
    
    return impact;
  }

  double _calculateActivityImmuneImpact(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 10.0;
      case 'light':
        return 5.0;
      case 'moderate':
        return 0.0;
      case 'active':
        return -8.0; // Protective
      case 'very active':
        return -15.0; // Strong protective
      default:
        return 0.0;
    }
  }

  double _calculateExposureTimeImpact(List<AirQualityData> data, int hours) {
    if (data.isEmpty) return 0.0;
    
    final recentData = data.where((d) => 
      d.timestamp.isAfter(DateTime.now().subtract(Duration(hours: hours)))).toList();
    
    if (recentData.isEmpty) return 0.0;
    
    final averageAQI = recentData.fold(0.0, (sum, d) => sum + d.aqi) / recentData.length;
    return _calculateAQIImpact(averageAQI) * 0.5;
  }

  double _calculateLongTermExposureImpact(List<AirQualityData> data) {
    if (data.length < 10) return 0.0;
    
    final weeklyData = <double>[];
    DateTime weekStart = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final dayStart = weekStart.subtract(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayData = data.where((d) => 
        d.timestamp.isAfter(dayStart) && d.timestamp.isBefore(dayEnd)).toList();
      
      if (dayData.isNotEmpty) {
        final dayAQI = dayData.fold(0.0, (sum, d) => sum + d.aqi) / dayData.length;
        weeklyData.add(dayAQI);
      }
    }
    
    if (weeklyData.isEmpty) return 0.0;
    
    final weeklyAverage = weeklyData.reduce((a, b) => a + b) / weeklyData.length;
    return _calculateAQIImpact(weeklyAverage) * 0.3;
  }

  double _calculateOutdoorActivityImpact(double aqi) {
    if (aqi <= 50) return 0.0; // No restriction
    if (aqi <= 100) return 5.0; // Minor restriction
    if (aqi <= 150) return 15.0; // Moderate restriction
    if (aqi <= 200) return 30.0; // Significant restriction
    return 50.0; // Major restriction
  }

  double _calculateExerciseImpact(double aqi, String activityLevel) {
    final baseImpact = _calculateOutdoorActivityImpact(aqi);
    final activityMultiplier = activityLevel.toLowerCase() == 'very active' ? 1.5 : 1.0;
    return baseImpact * activityMultiplier;
  }

  double _calculateSensitivityScore(UserProfile user, HealthProfile healthProfile) {
    double sensitivity = 0.0;
    
    // Age sensitivity
    if (user.age < 18 || user.age > 65) sensitivity += 10.0;
    
    // Health condition sensitivity
    if (healthProfile.respiratoryConditions.isNotEmpty) sensitivity += 15.0;
    if (healthProfile.cardiovascularConditions.isNotEmpty) sensitivity += 10.0;
    
    return sensitivity;
  }

  double _calculateLocationRestrictionImpact(AirQualityData airQuality) {
    return _calculateOutdoorActivityImpact(airQuality.aqi) * 0.3;
  }

  double _calculateRealTimeAdjustment(double aqi) {
    if (aqi > 200) return -0.1; // Penalty for very poor air
    if (aqi > 150) return -0.05;
    if (aqi < 50) return 0.05; // Bonus for good air
    return 0.0;
  }

  double _calculatePollutantImpact(double pollutantLoad) {
    if (pollutantLoad <= 20) return 0.0;
    if (pollutantLoad <= 50) return (pollutantLoad - 20) * 0.4;
    if (pollutantLoad <= 100) return 12.0 + (pollutantLoad - 50) * 0.6;
    return 42.0 + math.min(pollutantLoad - 100, 50) * 0.4;
  }

  /// Calculate risk level (0-1 scale)
  double _calculateRiskLevel(double overallScore, HealthProfile healthProfile) {
    double baseRisk = (100.0 - overallScore) / 100.0;
    
    // Adjust based on health profile
    switch (healthProfile.riskLevel.toLowerCase()) {
      case 'high':
        return math.min(1.0, baseRisk * 1.3);
      case 'medium':
        return baseRisk;
      case 'low':
        return baseRisk * 0.8;
      default:
        return baseRisk;
    }
  }

  /// Determine risk category from risk level
  String _determineRiskCategory(double riskLevel) {
    if (riskLevel >= 0.8) return 'Critical';
    if (riskLevel >= 0.6) return 'High';
    if (riskLevel >= 0.3) return 'Medium';
    return 'Low';
  }

  /// Analyze what factors contribute to the health score
  Map<String, dynamic> _analyzeContributingFactors(
    UserProfile user,
    HealthProfile healthProfile,
    AirQualityData airQuality,
    double overallScore,
  ) {
    final factors = <String, dynamic>{};

    // Air quality factors
    factors['air_quality'] = {
      'aqi': airQuality.aqi,
      'pm25': airQuality.pm25,
      'primary_concern': _getPrimaryPollutantConcern(airQuality),
      'trend': _analyzeAirQualityTrend(airQuality),
    };

    // User vulnerability factors
    factors['vulnerability'] = {
      'age_factor': _calculateAgeVulnerability(user.age),
      'bmi_factor': _calculateBMIImpact(user.bmi),
      'activity_factor': _calculateActivityVulnerability(user.activityLevel),
      'health_conditions': {
        'respiratory': healthProfile.respiratoryConditions,
        'cardiovascular': healthProfile.cardiovascularConditions,
        'overall_risk': healthProfile.riskLevel,
      },
    };

    // Protective factors
    factors['protective_factors'] = {
      'activity_level': user.activityLevel,
      'age_group': _getAgeGroup(user.age),
      'baseline_health': healthProfile.baselineLungCapacity,
    };

    return factors;
  }

  String _getPrimaryPollutantConcern(AirQualityData airQuality) {
    final pollutants = {
      'PM2.5': airQuality.pm25,
      'AQI': airQuality.aqi,
      'PM10': airQuality.pm10,
      'NO2': airQuality.no2,
      'O3': airQuality.o3,
    };

    String maxPollutant = 'PM2.5';
    double maxValue = airQuality.pm25;

    pollutants.forEach((pollutant, value) {
      if (value > maxValue) {
        maxPollutant = pollutant;
        maxValue = value;
      }
    });

    return maxPollutant;
  }

  String _analyzeAirQualityTrend(AirQualityData airQuality) {
    if (airQuality.aqi > 150) return 'Poor and worsening';
    if (airQuality.aqi > 100) return 'Moderate and concerning';
    if (airQuality.aqi > 50) return 'Acceptable but watch';
    return 'Good conditions';
  }

  String _getAgeGroup(int age) {
    if (age < 18) return 'Child/Youth';
    if (age < 30) return 'Young Adult';
    if (age < 50) return 'Adult';
    if (age < 65) return 'Middle Age';
    return 'Senior';
  }

  /// Generate personalized health recommendations
  Future<List<HealthRecommendation>> _generateRecommendations(
    double overallScore,
    String riskCategory,
    double respiratoryScore,
    double cardiovascularScore,
    double immuneScore,
    double activityImpactScore,
    UserProfile user,
    HealthProfile healthProfile,
    AirQualityData airQuality,
  ) async {
    
    final recommendations = <HealthRecommendation>[];
    
    // Critical recommendations for high-risk situations
    if (riskCategory == 'Critical' || overallScore < 30) {
      recommendations.add(HealthRecommendation(
        id: _uuid.v4(),
        type: 'Medical',
        priority: 'Critical',
        title: 'Seek Medical Attention',
        description: 'Current air quality poses significant health risks. Consider consulting a healthcare provider.',
        actions: [
          'Limit outdoor activities',
          'Use air purifiers indoors',
          'Wear N95 masks if going outside',
          'Monitor symptoms closely'
        ],
        category: 'Emergency',
        isUrgent: true,
        createdAt: DateTime.now(),
      ));
    }

    // Respiratory-specific recommendations
    if (respiratoryScore < 60) {
      recommendations.add(HealthRecommendation(
        id: _uuid.v4(),
        type: 'Respiratory',
        priority: riskCategory == 'Critical' ? 'Critical' : 'High',
        title: 'Protect Your Respiratory Health',
        description: 'Air quality is affecting your breathing health. Take protective measures.',
        actions: [
          'Keep windows closed during high pollution periods',
          'Use HEPA air filters at home',
          'Consider respiratory protection for outdoor activities',
          'Monitor breathing patterns and symptoms'
        ],
        category: 'Respiratory',
        isUrgent: riskCategory == 'Critical',
        createdAt: DateTime.now(),
      ));
    }

    // Activity recommendations
    if (activityImpactScore < 50) {
      recommendations.add(HealthRecommendation(
        id: _uuid.v4(),
        type: 'Activity',
        priority: 'Medium',
        title: 'Adjust Your Activity Schedule',
        description: 'Consider indoor alternatives to outdoor activities due to air quality.',
        actions: [
          'Move exercise indoors during poor air days',
          'Choose less polluted routes for outdoor activities',
          'Exercise during early morning or evening hours',
          'Use air quality apps to plan activities'
        ],
        category: 'Lifestyle',
        isUrgent: false,
        createdAt: DateTime.now(),
      ));
    }

    // Indoor air quality recommendations
    if (airQuality.aqi > 100) {
      recommendations.add(HealthRecommendation(
        id: _uuid.v4(),
        type: 'Indoor',
        priority: 'Medium',
        title: 'Improve Indoor Air Quality',
        description: 'Protect yourself indoors by improving air filtration.',
        actions: [
          'Keep windows and doors closed',
          'Use air purifiers with HEPA filters',
          'Avoid indoor air pollution sources',
          'Monitor indoor air quality with sensors'
        ],
        category: 'Indoor',
        isUrgent: false,
        createdAt: DateTime.now(),
      ));
    }

    // Lifestyle recommendations for long-term health
    if (user.activityLevel.toLowerCase() == 'sedentary') {
      recommendations.add(HealthRecommendation(
        id: _uuid.v4(),
        type: 'Lifestyle',
        priority: 'Low',
        title: 'Increase Physical Activity',
        description: 'Regular exercise can improve your resilience to air pollution.',
        actions: [
          'Start with light indoor exercises',
          'Use air quality data to plan outdoor activities',
          'Consider yoga or tai chi for gentle exercise',
          'Gradually increase activity level over time'
        ],
        category: 'Lifestyle',
        isUrgent: false,
        createdAt: DateTime.now(),
      ));
    }

    return recommendations;
  }

  /// Get health score trend over time
  Future<List<HealthScoreHistory>> getHealthScoreTrend({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // This would integrate with local storage or API to get historical data
    // For now, return empty list - implementation would fetch from database
    return [];
  }

  /// Check if current health score needs updating
  bool isHealthScoreStale(HealthScoreData? currentScore) {
    if (currentScore == null) return true;
    return DateTime.now().isAfter(currentScore.expiresAt);
  }
}
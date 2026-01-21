import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/user_profile.dart';
import '../../models/health_profile.dart';
import '../../models/air_quality_data.dart';
import '../../models/health_score_data.dart';
import '../services/health_score_service.dart';
import '../services/location_service.dart';
import '../services/air_quality_service.dart';
import '../services/storage_service.dart';

/// ViewModel for managing Health Score state and business logic
/// Uses Provider pattern for reactive state management
class HealthScoreViewModel extends ChangeNotifier {
  static const Uuid _uuid = Uuid();
  
  // Core services
  late final HealthScoreService _healthScoreService;
  late final LocationService _locationService;
  late final AirQualityService _airQualityService;
  late final StorageService _storageService;

  // State
  HealthScoreData? _currentScore;
  List<HealthScoreHistory> _scoreHistory = [];
  UserProfile? _userProfile;
  HealthProfile? _healthProfile;
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  // Computed state
  bool get hasValidScore => _currentScore != null && !_healthScoreService.isHealthScoreStale(_currentScore);
  bool get isLoading => _isLoading;
  String? get error => _error;
  HealthScoreData? get currentScore => _currentScore;
  List<HealthScoreHistory> get scoreHistory => _scoreHistory;
  UserProfile? get userProfile => _userProfile;
  HealthProfile? get healthProfile => _healthProfile;

  // Computed properties
  String get healthStatus {
    if (_currentScore == null) return 'Unknown';
    
    if (_currentScore!.overallScore >= 80) return 'Excellent';
    if (_currentScore!.overallScore >= 65) return 'Good';
    if (_currentScore!.overallScore >= 50) return 'Fair';
    if (_currentScore!.overallScore >= 35) return 'Poor';
    return 'Critical';
  }

  Color get healthStatusColor {
    switch (healthStatus) {
      case 'Excellent':
        return const Color(0xFF28A745);
      case 'Good':
        return const Color(0xFF20C997);
      case 'Fair':
        return const Color(0xFFFFC107);
      case 'Poor':
        return const Color(0xFFFF9800);
      case 'Critical':
        return const Color(0xFFDC3545);
      default:
        return const Color(0xFF6C757D);
    }
  }

  String get riskLevelDescription {
    if (_currentScore == null) return '';
    
    switch (_currentScore!.riskCategory.toLowerCase()) {
      case 'low':
        return 'Low risk - Continue normal activities with standard precautions';
      case 'medium':
        return 'Medium risk - Consider limiting prolonged outdoor exposure';
      case 'high':
        return 'High risk - Reduce outdoor activities and use protective measures';
      case 'critical':
        return 'Critical risk - Seek medical advice and minimize outdoor exposure';
      default:
        return 'Risk assessment unavailable';
    }
  }

  List<HealthRecommendation> get urgentRecommendations {
    if (_currentScore == null) return [];
    return _currentScore!.recommendations
        .where((rec) => rec.isUrgent || rec.priority == 'Critical')
        .toList();
  }

  List<HealthRecommendation> get generalRecommendations {
    if (_currentScore == null) return [];
    return _currentScore!.recommendations
        .where((rec) => !rec.isUrgent && rec.priority != 'Critical')
        .toList();
  }

  /// Initialize the ViewModel with required services
  void initialize({
    HealthScoreService? healthScoreService,
    LocationService? locationService,
    AirQualityService? airQualityService,
    StorageService? storageService,
  }) {
    _healthScoreService = healthScoreService ?? HealthScoreService();
    _locationService = locationService ?? LocationService();
    _airQualityService = airQualityService ?? AirQualityService();
    _storageService = storageService ?? StorageService();
    
    // Start periodic refresh for real-time updates
    _startPeriodicRefresh();
  }

  /// Load user profile and health profile data
  Future<void> loadUserData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load user profile
      final userProfileJson = await _storageService.getUserProfile();
      if (userProfileJson != null) {
        _userProfile = UserProfile.fromJson(userProfileJson);
      }

      // Load health profile
      final healthProfileJson = await _storageService.getHealthProfile();
      if (healthProfileJson != null) {
        _healthProfile = HealthProfile.fromJson(healthProfileJson);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load user data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate and update health score
  Future<bool> calculateHealthScore({bool forceRefresh = false}) async {
    try {
      if (_userProfile == null || _healthProfile == null) {
        await loadUserData();
      }

      if (_userProfile == null || _healthProfile == null) {
        _error = 'User profile data not available';
        notifyListeners();
        return false;
      }

      // Check if we need to calculate a new score
      if (!forceRefresh && hasValidScore) {
        return true; // Current score is still valid
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current location
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        throw Exception('Location not available');
      }

      // Get current air quality data
      final airQualityData = await _airQualityService.getCurrentAirQuality(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (airQualityData == null) {
        throw Exception('Air quality data not available');
      }

      // Get historical air quality data for trend analysis
      final historicalData = await _airQualityService.getHistoricalAirQuality(
        latitude: location.latitude,
        longitude: location.longitude,
        hours: 24,
      );

      // Calculate health score
      final healthScore = await _healthScoreService.calculateHealthScore(
        userId: _userProfile!.id,
        user: _userProfile!,
        healthProfile: _healthProfile!,
        currentAirQuality: airQualityData,
        historicalData: historicalData,
      );

      // Save to storage
      await _storageService.saveHealthScore(healthScore);

      // Update state
      _currentScore = healthScore;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to calculate health score: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load health score from storage
  Future<void> loadHealthScore() async {
    try {
      final savedScore = await _storageService.getHealthScore();
      if (savedScore != null && !_healthScoreService.isHealthScoreStale(savedScore)) {
        _currentScore = savedScore;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load health score: ${e.toString()}');
    }
  }

  /// Load health score history
  Future<void> loadHealthScoreHistory() async {
    try {
      final history = await _healthScoreService.getHealthScoreTrend(
        userId: _userProfile?.id ?? '',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );
      
      _scoreHistory = history;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load health score history: ${e.toString()}');
    }
  }

  /// Refresh health score with current data
  Future<void> refreshHealthScore() async {
    await calculateHealthScore(forceRefresh: true);
  }

  /// Mark a recommendation as dismissed
  Future<void> dismissRecommendation(String recommendationId) async {
    try {
      if (_currentScore != null) {
        // Update the recommendation in the current score
        final updatedRecommendations = _currentScore!.recommendations
            .where((rec) => rec.id != recommendationId)
            .toList();

        final updatedScore = _currentScore!.copyWith(
          recommendations: updatedRecommendations,
        );

        // Save updated score
        await _storageService.saveHealthScore(updatedScore);
        _currentScore = updatedScore;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to dismiss recommendation: ${e.toString()}');
    }
  }

  /// Mark a recommendation as completed
  Future<void> completeRecommendation(String recommendationId) async {
    try {
      if (_currentScore != null) {
        // Update the recommendation status
        final updatedRecommendations = _currentScore!.recommendations.map((rec) {
          if (rec.id == recommendationId) {
            return rec.copyWith(
              // Add completion status to the actions list
              actions: [...rec.actions, 'Completed - ${DateTime.now().toIso8601String()}'],
            );
          }
          return rec;
        }).toList();

        final updatedScore = _currentScore!.copyWith(
          recommendations: updatedRecommendations,
        );

        // Save updated score
        await _storageService.saveHealthScore(updatedScore);
        _currentScore = updatedScore;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to complete recommendation: ${e.toString()}');
    }
  }

  /// Start periodic refresh timer
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    
    // Refresh every 15 minutes
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (timer) {
        if (!isLoading && hasValidScore) {
          // Only refresh if current data is getting stale
          calculateHealthScore();
        }
      },
    );
  }

  /// Stop periodic refresh
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Check if specific health area needs attention
  bool needsAttention(HealthScoreType scoreType) {
    if (_currentScore == null) return false;

    switch (scoreType) {
      case HealthScoreType.respiratory:
        return _currentScore!.respiratoryScore < 60;
      case HealthScoreType.cardiovascular:
        return _currentScore!.cardiovascularScore < 60;
      case HealthScoreType.immune:
        return _currentScore!.immuneScore < 60;
      case HealthScoreType.activity:
        return _currentScore!.activityImpactScore < 60;
      case HealthScoreType.overall:
        return _currentScore!.overallScore < 60;
    }
  }

  /// Get personalized tips based on current health score
  List<String> getPersonalizedTips() {
    if (_currentScore == null) return [];

    final tips = <String>[];

    // Air quality based tips
    if (_currentScore!.overallScore < 50) {
      tips.add('Consider wearing an N95 mask when outdoors');
      tips.add('Keep windows closed and use air purifiers indoors');
    }

    // Activity based tips
    if (_currentScore!.activityImpactScore < 60) {
      tips.add('Move exercise indoors during poor air quality days');
      tips.add('Choose early morning or evening for outdoor activities');
    }

    // Respiratory tips
    if (_currentScore!.respiratoryScore < 60) {
      tips.add('Monitor your breathing and respiratory symptoms');
      tips.add('Consider consulting a pulmonologist if symptoms worsen');
    }

    // General health tips
    if (userProfile?.activityLevel == 'sedentary') {
      tips.add('Regular indoor exercise can improve your resilience to air pollution');
    }

    return tips;
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Extension to add copyWith method to HealthRecommendation
extension HealthRecommendationExtension on HealthRecommendation {
  HealthRecommendation copyWith({
    String? id,
    String? type,
    String? priority,
    String? title,
    String? description,
    List<String>? actions,
    String? category,
    bool? isUrgent,
    DateTime? createdAt,
  }) {
    return HealthRecommendation(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      actions: actions ?? this.actions,
      category: category ?? this.category,
      isUrgent: isUrgent ?? this.isUrgent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
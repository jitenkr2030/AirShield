part of 'health_score_bloc.dart';

/// States for Health Score BLoC
abstract class HealthScoreState extends Equatable {
  const HealthScoreState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no data loaded
class HealthScoreInitial extends HealthScoreState {}

/// Loading state - health score calculation in progress
class HealthScoreLoading extends HealthScoreState {}

/// Success state - health score calculated successfully
class HealthScoreSuccess extends HealthScoreState {
  final HealthScoreData healthScore;
  final List<HealthScoreHistory> scoreHistory;
  final AirQualityData airQualityData;
  final UserProfile userProfile;
  final HealthProfile healthProfile;

  const HealthScoreSuccess({
    required this.healthScore,
    this.scoreHistory = const [],
    required this.airQualityData,
    required this.userProfile,
    required this.healthProfile,
  });

  @override
  List<Object> get props => [
    healthScore,
    scoreHistory,
    airQualityData,
    userProfile,
    healthProfile,
  ];

  /// Create a copy with updated values
  HealthScoreSuccess copyWith({
    HealthScoreData? healthScore,
    List<HealthScoreHistory>? scoreHistory,
    AirQualityData? airQualityData,
    UserProfile? userProfile,
    HealthProfile? healthProfile,
  }) {
    return HealthScoreSuccess(
      healthScore: healthScore ?? this.healthScore,
      scoreHistory: scoreHistory ?? this.scoreHistory,
      airQualityData: airQualityData ?? this.airQualityData,
      userProfile: userProfile ?? this.userProfile,
      healthProfile: healthProfile ?? this.healthProfile,
    );
  }

  /// Get specific score by type
  int getScore(HealthScoreType scoreType) {
    switch (scoreType) {
      case HealthScoreType.overall:
        return healthScore.overallScore;
      case HealthScoreType.respiratory:
        return healthScore.respiratoryScore;
      case HealthScoreType.cardiovascular:
        return healthScore.cardiovascularScore;
      case HealthScoreType.immune:
        return healthScore.immuneScore;
      case HealthScoreType.activity:
        return healthScore.activityImpactScore;
    }
  }

  /// Check if any score component needs attention
  bool needsAttention(HealthScoreType scoreType) {
    final score = getScore(scoreType);
    return score < 60; // Threshold for concern
  }

  /// Get all scores that need attention
  List<HealthScoreType> getScoresNeedingAttention() {
    return HealthScoreType.values
        .where((type) => needsAttention(type))
        .toList();
  }

  /// Get color for specific score
  String getScoreColor(HealthScoreType scoreType) {
    final score = getScore(scoreType);
    
    if (score >= 80) return '#28A745'; // Green - Excellent
    if (score >= 65) return '#20C997'; // Teal - Good
    if (score >= 50) return '#FFC107'; // Yellow - Fair
    if (score >= 35) return '#FF9800'; // Orange - Poor
    return '#DC3545'; // Red - Critical
  }

  /// Get display text for score level
  String getScoreLevelText(HealthScoreType scoreType) {
    final score = getScore(scoreType);
    
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 35) return 'Poor';
    return 'Critical';
  }

  /// Get urgent recommendations
  List<HealthRecommendation> getUrgentRecommendations() {
    return healthScore.recommendations
        .where((rec) => rec.isUrgent || rec.priority == 'Critical')
        .toList();
  }

  /// Get recommendations by type
  List<HealthRecommendation> getRecommendationsByType(String type) {
    return healthScore.recommendations
        .where((rec) => rec.type.toLowerCase() == type.toLowerCase())
        .toList();
  }

  /// Get recommendations by priority
  List<HealthRecommendation> getRecommendationsByPriority(String priority) {
    return healthScore.recommendations
        .where((rec) => rec.priority.toLowerCase() == priority.toLowerCase())
        .toList();
  }
}

/// Failure state - error occurred during health score calculation
class HealthScoreFailure extends HealthScoreState {
  final String error;
  final HealthScoreData? previousScore;

  const HealthScoreFailure({
    required this.error,
    this.previousScore,
  });

  @override
  List<Object?> get props => [error, previousScore];
}

/// Error state - error occurred but maintaining current data
class HealthScoreErrorState extends HealthScoreState {
  final String error;
  final HealthScoreData? currentScore;

  const HealthScoreErrorState({
    required this.error,
    this.currentScore,
  });

  @override
  List<Object?> get props => [error, currentScore];
}

/// Monitoring state - actively monitoring for updates
class HealthScoreMonitoring extends HealthScoreState {
  final HealthScoreData currentScore;
  final bool isConnected;
  final DateTime lastUpdate;

  const HealthScoreMonitoring({
    required this.currentScore,
    this.isConnected = true,
    required this.lastUpdate,
  });

  @override
  List<Object> get props => [
    currentScore,
    isConnected,
    lastUpdate,
  ];

  /// Check if data is stale
  bool get isDataStale {
    final now = DateTime.now();
    final timeSinceUpdate = now.difference(lastUpdate);
    return timeSinceUpdate.inMinutes > 15; // Consider stale after 15 minutes
  }

  /// Get monitoring status description
  String get statusDescription {
    if (!isConnected) return 'Connection lost';
    if (isDataStale) return 'Data may be outdated';
    return 'Actively monitoring';
  }
}

/// Historical data state - showing historical health score trends
class HealthScoreHistory extends HealthScoreState {
  final List<HealthScoreData> historicalScores;
  final DateTime startDate;
  final DateTime endDate;
  final Map<HealthScoreType, List<HealthScoreHistory>> scoreTrends;
  final double averageOverallScore;
  final double improvementRate;

  const HealthScoreHistory({
    required this.historicalScores,
    required this.startDate,
    required this.endDate,
    this.scoreTrends = const {},
    this.averageOverallScore = 0.0,
    this.improvementRate = 0.0,
  });

  @override
  List<Object> get props => [
    historicalScores,
    startDate,
    endDate,
    scoreTrends,
    averageOverallScore,
    improvementRate,
  ];

  /// Get scores for a specific date range
  List<HealthScoreData> getScoresInRange(DateTime start, DateTime end) {
    return historicalScores
        .where((score) => 
            score.timestamp.isAfter(start) && score.timestamp.isBefore(end))
        .toList();
  }

  /// Calculate trend direction for a score type
  String getTrendDirection(HealthScoreType scoreType) {
    if (historicalScores.length < 2) return 'Insufficient data';
    
    final sortedScores = historicalScores.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final firstScore = _getScoreFromData(sortedScores.first, scoreType);
    final lastScore = _getScoreFromData(sortedScores.last, scoreType);
    
    final difference = lastScore - firstScore;
    
    if (difference > 5) return 'Improving';
    if (difference < -5) return 'Declining';
    return 'Stable';
  }

  int _getScoreFromData(HealthScoreData data, HealthScoreType type) {
    switch (type) {
      case HealthScoreType.overall:
        return data.overallScore;
      case HealthScoreType.respiratory:
        return data.respiratoryScore;
      case HealthScoreType.cardiovascular:
        return data.cardiovascularScore;
      case HealthScoreType.immune:
        return data.immuneScore;
      case HealthScoreType.activity:
        return data.activityImpactScore;
    }
  }
}

/// Notification state - health score triggered notifications
class HealthScoreNotification extends HealthScoreState {
  final HealthScoreData healthScore;
  final String notificationType;
  final String title;
  final String message;
  final Map<String, dynamic> notificationData;
  final DateTime timestamp;

  const HealthScoreNotification({
    required this.healthScore,
    required this.notificationType,
    required this.title,
    required this.message,
    this.notificationData = const {},
    required this.timestamp,
  });

  @override
  List<Object> get props => [
    healthScore,
    notificationType,
    title,
    message,
    notificationData,
    timestamp,
  ];

  /// Get notification priority
  String get priority {
    switch (notificationType) {
      case 'critical_score_drop':
      case 'urgent_recommendation':
        return 'Critical';
      case 'moderate_score_change':
        return 'High';
      case 'recommendation_completed':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  /// Check if notification requires immediate action
  bool get requiresImmediateAction {
    return priority == 'Critical';
  }
}

/// Configuration state - health score settings and preferences
class HealthScoreConfiguration extends HealthScoreState {
  final Map<String, dynamic> userPreferences;
  final Map<String, double> scoreWeights;
  final List<String> notificationTriggers;
  final bool isMonitoringEnabled;
  final int refreshIntervalMinutes;

  const HealthScoreConfiguration({
    this.userPreferences = const {},
    this.scoreWeights = const {
      'air_quality': 0.35,
      'user_vulnerability': 0.30,
      'exposure_time': 0.20,
      'activity_level': 0.15,
    },
    this.notificationTriggers = const [
      'critical_score_drop',
      'risk_category_change',
      'urgent_recommendation',
    ],
    this.isMonitoringEnabled = true,
    this.refreshIntervalMinutes = 15,
  });

  @override
  List<Object> get props => [
    userPreferences,
    scoreWeights,
    notificationTriggers,
    isMonitoringEnabled,
    refreshIntervalMinutes,
  ];

  /// Get weight for specific component
  double getWeightForComponent(String component) {
    return scoreWeights[component] ?? 0.0;
  }

  /// Check if specific trigger is enabled
  bool isTriggerEnabled(String trigger) {
    return notificationTriggers.contains(trigger);
  }
}
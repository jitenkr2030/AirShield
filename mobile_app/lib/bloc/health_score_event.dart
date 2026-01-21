part of 'health_score_bloc.dart';

/// Events for Health Score BLoC
abstract class HealthScoreEvent extends Equatable {
  const HealthScoreEvent();

  @override
  List<Object?> get props => [];
}

/// Request health score calculation
class HealthScoreRequested extends HealthScoreEvent {
  final UserProfile? userProfile;
  final HealthProfile? healthProfile;
  final bool includeHistorical;
  final HealthScoreData? previousScore;
  final Map<String, dynamic>? locationPatterns;

  const HealthScoreRequested({
    this.userProfile,
    this.healthProfile,
    this.includeHistorical = true,
    this.previousScore,
    this.locationPatterns,
  });

  @override
  List<Object?> get props => [
    userProfile,
    healthProfile,
    includeHistorical,
    previousScore,
    locationPatterns,
  ];
}

/// Refresh current health score
class HealthScoreRefreshed extends HealthScoreEvent {
  final Map<String, dynamic>? locationPatterns;

  const HealthScoreRefreshed({
    this.locationPatterns,
  });

  @override
  List<Object?> get props => [locationPatterns];
}

/// Load health score history for specified date range
class HealthScoreHistoryLoaded extends HealthScoreEvent {
  final DateTime startDate;
  final DateTime endDate;

  const HealthScoreHistoryLoaded({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [startDate, endDate];
}

/// Dismiss a health recommendation
class HealthScoreRecommendationDismissed extends HealthScoreEvent {
  final String recommendationId;

  const HealthScoreRecommendationDismissed({
    required this.recommendationId,
  });

  @override
  List<Object> get props => [recommendationId];
}

/// Mark a health recommendation as completed
class HealthScoreRecommendationCompleted extends HealthScoreEvent {
  final String recommendationId;
  final bool shouldRecalculateScore;
  final Map<String, dynamic>? locationPatterns;

  const HealthScoreRecommendationCompleted({
    required this.recommendationId,
    this.shouldRecalculateScore = false,
    this.locationPatterns,
  });

  @override
  List<Object?> get props => [
    recommendationId,
    shouldRecalculateScore,
    locationPatterns,
  ];
}

/// Update health score with external data (e.g., from Photo Analysis)
class HealthScoreDataUpdated extends HealthScoreEvent {
  final Map<String, dynamic> additionalData;

  const HealthScoreDataUpdated({
    required this.additionalData,
  });

  @override
  List<Object> get props => [additionalData];
}

/// Handle health score errors
class HealthScoreError extends HealthScoreEvent {
  final String error;

  const HealthScoreError({
    required this.error,
  });

  @override
  List<Object> get props => [error];
}

/// Initialize health score monitoring
class HealthScoreMonitoringStarted extends HealthScoreEvent {
  const HealthScoreMonitoringStarted();
}

/// Stop health score monitoring
class HealthScoreMonitoringStopped extends HealthScoreEvent {
  const HealthScoreMonitoringStopped();
}
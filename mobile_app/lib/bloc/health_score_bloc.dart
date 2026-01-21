import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/user_profile.dart';
import '../../models/health_profile.dart';
import '../../models/air_quality_data.dart';
import '../../models/health_score_data.dart';
import '../../core/services/health_score_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/air_quality_service.dart';
import '../../core/services/storage_service.dart';

part 'health_score_event.dart';
part 'health_score_state.dart';

/// BLoC for managing Health Score reactive state
/// Integrates with Smart Notifications and Photo Analysis features
class HealthScoreBloc extends Bloc<HealthScoreEvent, HealthScoreState> {
  final HealthScoreService _healthScoreService;
  final LocationService _locationService;
  final AirQualityService _airQualityService;
  final StorageService _storageService;

  StreamSubscription<AirQualityData>? _airQualitySubscription;
  StreamSubscription<UserProfile>? _userProfileSubscription;

  HealthScoreBloc({
    HealthScoreService? healthScoreService,
    LocationService? locationService,
    AirQualityService? airQualityService,
    StorageService? storageService,
  }) : _healthScoreService = healthScoreService ?? HealthScoreService(),
       _locationService = locationService ?? LocationService(),
       _airQualityService = airQualityService ?? AirQualityService(),
       _storageService = storageService ?? StorageService(),
       super(HealthScoreInitial()) {
    on<HealthScoreRequested>(_onHealthScoreRequested);
    on<HealthScoreRefreshed>(_onHealthScoreRefreshed);
    on<HealthScoreHistoryLoaded>(_onHealthScoreHistoryLoaded);
    on<HealthScoreRecommendationDismissed>(_onRecommendationDismissed);
    on<HealthScoreRecommendationCompleted>(_onRecommendationCompleted);
    on<HealthScoreDataUpdated>(_onHealthScoreDataUpdated);
    on<HealthScoreError>(_onHealthScoreError);
  }

  /// Handle health score calculation request
  Future<void> _onHealthScoreRequested(
    HealthScoreRequested event,
    Emitter<HealthScoreState> emit,
  ) async {
    try {
      emit(HealthScoreLoading());

      // Validate required data
      if (event.userProfile == null || event.healthProfile == null) {
        throw Exception('User profile or health profile data missing');
      }

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

      // Get historical data if available
      List<AirQualityData>? historicalData;
      if (event.includeHistorical) {
        historicalData = await _airQualityService.getHistoricalAirQuality(
          latitude: location.latitude,
          longitude: location.longitude,
          hours: 24,
        );
      }

      // Calculate health score
      final healthScore = await _healthScoreService.calculateHealthScore(
        userId: event.userProfile!.id,
        user: event.userProfile!,
        healthProfile: event.healthProfile!,
        currentAirQuality: airQualityData,
        historicalData: historicalData,
        locationPatterns: event.locationPatterns,
      );

      // Save to storage
      await _storageService.saveHealthScore(healthScore);

      // Get score history
      final scoreHistory = await _healthScoreService.getHealthScoreTrend(
        userId: event.userProfile!.id,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );

      emit(HealthScoreSuccess(
        healthScore: healthScore,
        scoreHistory: scoreHistory,
        airQualityData: airQualityData,
      ));

      // Check if we need to trigger notifications based on health score changes
      await _checkNotificationTriggers(healthScore, event.previousScore);

    } catch (e) {
      emit(HealthScoreFailure(error: e.toString()));
    }
  }

  /// Handle health score refresh
  Future<void> _onHealthScoreRefreshed(
    HealthScoreRefreshed event,
    Emitter<HealthScoreState> emit,
  ) async {
    // For refresh, we use the current state data if available
    if (state is HealthScoreSuccess) {
      final currentState = state as HealthScoreSuccess;
      add(HealthScoreRequested(
        userProfile: currentState.userProfile,
        healthProfile: currentState.healthProfile,
        includeHistorical: true,
        previousScore: currentState.healthScore,
        locationPatterns: event.locationPatterns,
      ));
    } else {
      // If no current data, emit error
      emit(HealthScoreFailure(error: 'No current health score data available'));
    }
  }

  /// Handle health score history loading
  Future<void> _onHealthScoreHistoryLoaded(
    HealthScoreHistoryLoaded event,
    Emitter<HealthScoreState> emit,
  ) async {
    try {
      if (state is HealthScoreSuccess) {
        final currentState = state as HealthScoreSuccess;
        
        // Load extended history if not already loaded
        final scoreHistory = await _healthScoreService.getHealthScoreTrend(
          userId: currentState.healthScore.userId,
          startDate: event.startDate,
          endDate: event.endDate,
        );

        emit(currentState.copyWith(scoreHistory: scoreHistory));
      }
    } catch (e) {
      // Emit error state while maintaining current data
      emit(HealthScoreErrorState(
        error: e.toString(),
        currentScore: state is HealthScoreSuccess ? (state as HealthScoreSuccess).healthScore : null,
      ));
    }
  }

  /// Handle recommendation dismissal
  Future<void> _onRecommendationDismissed(
    HealthScoreRecommendationDismissed event,
    Emitter<HealthScoreState> emit,
  ) async {
    try {
      if (state is HealthScoreSuccess) {
        final currentState = state as HealthScoreSuccess;
        
        // Remove the dismissed recommendation
        final updatedRecommendations = currentState.healthScore.recommendations
            .where((rec) => rec.id != event.recommendationId)
            .toList();

        final updatedScore = currentState.healthScore.copyWith(
          recommendations: updatedRecommendations,
        );

        // Save updated score
        await _storageService.saveHealthScore(updatedScore);

        emit(currentState.copyWith(healthScore: updatedScore));

        // Log the dismissal for analytics
        await _trackRecommendationDismissal(event.recommendationId, updatedScore);
      }
    } catch (e) {
      emit(HealthScoreErrorState(
        error: e.toString(),
        currentScore: state is HealthScoreSuccess ? (state as HealthScoreSuccess).healthScore : null,
      ));
    }
  }

  /// Handle recommendation completion
  Future<void> _onRecommendationCompleted(
    HealthScoreRecommendationCompleted event,
    Emitter<HealthScoreState> emit,
  ) async {
    try {
      if (state is HealthScoreSuccess) {
        final currentState = state as HealthScoreSuccess;
        
        // Update the recommendation with completion timestamp
        final updatedRecommendations = currentState.healthScore.recommendations.map((rec) {
          if (rec.id == event.recommendationId) {
            final completedActions = [...rec.actions, 'Completed - ${DateTime.now().toIso8601String()}'];
            return rec.copyWith(actions: completedActions);
          }
          return rec;
        }).toList();

        final updatedScore = currentState.healthScore.copyWith(
          recommendations: updatedRecommendations,
        );

        // Save updated score
        await _storageService.saveHealthScore(updatedScore);

        emit(currentState.copyWith(healthScore: updatedScore));

        // Log the completion for analytics
        await _trackRecommendationCompletion(event.recommendationId, updatedScore);

        // Check if we should recalculate score based on user actions
        if (event.shouldRecalculateScore) {
          await _onHealthScoreRefreshed(
            HealthScoreRefreshed(locationPatterns: event.locationPatterns),
            emit,
          );
        }
      }
    } catch (e) {
      emit(HealthScoreErrorState(
        error: e.toString(),
        currentScore: state is HealthScoreSuccess ? (state as HealthScoreSuccess).healthScore : null,
      ));
    }
  }

  /// Handle external health score data updates (e.g., from Photo Analysis)
  Future<void> _onHealthScoreDataUpdated(
    HealthScoreDataUpdated event,
    Emitter<HealthScoreState> emit,
  ) async {
    try {
      if (state is HealthScoreSuccess) {
        final currentState = state as HealthScoreSuccess;
        
        // Merge new data with existing score
        final updatedScore = currentState.healthScore.copyWith(
          contributingFactors: {
            ...currentState.healthScore.contributingFactors,
            ...event.additionalData,
          },
        );

        emit(currentState.copyWith(healthScore: updatedScore));

        // Save updated score
        await _storageService.saveHealthScore(updatedScore);
      }
    } catch (e) {
      emit(HealthScoreErrorState(
        error: e.toString(),
        currentScore: state is HealthScoreSuccess ? (state as HealthScoreSuccess).healthScore : null,
      ));
    }
  }

  /// Handle health score errors
  Future<void> _onHealthScoreError(
    HealthScoreError event,
    Emitter<HealthScoreState> emit,
  ) async {
    emit(HealthScoreErrorState(
      error: event.error,
      currentScore: state is HealthScoreSuccess ? (state as HealthScoreSuccess).healthScore : null,
    ));
  }

  /// Check if health score changes trigger notifications
  Future<void> _checkNotificationTriggers(
    HealthScoreData currentScore,
    HealthScoreData? previousScore,
  ) async {
    try {
      // If there's no previous score, don't send notifications
      if (previousScore == null) return;

      // Check for significant score drops
      final scoreDrop = previousScore.overallScore - currentScore.overallScore;
      if (scoreDrop > 20) {
        // Significant health score drop - trigger notification
        await _triggerHealthScoreAlert(currentScore, 'score_drop', scoreDrop);
      }

      // Check for risk category changes
      if (previousScore.riskCategory != currentScore.riskCategory) {
        await _triggerHealthScoreAlert(currentScore, 'risk_change', 0);
      }

      // Check for urgent recommendations
      final urgentRecommendations = currentScore.recommendations
          .where((rec) => rec.isUrgent)
          .toList();
      
      if (urgentRecommendations.isNotEmpty) {
        await _triggerUrgentRecommendationNotification(urgentRecommendations.first);
      }
    } catch (e) {
      // Log error but don't fail the main operation
      print('Error checking notification triggers: $e');
    }
  }

  /// Trigger health score alert notification
  Future<void> _triggerHealthScoreAlert(
    HealthScoreData score,
    String alertType,
    double changeValue,
  ) async {
    try {
      // This would integrate with the smart notification service
      // For now, we'll just log the trigger
      print('Health Score Alert Triggered: $alertType, Score: ${score.overallScore}, Change: $changeValue');
      
      // TODO: Integrate with SmartNotificationService
      // await _smartNotificationService.triggerHealthScoreAlert(score, alertType, changeValue);
    } catch (e) {
      print('Error triggering health score alert: $e');
    }
  }

  /// Trigger urgent recommendation notification
  Future<void> _triggerUrgentRecommendationNotification(HealthRecommendation recommendation) async {
    try {
      print('Urgent Recommendation Notification: ${recommendation.title}');
      
      // TODO: Integrate with SmartNotificationService for urgent recommendations
      // await _smartNotificationService.triggerUrgentRecommendation(recommendation);
    } catch (e) {
      print('Error triggering urgent recommendation notification: $e');
    }
  }

  /// Track recommendation dismissal for analytics
  Future<void> _trackRecommendationDismissal(String recommendationId, HealthScoreData score) async {
    try {
      // Log analytics event
      print('Recommendation dismissed: $recommendationId, Score: ${score.overallScore}');
      
      // TODO: Send to analytics service
      // await _analyticsService.trackEvent('health_recommendation_dismissed', {
      //   'recommendation_id': recommendationId,
      //   'health_score': score.overallScore,
      //   'risk_category': score.riskCategory,
      // });
    } catch (e) {
      print('Error tracking recommendation dismissal: $e');
    }
  }

  /// Track recommendation completion for analytics
  Future<void> _trackRecommendationCompletion(String recommendationId, HealthScoreData score) async {
    try {
      // Log analytics event
      print('Recommendation completed: $recommendationId, Score: ${score.overallScore}');
      
      // TODO: Send to analytics service
      // await _analyticsService.trackEvent('health_recommendation_completed', {
      //   'recommendation_id': recommendationId,
      //   'health_score': score.overallScore,
      //   'time_to_complete': calculateTimeToComplete(recommendationId),
      // });
    } catch (e) {
      print('Error tracking recommendation completion: $e');
    }
  }

  /// Start monitoring for external data updates
  void startMonitoring() {
    // Subscribe to air quality updates
    _airQualitySubscription = _airQualityService.getAirQualityStream().listen(
      (airQualityData) {
        if (airQualityData != null) {
          add(HealthScoreDataUpdated(
            additionalData: {
              'real_time_aqi': airQualityData.aqi,
              'real_time_pm25': airQualityData.pm25,
              'last_update': airQualityData.timestamp.toIso8601String(),
            },
          ));
        }
      },
      onError: (error) {
        add(HealthScoreError(error: 'Air quality monitoring error: $error'));
      },
    );

    // TODO: Subscribe to user profile updates if needed
    // _userProfileSubscription = _userProfileService.getProfileUpdates().listen(...
  }

  /// Stop monitoring for external data updates
  void stopMonitoring() {
    _airQualitySubscription?.cancel();
    _userProfileSubscription?.cancel();
    _airQualitySubscription = null;
    _userProfileSubscription = null;
  }

  /// Get current health score data synchronously
  HealthScoreData? getCurrentScore() {
    if (state is HealthScoreSuccess) {
      return (state as HealthScoreSuccess).healthScore;
    }
    return null;
  }

  /// Check if current health score needs attention
  bool needsImmediateAttention() {
    final currentScore = getCurrentScore();
    if (currentScore == null) return false;

    return currentScore.riskCategory == 'Critical' || 
           currentScore.overallScore < 30 ||
           currentScore.recommendations.any((rec) => rec.isUrgent);
  }

  @override
  Future<void> close() {
    stopMonitoring();
    return super.close();
  }
}
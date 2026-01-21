import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../core/services/notification_service.dart';
import '../core/services/smart_notification_service.dart';
import '../models/air_quality_data.dart';

/// Events for the air quality notification BLoC
abstract class AirQualityNotificationEvent extends Equatable {
  const AirQualityNotificationEvent();

  @override
  List<Object> get props => [];
}

class CheckAirQualityAlert extends AirQualityNotificationEvent {
  final String location;
  final double currentAQI;
  final double pm25;
  final Map<String, double>? nearbyAQIs;

  const CheckAirQualityAlert({
    required this.location,
    required this.currentAQI,
    required this.pm25,
    this.nearbyAQIs,
  });

  @override
  List<Object> get props => [location, currentAQI, pm25];
}

class CheckRouteAirQuality extends AirQualityNotificationEvent {
  final String from;
  final String to;
  final double currentAQI;
  final double cleanerRouteAQI;

  const CheckRouteAirQuality({
    required this.from,
    required this.to,
    required this.currentAQI,
    required this.cleanerRouteAQI,
  });

  @override
  List<Object> get props => [from, to, currentAQI, cleanerRouteAQI];
}

class CheckHealthScoreUpdate extends AirQualityNotificationEvent {
  final double newScore;
  final double change;
  final String reason;

  const CheckHealthScoreUpdate({
    required this.newScore,
    required this.change,
    required this.reason,
  });

  @override
  List<Object> get props => [newScore, change, reason];
}

class CheckPredictionAlert extends AirQualityNotificationEvent {
  final String location;
  final DateTime predictionTime;
  final double predictedAQI;
  final String level;

  const CheckPredictionAlert({
    required this.location,
    required this.predictionTime,
    required this.predictedAQI,
    required this.level,
  });

  @override
  List<Object> get props => [location, predictionTime, predictedAQI, level];
}

/// States for the air quality notification BLoC
abstract class AirQualityNotificationState extends Equatable {
  const AirQualityNotificationState();

  @override
  List<Object> get props => [];
}

class AirQualityNotificationInitial extends AirQualityNotificationState {}

class AirQualityNotificationLoading extends AirQualityNotificationState {}

class AirQualityNotificationLoaded extends AirQualityNotificationState {
  final bool shouldShowNotification;
  final String notificationType;
  final String? message;

  const AirQualityNotificationLoaded({
    required this.shouldShowNotification,
    required this.notificationType,
    this.message,
  });

  @override
  List<Object> get props => [shouldShowNotification, notificationType];
}

class AirQualityNotificationError extends AirQualityNotificationState {
  final String error;

  const AirQualityNotificationError(this.error);

  @override
  List<Object> get props => [error];
}

/// BLoC for handling smart air quality notifications
class AirQualityNotificationBloc 
    extends Bloc<AirQualityNotificationEvent, AirQualityNotificationState> {
  final NotificationService _notificationService = NotificationService();
  final SmartNotificationService _smartService = SmartNotificationService();

  AirQualityNotificationBloc() : super(AirQualityNotificationInitial()) {
    on<CheckAirQualityAlert>(_onCheckAirQualityAlert);
    on<CheckRouteAirQuality>(_onCheckRouteAirQuality);
    on<CheckHealthScoreUpdate>(_onCheckHealthScoreUpdate);
    on<CheckPredictionAlert>(_onCheckPredictionAlert);
  }

  Future<void> _onCheckAirQualityAlert(
    CheckAirQualityAlert event,
    Emitter<AirQualityNotificationState> emit,
  ) async {
    emit(AirQualityNotificationLoading());

    try {
      // Check if notification should be shown using smart filtering
      final filter = await _smartService.shouldShowNotification(
        severity: _getSeverityFromAQI(event.currentAQI),
        context: NotificationContext.airQuality,
        title: 'Air Quality Alert',
        message: 'AQI: ${event.currentAQI.round()}, PM2.5: ${event.pm25.round()} μg/m³',
        data: {
          'location': event.location,
          'aqi': event.currentAQI,
          'pm25': event.pm25,
          'nearby_aqis': event.nearbyAQIs,
        },
      );

      if (filter.shouldShow) {
        // Show the notification
        await _notificationService.showHighPollutionAlert(
          location: event.location,
          aqi: event.currentAQI,
          pm25: event.pm25,
        );

        emit(AirQualityNotificationLoaded(
          shouldShowNotification: true,
          notificationType: 'high_pollution',
          message: 'High pollution alert sent',
        ));
      } else {
        emit(AirQualityNotificationLoaded(
          shouldShowNotification: false,
          notificationType: 'high_pollution',
          message: 'Notification blocked by smart filter: ${filter.reason}',
        ));
      }
    } catch (e) {
      emit(AirQualityNotificationError(e.toString()));
    }
  }

  Future<void> _onCheckRouteAirQuality(
    CheckRouteAirQuality event,
    Emitter<AirQualityNotificationState> emit,
  ) async {
    emit(AirQualityNotificationLoading());

    try {
      final improvement = ((event.currentAQI - event.cleanerRouteAQI) / event.currentAQI * 100).round();
      
      // Only notify if improvement is significant (>= 10%)
      if (improvement < 10) {
        emit(AirQualityNotificationLoaded(
          shouldShowNotification: false,
          notificationType: 'route',
          message: 'Route improvement too small ($improvement%)',
        ));
        return;
      }

      final filter = await _smartService.shouldShowNotification(
        severity: NotificationSeverity.low, // Route suggestions are low priority
        context: NotificationContext.route,
        title: 'Cleaner Route Available',
        message: 'Take this route to reduce pollution exposure by $improvement%',
        data: {
          'from': event.from,
          'to': event.to,
          'current_aqi': event.currentAQI,
          'cleaner_route_aqi': event.cleanerRouteAQI,
          'improvement': improvement,
        },
      );

      if (filter.shouldShow) {
        await _notificationService.showSafeRouteSuggestion(
          from: event.from,
          to: event.to,
          currentAQINearby: event.currentAQI,
          cleanerRouteAQI: event.cleanerRouteAQI,
        );

        emit(AirQualityNotificationLoaded(
          shouldShowNotification: true,
          notificationType: 'route',
          message: 'Route suggestion sent',
        ));
      } else {
        emit(AirQualityNotificationLoaded(
          shouldShowNotification: false,
          notificationType: 'route',
          message: 'Notification blocked: ${filter.reason}',
        ));
      }
    } catch (e) {
      emit(AirQualityNotificationError(e.toString()));
    }
  }

  Future<void> _onCheckHealthScoreUpdate(
    CheckHealthScoreUpdate event,
    Emitter<AirQualityNotificationState> emit,
  ) async {
    emit(AirQualityNotificationLoading());

    try {
      final severity = _getHealthScoreSeverity(event.newScore, event.change);
      
      final filter = await _smartService.shouldShowNotification(
        severity: severity,
        context: NotificationContext.health,
        title: 'Health Score Update',
        message: 'Your score is now ${event.newScore.round()} (${event.change > 0 ? 'increased' : 'decreased'} by ${event.change.abs().round()})',
        data: {
          'new_score': event.newScore,
          'change': event.change,
          'reason': event.reason,
        },
      );

      if (filter.shouldShow) {
        await _notificationService.showHealthScoreUpdate(
          newScore: event.newScore,
          change: event.change,
          reason: event.reason,
        );

        emit(AirQualityNotificationLoaded(
          shouldShowNotification: true,
          notificationType: 'health_score',
          message: 'Health score notification sent',
        ));
      } else {
        emit(AirQualityNotificationLoaded(
          shouldShowNotification: false,
          notificationType: 'health_score',
          message: 'Notification blocked: ${filter.reason}',
        ));
      }
    } catch (e) {
      emit(AirQualityNotificationError(e.toString()));
    }
  }

  Future<void> _onCheckPredictionAlert(
    CheckPredictionAlert event,
    Emitter<AirQualityNotificationState> emit,
  ) async {
    emit(AirQualityNotificationLoading());

    try {
      final severity = _getPredictionSeverity(event.predictedAQI);
      
      final filter = await _smartService.shouldShowNotification(
        severity: severity,
        context: NotificationContext.prediction,
        title: 'Pollution Forecast',
        message: 'Expected ${event.level} pollution in ${event.location} at ${event.predictionTime.hour}:${event.predictionTime.minute.toString().padLeft(2, '0')} (${event.predictedAQI.round()} AQI)',
        data: {
          'location': event.location,
          'prediction_time': event.predictionTime.toIso8601String(),
          'predicted_aqi': event.predictedAQI,
          'level': event.level,
        },
      );

      if (filter.shouldShow) {
        await _notificationService.showPollutionForecast(
          location: event.location,
          predictionTime: event.predictionTime,
          predictedAQI: event.predictedAQI,
          level: event.level,
        );

        emit(AirQualityNotificationLoaded(
          shouldShowNotification: true,
          notificationType: 'prediction',
          message: 'Prediction notification sent',
        ));
      } else {
        emit(AirQualityNotificationLoaded(
          shouldShowNotification: false,
          notificationType: 'prediction',
          message: 'Notification blocked: ${filter.reason}',
        ));
      }
    } catch (e) {
      emit(AirQualityNotificationError(e.toString()));
    }
  }

  /// Determine notification severity based on AQI value
  NotificationSeverity _getSeverityFromAQI(double aqi) {
    if (aqi >= 300) return NotificationSeverity.critical;
    if (aqi >= 200) return NotificationSeverity.high;
    if (aqi >= 150) return NotificationSeverity.high;
    if (aqi >= 100) return NotificationSeverity.moderate;
    if (aqi >= 50) return NotificationSeverity.low;
    return NotificationSeverity.minimal;
  }

  /// Determine notification severity based on health score
  NotificationSeverity _getHealthScoreSeverity(double score, double change) {
    // Significant drops in health score warrant higher priority
    if (score < 40 || change <= -20) return NotificationSeverity.high;
    if (score < 60 || change <= -10) return NotificationSeverity.moderate;
    if (score > 80 || change >= 10) return NotificationSeverity.low; // Celebratory notifications
    return NotificationSeverity.minimal;
  }

  /// Determine notification severity based on prediction
  NotificationSeverity _getPredictionSeverity(double predictedAQI) {
    return _getSeverityFromAQI(predictedAQI);
  }
}

/// Example usage in a widget
class AirQualityScreen extends StatefulWidget {
  const AirQualityScreen({Key? key}) : super(key: key);

  @override
  State<AirQualityScreen> createState() => _AirQualityScreenState();
}

class _AirQualityScreenState extends State<AirQualityScreen> {
  late AirQualityNotificationBloc _notificationBloc;

  @override
  void initState() {
    super.initState();
    _notificationBloc = AirQualityNotificationBloc();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _notificationBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Air Quality'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationPreferencesScreen(),
                ),
              ),
            ),
          ],
        ),
        body: BlocConsumer<AirQualityNotificationBloc, AirQualityNotificationState>(
          listener: (context, state) {
            if (state is AirQualityNotificationLoaded && state.shouldShowNotification) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message ?? 'Notification sent'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Air Quality Monitoring'),
                  const SizedBox(height: 20),
                  // Example test buttons
                  ElevatedButton(
                    onPressed: () => _testHighPollutionAlert(context),
                    child: const Text('Test High Pollution Alert'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _testRouteSuggestion(context),
                    child: const Text('Test Route Suggestion'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _testHealthScoreUpdate(context),
                    child: const Text('Test Health Score Update'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _testPredictionAlert(context),
                    child: const Text('Test Prediction Alert'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _testHighPollutionAlert(BuildContext context) {
    context.read<AirQualityNotificationBloc>().add(
      const CheckAirQualityAlert(
        location: 'San Francisco, CA',
        currentAQI: 185, // Unhealthy for sensitive groups
        pm25: 35.5,
        nearbyAQIs: {'Oakland': 145, 'Berkeley': 120},
      ),
    );
  }

  void _testRouteSuggestion(BuildContext context) {
    context.read<AirQualityNotificationBloc>().add(
      const CheckRouteAirQuality(
        from: 'Home',
        to: 'Work',
        currentAQI: 120,
        cleanerRouteAQI: 85, // 29% improvement
      ),
    );
  }

  void _testHealthScoreUpdate(BuildContext context) {
    context.read<AirQualityNotificationBloc>().add(
      const CheckHealthScoreUpdate(
        newScore: 65,
        change: -15, // Significant drop
        reason: 'High pollution exposure',
      ),
    );
  }

  void _testPredictionAlert(BuildContext context) {
    context.read<AirQualityNotificationBloc>().add(
      CheckPredictionAlert(
        location: 'San Francisco, CA',
        predictionTime: DateTime.now().add(const Duration(hours: 4)),
        predictedAQI: 220, // Very unhealthy
        level: 'Very Unhealthy',
      ),
    );
  }

  @override
  void dispose() {
    _notificationBloc.close();
    super.dispose();
  }
}
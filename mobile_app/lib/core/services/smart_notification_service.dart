import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Smart Notification Service - Context-aware notification system
/// Provides intelligent filtering, quiet hours, and severity-based alerts
class SmartNotificationService {
  static final SmartNotificationService _instance = SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  // Service dependencies
  late final SharedPreferences _prefs;
  StreamSubscription<Position>? _positionSubscription;
  
  // Notification preference keys
  static const String _quietHoursEnabled = 'quiet_hours_enabled';
  static const String _quietStartHour = 'quiet_start_hour';
  static const String _quietEndHour = 'quiet_end_hour';
  static const String _highPriorityOnly = 'high_priority_only';
  static const String _smartNotificationsEnabled = 'smart_notifications_enabled';
  static const String _locationAwareAlerts = 'location_aware_alerts';
  static const String _homeLocation = 'home_location';
  static const String _workLocation = 'work_location';
  static const String _commuteRadius = 'commute_radius';
  static const String _activityBasedNotifications = 'activity_based_notifications';
  static const String _notificationHistory = 'notification_history';
  static const String _lastNotificationTime = 'last_notification_time';

  // Severity levels
  enum NotificationSeverity {
    critical(4), // Emergency alerts, hazardous air
    high(3),     // Very unhealthy, poor air quality
    moderate(2), // Unhealthy for sensitive groups
    low(1),      // Good air quality, informational
    minimal(0);  // Updates, tips, etc.

    const NotificationSeverity(this.priority);
    final int priority;
  }

  // Notification contexts
  enum NotificationContext {
    airQuality,
    health,
    prediction,
    community,
    system,
    emergency,
    route,
    activity
  }

  // User activity states for smart filtering
  enum UserActivity {
    active,      // User is moving/interacting with app
    driving,     // In a vehicle
    walking,     // On foot
    cycling,     // Cycling
    exercising,  // Workout/physical activity
    sleeping,    // Sleep hours
    working,     // During work hours
    commuting,   // Commuting
    meeting,     // In meetings (based on calendar or user input)
    idle         // Idle/not active
  }

  // Notification filtering result
  class NotificationFilter {
    final bool shouldShow;
    final NotificationSeverity severity;
    final String? reason;
    final Map<String, dynamic>? contextData;

    NotificationFilter({
      required this.shouldShow,
      required this.severity,
      this.reason,
      this.contextData,
    });
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Set default values if not set
    await _initializeDefaults();
    
    // Start location tracking for context-aware alerts
    _startLocationTracking();
    
    print('Smart Notification Service initialized');
  }

  Future<void> _initializeDefaults() async {
    await _prefs.setBool(_smartNotificationsEnabled, true);
    await _prefs.setBool(_highPriorityOnly, false);
    await _prefs.setBool(_quietHoursEnabled, true);
    await _prefs.setInt(_quietStartHour, 22); // 10 PM
    await _prefs.setInt(_quietEndHour, 7);    // 7 AM
    await _prefs.setBool(_locationAwareAlerts, true);
    await _prefs.setBool(_activityBasedNotifications, true);
    await _prefs.setInt(_commuteRadius, 1000); // 1km radius
  }

  /// Check if a notification should be shown based on smart filters
  Future<NotificationFilter> shouldShowNotification({
    required NotificationSeverity severity,
    required NotificationContext context,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    
    // Check if smart notifications are enabled
    if (!_prefs.getBool(_smartNotificationsEnabled) ?? true) {
      return NotificationFilter(
        shouldShow: false,
        severity: severity,
        reason: 'Smart notifications disabled',
      );
    }

    // Check quiet hours
    if (_isQuietHours()) {
      if (_isHighSeverity(severity) && !_prefs.getBool(_highPriorityOnly) ?? false) {
        return NotificationFilter(
          shouldShow: false,
          severity: severity,
          reason: 'Quiet hours active, notification below high priority threshold',
        );
      } else if (_isHighSeverity(severity)) {
        // Allow critical notifications during quiet hours
        return NotificationFilter(
          shouldShow: true,
          severity: severity,
          reason: 'Critical alert during quiet hours',
        );
      }
    }

    // Check notification frequency (prevent spam)
    if (!_isNotificationAllowed()) {
      return NotificationFilter(
        shouldShow: false,
        severity: severity,
        reason: 'Too frequent notifications',
      );
    }

    // Check location-based filtering
    if (context == NotificationContext.route || context == NotificationContext.airQuality) {
      final locationFilter = await _checkLocationContext(data);
      if (!locationFilter.shouldShow) {
        return locationFilter;
      }
    }

    // Check activity-based filtering
    if (_prefs.getBool(_activityBasedNotifications) ?? true) {
      final activityFilter = await _checkActivityContext(severity, context);
      if (!activityFilter.shouldShow) {
        return activityFilter;
      }
    }

    // Check high priority only mode
    if (_prefs.getBool(_highPriorityOnly) ?? false) {
      if (!_isHighSeverity(severity)) {
        return NotificationFilter(
          shouldShow: false,
          severity: severity,
          reason: 'High priority only mode enabled',
        );
      }
    }

    return NotificationFilter(
      shouldShow: true,
      severity: severity,
      reason: 'All filters passed',
    );
  }

  /// Determine if current time is within quiet hours
  bool _isQuietHours() {
    if (!_prefs.getBool(_quietHoursEnabled) ?? true) return false;

    final now = DateTime.now();
    final currentHour = now.hour;
    
    final startHour = _prefs.getInt(_quietStartHour) ?? 22;
    final endHour = _prefs.getInt(_quietEndHour) ?? 7;

    if (startHour <= endHour) {
      // Same day hours (e.g., 22:00 to 07:00 doesn't work with this)
      return currentHour >= startHour && currentHour <= endHour;
    } else {
      // Cross-day hours (e.g., 22:00 to 07:00)
      return currentHour >= startHour || currentHour <= endHour;
    }
  }

  /// Check if notification meets high severity threshold
  bool _isHighSeverity(NotificationSeverity severity) {
    return severity.priority >= NotificationSeverity.high.priority;
  }

  /// Check if enough time has passed since last notification
  bool _isNotificationAllowed() {
    final lastTime = _prefs.getInt(_lastNotificationTime) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = currentTime - lastTime;

    // Minimum 30 seconds between notifications
    const minInterval = 30000;
    
    if (timeDifference < minInterval) {
      return false;
    }

    // Update last notification time
    _prefs.setInt(_lastNotificationTime, currentTime);
    return true;
  }

  /// Check location-based notification context
  Future<NotificationFilter> _checkLocationContext(Map<String, dynamic>? data) async {
    if (!_prefs.getBool(_locationAwareAlerts) ?? true) {
      return NotificationFilter(
        shouldShow: true,
        severity: NotificationSeverity.low,
      );
    }

    final position = await Geolocator.getCurrentPosition();
    final homeLocationStr = _prefs.getString(_homeLocation);
    final workLocationStr = _prefs.getString(_workLocation);
    final commuteRadius = _prefs.getInt(_commuteRadius) ?? 1000;

    if (homeLocationStr == null && workLocationStr == null) {
      // No location preferences set, show all location-based notifications
      return NotificationFilter(
        shouldShow: true,
        severity: NotificationSeverity.low,
      );
    }

    double? minDistance;
    String? nearestLocation;

    if (homeLocationStr != null) {
      final homeData = json.decode(homeLocationStr);
      final homeDistance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        homeData['lat'],
        homeData['lng'],
      );
      minDistance = homeDistance;
      nearestLocation = 'home';
    }

    if (workLocationStr != null) {
      final workData = json.decode(workLocationStr);
      final workDistance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        workData['lat'],
        workData['lng'],
      );
      
      if (minDistance == null || workDistance < minDistance) {
        minDistance = workDistance;
        nearestLocation = 'work';
      }
    }

    if (minDistance != null && minDistance <= commuteRadius) {
      return NotificationFilter(
        shouldShow: true,
        severity: NotificationSeverity.low,
        reason: 'User is near $nearestLocation',
      );
    } else {
      return NotificationFilter(
        shouldShow: false,
        severity: NotificationSeverity.low,
        reason: 'User not near configured locations',
      );
    }
  }

  /// Check activity-based notification context
  Future<NotificationFilter> _checkActivityContext(
    NotificationSeverity severity,
    NotificationContext context,
  ) async {
    final activity = await _determineUserActivity();

    switch (activity) {
      case UserActivity.sleeping:
        if (severity.priority < NotificationSeverity.high.priority) {
          return NotificationFilter(
            shouldShow: false,
            severity: severity,
            reason: 'User sleeping, low priority notification',
          );
        }
        break;

      case UserActivity.meeting:
        if (severity.priority < NotificationSeverity.high.priority) {
          return NotificationFilter(
            shouldShow: false,
            severity: severity,
            reason: 'User in meeting, low priority notification',
          );
        }
        break;

      case UserActivity.exercising:
        // Reduce air quality notifications during exercise
        if (context == NotificationContext.health || context == NotificationContext.airQuality) {
          return NotificationFilter(
            shouldShow: severity.priority >= NotificationSeverity.moderate.priority,
            severity: severity,
            reason: 'User exercising, reduced notifications',
          );
        }
        break;

      case UserActivity.driving:
      case UserActivity.commuting:
        // Prioritize route-related notifications
        if (context == NotificationContext.route) {
          return NotificationFilter(
            shouldShow: true,
            severity: severity,
            reason: 'User commuting, route notifications prioritized',
          );
        }
        break;

      default:
        break;
    }

    return NotificationFilter(
      shouldShow: true,
      severity: severity,
    );
  }

  /// Determine current user activity (simplified implementation)
  Future<UserActivity> _determineUserActivity() async {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Basic time-based activity detection
    if (hour >= 23 || hour <= 6) {
      return UserActivity.sleeping;
    }
    
    if (hour >= 9 && hour <= 17) {
      return UserActivity.working;
    }
    
    if (hour >= 7 && hour <= 9 || hour >= 17 && hour <= 19) {
      return UserActivity.commuting;
    }

    // Check location-based activity
    final position = await Geolocator.getCurrentPosition().catchError((e) {
      return null;
    });

    if (position != null) {
      final speed = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        position.latitude,
        position.longitude,
      ); // Placeholder for actual speed calculation

      // Simplified speed-based detection
      if (speed > 30) { // > 30 km/h
        return UserActivity.driving;
      } else if (speed > 5 && speed <= 15) { // 5-15 km/h
        return UserActivity.cycling;
      } else if (speed > 0 && speed <= 5) { // 0-5 km/h
        return UserActivity.walking;
      }
    }

    return UserActivity.idle;
  }

  /// Start location tracking for context-aware notifications
  void _startLocationTracking() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    ).listen((Position position) {
      // Update location context for future notifications
      // This can trigger activity detection or location-based filtering
    });
  }

  /// Set user location preferences
  Future<void> setHomeLocation(double lat, double lng) async {
    final locationData = {'lat': lat, 'lng': lng};
    await _prefs.setString(_homeLocation, json.encode(locationData));
  }

  Future<void> setWorkLocation(double lat, double lng) async {
    final locationData = {'lat': lat, 'lng': lng};
    await _prefs.setString(_workLocation, json.encode(locationData));
  }

  Future<void> setCommuteRadius(int meters) async {
    await _prefs.setInt(_commuteRadius, meters);
  }

  /// Configure quiet hours
  Future<void> setQuietHours(int startHour, int endHour) async {
    await _prefs.setInt(_quietStartHour, startHour);
    await _prefs.setInt(_quietEndHour, endHour);
  }

  Future<void> setQuietHoursEnabled(bool enabled) async {
    await _prefs.setBool(_quietHoursEnabled, enabled);
  }

  /// Toggle smart notification features
  Future<void> setSmartNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_smartNotificationsEnabled, enabled);
  }

  Future<void> setHighPriorityOnly(bool enabled) async {
    await _prefs.setBool(_highPriorityOnly, enabled);
  }

  Future<void> setLocationAwareAlerts(bool enabled) async {
    await _prefs.setBool(_locationAwareAlerts, enabled);
  }

  Future<void> setActivityBasedNotifications(bool enabled) async {
    await _prefs.setBool(_activityBasedNotifications, enabled);
  }

  /// Get notification preferences
  Map<String, dynamic> getNotificationPreferences() {
    return {
      'smart_notifications_enabled': _prefs.getBool(_smartNotificationsEnabled) ?? true,
      'high_priority_only': _prefs.getBool(_highPriorityOnly) ?? false,
      'quiet_hours_enabled': _prefs.getBool(_quietHoursEnabled) ?? true,
      'quiet_start_hour': _prefs.getInt(_quietStartHour) ?? 22,
      'quiet_end_hour': _prefs.getInt(_quietEndHour) ?? 7,
      'location_aware_alerts': _prefs.getBool(_locationAwareAlerts) ?? true,
      'activity_based_notifications': _prefs.getBool(_activityBasedNotifications) ?? true,
      'commute_radius': _prefs.getInt(_commuteRadius) ?? 1000,
    };
  }

  /// Test notification filtering
  Future<Map<String, dynamic>> testNotificationFiltering({
    required NotificationSeverity severity,
    required NotificationContext context,
    String title = 'Test Alert',
    String message = 'This is a test notification',
  }) async {
    final filter = await shouldShowNotification(
      severity: severity,
      context: context,
      title: title,
      message: message,
    );

    return {
      'should_show': filter.shouldShow,
      'severity': severity.name,
      'context': context.name,
      'reason': filter.reason,
      'timestamp': DateTime.now().toIso8601String(),
      'preferences': getNotificationPreferences(),
      'current_time': DateTime.now().toIso8601String(),
      'is_quiet_hours': _isQuietHours(),
      'user_activity': (await _determineUserActivity()).name,
    };
  }

  /// Clean up resources
  void dispose() {
    _positionSubscription?.cancel();
  }
}
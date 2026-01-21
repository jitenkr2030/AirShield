import 'package:flutter/foundation.dart';
import '../core/services/smart_notification_service.dart';

/// ViewModel for managing notification preferences
class NotificationPreferencesViewModel extends ChangeNotifier {
  final SmartNotificationService _smartService = SmartNotificationService();
  
  // Current preferences
  bool _smartNotificationsEnabled = true;
  bool _highPriorityOnly = false;
  bool _quietHoursEnabled = true;
  int _quietStartHour = 22;
  int _quietEndHour = 7;
  bool _locationAwareAlerts = true;
  bool _activityBasedNotifications = true;
  int _commuteRadius = 1000;
  
  // Loading states
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get smartNotificationsEnabled => _smartNotificationsEnabled;
  bool get highPriorityOnly => _highPriorityOnly;
  bool get quietHoursEnabled => _quietHoursEnabled;
  int get quietStartHour => _quietStartHour;
  int get quietEndHour => _quietEndHour;
  bool get locationAwareAlerts => _locationAwareAlerts;
  bool get activityBasedNotifications => _activityBasedNotifications;
  int get commuteRadius => _commuteRadius;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  String get quietHoursDescription => _getQuietHoursDescription();
  List<String> get commuteRadiusOptions => ['500m', '1km', '2km', '5km', '10km'];
  int get selectedRadiusIndex => commuteRadiusOptions.indexOf('${_commuteRadius}m');
  
  /// Initialize the viewmodel by loading current preferences
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _smartService.initialize();
      _loadCurrentPreferences();
    } catch (e) {
      _error = 'Failed to load notification preferences: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load current preferences from service
  void _loadCurrentPreferences() {
    final prefs = _smartService.getNotificationPreferences();
    
    _smartNotificationsEnabled = prefs['smart_notifications_enabled'] ?? true;
    _highPriorityOnly = prefs['high_priority_only'] ?? false;
    _quietHoursEnabled = prefs['quiet_hours_enabled'] ?? true;
    _quietStartHour = prefs['quiet_start_hour'] ?? 22;
    _quietEndHour = prefs['quiet_end_hour'] ?? 7;
    _locationAwareAlerts = prefs['location_aware_alerts'] ?? true;
    _activityBasedNotifications = prefs['activity_based_notifications'] ?? true;
    _commuteRadius = prefs['commute_radius'] ?? 1000;
    
    notifyListeners();
  }
  
  /// Update smart notifications enabled state
  Future<void> setSmartNotificationsEnabled(bool enabled) async {
    await _smartService.setSmartNotificationsEnabled(enabled);
    _smartNotificationsEnabled = enabled;
    notifyListeners();
  }
  
  /// Update high priority only mode
  Future<void> setHighPriorityOnly(bool enabled) async {
    await _smartService.setHighPriorityOnly(enabled);
    _highPriorityOnly = enabled;
    notifyListeners();
  }
  
  /// Update quiet hours enabled state
  Future<void> setQuietHoursEnabled(bool enabled) async {
    await _smartService.setQuietHoursEnabled(enabled);
    _quietHoursEnabled = enabled;
    notifyListeners();
  }
  
  /// Update quiet hours start time
  Future<void> setQuietStartHour(int hour) async {
    await _smartService.setQuietHours(hour, _quietEndHour);
    _quietStartHour = hour;
    notifyListeners();
  }
  
  /// Update quiet hours end time
  Future<void> setQuietEndHour(int hour) async {
    await _smartService.setQuietHours(_quietStartHour, hour);
    _quietEndHour = hour;
    notifyListeners();
  }
  
  /// Update location aware alerts
  Future<void> setLocationAwareAlerts(bool enabled) async {
    await _smartService.setLocationAwareAlerts(enabled);
    _locationAwareAlerts = enabled;
    notifyListeners();
  }
  
  /// Update activity based notifications
  Future<void> setActivityBasedNotifications(bool enabled) async {
    await _smartService.setActivityBasedNotifications(enabled);
    _activityBasedNotifications = enabled;
    notifyListeners();
  }
  
  /// Update commute radius
  Future<void> setCommuteRadius(int meters) async {
    await _smartService.setCommuteRadius(meters);
    _commuteRadius = meters;
    notifyListeners();
  }
  
  /// Set commute radius by index (for UI)
  Future<void> setCommuteRadiusByIndex(int index) async {
    final values = [500, 1000, 2000, 5000, 10000];
    if (index >= 0 && index < values.length) {
      await setCommuteRadius(values[index]);
    }
  }
  
  /// Set home location
  Future<void> setHomeLocation(double lat, double lng) async {
    await _smartService.setHomeLocation(lat, lng);
    notifyListeners();
  }
  
  /// Set work location
  Future<void> setWorkLocation(double lat, double lng) async {
    await _smartService.setWorkLocation(lat, lng);
    notifyListeners();
  }
  
  /// Test notification filtering
  Future<Map<String, dynamic>> testNotificationFiltering({
    required NotificationSeverity severity,
    required NotificationContext context,
    String title = 'Test Alert',
    String message = 'This is a test notification',
  }) async {
    return await _smartService.testNotificationFiltering(
      severity: severity,
      context: context,
      title: title,
      message: message,
    );
  }
  
  /// Get quiet hours description
  String _getQuietHoursDescription() {
    if (!_quietHoursEnabled) {
      return 'Quiet hours are disabled';
    }
    
    final startTime = _formatTime(_quietStartHour);
    final endTime = _formatTime(_quietEndHour);
    return 'Quiet from $startTime to $endTime';
  }
  
  /// Format hour to readable time
  String _formatTime(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:00 $period';
  }
  
  /// Get available severity levels for testing
  List<NotificationSeverity> get availableSeverities => [
    NotificationSeverity.minimal,
    NotificationSeverity.low,
    NotificationSeverity.moderate,
    NotificationSeverity.high,
    NotificationSeverity.critical,
  ];
  
  /// Get available notification contexts for testing
  List<NotificationContext> get availableContexts => [
    NotificationContext.airQuality,
    NotificationContext.health,
    NotificationContext.prediction,
    NotificationContext.community,
    NotificationContext.system,
    NotificationContext.emergency,
    NotificationContext.route,
    NotificationContext.activity,
  ];
  
  /// Get severity descriptions
  Map<NotificationSeverity, String> get severityDescriptions => {
    NotificationSeverity.minimal: 'Updates, tips, and informational messages',
    NotificationSeverity.low: 'Good air quality updates and general alerts',
    NotificationSeverity.moderate: 'Unhealthy for sensitive groups',
    NotificationSeverity.high: 'Very unhealthy and poor air quality',
    NotificationSeverity.critical: 'Hazardous conditions and emergencies',
  };
  
  /// Get context descriptions
  Map<NotificationContext, String> get contextDescriptions => {
    NotificationContext.airQuality: 'Air quality readings and alerts',
    NotificationContext.health: 'Health score updates and exposure alerts',
    NotificationContext.prediction: 'Forecast and prediction updates',
    NotificationContext.community: 'Community features and challenges',
    NotificationContext.system: 'App updates and system notifications',
    NotificationContext.emergency: 'Emergency alerts and safety warnings',
    NotificationContext.route: 'Route planning and navigation alerts',
    NotificationContext.activity: 'Activity-based recommendations',
  };
  
  /// Reset all preferences to defaults
  Future<void> resetToDefaults() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _smartService.setSmartNotificationsEnabled(true);
      await _smartService.setHighPriorityOnly(false);
      await _smartService.setQuietHoursEnabled(true);
      await _smartService.setQuietHours(22, 7);
      await _smartService.setLocationAwareAlerts(true);
      await _smartService.setActivityBasedNotifications(true);
      await _smartService.setCommuteRadius(1000);
      
      _loadCurrentPreferences();
    } catch (e) {
      _error = 'Failed to reset preferences: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    // No specific disposal needed for SharedPreferences
    super.dispose();
  }
}
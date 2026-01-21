import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../config/app_config.dart';
import 'smart_notification_service.dart';

class NotificationService {
  late final FirebaseMessaging _firebaseMessaging;
  late final FlutterLocalNotificationsPlugin _localNotifications;
  late final SmartNotificationService _smartNotificationService;
  StreamSubscription<RemoteMessage>? _firebaseSubscription;
  
  // Notification channels
  static const String _airQualityChannelId = 'air_quality';
  static const String _alertsChannelId = 'alerts';
  static const String _healthChannelId = 'health';
  static const String _communityChannelId = 'community';
  
  // Notification IDs
  static const int _highPollutionId = 1001;
  static const int _safeRouteId = 1002;
  static const int _healthScoreId = 1003;
  static const int _predictionId = 1004;
  static const int _photoAnalysisId = 1005;

  NotificationService() {
    _firebaseMessaging = FirebaseMessaging.instance;
    _localNotifications = FlutterLocalNotificationsPlugin();
    _smartNotificationService = SmartNotificationService();
  }

  Future<void> initialize() async {
    // Initialize smart notification service
    await _smartNotificationService.initialize();
    
    // Request permissions
    await _requestPermissions();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Initialize Firebase messaging
    await _initializeFirebaseMessaging();
    
    // Create notification channels
    await _createNotificationChannels();
    
    print('Notification service initialized');
  }

  Future<void> _requestPermissions() async {
    // Request notification permissions
    final notificationStatus = await Permission.notification.request();
    if (notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) {
      throw NotificationException('Notification permission denied');
    }

    // Request iOS permissions for local notifications
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        throw NotificationException('iOS notification permission denied');
      }
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInitializationSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iOSInitializationSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iOSInitializationSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Handle message opened app
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Air Quality Channel
      await _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        const AndroidNotificationChannel(
          _airQualityChannelId,
          'Air Quality',
          description: 'Air quality updates and alerts',
          importance: Importance.high,
        ),
      );

      // Alerts Channel
      await _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        const AndroidNotificationChannel(
          _alertsChannelId,
          'Alerts',
          description: 'Safety and pollution alerts',
          importance: Importance.max,
        ),
      );

      // Health Channel
      await _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        const AndroidNotificationChannel(
          _healthChannelId,
          'Health',
          description: 'Health score and exposure alerts',
          importance: Importance.defaultImportance,
        ),
      );

      // Community Channel
      await _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        const AndroidNotificationChannel(
          _communityChannelId,
          'Community',
          description: 'Community updates and challenges',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  // Air Quality Notifications
  Future<void> showHighPollutionAlert({
    required String location,
    required double aqi,
    required double pm25,
    String? routeSuggestion,
  }) async {
    if (!AppConfig.prefs.getBool('notifications_enabled')) return;

    // Determine notification severity based on AQI
    final severity = _getAQISeverity(aqi);
    
    // Apply smart notification filtering
    final filter = await _smartNotificationService.shouldShowNotification(
      severity: severity,
      context: NotificationContext.airQuality,
      title: 'High Pollution Alert',
      message: 'Air quality in $location is poor (AQI: ${aqi.round()}, PM2.5: ${pm25.round()} μg/m³)',
      data: {
        'location': location,
        'aqi': aqi,
        'pm25': pm25,
        'route_suggestion': routeSuggestion,
      },
    );

    if (!filter.shouldShow) {
      print('Notification blocked by smart filter: ${filter.reason}');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _airQualityChannelId,
      'Air Quality',
      channelDescription: 'Air quality alerts',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'High Pollution Alert',
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      _highPollutionId,
      'High Pollution Alert',
      'Air quality in $location is poor (AQI: ${aqi.round()}, PM2.5: ${pm25.round()} μg/m³)',
      details,
    );
  }

  /// Determine notification severity based on AQI value
  NotificationSeverity _getAQISeverity(double aqi) {
    if (aqi >= 300) return NotificationSeverity.critical;
    if (aqi >= 200) return NotificationSeverity.high;
    if (aqi >= 150) return NotificationSeverity.high;
    if (aqi >= 100) return NotificationSeverity.moderate;
    if (aqi >= 50) return NotificationSeverity.low;
    return NotificationSeverity.minimal;
  }

  Future<void> showSafeRouteSuggestion({
    required String from,
    required String to,
    required double currentAQINearby,
    required double cleanerRouteAQI,
  }) async {
    if (!AppConfig.prefs.getBool('notifications_enabled')) return;

    const androidDetails = AndroidNotificationDetails(
      _airQualityChannelId,
      'Air Quality',
      channelDescription: 'Route recommendations',
      importance: Importance.defaultImportance,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    final improvement = ((currentAQINearby - cleanerRouteAQI) / currentAQINearby * 100).round();
    
    await _localNotifications.show(
      _safeRouteId,
      'Cleaner Route Available',
      'Take this route to reduce pollution exposure by $improvement%',
      details,
    );
  }

  // Health Notifications
  Future<void> showHealthScoreUpdate({
    required double newScore,
    required double change,
    required String reason,
  }) async {
    if (!AppConfig.prefs.getBool('notifications_enabled')) return;

    const androidDetails = AndroidNotificationDetails(
      _healthChannelId,
      'Health',
      channelDescription: 'Health score updates',
      importance: Importance.defaultImportance,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    final changeText = change > 0 ? 'increased by ${change.round()}' : 'decreased by ${change.abs().round()}';
    
    await _localNotifications.show(
      _healthScoreId,
      'Health Score Update',
      'Your score is now $newScore ($changeText)',
      details,
    );
  }

  Future<void> showExposureAlert({
    required String activity,
    required double duration,
    required double avgAQIS,
    required String recommendation,
  }) async {
    if (!AppConfig.prefs.getBool('notifications_enabled')) return;

    const androidDetails = AndroidNotificationDetails(
      _healthChannelId,
      'Health',
      channelDescription: 'Exposure alerts',
      importance: Importance.defaultImportance,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      _healthScoreId + 1,
      'High Exposure Alert',
      'You\'ve been $activity for ${duration.round()} minutes in poor air quality (${avgAQIS.round()} AQI). $recommendation',
      details,
    );
  }

  // Prediction Notifications
  Future<void> showPollutionForecast({
    required String location,
    required DateTime predictionTime,
    required double predictedAQI,
    required String level,
  }) async {
    if (!AppConfig.prefs.getBool('notifications_enabled')) return;

    const androidDetails = AndroidNotificationDetails(
      _alertsChannelId,
      'Alerts',
      channelDescription: 'Pollution predictions',
      importance: Importance.high,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    final timeStr = '${predictionTime.hour}:${predictionTime.minute.toString().padLeft(2, '0')}';
    
    await _localNotifications.show(
      _predictionId,
      'Pollution Forecast',
      'Expected $level pollution in $location at $timeStr (${predictedAQI.round()} AQI)',
      details,
    );
  }

  // Photo Analysis Notifications
  Future<void> showPhotoAnalysisComplete({
    required String photoTitle,
    required double estimatedPM25,
    required double confidence,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _communityChannelId,
      'Community',
      channelDescription: 'Photo analysis updates',
      importance: Importance.defaultImportance,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      _photoAnalysisId,
      'Photo Analysis Complete',
      'Your photo "$photoTitle" shows PM2.5: ${estimatedPM25.round()} μg/m³ (${confidence.round()}% confidence)',
      details,
    );
  }

  // Scheduled Notifications
  Future<void> scheduleDailyHealthReport({
    required String userId,
    required TimeOfDay time,
  }) async {
    if (!AppConfig.prefs.getBool('notifications_enabled')) return;

    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day + 1,
      time.hour,
      time.minute,
    );

    const androidDetails = AndroidNotificationDetails(
      _healthChannelId,
      'Health',
      channelDescription: 'Daily health reports',
      importance: Importance.defaultImportance,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.zonedSchedule(
      _healthScoreId + 2,
      'Daily Health Report',
      'Check your daily pollution exposure and health score',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> schedulePredictionReminder({
    required String location,
    required DateTime reminderTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _alertsChannelId,
      'Alerts',
      channelDescription: 'Prediction reminders',
      importance: Importance.defaultImportance,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.zonedSchedule(
      _predictionId + 1,
      'Air Quality Update',
      'Time to check air quality forecast for $location',
      tz.TZDateTime.from(reminderTime, tz.local),
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // FCM Push Notifications
  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This would typically be called from the backend
    // Implementation depends on FCM service
  }

  void _onForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    // Show notification based on message data
    _handleRemoteMessage(message);
  }

  void _onMessageOpened(RemoteMessage message) {
    print('Message opened: ${message.messageId}');
    
    // Handle notification tap - navigate to relevant screen
    _handleNotificationTap(message.data);
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    
    // Handle local notification tap
    if (response.payload != null) {
      try {
        final data = Map<String, dynamic>.from(
          (response.payload as String).split('&').map((pair) {
            final parts = pair.split('=');
            return MapEntry(parts[0], parts[1]);
          })
        );
        _handleNotificationTap(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Handle navigation based on notification type
    final type = data['type'];
    
    switch (type) {
      case 'pollution_alert':
        // Navigate to air quality screen
        break;
      case 'health_score':
        // Navigate to health screen
        break;
      case 'photo_analysis':
        // Navigate to photo analysis screen
        break;
      case 'prediction':
        // Navigate to prediction screen
        break;
    }
  }

  void _handleRemoteMessage(RemoteMessage message) {
    // Handle different types of FCM messages
    if (message.notification != null) {
      final type = message.data['type'];
      
      switch (type) {
        case 'high_pollution':
          // Show high pollution notification
          break;
        case 'safe_route':
          // Show safe route notification
          break;
        case 'prediction_update':
          // Show prediction notification
          break;
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> showNotificationSettings() async {
    await openAppSettings();
  }

  void dispose() {
    _firebaseSubscription?.cancel();
  }
}

// TimeOfDay extension for timezone
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay(this.hour, this.minute);
}

class NotificationException implements Exception {
  final String message;
  
  NotificationException(this.message);
  
  @override
  String toString() => 'NotificationException: $message';
}

// Background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Handle background messages
}
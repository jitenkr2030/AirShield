# Smart Notifications Implementation Guide

## Overview

This guide provides step-by-step instructions for implementing and integrating AIRSHIELD's Smart Notifications feature. The system provides context-aware notification filtering, quiet hours, and intelligent alert management to reduce notification fatigue while ensuring critical alerts reach users.

## Features Implemented

### ✅ Completed Features
- **Smart Notification Filtering**: Context-aware notification decisions
- **Quiet Hours**: Time-based notification silencing
- **Severity-Based Filtering**: Priority-based notification handling
- **Location-Aware Alerts**: Proximity-based notification filtering
- **Activity-Based Filtering**: User activity context awareness
- **Notification Preferences**: Comprehensive settings management
- **Testing Framework**: Built-in notification filtering tests

### 🚧 Future Enhancements
- Machine learning-based activity detection
- Calendar integration for meeting detection
- Advanced location context (transit, driving patterns)
- Personalized notification timing optimization

## File Structure

```
lib/
├── core/services/
│   ├── notification_service.dart           # Enhanced existing service
│   └── smart_notification_service.dart     # New smart filtering service
├── viewmodels/
│   └── notification_preferences_viewmodel.dart  # Settings management
├── screens/
│   └── notification_preferences_screen.dart     # User interface
├── bloc/
│   └── air_quality_notification_bloc.dart       # BLoC integration example
└── models/
    └── (existing models continue to work)
```

## Implementation Steps

### Step 1: Add Dependencies

Add the following dependencies to `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies
  geolocator: ^10.1.0
  shared_preferences: ^2.2.2
  provider: ^6.1.1
  
  # Ensure these are already present
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.0
  permission_handler: ^11.1.0
```

### Step 2: Update NotificationService

The existing `NotificationService` has been enhanced to integrate with smart filtering:

```dart
// Example usage
final notificationService = NotificationService();

// Initialize both services
await notificationService.initialize();

// Smart notification methods now automatically filter
await notificationService.showHighPollutionAlert(
  location: 'San Francisco, CA',
  aqi: 185,
  pm25: 35.5,
);
```

### Step 3: Initialize SmartNotificationService

The `SmartNotificationService` is automatically initialized when you call `NotificationService.initialize()`. For standalone usage:

```dart
final smartService = SmartNotificationService();
await smartService.initialize();

// Check if a notification should be shown
final filter = await smartService.shouldShowNotification(
  severity: NotificationSeverity.high,
  context: NotificationContext.airQuality,
  title: 'High Pollution Alert',
  message: 'Air quality is poor in your area',
);
```

### Step 4: Integrate with BLoC Architecture

Use the provided `AirQualityNotificationBloc` for reactive notification handling:

```dart
// Add to your dependency injection
final notificationBloc = AirQualityNotificationBloc();

// Trigger smart notifications based on data changes
notificationBloc.add(CheckAirQualityAlert(
  location: 'San Francisco, CA',
  currentAQI: 185,
  pm25: 35.5,
));

// Listen for results
BlocConsumer<AirQualityNotificationBloc, AirQualityNotificationState>(
  listener: (context, state) {
    if (state is AirQualityNotificationLoaded) {
      // Handle notification results
    }
  },
  builder: (context, state) {
    // Build your UI
  },
)
```

### Step 5: Add Notification Preferences Screen

Navigate to the notification preferences from your settings screen:

```dart
// In your settings screen
ListTile(
  title: Text('Notification Preferences'),
  subtitle: Text('Configure smart notifications'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const NotificationPreferencesScreen(),
    ),
  ),
),
```

### Step 6: Request Required Permissions

Ensure your app requests necessary permissions:

```dart
// In your main app initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request location permission for context-aware notifications
  await Permission.locationWhenInUse.request();
  
  runApp(MyApp());
}
```

## Usage Examples

### Basic Smart Notification

```dart
// Check if notification should be shown
final filter = await smartService.shouldShowNotification(
  severity: NotificationSeverity.high,
  context: NotificationContext.airQuality,
  title: 'Air Quality Alert',
  message: 'High pollution levels detected',
  data: {'aqi': 185, 'location': 'San Francisco'},
);

if (filter.shouldShow) {
  // Show notification
  await notificationService.showHighPollutionAlert(
    location: 'San Francisco, CA',
    aqi: 185,
    pm25: 35.5,
  );
}
```

### Setting User Preferences

```dart
// Configure quiet hours
await smartService.setQuietHours(22, 7); // 10 PM to 7 AM
await smartService.setQuietHoursEnabled(true);

// Set location preferences
await smartService.setHomeLocation(37.7749, -122.4194);
await smartService.setWorkLocation(37.7849, -122.4094);
await smartService.setCommuteRadius(1000); // 1km

// Configure filtering
await smartService.setHighPriorityOnly(false);
await smartService.setLocationAwareAlerts(true);
await smartService.setActivityBasedNotifications(true);
```

### Testing Notification Filtering

```dart
// Test how different notifications are filtered
final testResult = await smartService.testNotificationFiltering(
  severity: NotificationSeverity.low,
  context: NotificationContext.community,
);

print('Should show: ${testResult['should_show']}');
print('Reason: ${testResult['reason']}');
```

## Notification Severity Levels

| Severity | Priority | Examples |
|----------|----------|----------|
| Critical (4) | Emergency | Hazardous air quality (>300 AQI) |
| High (3) | Urgent | Very unhealthy air (200-299 AQI) |
| Moderate (2) | Important | Unhealthy for sensitive groups (150-199 AQI) |
| Low (1) | Informational | Good air quality updates, route suggestions |
| Minimal (0) | Background | Daily tips, system updates |

## Notification Contexts

| Context | Description | Examples |
|---------|-------------|----------|
| Air Quality | Pollution readings and alerts | High pollution, AQI updates |
| Health | Health score and exposure | Score changes, exposure warnings |
| Prediction | Forecast updates | Tomorrow's pollution forecast |
| Community | Social features | Photo analysis, challenges |
| System | App functionality | Updates, maintenance |
| Emergency | Safety alerts | Evacuation warnings |
| Route | Navigation assistance | Cleaner route suggestions |
| Activity | User activity | Exercise recommendations |

## Smart Filtering Logic

### 1. Quiet Hours
- **Enabled**: Silences non-high-priority notifications
- **Critical Always Shows**: Emergency alerts break through quiet hours
- **Configurable**: 22:00-07:00 default, user customizable

### 2. High Priority Only Mode
- **Shows**: Critical and High severity only
- **Hides**: Moderate, Low, and Minimal notifications
- **Use Case**: During important meetings, travel, etc.

### 3. Location Awareness
- **Home/Work Radius**: Notifications when within configured radius
- **Commute Radius**: Route-based notifications during travel
- **Privacy**: Only approximate location needed

### 4. Activity-Based Filtering
- **Sleeping**: Reduces all notifications except critical
- **Working**: Minimizes non-urgent notifications
- **Exercising**: Focuses on health-related alerts
- **Commuting**: Prioritizes route and traffic alerts

## Testing

### Automated Testing
```dart
// Test all severity levels
for (final severity in NotificationSeverity.values) {
  final result = await smartService.testNotificationFiltering(
    severity: severity,
    context: NotificationContext.airQuality,
  );
  print('${severity.name}: ${result['should_show']}');
}
```

### Manual Testing
1. Open Notification Preferences screen
2. Use the "Test Filter" section
3. Select different severity/context combinations
4. Verify filtering logic works as expected

### Integration Testing
```dart
// Test with actual notification service
testWidgets('Smart notification filtering', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Trigger air quality check
  context.read<AirQualityNotificationBloc>().add(
    CheckAirQualityAlert(
      location: 'Test City',
      currentAQI: 250, // Very unhealthy
      pm25: 45.0,
    ),
  );
  
  // Verify notification was sent
  expect(find.text('High Pollution Alert'), findsOneWidget);
});
```

## Performance Considerations

### Memory Usage
- **SharedPreferences**: Minimal memory footprint
- **Location Tracking**: GPS only when needed
- **Activity Detection**: Lightweight time-based detection

### Battery Impact
- **Location Updates**: 100-meter threshold, updates when moving
- **Activity Detection**: Time-based, no sensors required
- **Filtering**: Instant checks, no background processing

### Network Impact
- **No Additional APIs**: Filtering happens locally
- **Cache-Friendly**: Preferences stored locally
- **Offline Support**: Works without internet connection

## Troubleshooting

### Common Issues

**Notifications not showing:**
1. Check `notifications_enabled` in AppConfig
2. Verify app notification permissions
3. Test with `testNotificationFiltering()`
4. Check quiet hours settings

**Smart filtering too restrictive:**
1. Disable "High Priority Only" mode
2. Adjust quiet hours settings
3. Check location preferences
4. Review activity detection context

**Performance issues:**
1. Check location permission status
2. Verify geolocator service availability
3. Reduce location update frequency if needed

### Debug Mode
Enable debug logging:
```dart
// Add to main.dart for development
if (kDebugMode) {
  print('Smart Notification Service initialized');
  print('Preferences: ${smartService.getNotificationPreferences()}');
}
```

## Migration Guide

### From Basic Notifications

1. **Keep existing notification methods**: They work unchanged
2. **Add smart filtering**: Use `shouldShowNotification()` for new features
3. **Update preference screens**: Integrate new smart settings
4. **Test thoroughly**: Verify all existing functionality works

### User Data Migration

```dart
// Preserve existing notification preferences
final oldEnabled = prefs.getBool('notifications_enabled') ?? true;
await smartService.setSmartNotificationsEnabled(oldEnabled);

// Set default smart preferences
await smartService.setQuietHours(22, 7);
await smartService.setLocationAwareAlerts(true);
```

## Future Enhancements

### Planned Features
- **ML Activity Detection**: Learn user patterns over time
- **Calendar Integration**: Automatic meeting detection
- **Advanced Location Context**: Transit mode detection
- **Personalized Timing**: Optimal notification timing

### Extension Points
- **Custom Filters**: Add your own filtering logic
- **Activity Sources**: Integrate with fitness/calendar apps
- **Learning System**: Improve filtering based on user feedback
- **Cross-App Integration**: Share preferences across AIRSHIELD apps

## Support and Resources

### Documentation
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Messaging](https://pub.dev/packages/firebase_messaging)
- [Geolocator](https://pub.dev/packages/geolocator)

### Example Projects
- Complete working examples in `/examples/`
- Test cases in `/test/core/services/`
- UI components in `/lib/screens/`

### API Reference
All classes are fully documented with DartDoc comments. Key classes:
- `SmartNotificationService`
- `NotificationPreferencesViewModel`
- `NotificationPreferencesScreen`
- `AirQualityNotificationBloc`

---

This implementation provides a robust, user-friendly smart notification system that significantly improves the user experience while maintaining full functionality and backward compatibility.
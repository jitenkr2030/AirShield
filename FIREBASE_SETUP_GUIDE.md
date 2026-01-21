# Firebase Configuration Setup for AIRSHIELD

## Overview
This guide covers setting up Firebase services for AIRSHIELD including Analytics, Crashlytics, Cloud Messaging, and Authentication.

## Prerequisites
1. Firebase project created at https://console.firebase.google.com
2. FlutterFire CLI installed: `dart pub global activate flutterfire_cli`
3. Google account with Firebase access

---

## Step 1: Firebase Project Setup

### Create New Firebase Project
1. Go to Firebase Console (https://console.firebase.google.com)
2. Click "Add Project"
3. Project Name: `airshield-app`
4. Enable Google Analytics (recommended)
5. Select or create Google Analytics account
6. Choose Google Analytics data sharing settings
7. Click "Create Project"

### Enable Required Services
1. **Analytics**
   - Enable Google Analytics for the project
   - Configure data sharing settings
   - Note down Measurement ID (G-XXXXXXXXXX)

2. **Crashlytics**
   - Go to Crashlytics
   - Click "Get Started"
   - Follow setup instructions

3. **Cloud Messaging**
   - Enable Cloud Messaging API
   - Configure notification permissions

4. **Authentication** (Future Implementation)
   - Enable Authentication service
   - Configure sign-in providers

---

## Step 2: Configure Android App

### Add Android App to Firebase
1. In Firebase Console, click "Add App" → Android
2. Package Name: `com.airshield.app`
3. App Nickname: `AIRSHIELD Android`
4. Debug Signing Key SHA-1: Generate using:
   ```bash
   cd /workspace/airshield/mobile_app/android
   ./gradlew signingReport
   ```
5. Add SHA-256 fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
6. Click "Register App"

### Download Configuration
1. Download `google-services.json`
2. Place in `android/app/` directory
3. Ensure file is NOT in `.gitignore`

### Update Gradle Files

**android/build.gradle:**
```gradle
buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.3.15'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

**android/app/build.gradle:**
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    // ... existing configuration ...
}

dependencies {
    // Firebase dependencies
    implementation 'com.google.firebase:firebase-analytics:21.2.0'
    implementation 'com.google.firebase:firebase-crashlytics:18.2.2'
    implementation 'com.google.firebase:firebase-messaging:23.0.0'
}
```

---

## Step 3: Configure iOS App

### Add iOS App to Firebase
1. In Firebase Console, click "Add App" → iOS
2. Bundle ID: `com.airshield.app`
3. App Nickname: `AIRSHIELD iOS`
4. App Store ID: Leave blank for now
5. Click "Register App"

### Download Configuration
1. Download `GoogleService-Info.plist`
2. Add to iOS project in Xcode:
   - Right-click on Runner folder → Add Files
   - Select `GoogleService-Info.plist`
   - Ensure "Copy items if needed" is checked
   - Click "Add"

### Update Podfile
```ruby
# Add at top of Podfile
require 'cocoapods'
require 'cocoapods/user_hooks'

# Add after existing post_install hook
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
                '$(inherited)',
                'PERMISSION_CAMERA=1',
                'PERMISSION_PHOTOS=1',
                'PERMISSION_LOCATION=1',
                'PERMISSION_BLUETOOTH=1',
                'PERMISSION_NOTIFICATIONS=1',
            ]
        end
    end
end
```

### Install Firebase Dependencies
```bash
cd /workspace/airshield/mobile_app/ios
flutter pub add firebase_core firebase_analytics firebase_crashlytics firebase_messaging
pod install
```

---

## Step 4: Flutter Configuration

### Configure FlutterFire
```bash
cd /workspace/airshield/mobile_app
flutterfire configure
```

This will:
- Detect your Firebase projects
- Generate `lib/firebase_options.dart`
- Update platform configurations

### Update Main App Code

**lib/main.dart:**
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize configuration
  await AppConfig.initialize();
  
  // Initialize services
  await configureDependencies();
  await getIt<NotificationService>().initialize();
  await getIt<LocationService>().requestPermissions();
  await getIt<BluetoothService>().initialize();
  
  runApp(AirShieldApp());
}
```

---

## Step 5: Firebase Analytics Events

### Custom Event Implementation
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  
  // User Events
  static Future<void> trackAppInstall() async {
    await analytics.logEvent(
      name: 'app_install',
      parameters: {
        'platform': Platform.operatingSystem,
        'app_version': AppConfig.appVersion,
        'install_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  static Future<void> trackSensorConnection({
    required String deviceType,
    required String connectionStatus,
    required bool locationPermissionGranted,
  }) async {
    await analytics.logEvent(
      name: 'sensor_connection',
      parameters: {
        'device_type': deviceType,
        'connection_status': connectionStatus,
        'location_permission': locationPermissionGranted,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  static Future<void> trackPhotoAnalysis({
    required String analysisType,
    required double confidence,
    required String photoSource,
  }) async {
    await analytics.logEvent(
      name: 'photo_analysis',
      parameters: {
        'analysis_type': analysisType,
        'confidence': confidence,
        'photo_source': photoSource,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  static Future<void> trackPredictionView({
    required String location,
    required int predictionHorizon,
    required String predictionLevel,
  }) async {
    await analytics.logEvent(
      name: 'prediction_view',
      parameters: {
        'location': location,
        'prediction_horizon': predictionHorizon,
        'prediction_level': predictionLevel,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  static Future<void> trackHealthScoreView({
    required double score,
    required String scoreCategory,
    required int trendDirection,
  }) async {
    await analytics.logEvent(
      name: 'health_score_view',
      parameters: {
        'score': score,
        'score_category': scoreCategory,
        'trend_direction': trendDirection,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  static Future<void> trackSubscriptionPurchase({
    required String subscriptionType,
    required String purchaseStatus,
    required double amount,
  }) async {
    await analytics.logEvent(
      name: 'subscription_purchase',
      parameters: {
        'subscription_type': subscriptionType,
        'purchase_status': purchaseStatus,
        'amount': amount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
```

---

## Step 6: Crashlytics Configuration

### Custom Crash Reporting
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService {
  static FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;
  
  // Set crash collection enabled
  static Future<void> initialize() async {
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    
    // Enable crash collection in release builds
    if (kReleaseMode) {
      await crashlytics.setCrashlyticsCollectionEnabled(true);
    }
    
    // Set user identifier
    await crashlytics.setUserIdentifier('user_${DateTime.now().millisecondsSinceEpoch}');
    
    // Set custom keys
    await crashlytics.setCustomKey('app_version', AppConfig.appVersion);
    await crashlytics.setCustomKey('platform', Platform.operatingSystem);
    await crashlytics.setCustomKey('build_mode', kReleaseMode ? 'release' : 'debug');
  }
  
  // Custom error reporting
  static Future<void> recordError({
    required String error,
    required StackTrace stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    await crashlytics.recordError(
      error,
      stackTrace,
      reason: 'Handled error in AIRSHIELD',
      information: additionalData?.entries.map((e) => DiagnosticsProperty(e.key, e.value)).toList(),
      fatal: false,
    );
  }
  
  // Custom fatal error
  static Future<void> recordFatalError({
    required String error,
    required StackTrace stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    await crashlytics.recordError(
      error,
      stackTrace,
      reason: 'Fatal error in AIRSHIELD',
      information: additionalData?.entries.map((e) => DiagnosticsProperty(e.key, e.value)).toList(),
      fatal: true,
    );
  }
}
```

---

## Step 7: Cloud Messaging Configuration

### Notification Service Integration
```dart
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
    
    // Get FCM token
    String? token = await messaging.getToken();
    print('FCM Token: $token');
    
    // Handle messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }
  
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    if (message.notification != null) {
      // Show local notification
      _showLocalNotification(message);
    }
  }
  
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message: ${message.messageId}');
  }
  
  static void _showLocalNotification(RemoteMessage message) {
    // Implementation with flutter_local_notifications
  }
}
```

---

## Step 8: Testing & Verification

### Local Testing
1. **Analytics Testing**
   ```bash
   # Enable debug mode for development
   adb shell setprop debug.firebase.analytics.app com.airshield.app
   ```

2. **Crashlytics Testing**
   ```dart
   // Add test crash in development
   if (kDebugMode) {
     FirebaseCrashlytics.instance.crash();
   }
   ```

3. **Messaging Testing**
   - Use Firebase Console to send test messages
   - Check notification delivery on device

### Verification Checklist
- [ ] Firebase project created and configured
- [ ] Android app added with correct SHA certificates
- [ ] iOS app added with bundle identifier
- [ ] Configuration files downloaded and placed correctly
- [ ] Dependencies installed for both platforms
- [ ] Analytics events firing correctly
- [ ] Crash reports appearing in Firebase Console
- [ ] Push notifications working on both platforms
- [ ] Debug logging configured appropriately

---

## Step 9: Production Configuration

### Security Rules
1. **Database Rules** (When implemented)
   ```json
   {
     "rules": {
       "users": {
         "$uid": {
           ".read": "$uid === auth.uid",
           ".write": "$uid === auth.uid"
         }
       }
     }
   }
   ```

2. **Storage Rules** (When implemented)
   ```json
   {
     "rules": {
       "userUploads": {
         "$uid": {
           ".read": "$uid === auth.uid",
           ".write": "$uid === auth.uid"
         }
       }
     }
   }
   ```

### Environment Configuration
- Use different Firebase projects for development/staging/production
- Configure environment-specific settings
- Ensure proper API keys for each environment

---

## Troubleshooting

### Common Issues
1. **Configuration file not found**
   - Verify file placement in correct directories
   - Check file names match exactly

2. **Build failures**
   - Run `flutter clean && flutter pub get`
   - Verify all dependencies installed correctly

3. **Firebase services not working**
   - Check internet connectivity
   - Verify Firebase project settings
   - Check API keys and permissions

### Resources
- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
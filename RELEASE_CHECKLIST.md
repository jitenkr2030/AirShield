# AIRSHIELD Release Checklist - App Store & Play Store

## Overview
This comprehensive checklist covers all requirements for releasing AIRSHIELD on both Android Play Store and iOS App Store platforms.

## Pre-Release Preparation

### ✅ Code Requirements
- [ ] All features implemented and tested
- [ ] Firebase Crashlytics and Analytics integrated
- [ ] API keys and credentials configured
- [ ] Privacy policy hosted and accessible
- [ ] App icons and splash screens designed
- [ ] Localizations for target markets (English, Hindi)
- [ ] TFLite model size optimized (< 50MB)
- [ ] Performance optimized and tested on target devices

### ✅ Testing Requirements
- [ ] Unit tests implemented (>80% coverage)
- [ ] Integration tests for critical flows
- [ ] User acceptance testing completed
- [ ] Device testing on multiple screen sizes
- [ ] Network condition testing (3G, 4G, WiFi)
- [ ] Battery optimization testing
- [ ] Location permission flow testing

---

## Android Platform - Google Play Store

### Build Configuration

#### 1. Generate Release Build
```bash
# Navigate to mobile app directory
cd /workspace/airshield/mobile_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK for testing
flutter build apk --release

# Build Android App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### 2. Keystore & Security
```bash
# Generate release keystore (ONE TIME ONLY)
keytool -genkey -v -keystore airshield-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias airshield

# Store keystore securely in password manager
# Backup keystore file to secure cloud storage
```

**Keystore Configuration (`android/key.properties`):**
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=airshield
storeFile=path/to/airshield-release-key.jks
```

#### 3. Release Build Configuration
**Update `android/app/build.gradle`:**
```gradle
android {
    compileSdkVersion 34
    minSdkVersion 21
    targetSdkVersion 34

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Play Console Setup

#### 4. App Listing Information
- [ ] **App Title**: "AIRSHIELD - Air Quality Monitor"
- [ ] **Short Description** (80 chars): "Personal pollution defense system with real-time air quality monitoring"
- [ ] **Full Description**: Comprehensive feature description (4000 chars max)
- [ ] **Feature Graphic**: 1024x500px high-quality banner
- [ ] **Screenshots**: 
  - 6-8 screenshots for phones (1080x1920 or similar)
  - 2-3 screenshots for tablets (optional)
  - Show key features: map view, real-time AQI, predictions, health score
- [ ] **Promo Video**: 30-60 second demo video (optional but recommended)

#### 5. Content Rating
- [ ] Complete IARC content rating questionnaire
- [ ] Expected rating: "Everyone" (no concerning content)
- [ ] Provide detailed app description for rating review

#### 6. Pricing & Distribution
- [ ] **Pricing Model**: Free with in-app purchases
- [ ] **Target Countries**: India, USA, UK, Canada, Australia
- [ ] **Excluded Countries**: Countries with regulatory restrictions
- [ ] **Device Requirements**: Android 5.0+ (API 21+)

#### 7. App Content & Privacy
- [ ] **Privacy Policy URL**: Hosted at `https://airshield.app/privacy`
- [ ] **Data Safety Section**: Complete Google's data safety questionnaire
- [ ] **Permissions Declaration**: Justify all requested permissions
- [ ] **Contact Information**: Developer contact details

### Release Tracks

#### 8. Internal Testing Track
- [ ] Upload APK/App Bundle to Internal Testing
- [ ] Add internal testers (email addresses)
- [ ] Test core functionality on real devices
- [ ] Address critical issues found

#### 9. Closed Beta Track
- [ ] Upload to Closed Testing
- [ ] Add 20-50 beta testers
- [ ] Collect feedback and ratings
- [ ] Monitor crash reports and performance

#### 10. Open Beta Track (Optional)
- [ ] Upload to Open Testing
- [ ] Expand tester pool to 100-500 users
- [ ] Final testing before production release

#### 11. Production Release
- [ ] Upload final build to Production
- [ ] Submit for review
- [ ] Monitor release metrics
- [ ] Respond to user reviews

---

## iOS Platform - Apple App Store

### Development Requirements

#### 1. Apple Developer Account Setup
- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Complete company/organization verification
- [ ] Set up team roles and permissions

#### 2. App Store Connect Setup
- [ ] Create app in App Store Connect
- [ ] Configure app information and metadata
- [ ] Set up pricing and availability
- [ ] Configure app categories and subcategories

### Build Configuration

#### 3. Provisioning Profiles & Certificates
```bash
# Generate development certificates
# Generate distribution certificate
# Create provisioning profiles for development and distribution

# Update ios/Runner.xcodeproj/project.pbxproj with correct bundle identifiers
# Ensure iOS deployment target is set appropriately
```

#### 4. TFLite Model Size Check
```bash
# Check model sizes
ls -la assets/ml_models/

# Optimize models if needed:
# - Use TensorFlow Lite quantization
# - Compress model files
# - Total app size should be under 100MB for cellular download
```

#### 5. iOS-Specific Configuration
**Update `ios/Runner/Info.plist`:**
```xml
<key>CFBundleIdentifier</key>
<string>com.yourcompany.airshield</string>
<key>CFBundleVersion</key>
<string>1.0.0</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
```

### App Store Listing

#### 6. App Privacy Details
- [ ] Complete App Privacy questionnaire in App Store Connect
- [ ] Declare data collected (location, device identifiers)
- [ ] Specify data usage (air quality monitoring, health tracking)
- [ ] Link to privacy policy

#### 7. App Store Assets
- [ ] **App Icon**: 1024x1024px (required)
- [ ] **Screenshots for iPhone**:
  - iPhone 6.7": 1290x2796px
  - iPhone 6.5": 1242x2688px  
  - iPhone 5.5": 1242x2208px
- [ ] **Screenshots for iPad** (optional):
  - iPad Pro 12.9": 2048x2732px
- [ ] **App Preview Video**: 15-30 seconds (optional)

#### 8. Metadata
- [ ] **App Name**: "AIRSHIELD"
- [ ] **Subtitle**: "Personal Air Quality Defense"
- [ ] **Keywords**: air quality, pollution, health, environment, monitoring
- [ ] **Description**: Detailed feature description
- [ ] **What's New**: Release notes for updates

### Testing & Release

#### 9. TestFlight Closed Beta
- [ ] Upload build to TestFlight via Xcode or Transporter
- [ ] Add internal testers (App Store Connect team members)
- [ ] Add external testers (up to 10,000 users)
- [ ] Collect feedback and fix critical issues
- [ ] Ensure app meets App Store Review Guidelines

#### 10. Production Release
- [ ] Submit app for App Store Review
- [ ] Respond to review feedback if needed
- [ ] Release app to production
- [ ] Monitor release metrics and user reviews

---

## Cross-Platform Requirements

### Firebase Integration

#### 1. Crashlytics Setup
```bash
# Add Firebase to Flutter project
flutter pub add firebase_core
flutter pub add firebase_crashlytics

# Configure for Android and iOS platforms
```

**Android Configuration (`android/app/google-services.json`):**
- Download from Firebase Console
- Place in `android/app/` directory

**iOS Configuration (`ios/Runner/GoogleService-Info.plist`):**
- Download from Firebase Console  
- Add to iOS project in Xcode

#### 2. Analytics Configuration
**Custom Event Tracking:**
- `app_install` - App installation event
- `sensor_connection` - Sensor device connection
- `photo_capture` - Photo capture for analysis
- `prediction_view` - Viewing pollution predictions
- `subscription_purchase` - Pro subscription events
- `health_score_view` - Health dashboard views

**Implementation Example:**
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

FirebaseAnalytics.instance.logEvent(
  name: 'sensor_connection',
  parameters: {
    'device_type': 'bluetooth_sensor',
    'connection_status': 'success',
    'location_permission': granted,
  },
);
```

### Additional Requirements

#### 3. Performance Optimization
- [ ] App bundle size < 50MB for Android
- [ ] App size < 100MB for iOS (cellular download limit)
- [ ] Cold start time < 3 seconds
- [ ] Memory usage < 200MB
- [ ] Battery usage optimized

#### 4. Accessibility
- [ ] Screen reader compatibility
- [ ] High contrast mode support
- [ ] Large text support
- [ ] Voice over navigation (iOS)
- [ ] TalkBack navigation (Android)

#### 5. Legal Compliance
- [ ] Privacy Policy hosted and compliant with GDPR/CCPA
- [ ] Terms of Service implemented in-app
- [ ] Data retention policy documented
- [ ] User consent flows implemented
- [ ] COPPA compliance (if collecting data from minors)

#### 6. Support & Maintenance
- [ ] Support email: support@airshield.app
- [ ] Privacy contact: privacy@airshield.app
- [ ] Website: https://airshield.app
- [ ] User documentation and FAQs
- [ ] In-app feedback mechanism

---

## Release Timeline

### Week 1-2: Preparation
- [ ] Final code integration and testing
- [ ] Firebase setup and configuration
- [ ] App icons and assets creation
- [ ] Privacy policy and legal documents

### Week 3: Android Release
- [ ] Generate release builds
- [ ] Play Console listing setup
- [ ] Internal testing phase
- [ ] Closed beta testing

### Week 4: iOS Release  
- [ ] iOS build configuration
- [ ] App Store Connect setup
- [ ] TestFlight testing
- [ ] App Store submission

### Week 5: Launch
- [ ] Production releases for both platforms
- [ ] Monitor crash reports and performance
- [ ] Respond to user reviews
- [ ] Marketing and promotion

---

## Post-Launch Monitoring

### Key Metrics to Track
- [ ] Daily Active Users (DAU)
- [ ] Crash-free sessions
- [ ] App Store ratings and reviews
- [ ] Feature usage analytics
- [ ] Sensor connection success rates
- [ ] Subscription conversion rates
- [ ] User retention (Day 1, 7, 30)

### Success Criteria
- [ ] < 2% crash rate
- [ ] > 4.0 app store rating
- [ ] > 50% Day 1 retention
- [ ] > 20% Day 7 retention
- [ ] < 3 second app load time

---

## Emergency Contacts

### Development Team
- **Lead Developer**: [Contact Information]
- **QA Lead**: [Contact Information]  
- **DevOps**: [Contact Information]

### Business Contacts
- **Product Manager**: [Contact Information]
- **Legal/Compliance**: [Contact Information]
- **Marketing**: [Contact Information]

### Platform Contacts
- **Apple Developer Support**: https://developer.apple.com/support/
- **Google Play Console Support**: https://support.google.com/googleplay/android-developer/
- **Firebase Support**: https://firebase.google.com/support

---

## Notes
- Keep this checklist updated throughout the release process
- Document any issues encountered and their resolutions
- Save all generated certificates and keys in secure storage
- Maintain a rollback plan in case of critical issues post-launch
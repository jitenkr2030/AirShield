import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final int age;
  final String gender;
  final double height; // in cm
  final double weight; // in kg
  final List<String> healthConditions;
  final List<String> medications;
  final List<String> allergies;
  final String activityLevel;
  final String location;
  final double latitude;
  final double longitude;
  final bool notificationsEnabled;
  final bool locationTrackingEnabled;
  final bool dataSharingEnabled;
  final String privacySettings;
  final String theme;
  final String language;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final DateTime? lastLoginAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    this.healthConditions = const [],
    this.medications = const [],
    this.allergies = const [],
    this.activityLevel = 'moderate',
    required this.location,
    required this.latitude,
    required this.longitude,
    this.notificationsEnabled = true,
    this.locationTrackingEnabled = true,
    this.dataSharingEnabled = false,
    this.privacySettings = 'medium',
    this.theme = 'system',
    this.language = 'en',
    this.preferences = const {},
    required this.createdAt,
    required this.lastUpdated,
    this.lastLoginAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    int? age,
    String? gender,
    double? height,
    double? weight,
    List<String>? healthConditions,
    List<String>? medications,
    List<String>? allergies,
    String? activityLevel,
    String? location,
    double? latitude,
    double? longitude,
    bool? notificationsEnabled,
    bool? locationTrackingEnabled,
    bool? dataSharingEnabled,
    String? privacySettings,
    String? theme,
    String? language,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? lastUpdated,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      healthConditions: healthConditions ?? this.healthConditions,
      medications: medications ?? this.medications,
      allergies: allergies ?? this.allergies,
      activityLevel: activityLevel ?? this.activityLevel,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationTrackingEnabled: locationTrackingEnabled ?? this.locationTrackingEnabled,
      dataSharingEnabled: dataSharingEnabled ?? this.dataSharingEnabled,
      privacySettings: privacySettings ?? this.privacySettings,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  // Computed properties
  double get bmi => weight / ((height / 100) * (height / 100));
  
  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  String get fullName => '$firstName $lastName';

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, fullName: $fullName, age: $age, location: $location)';
  }
}

@JsonSerializable()
class HealthProfile {
  final String userId;
  final String respiratoryConditions;
  final String cardiovascularConditions;
  final String additionalConditions;
  final String riskLevel;
  final double baselineLungCapacity;
  final String activityRecommendations;
  final List<String> precautions;
  final Map<String, dynamic> vitalSigns;
  final DateTime lastMedicalUpdate;

  const HealthProfile({
    required this.userId,
    this.respiratoryConditions = '',
    this.cardiovascularConditions = '',
    this.additionalConditions = '',
    this.riskLevel = 'low',
    this.baselineLungCapacity = 0.0,
    this.activityRecommendations = '',
    this.precautions = const [],
    this.vitalSigns = const {},
    required this.lastMedicalUpdate,
  });

  factory HealthProfile.fromJson(Map<String, dynamic> json) =>
      _$HealthProfileFromJson(json);

  Map<String, dynamic> toJson() => _$HealthProfileToJson(this);
}

enum Gender {
  male,
  female,
  other,
  preferNotToSay,
}

extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }
}

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive,
}

extension ActivityLevelExtension on ActivityLevel {
  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.light:
        return 'Light';
      case ActivityLevel.moderate:
        return 'Moderate';
      case ActivityLevel.active:
        return 'Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
    }
  }
  
  int get weeklyExerciseDays {
    switch (this) {
      case ActivityLevel.sedentary:
        return 0;
      case ActivityLevel.light:
        return 1;
      case ActivityLevel.moderate:
        return 3;
      case ActivityLevel.active:
        return 5;
      case ActivityLevel.veryActive:
        return 7;
    }
  }
}

enum PrivacyLevel {
  minimal,
  low,
  medium,
  high,
  complete,
}

extension PrivacyLevelExtension on PrivacyLevel {
  String get displayName {
    switch (this) {
      case PrivacyLevel.minimal:
        return 'Minimal';
      case PrivacyLevel.low:
        return 'Low';
      case PrivacyLevel.medium:
        return 'Medium';
      case PrivacyLevel.high:
        return 'High';
      case PrivacyLevel.complete:
        return 'Complete';
    }
  }
}
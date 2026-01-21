import 'package:json_annotation/json_annotation.dart';
import 'air_quality_data.dart';

part 'photo_data.g.dart';

@JsonSerializable()
class PhotoData {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String imageUrl;
  final double thumbnailUrl;
  final double latitude;
  final double longitude;
  final String locationName;
  final DateTime capturedAt;
  final DateTime uploadedAt;
  final PhotoAnalysis analysis;
  final String visibility;
  final double weatherQuality;
  final String cameraMetadata;
  final String status; // pending, approved, rejected, verified
  final double communityRating;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final Map<String, dynamic> metadata;
  final String verificationStatus;

  const PhotoData({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.capturedAt,
    required this.uploadedAt,
    required this.analysis,
    this.visibility = 'good',
    this.weatherQuality = 1.0,
    this.cameraMetadata = '',
    this.status = 'pending',
    this.communityRating = 0.0,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.metadata = const {},
    this.verificationStatus = 'unverified',
  });

  factory PhotoData.fromJson(Map<String, dynamic> json) =>
      _$PhotoDataFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoDataToJson(this);

  PhotoData copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? imageUrl,
    double? thumbnailUrl,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? capturedAt,
    DateTime? uploadedAt,
    PhotoAnalysis? analysis,
    String? visibility,
    double? weatherQuality,
    String? cameraMetadata,
    String? status,
    double? communityRating,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    Map<String, dynamic>? metadata,
    String? verificationStatus,
  }) {
    return PhotoData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      capturedAt: capturedAt ?? this.capturedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      analysis: analysis ?? this.analysis,
      visibility: visibility ?? this.visibility,
      weatherQuality: weatherQuality ?? this.weatherQuality,
      cameraMetadata: cameraMetadata ?? this.cameraMetadata,
      status: status ?? this.status,
      communityRating: communityRating ?? this.communityRating,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      metadata: metadata ?? this.metadata,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  AQILevel get estimatedAQILevel => AQILevelExtension.fromValue(analysis.estimatedPM25);

  @override
  String toString() {
    return 'PhotoData(id: $id, userId: $userId, location: $locationName, estimatedPM25: ${analysis.estimatedPM25}, status: $status)';
  }
}

@JsonSerializable()
class PhotoAnalysis {
  final String analysisId;
  final double estimatedPM25;
  final double estimatedAQI;
  final double confidence;
  final double visibilityScore;
  final double hazeIntensity;
  final double colorScattering;
  final double sunAngle;
  final List<AnalysisFactor> factors;
  final String analysisMethod;
  final String modelVersion;
  final DateTime analyzedAt;
  final Map<String, double> qualityMetrics;

  const PhotoAnalysis({
    required this.analysisId,
    required this.estimatedPM25,
    required this.estimatedAQI,
    required this.confidence,
    required this.visibilityScore,
    required this.hazeIntensity,
    required this.colorScattering,
    required this.sunAngle,
    this.factors = const [],
    this.analysisMethod = 'cnn_vision',
    this.modelVersion = '1.0.0',
    required this.analyzedAt,
    this.qualityMetrics = const {},
  });

  factory PhotoAnalysis.fromJson(Map<String, dynamic> json) =>
      _$PhotoAnalysisFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoAnalysisToJson(this);
}

@JsonSerializable()
class AnalysisFactor {
  final String factor;
  final String name;
  final double impact;
  final String description;
  final double weight;

  const AnalysisFactor({
    required this.factor,
    required this.name,
    required this.impact,
    required this.description,
    required this.weight,
  });

  factory AnalysisFactor.fromJson(Map<String, dynamic> json) =>
      _$AnalysisFactorFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisFactorToJson(this);

  double get contribution => (impact * weight * 100).roundToDouble() / 100;
}

@JsonSerializable()
class CommunityPhotoMap {
  final String mapId;
  final String areaName;
  final LatLngBounds bounds;
  final List<PhotoLocationMarker> markers;
  final double averageAQI;
  final String coverageLevel;
  final DateTime lastUpdated;
  final int totalPhotos;
  final Map<String, int> pollutantStats;
  final List<CommunityHotspot> hotspots;

  const CommunityPhotoMap({
    required this.mapId,
    required this.areaName,
    required this.bounds,
    this.markers = const [],
    required this.averageAQI,
    this.coverageLevel = 'medium',
    required this.lastUpdated,
    this.totalPhotos = 0,
    this.pollutantStats = const {},
    this.hotspots = const [],
  });

  factory CommunityPhotoMap.fromJson(Map<String, dynamic> json) =>
      _$CommunityPhotoMapFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityPhotoMapToJson(this);
}

@JsonSerializable()
class PhotoLocationMarker {
  final String photoId;
  final String title;
  final double latitude;
  final double longitude;
  final double estimatedPM25;
  final double estimatedAQI;
  final String status;
  final String thumbnailUrl;
  final DateTime capturedAt;
  final String userAlias;
  final double rating;

  const PhotoLocationMarker({
    required this.photoId,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.estimatedPM25,
    required this.estimatedAQI,
    required this.status,
    required this.thumbnailUrl,
    required this.capturedAt,
    required this.userAlias,
    this.rating = 0.0,
  });

  factory PhotoLocationMarker.fromJson(Map<String, dynamic> json) =>
      _$PhotoLocationMarkerFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoLocationMarkerToJson(this);
}

@JsonSerializable()
class CommunityHotspot {
  final String hotspotId;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final double averagePM25;
  final int photoCount;
  final List<String> sources;
  final String riskLevel;
  final List<PhotoLocationMarker> contributingPhotos;

  const CommunityHotspot({
    required this.hotspotId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.averagePM25,
    required this.photoCount,
    this.sources = const [],
    required this.riskLevel,
    this.contributingPhotos = const [],
  });

  factory CommunityHotspot.fromJson(Map<String, dynamic> json) =>
      _$CommunityHotspotFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityHotspotToJson(this);
}

@JsonSerializable()
class GamificationData {
  final String userId;
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final int totalPhotos;
  final int verifiedPhotos;
  final String currentRank;
  final int rankPosition;
  final List<Badge> badges;
  final List<Achievement> achievements;
  final List<Challenge> activeChallenges;
  final List<Challenge> completedChallenges;
  final Map<String, int> leaderboardScores;

  const GamificationData({
    required this.userId,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalPhotos = 0,
    this.verifiedPhotos = 0,
    this.currentRank = 'Rookie',
    this.rankPosition = 0,
    this.badges = const [],
    this.achievements = const [],
    this.activeChallenges = const [],
    this.completedChallenges = const [],
    this.leaderboardScores = const {},
  });

  factory GamificationData.fromJson(Map<String, dynamic> json) =>
      _$GamificationDataFromJson(json);

  Map<String, dynamic> toJson() => _$GamificationDataToJson(this);
}

@JsonSerializable()
class Badge {
  final String badgeId;
  final String name;
  final String description;
  final String iconUrl;
  final String category;
  final DateTime earnedAt;
  final int pointsRequired;

  const Badge({
    required this.badgeId,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.earnedAt,
    this.pointsRequired = 0,
  });

  factory Badge.fromJson(Map<String, dynamic> json) =>
      _$BadgeFromJson(json);

  Map<String, dynamic> toJson() => _$BadgeToJson(this);
}

@JsonSerializable()
class Achievement {
  final String achievementId;
  final String title;
  final String description;
  final String category;
  final double progress; // 0.0 to 1.0
  final int target;
  final int current;
  final DateTime completedAt;
  final int pointsAwarded;

  const Achievement({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.category,
    required this.progress,
    required this.target,
    required this.current,
    required this.completedAt,
    this.pointsAwarded = 0,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  bool get isCompleted => progress >= 1.0;
}

@JsonSerializable()
class Challenge {
  final String challengeId;
  final String title;
  final String description;
  final String type; // daily, weekly, monthly, special
  final int target;
  final int current;
  final DateTime startDate;
  final DateTime endDate;
  final int pointsReward;
  final String difficulty;
  final List<String> requirements;

  const Challenge({
    required this.challengeId,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.current,
    required this.startDate,
    required this.endDate,
    required this.pointsReward,
    required this.difficulty,
    this.requirements = const [],
  });

  factory Challenge.fromJson(Map<String, dynamic> json) =>
      _$ChallengeFromJson(json);

  Map<String, dynamic> toJson() => _$ChallengeToJson(this);

  double get progress => current / target;
  bool get isCompleted => current >= target;
  bool get isActive => DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
}

enum PhotoStatus {
  pending,
  approved,
  rejected,
  verified,
  flagged,
}

extension PhotoStatusExtension on PhotoStatus {
  String get displayName {
    switch (this) {
      case PhotoStatus.pending:
        return 'Pending Review';
      case PhotoStatus.approved:
        return 'Approved';
      case PhotoStatus.rejected:
        return 'Rejected';
      case PhotoStatus.verified:
        return 'Verified';
      case PhotoStatus.flagged:
        return 'Flagged';
    }
  }
  
  Color get color {
    switch (this) {
      case PhotoStatus.pending:
        return const Color(0xFFFFC107);
      case PhotoStatus.approved:
        return const Color(0xFF28A745);
      case PhotoStatus.rejected:
        return const Color(0xFFDC3545);
      case PhotoStatus.verified:
        return const Color(0xFF007BFF);
      case PhotoStatus.flagged:
        return const Color(0xFFFF5722);
    }
  }
}

enum VisibilityLevel {
  excellent,
  good,
  fair,
  poor,
  veryPoor,
}

extension VisibilityLevelExtension on VisibilityLevel {
  String get displayName {
    switch (this) {
      case VisibilityLevel.excellent:
        return 'Excellent';
      case VisibilityLevel.good:
        return 'Good';
      case VisibilityLevel.fair:
        return 'Fair';
      case VisibilityLevel.poor:
        return 'Poor';
      case VisibilityLevel.veryPoor:
        return 'Very Poor';
    }
  }
}
import 'package:json_annotation/json_annotation.dart';

part 'community_network_data.g.dart';

@JsonSerializable()
class CommunityUser {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime joinedAt;
  final CommunityRole role;
  final CommunityStats stats;
  final List<String> interests;
  final LocationPermission locationPermission;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? bio;
  final List<String> badges;

  const CommunityUser({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.joinedAt,
    this.role = CommunityRole.member,
    required this.stats,
    this.interests = const [],
    this.locationPermission = LocationPermission.neighbors,
    this.isOnline = false,
    this.lastSeen,
    this.bio,
    this.badges = const [],
  });

  factory CommunityUser.fromJson(Map<String, dynamic> json) =>
      _$CommunityUserFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityUserToJson(this);
}

enum CommunityRole {
  @JsonValue('admin')
  admin,
  @JsonValue('moderator')
  moderator,
  @JsonValue('member')
  member,
  @JsonValue('newcomer')
  newcomer,
  @JsonValue('honorary')
  honorary,
}

enum LocationPermission {
  @JsonValue('public')
  public,
  @JsonValue('neighbors')
  neighbors,
  @JsonValue('friends_only')
  friendsOnly,
  @JsonValue('private')
  private,
}

@JsonSerializable()
class CommunityStats {
  final int reportsSubmitted;
  final int reportsVerified;
  final int challengesCompleted;
  final int communityScore;
  final double reputationLevel;
  final List<String> achievements;

  const CommunityStats({
    this.reportsSubmitted = 0,
    this.reportsVerified = 0,
    this.challengesCompleted = 0,
    this.communityScore = 0,
    this.reputationLevel = 0.0,
    this.achievements = const [],
  });

  factory CommunityStats.fromJson(Map<String, dynamic> json) =>
      _$CommunityStatsFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityStatsToJson(this);
}

@JsonSerializable()
class AirQualityReport {
  final String reportId;
  final String reporterId;
  final String locationId;
  final double latitude;
  final double longitude;
  final String address;
  final double aqi;
  final AirQualityLevel level;
  final ReportType type;
  final Map<String, double> pollutantLevels;
  final String? description;
  final List<String> photos;
  final DateTime timestamp;
  final ReportStatus status;
  final List<String> verificationVotes;
  final int verificationScore;
  final List<String> comments;
  final String? weatherConditions;

  const AirQualityReport({
    required this.reportId,
    required this.reporterId,
    required this.locationId,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.aqi,
    required this.level,
    required this.type,
    required this.pollutantLevels,
    this.description,
    this.photos = const [],
    required this.timestamp,
    this.status = ReportStatus.pending,
    this.verificationVotes = const [],
    this.verificationScore = 0,
    this.comments = const [],
    this.weatherConditions,
  });

  factory AirQualityReport.fromJson(Map<String, dynamic> json) =>
      _$AirQualityReportFromJson(json);

  Map<String, dynamic> toJson() => _$AirQualityReportToJson(this);
}

enum ReportType {
  @JsonValue('official')
  official,
  @JsonValue('community')
  community,
  @JsonValue('sensor')
  sensor,
  @JsonValue('crowdsourced')
  crowdsourced,
}

enum ReportStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('verified')
  verified,
  @JsonValue('disputed')
  disputed,
  @JsonValue('expired')
  expired,
}

enum AirQualityLevel {
  @JsonValue('good')
  good,
  @JsonValue('moderate')
  moderate,
  @JsonValue('unhealthy_for_sensitive')
  unhealthyForSensitive,
  @JsonValue('unhealthy')
  unhealthy,
  @JsonValue('very_unhealthy')
  veryUnhealthy,
  @JsonValue('hazardous')
  hazardous,
}

@JsonSerializable()
class LocationReport {
  final String locationId;
  final String locationName;
  final String locationType;
  final double latitude;
  final double longitude;
  final List<AirQualityReport> reports;
  final double averageAQI;
  final int totalReports;
  final DateTime lastUpdated;
  final bool isActive;
  final Map<String, double> trendingData;

  const LocationReport({
    required this.locationId,
    required this.locationName,
    required this.locationType,
    required this.latitude,
    required this.longitude,
    this.reports = const [],
    this.averageAQI = 0.0,
    this.totalReports = 0,
    required this.lastUpdated,
    this.isActive = true,
    this.trendingData = const {},
  });

  factory LocationReport.fromJson(Map<String, dynamic> json) =>
      _$LocationReportFromJson(json);

  Map<String, dynamic> toJson() => _$LocationReportToJson(this);
}

@JsonSerializable()
class CommunityChallenge {
  final String challengeId;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeCategory category;
  final DateTime startDate;
  final DateTime endDate;
  final ChallengeStatus status;
  final int maxParticipants;
  final int currentParticipants;
  final int rewardPoints;
  final List<String> requirements;
  final Map<String, dynamic> challengeData;
  final List<ChallengeParticipant> participants;

  const CommunityChallenge({
    required this.challengeId,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.startDate,
    required this.endDate,
    this.status = ChallengeStatus.active,
    this.maxParticipants = 100,
    this.currentParticipants = 0,
    this.rewardPoints = 100,
    this.requirements = const [],
    this.challengeData = const {},
    this.participants = const [],
  });

  factory CommunityChallenge.fromJson(Map<String, dynamic> json) =>
      _$CommunityChallengeFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityChallengeToJson(this);
}

enum ChallengeType {
  @JsonValue('individual')
  individual,
  @JsonValue('team')
  team,
  @JsonValue('community')
  community,
  @JsonValue('location_based')
  locationBased,
  @JsonValue('time_based')
  timeBased,
}

enum ChallengeCategory {
  @JsonValue('air_quality_reporting')
  airQualityReporting,
  @JsonValue('clean_route_planning')
  cleanRoutePlanning,
  @JsonValue('health_improvement')
  healthImprovement,
  @JsonValue('environmental_action')
  environmentalAction,
  @JsonValue('education')
  education,
  @JsonValue('awareness')
  awareness,
}

enum ChallengeStatus {
  @JsonValue('upcoming')
  upcoming,
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

@JsonSerializable()
class ChallengeParticipant {
  final String participantId;
  final String userId;
  final String challengeId;
  final ParticipationStatus status;
  final DateTime joinedAt;
  final int score;
  final List<String> completedActions;
  final DateTime? lastActivity;

  const ChallengeParticipant({
    required this.participantId,
    required this.userId,
    required this.challengeId,
    this.status = ParticipationStatus.active,
    required this.joinedAt,
    this.score = 0,
    this.completedActions = const [],
    this.lastActivity,
  });

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) =>
      _$ChallengeParticipantFromJson(json);

  Map<String, dynamic> toJson() => _$ChallengeParticipantToJson(this);
}

enum ParticipationStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('withdrawn')
  withdrawn,
  @JsonValue('disqualified')
  disqualified,
}

@JsonSerializable()
class CommunityEvent {
  final String eventId;
  final String title;
  final String description;
  final EventType type;
  final DateTime startDate;
  final DateTime endDate;
  final EventStatus status;
  final String locationId;
  final String locationName;
  final double latitude;
  final double longitude;
  final int maxAttendees;
  final int currentAttendees;
  final List<String> tags;
  final List<EventAttendee> attendees;

  const CommunityEvent({
    required this.eventId,
    required this.title,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.status = EventStatus.upcoming,
    required this.locationId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.maxAttendees = 50,
    this.currentAttendees = 0,
    this.tags = const [],
    this.attendees = const [],
  });

  factory CommunityEvent.fromJson(Map<String, dynamic> json) =>
      _$CommunityEventFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityEventToJson(this);
}

enum EventType {
  @JsonValue('clean_up')
  cleanUp,
  @JsonValue('awareness_campaign')
  awarenessCampaign,
  @JsonValue('education_workshop')
  educationWorkshop,
  @JsonValue('data_collection')
  dataCollection,
  @JsonValue('meeting')
  meeting,
  @JsonValue('celebration')
  celebration,
}

enum EventStatus {
  @JsonValue('upcoming')
  upcoming,
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

@JsonSerializable()
class EventAttendee {
  final String attendeeId;
  final String userId;
  final String eventId;
  final AttendanceStatus status;
  final DateTime registeredAt;
  final DateTime? checkedInAt;

  const EventAttendee({
    required this.attendeeId,
    required this.userId,
    required this.eventId,
    this.status = AttendanceStatus.registered,
    required this.registeredAt,
    this.checkedInAt,
  });

  factory EventAttendee.fromJson(Map<String, dynamic> json) =>
      _$EventAttendeeFromJson(json);

  Map<String, dynamic> toJson() => _$EventAttendeeToJson(this);
}

enum AttendanceStatus {
  @JsonValue('registered')
  registered,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('attended')
  attended,
  @JsonValue('no_show')
  noShow,
  @JsonValue('cancelled')
  cancelled,
}

@JsonSerializable()
class CommunityGroup {
  final String groupId;
  final String name;
  final String description;
  final GroupType type;
  final int memberCount;
  final List<String> memberIds;
  final String creatorId;
  final DateTime createdAt;
  final bool isPrivate;
  final List<String> rules;
  final List<GroupActivity> activities;

  const CommunityGroup({
    required this.groupId,
    required this.name,
    required this.description,
    required this.type,
    this.memberCount = 0,
    this.memberIds = const [],
    required this.creatorId,
    required this.createdAt,
    this.isPrivate = false,
    this.rules = const [],
    this.activities = const [],
  });

  factory CommunityGroup.fromJson(Map<String, dynamic> json) =>
      _$CommunityGroupFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityGroupToJson(this);
}

enum GroupType {
  @JsonValue('neighborhood')
  neighborhood,
  @JsonValue('workplace')
  workplace,
  @JsonValue('school')
  school,
  @JsonValue('interest_based')
  interestBased,
  @JsonValue('location_based')
  locationBased,
  @JsonValue('general')
  general,
}

@JsonSerializable()
class GroupActivity {
  final String activityId;
  final String groupId;
  final String userId;
  final String content;
  final ActivityType type;
  final DateTime timestamp;
  final List<String> mediaUrls;
  final int likes;
  final List<String> comments;

  const GroupActivity({
    required this.activityId,
    required this.groupId,
    required this.userId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.mediaUrls = const [],
    this.likes = 0,
    this.comments = const [],
  });

  factory GroupActivity.fromJson(Map<String, dynamic> json) =>
      _$GroupActivityFromJson(json);

  Map<String, dynamic> toJson() => _$GroupActivityToJson(this);
}

enum ActivityType {
  @JsonValue('post')
  post,
  @JsonValue('report_sharing')
  reportSharing,
  @JsonValue('achievement')
  achievement,
  @JsonValue('discussion')
  discussion,
  @JsonValue('event_creation')
  eventCreation,
}

@JsonSerializable()
class CommunityMessage {
  final String messageId;
  final String senderId;
  final String recipientId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final List<String> attachments;
  final String? replyToId;

  const CommunityMessage({
    required this.messageId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.attachments = const [],
    this.replyToId,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json) =>
      _$CommunityMessageFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityMessageToJson(this);
}

enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('location_share')
  locationShare,
  @JsonValue('air_quality_alert')
  airQualityAlert,
  @JsonValue('health_warning')
  healthWarning,
  @JsonValue('report_invitation')
  reportInvitation,
  @JsonValue('achievement_share')
  achievementShare,
}

enum MessageStatus {
  @JsonValue('sent')
  sent,
  @JsonValue('delivered')
  delivered,
  @JsonValue('read')
  read,
  @JsonValue('failed')
  failed,
}

@JsonSerializable()
class CommunityMap {
  final String mapId;
  final String name;
  final MapType type;
  final List<MapMarker> markers;
  final Map<String, dynamic> mapData;
  final DateTime lastUpdated;
  final bool isPublic;

  const CommunityMap({
    required this.mapId,
    required this.name,
    required this.type,
    this.markers = const [],
    this.mapData = const {},
    required this.lastUpdated,
    this.isPublic = true,
  });

  factory CommunityMap.fromJson(Map<String, dynamic> json) =>
      _$CommunityMapFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityMapToJson(this);
}

enum MapType {
  @JsonValue('air_quality_heatmap')
  airQualityHeatmap,
  @JsonValue('report_locations')
  reportLocations,
  @JsonValue('healthy_routes')
  healthyRoutes,
  @JsonValue('community_points')
  communityPoints,
  @JsonValue('event_locations')
  eventLocations,
}

@JsonSerializable()
class MapMarker {
  final String markerId;
  final double latitude;
  final double longitude;
  final String title;
  final String? description;
  final MarkerType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const MapMarker({
    required this.markerId,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.description,
    required this.type,
    required this.timestamp,
    this.data = const {},
  });

  factory MapMarker.fromJson(Map<String, dynamic> json) =>
      _$MapMarkerFromJson(json);

  Map<String, dynamic> toJson() => _$MapMarkerToJson(this);
}

enum MarkerType {
  @JsonValue('air_quality_report')
  airQualityReport,
  @JsonValue('healthy_location')
  healthyLocation,
  @JsonValue('pollution_source')
  pollutionSource,
  @JsonValue('community_event')
  communityEvent,
  @JsonValue('user_location')
  userLocation,
  @JsonValue('route_point')
  routePoint,
}

@JsonSerializable()
class CommunityAnalytics {
  final String analyticsId;
  final DateTime period;
  final CommunityMetrics totalMetrics;
  final Map<String, double> geographicData;
  final Map<String, dynamic> trendingTopics;
  final List<String> topContributors;
  final Map<String, int> activityBreakdown;

  const CommunityAnalytics({
    required this.analyticsId,
    required this.period,
    required this.totalMetrics,
    this.geographicData = const {},
    this.trendingTopics = const {},
    this.topContributors = const [],
    this.activityBreakdown = const {},
  });

  factory CommunityAnalytics.fromJson(Map<String, dynamic> json) =>
      _$CommunityAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityAnalyticsToJson(this);
}

@JsonSerializable()
class CommunityMetrics {
  final int totalUsers;
  final int activeUsers;
  final int totalReports;
  final int verifiedReports;
  final int completedChallenges;
  final int totalEvents;
  final double averageAQI;
  final double communityEngagementScore;

  const CommunityMetrics({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.totalReports = 0,
    this.verifiedReports = 0,
    this.completedChallenges = 0,
    this.totalEvents = 0,
    this.averageAQI = 0.0,
    this.communityEngagementScore = 0.0,
  });

  factory CommunityMetrics.fromJson(Map<String, dynamic> json) =>
      _$CommunityMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityMetricsToJson(this);
}

@JsonSerializable()
class CommunityNotification {
  final String notificationId;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic> data;

  const CommunityNotification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.actionUrl,
    this.data = const {},
  });

  factory CommunityNotification.fromJson(Map<String, dynamic> json) =>
      _$CommunityNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityNotificationToJson(this);
}

enum NotificationType {
  @JsonValue('air_quality_alert')
  airQualityAlert,
  @JsonValue('challenge_invite')
  challengeInvite,
  @JsonValue('event_reminder')
  eventReminder,
  @JsonValue('achievement_unlocked')
  achievementUnlocked,
  @JsonValue('community_update')
  communityUpdate,
  @JsonValue('friend_activity')
  friendActivity,
  @JsonValue('report_verification')
  reportVerification,
}
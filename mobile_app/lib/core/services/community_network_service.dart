import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/community_network_data.dart';
import 'location_service.dart'; // Assuming this exists
import 'notification_service.dart'; // Assuming this exists

class CommunityNetworkService {
  static const String TAG = 'CommunityNetworkService';
  
  late final Dio _dio;
  late final FirebaseAuth _firebaseAuth;
  late final FirebaseFirestore _firestore;
  late final LocationService _locationService;
  late final NotificationService _notificationService;
  
  late IO.Socket _socket;
  StreamSubscription? _realTimeSubscription;
  StreamController<CommunityNotification> _notificationController = StreamController.broadcast();
  StreamController<AirQualityReport> _reportController = StreamController.broadcast();
  StreamController<CommunityEvent> _eventController = StreamController.broadcast();
  
  String? _currentUserId;
  CommunityUser? _currentUser;
  
  // Cache for frequently accessed data
  final Map<String, AirQualityReport> _reportsCache = {};
  final Map<String, CommunityEvent> _eventsCache = {};
  final Map<String, CommunityGroup> _groupsCache = {};

  CommunityNetworkService() {
    _dio = Dio();
    _firebaseAuth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _locationService = LocationService();
    _notificationService = NotificationService();
    
    _initializeRealTimeConnection();
  }

  void _initializeRealTimeConnection() {
    try {
      _socket = IO.io('https://your-community-server.com', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });
      
      _socket.onConnect((_) {
        print('Connected to community server');
        if (_currentUserId != null) {
          _socket.emit('user_online', _currentUserId);
        }
      });
      
      _socket.onDisconnect((_) {
        print('Disconnected from community server');
      });
      
      _socket.on('new_report', (data) {
        _handleNewReport(data);
      });
      
      _socket.on('new_event', (data) {
        _handleNewEvent(data);
      });
      
      _socket.on('community_notification', (data) {
        _handleCommunityNotification(data);
      });
      
    } catch (e) {
      print('Failed to initialize real-time connection: $e');
    }
  }

  // User Management
  Future<CommunityUser> createOrUpdateUserProfile(CommunityUser userProfile) async {
    try {
      // Authenticate user if not already authenticated
      if (_firebaseAuth.currentUser == null) {
        throw Exception('User must be authenticated');
      }
      
      _currentUserId = _firebaseAuth.currentUser!.uid;
      final user = userProfile.copyWith(
        userId: _currentUserId,
        joinedAt: DateTime.now(),
        isOnline: true,
        lastSeen: DateTime.now(),
      );
      
      // Save to Firestore
      await _firestore.collection('users').doc(_currentUserId).set(user.toJson());
      
      // Cache user data
      _currentUser = user;
      
      // Connect to real-time services
      _connectToRealTimeServices();
      
      return user;
    } catch (e) {
      throw Exception('Failed to create/update user profile: $e');
    }
  }

  Future<CommunityUser> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        throw Exception('User profile not found');
      }
      
      return CommunityUser.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<List<CommunityUser>> getNearbyUsers({
    double latitude = 0.0,
    double longitude = 0.0,
    double radiusInKm = 10.0,
    int limit = 50,
  }) async {
    try {
      if (latitude == 0.0 || longitude == 0.0) {
        final location = await _locationService.getCurrentLocation();
        latitude = location.latitude;
        longitude = location.longitude;
      }
      
      // Get users within radius using geohash or geofirestore
      final QuerySnapshot query = await _firestore
        .collection('users')
        .where('locationPermission', whereIn: ['public', 'neighbors'])
        .limit(limit)
        .get();
      
      final List<CommunityUser> nearbyUsers = [];
      
      for (final doc in query.docs) {
        final user = CommunityUser.fromJson(doc.data() as Map<String, dynamic>);
        
        // Calculate distance
        final distance = _calculateDistance(
          latitude, 
          longitude, 
          0.0, // Assuming we don't have user location stored
          0.0,
        );
        
        if (distance <= radiusInKm) {
          nearbyUsers.add(user);
        }
      }
      
      return nearbyUsers;
    } catch (e) {
      throw Exception('Failed to get nearby users: $e');
    }
  }

  // Air Quality Reporting
  Future<AirQualityReport> submitAirQualityReport({
    required double latitude,
    required double longitude,
    required String address,
    required double aqi,
    required AirQualityLevel level,
    required ReportType type,
    Map<String, double>? pollutantLevels,
    String? description,
    List<String>? photos,
    String? weatherConditions,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be authenticated');
      }
      
      final report = AirQualityReport(
        reportId: 'report_${DateTime.now().millisecondsSinceEpoch}',
        reporterId: _currentUserId!,
        locationId: _generateLocationId(latitude, longitude),
        latitude: latitude,
        longitude: longitude,
        address: address,
        aqi: aqi,
        level: level,
        type: type,
        pollutantLevels: pollutantLevels ?? {},
        description: description,
        photos: photos ?? [],
        timestamp: DateTime.now(),
        status: ReportStatus.pending,
        verificationVotes: [],
        verificationScore: 0,
        comments: [],
        weatherConditions: weatherConditions,
      );
      
      // Save to Firestore
      await _firestore.collection('reports').doc(report.reportId).set(report.toJson());
      
      // Emit real-time update
      _socket.emit('new_report', report.toJson());
      
      // Cache the report
      _reportsCache[report.reportId] = report;
      
      // Emit to local stream
      _reportController.add(report);
      
      // Send notifications to nearby users
      await _notifyNearbyUsersOfReport(report);
      
      return report;
    } catch (e) {
      throw Exception('Failed to submit air quality report: $e');
    }
  }

  Future<List<AirQualityReport>> getAirQualityReports({
    double? latitude,
    double? longitude,
    double radiusInKm = 10.0,
    DateTime? startDate,
    DateTime? endDate,
    AirQualityLevel? minLevel,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('reports');
      
      // Add date filters
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      // Add level filter
      if (minLevel != null) {
        query = query.where('level', isGreaterThanOrEqualTo: minLevel.toString());
      }
      
      final QuerySnapshot querySnapshot = await query
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
      
      final List<AirQualityReport> reports = [];
      
      for (final doc in querySnapshot.docs) {
        final report = AirQualityReport.fromJson(doc.data() as Map<String, dynamic>);
        
        // Apply location filter if specified
        if (latitude != null && longitude != null) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            report.latitude,
            report.longitude,
          );
          
          if (distance <= radiusInKm) {
            reports.add(report);
          }
        } else {
          reports.add(report);
        }
      }
      
      // Cache reports
      for (final report in reports) {
        _reportsCache[report.reportId] = report;
      }
      
      return reports;
    } catch (e) {
      throw Exception('Failed to get air quality reports: $e');
    }
  }

  Future<void> verifyReport(String reportId, bool isAccurate) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be authenticated');
      }
      
      final reportRef = _firestore.collection('reports').doc(reportId);
      final reportDoc = await reportRef.get();
      
      if (!reportDoc.exists) {
        throw Exception('Report not found');
      }
      
      final report = AirQualityReport.fromJson(reportDoc.data()!);
      
      // Check if user already voted
      if (report.verificationVotes.contains(_currentUserId)) {
        throw Exception('User has already voted on this report');
      }
      
      // Update verification votes
      final updatedVotes = List<String>.from(report.verificationVotes);
      updatedVotes.add(_currentUserId!);
      
      // Update verification score
      final updatedScore = report.verificationScore + (isAccurate ? 1 : -1);
      
      // Update report status based on score
      ReportStatus newStatus = report.status;
      if (updatedScore >= 5) {
        newStatus = ReportStatus.verified;
      } else if (updatedScore <= -3) {
        newStatus = ReportStatus.disputed;
      }
      
      final updatedReport = report.copyWith(
        verificationVotes: updatedVotes,
        verificationScore: updatedScore,
        status: newStatus,
      );
      
      await reportRef.update(updatedReport.toJson());
      
      // Emit real-time update
      _socket.emit('report_updated', updatedReport.toJson());
      
      // Update cache
      _reportsCache[reportId] = updatedReport;
      
    } catch (e) {
      throw Exception('Failed to verify report: $e');
    }
  }

  // Community Challenges
  Future<CommunityChallenge> createCommunityChallenge({
    required String title,
    required String description,
    required ChallengeType type,
    required ChallengeCategory category,
    required DateTime startDate,
    required DateTime endDate,
    int maxParticipants = 100,
    int rewardPoints = 100,
    List<String>? requirements,
    Map<String, dynamic>? challengeData,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be authenticated');
      }
      
      final challenge = CommunityChallenge(
        challengeId: 'challenge_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        type: type,
        category: category,
        startDate: startDate,
        endDate: endDate,
        status: ChallengeStatus.active,
        maxParticipants: maxParticipants,
        currentParticipants: 0,
        rewardPoints: rewardPoints,
        requirements: requirements ?? [],
        challengeData: challengeData ?? {},
        participants: [],
      );
      
      // Save to Firestore
      await _firestore.collection('challenges').doc(challenge.challengeId).set(challenge.toJson());
      
      // Emit real-time update
      _socket.emit('new_challenge', challenge.toJson());
      
      return challenge;
    } catch (e) {
      throw Exception('Failed to create community challenge: $e');
    }
  }

  Future<List<CommunityChallenge>> getActiveChallenges({
    ChallengeCategory? category,
    ChallengeType? type,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('challenges')
        .where('status', isEqualTo: ChallengeStatus.active.toString())
        .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()));
      
      if (category != null) {
        query = query.where('category', isEqualTo: category.toString());
      }
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.toString());
      }
      
      final QuerySnapshot querySnapshot = await query
        .orderBy('startDate', descending: true)
        .limit(limit)
        .get();
      
      final List<CommunityChallenge> challenges = [];
      
      for (final doc in querySnapshot.docs) {
        challenges.add(CommunityChallenge.fromJson(doc.data() as Map<String, dynamic>));
      }
      
      return challenges;
    } catch (e) {
      throw Exception('Failed to get active challenges: $e');
    }
  }

  Future<ChallengeParticipant> joinChallenge(String challengeId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be authenticated');
      }
      
      final challengeRef = _firestore.collection('challenges').doc(challengeId);
      final challengeDoc = await challengeRef.get();
      
      if (!challengeDoc.exists) {
        throw Exception('Challenge not found');
      }
      
      final challenge = CommunityChallenge.fromJson(challengeDoc.data()!);
      
      // Check if user already joined
      final existingParticipant = challenge.participants
          .firstWhere((p) => p.userId == _currentUserId, orElse: () => throw Exception('Not joined'));
      
      // Check if challenge is full
      if (challenge.currentParticipants >= challenge.maxParticipants) {
        throw Exception('Challenge is full');
      }
      
      // Create participant record
      final participant = ChallengeParticipant(
        participantId: 'participant_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUserId!,
        challengeId: challengeId,
        status: ParticipationStatus.active,
        joinedAt: DateTime.now(),
        score: 0,
        completedActions: [],
        lastActivity: DateTime.now(),
      );
      
      // Update challenge with new participant
      final updatedParticipants = List<ChallengeParticipant>.from(challenge.participants);
      updatedParticipants.add(participant);
      
      final updatedChallenge = challenge.copyWith(
        currentParticipants: challenge.currentParticipants + 1,
        participants: updatedParticipants,
      );
      
      await challengeRef.update(updatedChallenge.toJson());
      
      // Save participant record
      await _firestore.collection('participants').doc(participant.participantId).set(participant.toJson());
      
      return participant;
    } catch (e) {
      throw Exception('Failed to join challenge: $e');
    }
  }

  // Community Events
  Future<CommunityEvent> createCommunityEvent({
    required String title,
    required String description,
    required EventType type,
    required DateTime startDate,
    required DateTime endDate,
    required String locationId,
    required String locationName,
    required double latitude,
    required double longitude,
    int maxAttendees = 50,
    List<String>? tags,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be authenticated');
      }
      
      final event = CommunityEvent(
        eventId: 'event_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        type: type,
        startDate: startDate,
        endDate: endDate,
        status: EventStatus.upcoming,
        locationId: locationId,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        maxAttendees: maxAttendees,
        currentAttendees: 0,
        tags: tags ?? [],
        attendees: [],
      );
      
      // Save to Firestore
      await _firestore.collection('events').doc(event.eventId).set(event.toJson());
      
      // Emit real-time update
      _socket.emit('new_event', event.toJson());
      
      // Cache the event
      _eventsCache[event.eventId] = event;
      
      // Emit to local stream
      _eventController.add(event);
      
      // Notify nearby users
      await _notifyNearbyUsersOfEvent(event);
      
      return event;
    } catch (e) {
      throw Exception('Failed to create community event: $e');
    }
  }

  Future<List<CommunityEvent>> getNearbyEvents({
    double? latitude,
    double? longitude,
    double radiusInKm = 25.0,
    DateTime? startDate,
    DateTime? endDate,
    EventType? type,
    int limit = 50,
  }) async {
    try {
      if (latitude == null || longitude == null) {
        final location = await _locationService.getCurrentLocation();
        latitude = location.latitude;
        longitude = location.longitude;
      }
      
      Query query = _firestore.collection('events')
        .where('status', whereIn: [EventStatus.upcoming.toString(), EventStatus.active.toString()]);
      
      if (startDate != null) {
        query = query.where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.toString());
      }
      
      final QuerySnapshot querySnapshot = await query
        .orderBy('startDate', descending: true)
        .limit(limit)
        .get();
      
      final List<CommunityEvent> nearbyEvents = [];
      
      for (final doc in querySnapshot.docs) {
        final event = CommunityEvent.fromJson(doc.data() as Map<String, dynamic>);
        
        // Calculate distance
        final distance = _calculateDistance(
          latitude!,
          longitude!,
          event.latitude,
          event.longitude,
        );
        
        if (distance <= radiusInKm) {
          nearbyEvents.add(event);
        }
      }
      
      // Cache events
      for (final event in nearbyEvents) {
        _eventsCache[event.eventId] = event;
      }
      
      return nearbyEvents;
    } catch (e) {
      throw Exception('Failed to get nearby events: $e');
    }
  }

  Future<EventAttendee> registerForEvent(String eventId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be authenticated');
      }
      
      final eventRef = _firestore.collection('events').doc(eventId);
      final eventDoc = await eventRef.get();
      
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }
      
      final event = CommunityEvent.fromJson(eventDoc.data()!);
      
      // Check if user already registered
      final existingAttendee = event.attendees
          .firstWhere((a) => a.userId == _currentUserId, orElse: () => throw Exception('Already registered'));
      
      // Check if event is full
      if (event.currentAttendees >= event.maxAttendees) {
        throw Exception('Event is full');
      }
      
      // Create attendee record
      final attendee = EventAttendee(
        attendeeId: 'attendee_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUserId!,
        eventId: eventId,
        status: AttendanceStatus.registered,
        registeredAt: DateTime.now(),
      );
      
      // Update event with new attendee
      final updatedAttendees = List<EventAttendee>.from(event.attendees);
      updatedAttendees.add(attendee);
      
      final updatedEvent = event.copyWith(
        currentAttendees: event.currentAttendees + 1,
        attendees: updatedAttendees,
      );
      
      await eventRef.update(updatedEvent.toJson());
      
      // Save attendee record
      await _firestore.collection('event_attendees').doc(attendee.attendeeId).set(attendee.toJson());
      
      return attendee;
    } catch (e) {
      throw Exception('Failed to register for event: $e');
    }
  }

  // Community Groups
  Future<CommunityGroup> createCommunityGroup({
    required String name,
    required String description,
    required GroupType type,
    bool isPrivate = false,
    List<String>? rules,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be authenticated');
      }
      
      final group = CommunityGroup(
        groupId: 'group_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        type: type,
        memberCount: 1,
        memberIds: [_currentUserId!],
        creatorId: _currentUserId!,
        createdAt: DateTime.now(),
        isPrivate: isPrivate,
        rules: rules ?? [],
        activities: [],
      );
      
      // Save to Firestore
      await _firestore.collection('groups').doc(group.groupId).set(group.toJson());
      
      // Cache the group
      _groupsCache[group.groupId] = group;
      
      return group;
    } catch (e) {
      throw Exception('Failed to create community group: $e');
    }
  }

  Future<List<CommunityGroup>> getNearbyGroups({
    double? latitude,
    double? longitude,
    double radiusInKm = 50.0,
    GroupType? type,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('groups');
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.toString());
      }
      
      final QuerySnapshot querySnapshot = await query
        .orderBy('memberCount', descending: true)
        .limit(limit)
        .get();
      
      final List<CommunityGroup> groups = [];
      
      for (final doc in querySnapshot.docs) {
        groups.add(CommunityGroup.fromJson(doc.data() as Map<String, dynamic>));
      }
      
      return groups;
    } catch (e) {
      throw Exception('Failed to get community groups: $e');
    }
  }

  // Real-time Features
  void _handleNewReport(Map<String, dynamic> data) {
    try {
      final report = AirQualityReport.fromJson(data);
      _reportController.add(report);
      _reportsCache[report.reportId] = report;
    } catch (e) {
      print('Failed to handle new report: $e');
    }
  }

  void _handleNewEvent(Map<String, dynamic> data) {
    try {
      final event = CommunityEvent.fromJson(data);
      _eventController.add(event);
      _eventsCache[event.eventId] = event;
    } catch (e) {
      print('Failed to handle new event: $e');
    }
  }

  void _handleCommunityNotification(Map<String, dynamic> data) {
    try {
      final notification = CommunityNotification.fromJson(data);
      _notificationController.add(notification);
    } catch (e) {
      print('Failed to handle community notification: $e');
    }
  }

  // Community Map Features
  Future<CommunityMap> createCommunityMap({
    required String name,
    required MapType type,
    bool isPublic = true,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be authenticated');
      }
      
      final map = CommunityMap(
        mapId: 'map_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: type,
        markers: [],
        mapData: {},
        lastUpdated: DateTime.now(),
        isPublic: isPublic,
      );
      
      await _firestore.collection('maps').doc(map.mapId).set(map.toJson());
      
      return map;
    } catch (e) {
      throw Exception('Failed to create community map: $e');
    }
  }

  Future<void> addMapMarker(CommunityMap map, MapMarker marker) async {
    try {
      final updatedMarkers = List<MapMarker>.from(map.markers);
      updatedMarkers.add(marker);
      
      final updatedMap = map.copyWith(
        markers: updatedMarkers,
        lastUpdated: DateTime.now(),
      );
      
      await _firestore.collection('maps').doc(map.mapId).update(updatedMap.toJson());
      
      // Emit real-time update
      _socket.emit('map_updated', updatedMap.toJson());
    } catch (e) {
      throw Exception('Failed to add map marker: $e');
    }
  }

  // Analytics and Insights
  Future<CommunityAnalytics> generateCommunityAnalytics(DateTime period) async {
    try {
      // Get community metrics
      final totalMetrics = await _calculateCommunityMetrics(period);
      
      // Get geographic data
      final geographicData = await _calculateGeographicData(period);
      
      // Get trending topics
      final trendingTopics = await _calculateTrendingTopics(period);
      
      // Get top contributors
      final topContributors = await _calculateTopContributors(period);
      
      // Get activity breakdown
      final activityBreakdown = await _calculateActivityBreakdown(period);
      
      return CommunityAnalytics(
        analyticsId: 'analytics_${DateTime.now().millisecondsSinceEpoch}',
        period: period,
        totalMetrics: totalMetrics,
        geographicData: geographicData,
        trendingTopics: trendingTopics,
        topContributors: topContributors,
        activityBreakdown: activityBreakdown,
      );
    } catch (e) {
      throw Exception('Failed to generate community analytics: $e');
    }
  }

  Future<CommunityMetrics> _calculateCommunityMetrics(DateTime period) async {
    // Calculate various community metrics
    final userCount = await _getTotalUserCount();
    final activeUsers = await _getActiveUserCount(period);
    final reportCount = await _getReportCount(period);
    final verifiedReports = await _getVerifiedReportCount(period);
    final completedChallenges = await _getCompletedChallengeCount(period);
    final eventCount = await _getEventCount(period);
    final averageAQI = await _getAverageAQI(period);
    final engagementScore = await _calculateEngagementScore(period);
    
    return CommunityMetrics(
      totalUsers: userCount,
      activeUsers: activeUsers,
      totalReports: reportCount,
      verifiedReports: verifiedReports,
      completedChallenges: completedChallenges,
      totalEvents: eventCount,
      averageAQI: averageAQI,
      communityEngagementScore: engagementScore,
    );
  }

  Future<int> _getTotalUserCount() async {
    final query = await _firestore.collection('users').count().get();
    return query.count;
  }

  Future<int> _getActiveUserCount(DateTime period) async {
    final startDate = Timestamp.fromDate(period);
    final query = await _firestore
      .collection('users')
      .where('lastSeen', isGreaterThanOrEqualTo: startDate)
      .count()
      .get();
    return query.count;
  }

  Future<int> _getReportCount(DateTime period) async {
    final startDate = Timestamp.fromDate(period);
    final query = await _firestore
      .collection('reports')
      .where('timestamp', isGreaterThanOrEqualTo: startDate)
      .count()
      .get();
    return query.count;
  }

  Future<int> _getVerifiedReportCount(DateTime period) async {
    final startDate = Timestamp.fromDate(period);
    final query = await _firestore
      .collection('reports')
      .where('timestamp', isGreaterThanOrEqualTo: startDate)
      .where('status', isEqualTo: ReportStatus.verified.toString())
      .count()
      .get();
    return query.count;
  }

  Future<int> _getCompletedChallengeCount(DateTime period) async {
    final startDate = Timestamp.fromDate(period);
    final query = await _firestore
      .collection('challenges')
      .where('startDate', isGreaterThanOrEqualTo: startDate)
      .where('status', isEqualTo: ChallengeStatus.completed.toString())
      .count()
      .get();
    return query.count;
  }

  Future<int> _getEventCount(DateTime period) async {
    final startDate = Timestamp.fromDate(period);
    final query = await _firestore
      .collection('events')
      .where('startDate', isGreaterThanOrEqualTo: startDate)
      .count()
      .get();
    return query.count;
  }

  Future<double> _getAverageAQI(DateTime period) async {
    final startDate = Timestamp.fromDate(period);
    final query = await _firestore
      .collection('reports')
      .where('timestamp', isGreaterThanOrEqualTo: startDate)
      .get();
    
    if (query.docs.isEmpty) return 50.0;
    
    final totalAQI = query.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['aqi'] as double)
        .reduce((a, b) => a + b);
    
    return totalAQI / query.docs.length;
  }

  Future<double> _calculateEngagementScore(DateTime period) async {
    // Calculate community engagement score based on various metrics
    // This is a simplified calculation
    return 75.0; // Placeholder
  }

  // Utility Methods
  void _connectToRealTimeServices() {
    if (!_socket.connected) {
      _socket.connect();
    }
  }

  void _disconnectFromRealTimeServices() {
    if (_socket.connected) {
      _socket.disconnect();
    }
  }

  Future<void> _notifyNearbyUsersOfReport(AirQualityReport report) async {
    // Notify users about new air quality report
    // Implementation would send push notifications to nearby users
  }

  Future<void> _notifyNearbyUsersOfEvent(CommunityEvent event) async {
    // Notify users about new community event
    // Implementation would send push notifications to nearby users
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth's radius in kilometers
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  String _generateLocationId(double latitude, double longitude) {
    // Generate a unique location ID based on coordinates
    return '${latitude.toStringAsFixed(6)}_${longitude.toStringAsFixed(6)}';
  }

  // Public Stream Accessors
  Stream<CommunityNotification> get notificationStream => _notificationController.stream;
  Stream<AirQualityReport> get reportStream => _reportController.stream;
  Stream<CommunityEvent> get eventStream => _eventController.stream;
  
  // Getters
  CommunityUser? get currentUser => _currentUser;
  bool get isConnected => _socket.connected;
  int get connectedUserCount => _reportsCache.length; // Simplified

  // Cleanup
  void dispose() {
    _realTimeSubscription?.cancel();
    _notificationController.close();
    _reportController.close();
    _eventController.close();
    _disconnectFromRealTimeServices();
  }
}

// Extension for CommunityEvent
extension CommunityEventExtension on CommunityEvent {
  CommunityEvent copyWith({
    String? eventId,
    String? title,
    String? description,
    EventType? type,
    DateTime? startDate,
    DateTime? endDate,
    EventStatus? status,
    String? locationId,
    String? locationName,
    double? latitude,
    double? longitude,
    int? maxAttendees,
    int? currentAttendees,
    List<String>? tags,
    List<EventAttendee>? attendees,
  }) {
    return CommunityEvent(
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      currentAttendees: currentAttendees ?? this.currentAttendees,
      tags: tags ?? this.tags,
      attendees: attendees ?? this.attendees,
    );
  }
}

// Extension for CommunityMap
extension CommunityMapExtension on CommunityMap {
  CommunityMap copyWith({
    String? mapId,
    String? name,
    MapType? type,
    List<MapMarker>? markers,
    Map<String, dynamic>? mapData,
    DateTime? lastUpdated,
    bool? isPublic,
  }) {
    return CommunityMap(
      mapId: mapId ?? this.mapId,
      name: name ?? this.name,
      type: type ?? this.type,
      markers: markers ?? this.markers,
      mapData: mapData ?? this.mapData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
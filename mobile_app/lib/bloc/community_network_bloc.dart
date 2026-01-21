import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/community_network_data.dart';
import '../core/services/community_network_service.dart';

abstract class CommunityNetworkEvent {}

class InitializeUserEvent extends CommunityNetworkEvent {
  final CommunityUser userProfile;
  
  const InitializeUserEvent(this.userProfile);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InitializeUserEvent && runtimeType == other.runtimeType && userProfile == other.userProfile;
  
  @override
  int get hashCode => userProfile.hashCode;
}

class SubmitAirQualityReportEvent extends CommunityNetworkEvent {
  final double latitude;
  final double longitude;
  final String address;
  final double aqi;
  final AirQualityLevel level;
  final ReportType type;
  final Map<String, double>? pollutantLevels;
  final String? description;
  final List<String>? photos;
  final String? weatherConditions;
  
  const SubmitAirQualityReportEvent({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.aqi,
    required this.level,
    required this.type,
    this.pollutantLevels,
    this.description,
    this.photos,
    this.weatherConditions,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmitAirQualityReportEvent &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          address == other.address &&
          aqi == other.aqi &&
          level == other.level &&
          type == other.type &&
          pollutantLevels == other.pollutantLevels &&
          description == other.description &&
          photos == other.photos &&
          weatherConditions == other.weatherConditions;
  
  @override
  int get hashCode => latitude.hashCode ^
      longitude.hashCode ^
      address.hashCode ^
      aqi.hashCode ^
      level.hashCode ^
      type.hashCode ^
      pollutantLevels.hashCode ^
      description.hashCode ^
      photos.hashCode ^
      weatherConditions.hashCode;
}

class GetNearbyReportsEvent extends CommunityNetworkEvent {
  final double? latitude;
  final double? longitude;
  final double radiusInKm;
  final DateTime? startDate;
  final DateTime? endDate;
  final AirQualityLevel? minLevel;
  final int limit;
  
  const GetNearbyReportsEvent({
    this.latitude,
    this.longitude,
    this.radiusInKm = 10.0,
    this.startDate,
    this.endDate,
    this.minLevel,
    this.limit = 100,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetNearbyReportsEvent &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radiusInKm == other.radiusInKm &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          minLevel == other.minLevel &&
          limit == other.limit;
  
  @override
  int get hashCode => latitude.hashCode ^
      longitude.hashCode ^
      radiusInKm.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      minLevel.hashCode ^
      limit.hashCode;
}

class VerifyReportEvent extends CommunityNetworkEvent {
  final String reportId;
  final bool isAccurate;
  
  const VerifyReportEvent(this.reportId, this.isAccurate);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerifyReportEvent && runtimeType == other.runtimeType && reportId == other.reportId && isAccurate == other.isAccurate;
  
  @override
  int get hashCode => reportId.hashCode ^ isAccurate.hashCode;
}

class CreateChallengeEvent extends CommunityNetworkEvent {
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeCategory category;
  final DateTime startDate;
  final DateTime endDate;
  final int maxParticipants;
  final int rewardPoints;
  final List<String>? requirements;
  final Map<String, dynamic>? challengeData;
  
  const CreateChallengeEvent({
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.startDate,
    required this.endDate,
    this.maxParticipants = 100,
    this.rewardPoints = 100,
    this.requirements,
    this.challengeData,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateChallengeEvent &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          description == other.description &&
          type == other.type &&
          category == other.category &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          maxParticipants == other.maxParticipants &&
          rewardPoints == other.rewardPoints &&
          requirements == other.requirements &&
          challengeData == other.challengeData;
  
  @override
  int get hashCode => title.hashCode ^
      description.hashCode ^
      type.hashCode ^
      category.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      maxParticipants.hashCode ^
      rewardPoints.hashCode ^
      requirements.hashCode ^
      challengeData.hashCode;
}

class GetActiveChallengesEvent extends CommunityNetworkEvent {
  final ChallengeCategory? category;
  final ChallengeType? type;
  final int limit;
  
  const GetActiveChallengesEvent({
    this.category,
    this.type,
    this.limit = 20,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetActiveChallengesEvent &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          type == other.type &&
          limit == other.limit;
  
  @override
  int get hashCode => category.hashCode ^ type.hashCode ^ limit.hashCode;
}

class JoinChallengeEvent extends CommunityNetworkEvent {
  final String challengeId;
  
  const JoinChallengeEvent(this.challengeId);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JoinChallengeEvent && runtimeType == other.runtimeType && challengeId == other.challengeId;
  
  @override
  int get hashCode => challengeId.hashCode;
}

class CreateEventEvent extends CommunityNetworkEvent {
  final String title;
  final String description;
  final EventType type;
  final DateTime startDate;
  final DateTime endDate;
  final String locationId;
  final String locationName;
  final double latitude;
  final double longitude;
  final int maxAttendees;
  final List<String>? tags;
  
  const CreateEventEvent({
    required this.title,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.locationId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.maxAttendees = 50,
    this.tags,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateEventEvent &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          description == other.description &&
          type == other.type &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          locationId == other.locationId &&
          locationName == other.locationName &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          maxAttendees == other.maxAttendees &&
          tags == other.tags;
  
  @override
  int get hashCode => title.hashCode ^
      description.hashCode ^
      type.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      locationId.hashCode ^
      locationName.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      maxAttendees.hashCode ^
      tags.hashCode;
}

class GetNearbyEventsEvent extends CommunityNetworkEvent {
  final double? latitude;
  final double? longitude;
  final double radiusInKm;
  final DateTime? startDate;
  final DateTime? endDate;
  final EventType? type;
  final int limit;
  
  const GetNearbyEventsEvent({
    this.latitude,
    this.longitude,
    this.radiusInKm = 25.0,
    this.startDate,
    this.endDate,
    this.type,
    this.limit = 50,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetNearbyEventsEvent &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radiusInKm == other.radiusInKm &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          type == other.type &&
          limit == other.limit;
  
  @override
  int get hashCode => latitude.hashCode ^
      longitude.hashCode ^
      radiusInKm.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      type.hashCode ^
      limit.hashCode;
}

class RegisterForEventEvent extends CommunityNetworkEvent {
  final String eventId;
  
  const RegisterForEventEvent(this.eventId);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegisterForEventEvent && runtimeType == other.runtimeType && eventId == other.eventId;
  
  @override
  int get hashCode => eventId.hashCode;
}

class GetNearbyUsersEvent extends CommunityNetworkEvent {
  final double? latitude;
  final double? longitude;
  final double radiusInKm;
  final int limit;
  
  const GetNearbyUsersEvent({
    this.latitude,
    this.longitude,
    this.radiusInKm = 10.0,
    this.limit = 50,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetNearbyUsersEvent &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radiusInKm == other.radiusInKm &&
          limit == other.limit;
  
  @override
  int get hashCode => latitude.hashCode ^
      longitude.hashCode ^
      radiusInKm.hashCode ^
      limit.hashCode;
}

class GenerateCommunityAnalyticsEvent extends CommunityNetworkEvent {
  final DateTime period;
  
  const GenerateCommunityAnalyticsEvent(this.period);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerateCommunityAnalyticsEvent && runtimeType == other.runtimeType && period == other.period;
  
  @override
  int get hashCode => period.hashCode;
}

class CommunityNotificationReceivedEvent extends CommunityNetworkEvent {
  final CommunityNotification notification;
  
  const CommunityNotificationReceivedEvent(this.notification);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityNotificationReceivedEvent && runtimeType == other.runtimeType && notification == other.notification;
  
  @override
  int get hashCode => notification.hashCode;
}

abstract class CommunityNetworkState {}

class CommunityNetworkInitial extends CommunityNetworkState {}

class CommunityNetworkLoading extends CommunityNetworkState {}

class UserInitializedState extends CommunityNetworkState {
  final CommunityUser user;
  
  const UserInitializedState(this.user);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserInitializedState && runtimeType == other.runtimeType && user == other.user;
  
  @override
  int get hashCode => user.hashCode;
}

class ReportsLoadedState extends CommunityNetworkState {
  final List<AirQualityReport> reports;
  final List<CommunityUser>? nearbyUsers;
  
  const ReportsLoadedState({
    required this.reports,
    this.nearbyUsers,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportsLoadedState &&
          runtimeType == other.runtimeType &&
          reports == other.reports &&
          nearbyUsers == other.nearbyUsers;
  
  @override
  int get hashCode => reports.hashCode ^ (nearbyUsers?.hashCode ?? 0);
}

class ReportSubmittedState extends CommunityNetworkState {
  final AirQualityReport report;
  final List<AirQualityReport> allReports;
  
  const ReportSubmittedState({
    required this.report,
    required this.allReports,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportSubmittedState &&
          runtimeType == other.runtimeType &&
          report == other.report &&
          allReports == other.allReports;
  
  @override
  int get hashCode => report.hashCode ^ allReports.hashCode;
}

class ChallengesLoadedState extends CommunityNetworkState {
  final List<CommunityChallenge> challenges;
  
  const ChallengesLoadedState(this.challenges);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengesLoadedState && runtimeType == other.runtimeType && challenges == other.challenges;
  
  @override
  int get hashCode => challenges.hashCode;
}

class ChallengeJoinedState extends CommunityNetworkState {
  final CommunityChallenge challenge;
  final ChallengeParticipant participant;
  
  const ChallengeJoinedState({
    required this.challenge,
    required this.participant,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeJoinedState &&
          runtimeType == other.runtimeType &&
          challenge == other.challenge &&
          participant == other.participant;
  
  @override
  int get hashCode => challenge.hashCode ^ participant.hashCode;
}

class EventsLoadedState extends CommunityNetworkState {
  final List<CommunityEvent> events;
  
  const EventsLoadedState(this.events);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventsLoadedState && runtimeType == other.runtimeType && events == other.events;
  
  @override
  int get hashCode => events.hashCode;
}

class EventRegisteredState extends CommunityNetworkState {
  final CommunityEvent event;
  final EventAttendee attendee;
  
  const EventRegisteredState({
    required this.event,
    required this.attendee,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventRegisteredState &&
          runtimeType == other.runtimeType &&
          event == other.event &&
          attendee == other.attendee;
  
  @override
  int get hashCode => event.hashCode ^ attendee.hashCode;
}

class CommunityAnalyticsState extends CommunityNetworkState {
  final CommunityAnalytics analytics;
  
  const CommunityAnalyticsState(this.analytics);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityAnalyticsState && runtimeType == other.runtimeType && analytics == other.analytics;
  
  @override
  int get hashCode => analytics.hashCode;
}

class CommunityNotificationState extends CommunityNetworkState {
  final CommunityNotification notification;
  final List<CommunityNotification> allNotifications;
  
  const CommunityNotificationState({
    required this.notification,
    required this.allNotifications,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityNotificationState &&
          runtimeType == other.runtimeType &&
          notification == other.notification &&
          allNotifications == other.allNotifications;
  
  @override
  int get hashCode => notification.hashCode ^ allNotifications.hashCode;
}

class CommunityNetworkError extends CommunityNetworkState {
  final String message;
  final String? details;
  
  const CommunityNetworkError(this.message, {this.details});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityNetworkError && runtimeType == other.runtimeType && message == other.message && details == other.details;
  
  @override
  int get hashCode => message.hashCode ^ (details?.hashCode ?? 0);
}

class CommunityNetworkBloc extends Bloc<CommunityNetworkEvent, CommunityNetworkState> {
  final CommunityNetworkService _communityNetworkService;
  
  // Internal state tracking
  CommunityUser? _currentUser;
  final List<AirQualityReport> _reports = [];
  final List<CommunityChallenge> _challenges = [];
  final List<CommunityEvent> _events = [];
  final List<CommunityUser> _nearbyUsers = [];
  final List<CommunityNotification> _notifications = [];
  CommunityAnalytics? _analytics;
  
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _reportSubscription;
  StreamSubscription? _eventSubscription;
  
  CommunityNetworkBloc(this._communityNetworkService) : super(CommunityNetworkInitial()) {
    on<InitializeUserEvent>(_onInitializeUser);
    on<SubmitAirQualityReportEvent>(_onSubmitReport);
    on<GetNearbyReportsEvent>(_onGetNearbyReports);
    on<VerifyReportEvent>(_onVerifyReport);
    on<CreateChallengeEvent>(_onCreateChallenge);
    on<GetActiveChallengesEvent>(_onGetActiveChallenges);
    on<JoinChallengeEvent>(_onJoinChallenge);
    on<CreateEventEvent>(_onCreateEvent);
    on<GetNearbyEventsEvent>(_onGetNearbyEvents);
    on<RegisterForEventEvent>(_onRegisterForEvent);
    on<GetNearbyUsersEvent>(_onGetNearbyUsers);
    on<GenerateCommunityAnalyticsEvent>(_onGenerateAnalytics);
    on<CommunityNotificationReceivedEvent>(_onNotificationReceived);
    
    // Start listening to service streams
    _startServiceStreams();
  }

  void _startServiceStreams() {
    // Listen to notification stream from service
    _notificationSubscription = _communityNetworkService.notificationStream.listen((notification) {
      add(CommunityNotificationReceivedEvent(notification));
    });
    
    // Listen to report stream from service
    _reportSubscription = _communityNetworkService.reportStream.listen((report) {
      // Handle new reports from real-time updates
      if (!_reports.any((r) => r.reportId == report.reportId)) {
        _reports.insert(0, report);
        emit(ReportsLoadedState(reports: List.unmodifiable(_reports)));
      }
    });
    
    // Listen to event stream from service
    _eventSubscription = _communityNetworkService.eventStream.listen((event) {
      // Handle new events from real-time updates
      if (!_events.any((e) => e.eventId == event.eventId)) {
        _events.insert(0, event);
        emit(EventsLoadedState(List.unmodifiable(_events)));
      }
    });
  }

  Future<void> _onInitializeUser(
    InitializeUserEvent event,
    Emitter<CommunityNetworkState> emit,
  ) async {
    emit(CommunityNetworkLoading());
    
    try {
      final user = await _communityNetworkService.createOrUpdateUserProfile(event.userProfile);
      _currentUser = user;
      
      emit(UserInitializedState(user));
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to initialize user',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onSubmitReport(
    SubmitAirQualityReportEvent event,
    Emitter<CommunityNetworkState> emit,
  ) async {
    emit(CommunityNetworkLoading());
    
    try {
      final report = await _communityNetworkService.submitAirQualityReport(
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address,
        aqi: event.aqi,
        level: event.level,
        type: event.type,
        pollutantLevels: event.pollutantLevels,
        description: event.description,
        photos: event.photos,
        weatherConditions: event.weatherConditions,
      );
      
      // Add to reports list
      _reports.insert(0, report);
      
      emit(ReportSubmittedState(
        report: report,
        allReports: List.unmodifiable(_reports),
      ));
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to submit report',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onGetNearbyReports(
    GetNearbyReportsEvent event,
    Emitter<CommunityNetworkState> emit,
  ) async {
    emit(CommunityNetworkLoading());
    
    try {
      final reports = await _communityNetworkService.getAirQualityReports(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusInKm: event.radiusInKm,
        startDate: event.startDate,
        endDate: event.endDate,
        minLevel: event.minLevel,
        limit: event.limit,
      );
      
      _reports.clear();
      _reports.addAll(reports);
      
      // Optionally get nearby users
      List<CommunityUser>? nearbyUsers;
      if (event.latitude != null && event.longitude != null) {
        try {
          nearbyUsers = await _communityNetworkService.getNearbyUsers(
            latitude: event.latitude!,
            longitude: event.longitude!,
            radiusInKm: event.radiusInKm,
            limit: 20,
          );
          _nearbyUsers.clear();
          _nearbyUsers.addAll(nearbyUsers);
        } catch (e) {
          // Continue without nearby users if this fails
        }
      }
      
      emit(ReportsLoadedState(
        reports: List.unmodifiable(_reports),
        nearbyUsers: nearbyUsers != null ? List.unmodifiable(nearbyUsers) : null,
      ));
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to get nearby reports',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onVerifyReport(
    VerifyReportEvent event,
    Emitter<CommunityNetworkState> emit,
  ) async {
    try {
      await _communityNetworkService.verifyReport(event.reportId, event.isAccurate);
      
      // Update the report in the local list
      final reportIndex = _reports.indexWhere((r) => r.reportId == event.reportId);
      if (reportIndex != -1) {
        // In a real implementation, you would get the updated report
        // For now, just re-emit the current state
        emit(ReportsLoadedState(
          reports: List.unmodifiable(_reports),
        ));
      }
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to verify report',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onCreateChallenge(
    CreateChallengeEvent event,
    Emitter<CommunityNetworkState> emit,
  ) async {
    emit(CommunityNetworkLoading());
    
    try {
      final challenge = await _communityNetworkService.createCommunityChallenge(
        title: event.title,
        description: event.description,
        type: event.type,
        category: event.category,
        startDate: event.startDate,
        endDate: event.endDate,
        maxParticipants: event.maxParticipants,
        rewardPoints: event.rewardPoints,
        requirements: event.requirements,
        challengeData: event.challengeData,
      );
      
      // Add to challenges list
      _challenges.insert(0, challenge);
      
      emit(ChallengesLoadedState(List.unmodifiable(_challenges)));
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to create challenge',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onGetActiveChallenges(
    GetActiveChallengesEvent event,
    Emitter<CommunityNetworkState> emit,
  ) async {
    emit(CommunityNetworkLoading());
    
    try {
      final challenges = await _communityNetworkService.getActiveChallenges(
        category: event.category,
        type: event.type,
        limit: event.limit,
      );
      
      _challenges.clear();
      _challenges.addAll(challenges);
      
      emit(ChallengesLoadedState(List.unmodifiable(_challenges)));
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to get active challenges',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onJoinChallenge(
    JoinChallengeEvent event,
    Emitter<CommunityNetworkState> emit,
  ) async {
    emit(CommunityNetworkLoading());
    
    try {
      final participant = await _communityNetworkService.joinChallenge(event.challengeId);
      
      // Find the challenge and update it
      final challengeIndex = _challenges.indexWhere((c) => c.challengeId == event.challengeId);
      if (challengeIndex != -1) {
        final challenge = _challenges[challengeIndex];
        final updatedParticipants = List<ChallengeParticipant>.from(challenge.participants);
        updatedParticipants.add(participant);
        
        final updatedChallenge = challenge.copyWith(
          currentParticipants: challenge.currentParticipants + 1,
          participants: updatedParticipants,
        );
        
        _challenges[challengeIndex] = updatedChallenge;
        
        emit(ChallengeJoinedState(
          challenge: updatedChallenge,
          participant: participant,
        ));
      }
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to join challenge',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onCreateEvent(
    CreateEventEvent event,
    Emitter<CommunityNetworkState> emit,
  ) async {
    emit(CommunityNetworkLoading());
    
    try {
      final eventObj = await _communityNetworkService.createCommunityEvent(
        title: event.title,
        description: event.description,
        type: event.type,
        startDate: event.startDate,
        endDate: event.endDate,
        locationId: event.locationId,
        locationName: event.locationName,
        latitude: event.latitude,
        longitude: event.longitude,
        maxAttendees: event.maxAttendees,
        tags: event.tags,
      );
      
      // Add to events list
      _events.insert(0, eventObj);
      
      emit(EventsLoadedState(List.unmodifiable(_events)));
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to create event',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onGetNearbyEvents(
    GetNearbyEventsEvent event,
    Emitter<CommunityNetworkState> emit,
  ) async {
    emit(CommunityNetworkLoading());
    
    try {
      final events = await _communityNetworkService.getNearbyEvents(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusInKm: event.radiusInKm,
        startDate: event.startDate,
        endDate: event.endDate,
        type: event.type,
        limit: event.limit,
      );
      
      _events.clear();
      _events.addAll(events);
      
      emit(EventsLoadedState(List.unmodifiable(_events)));
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to get nearby events',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onRegisterForEvent(
    RegisterForEventEvent event,
    Emitter<CommunityNetworkState> emit,
  ) async {
    emit(CommunityNetworkLoading());
    
    try {
      final attendee = await _communityNetworkService.registerForEvent(event.eventId);
      
      // Find the event and update it
      final eventIndex = _events.indexWhere((e) => e.eventId == event.eventId);
      if (eventIndex != -1) {
        final eventObj = _events[eventIndex];
        final updatedAttendees = List<EventAttendee>.from(eventObj.attendees);
        updatedAttendees.add(attendee);
        
        final updatedEvent = eventObj.copyWith(
          currentAttendees: eventObj.currentAttendees + 1,
          attendees: updatedAttendees,
        );
        
        _events[eventIndex] = updatedEvent;
        
        emit(EventRegisteredState(
          event: updatedEvent,
          attendee: attendee,
        ));
      }
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to register for event',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onGetNearbyUsers(
    GetNearbyUsersEvent event,
    Emitter<CommunityNetworkState> emit,
  ) async {
    emit(CommunityNetworkLoading());
    
    try {
      final users = await _communityNetworkService.getNearbyUsers(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusInKm: event.radiusInKm,
        limit: event.limit,
      );
      
      _nearbyUsers.clear();
      _nearbyUsers.addAll(users);
      
      // Emit with current reports if available
      emit(ReportsLoadedState(
        reports: List.unmodifiable(_reports),
        nearbyUsers: List.unmodifiable(_nearbyUsers),
      ));
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to get nearby users',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onGenerateAnalytics(
    GenerateCommunityAnalyticsEvent event,
    Emitter<CommunityNetworkState> emit,
  ) async {
    emit(CommunityNetworkLoading());
    
    try {
      final analytics = await _communityNetworkService.generateCommunityAnalytics(event.period);
      _analytics = analytics;
      
      emit(CommunityAnalyticsState(analytics));
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to generate community analytics',
        details: e.toString(),
      ));
    }
  }

  void _onNotificationReceived(
    CommunityNotificationReceivedEvent event,
    Emitter<CommunityNetworkState> emit,
  ) {
    try {
      // Add to notifications list (keep only last 100)
      _notifications.insert(0, event.notification);
      if (_notifications.length > 100) {
        _notifications.removeRange(100, _notifications.length);
      }
      
      emit(CommunityNotificationState(
        notification: event.notification,
        allNotifications: List.unmodifiable(_notifications),
      ));
    } catch (e) {
      emit(CommunityNetworkError(
        'Failed to process notification',
        details: e.toString(),
      ));
    }
  }

  // Public getters for current state
  CommunityUser? get currentUser => _currentUser;
  List<AirQualityReport> get reports => List.unmodifiable(_reports);
  List<CommunityChallenge> get challenges => List.unmodifiable(_challenges);
  List<CommunityEvent> get events => List.unmodifiable(_events);
  List<CommunityUser> get nearbyUsers => List.unmodifiable(_nearbyUsers);
  List<CommunityNotification> get notifications => List.unmodifiable(_notifications);
  CommunityAnalytics? get analytics => _analytics;
  
  bool get isUserInitialized => _currentUser != null;
  int get totalReports => _reports.length;
  int get totalChallenges => _challenges.length;
  int get totalEvents => _events.length;
  int get totalNotifications => _notifications.length;

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _reportSubscription?.cancel();
    _eventSubscription?.cancel();
    return super.close();
  }
}
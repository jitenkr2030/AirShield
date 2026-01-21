import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../bloc/community_network_bloc.dart';
import '../../core/services/location_service.dart';
import '../../models/community_network_data.dart';
import 'components/community_feed_widget.dart';
import 'components/community_challenges_widget.dart';
import 'components/community_events_widget.dart';
import 'components/community_analytics_widget.dart';

class CommunityNetworkScreen extends StatefulWidget {
  const CommunityNetworkScreen({Key? key}) : super(key: key);

  @override
  State<CommunityNetworkScreen> createState() => _CommunityNetworkScreenState();
}

class _CommunityNetworkScreenState extends State<CommunityNetworkScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  final LocationService _locationService = LocationService();
  
  Position? _currentPosition;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeScreen();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });

      // Initialize user (in a real app, this would be done after authentication)
      final user = CommunityUser(
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        username: 'demo_user',
        displayName: 'Demo User',
        joinedAt: DateTime.now(),
        role: CommunityRole.member,
        stats: const CommunityStats(),
        interests: ['air quality', 'environment', 'health'],
        locationPermission: LocationPermission.neighbors,
        isOnline: true,
        lastSeen: DateTime.now(),
        bio: 'Air quality enthusiast',
        badges: [],
      );

      context.read<CommunityNetworkBloc>().add(InitializeUserEvent(user));
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to initialize: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Network'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
            badge: _getNotificationCount(),
            tooltip: 'Notifications',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.feed), text: 'Feed'),
            Tab(icon: Icon(Icons.flag), text: 'Challenges'),
            Tab(icon: Icon(Icons.event), text: 'Events'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.group), text: 'Members'),
          ],
        ),
      ),
      body: _isInitialized ? _buildMainContent() : _buildLoadingScreen(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing community...'),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return BlocConsumer<CommunityNetworkBloc, CommunityNetworkState>(
      listener: (context, state) {
        if (state is CommunityNetworkError) {
          _showErrorSnackBar(state.message);
        }
      },
      builder: (context, state) {
        return TabBarView(
          controller: _tabController,
          children: [
            _buildFeedTab(state),
            _buildChallengesTab(state),
            _buildEventsTab(state),
            _buildAnalyticsTab(state),
            _buildMembersTab(state),
          ],
        );
      },
    );
  }

  Widget _buildFeedTab(CommunityNetworkState state) {
    return Column(
      children: [
        _buildFeedHeader(),
        Expanded(
          child: CommunityFeedWidget(
            reports: state is ReportsLoadedState ? state.reports : [],
            nearbyUsers: state is ReportsLoadedState ? state.nearbyUsers : [],
            onSubmitReport: _showSubmitReportDialog,
            onVerifyReport: (reportId, isAccurate) {
              context.read<CommunityNetworkBloc>().add(
                VerifyReportEvent(reportId, isAccurate),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChallengesTab(CommunityNetworkState state) {
    if (state is ChallengesLoadedState) {
      return CommunityChallengesWidget(
        challenges: state.challenges,
        onJoinChallenge: (challengeId) {
          context.read<CommunityNetworkBloc>().add(
            JoinChallengeEvent(challengeId),
          );
        },
        onCreateChallenge: _showCreateChallengeDialog,
      );
    }

    // Load challenges
    context.read<CommunityNetworkBloc>().add(const GetActiveChallengesEvent());

    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEventsTab(CommunityNetworkState state) {
    if (state is EventsLoadedState) {
      return CommunityEventsWidget(
        events: state.events,
        onRegisterForEvent: (eventId) {
          context.read<CommunityNetworkBloc>().add(
            RegisterForEventEvent(eventId),
          );
        },
        onCreateEvent: _showCreateEventDialog,
        currentPosition: _currentPosition,
      );
    }

    // Load events if location is available
    if (_currentPosition != null) {
      context.read<CommunityNetworkBloc>().add(
        GetNearbyEventsEvent(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radiusInKm: 25.0,
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildAnalyticsTab(CommunityNetworkState state) {
    if (state is CommunityAnalyticsState) {
      return CommunityAnalyticsWidget(
        analytics: state.analytics,
        onGenerateNew: () {
          context.read<CommunityNetworkBloc>().add(
            GenerateCommunityAnalyticsEvent(DateTime.now()),
          );
        },
      );
    }

    // Generate analytics
    context.read<CommunityNetworkBloc>().add(
      GenerateCommunityAnalyticsEvent(DateTime.now()),
    );

    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildMembersTab(CommunityNetworkState state) {
    // This would show community members
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Community Members'),
          SizedBox(height: 8),
          Text('Feature coming soon'),
        ],
      ),
    );
  }

  Widget _buildFeedHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.feed,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Community Feed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _showSubmitReportDialog,
                tooltip: 'Submit Air Quality Report',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Stay updated with local air quality reports and community activities',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showCreateMenu,
      child: const Icon(Icons.add),
      tooltip: 'Create',
    );
  }

  void _refreshAllData() {
    // Refresh all data based on current tab
    switch (_tabController.index) {
      case 0: // Feed
        if (_currentPosition != null) {
          context.read<CommunityNetworkBloc>().add(
            GetNearbyReportsEvent(
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
            ),
          );
        }
        break;
      case 1: // Challenges
        context.read<CommunityNetworkBloc>().add(const GetActiveChallengesEvent());
        break;
      case 2: // Events
        if (_currentPosition != null) {
          context.read<CommunityNetworkBloc>().add(
            GetNearbyEventsEvent(
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
            ),
          );
        }
        break;
      case 3: // Analytics
        context.read<CommunityNetworkBloc>().add(
          GenerateCommunityAnalyticsEvent(DateTime.now()),
        );
        break;
    }
  }

  void _showNotifications() {
    // Show notifications dialog or navigate to notifications screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications feature coming soon'),
      ),
    );
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create Something',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Air Quality Report'),
              subtitle: const Text('Report local air quality'),
              onTap: () {
                Navigator.pop(context);
                _showSubmitReportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Community Challenge'),
              subtitle: const Text('Start a new challenge'),
              onTap: () {
                Navigator.pop(context);
                _showCreateChallengeDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Community Event'),
              subtitle: const Text('Organize an event'),
              onTap: () {
                Navigator.pop(context);
                _showCreateEventDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitReportDialog() {
    final TextEditingController aqiController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Air Quality Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: aqiController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'AQI Value',
                hintText: 'Enter AQI value (0-500)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Describe conditions, weather, etc.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final aqi = double.tryParse(aqiController.text);
              if (aqi == null) {
                _showErrorSnackBar('Please enter a valid AQI value');
                return;
              }

              final level = _getAirQualityLevel(aqi);
              
              if (_currentPosition != null) {
                context.read<CommunityNetworkBloc>().add(
                  SubmitAirQualityReportEvent(
                    latitude: _currentPosition!.latitude,
                    longitude: _currentPosition!.longitude,
                    address: 'Current Location',
                    aqi: aqi,
                    level: level,
                    type: ReportType.community,
                    description: descriptionController.text.isNotEmpty 
                        ? descriptionController.text 
                        : null,
                  ),
                );
              }
              
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showCreateChallengeDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Community Challenge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Challenge Title',
                hintText: 'Enter challenge title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the challenge',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                _showErrorSnackBar('Please fill in all fields');
                return;
              }

              context.read<CommunityNetworkBloc>().add(
                CreateChallengeEvent(
                  title: titleController.text,
                  description: descriptionController.text,
                  type: ChallengeType.community,
                  category: ChallengeCategory.airQualityReporting,
                  startDate: DateTime.now(),
                  endDate: DateTime.now().add(const Duration(days: 30)),
                ),
              );
              
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateEventDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Community Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                hintText: 'Enter event title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the event',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                _showErrorSnackBar('Please fill in all fields');
                return;
              }

              if (_currentPosition != null) {
                context.read<CommunityNetworkBloc>().add(
                  CreateEventEvent(
                    title: titleController.text,
                    description: descriptionController.text,
                    type: EventType.awarenessCampaign,
                    startDate: DateTime.now().add(const Duration(days: 1)),
                    endDate: DateTime.now().add(const Duration(days: 1, hours: 2)),
                    locationId: 'current_location',
                    locationName: 'Current Location',
                    latitude: _currentPosition!.latitude,
                    longitude: _currentPosition!.longitude,
                  ),
                );
              }
              
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  AirQualityLevel _getAirQualityLevel(double aqi) {
    if (aqi <= 50) return AirQualityLevel.good;
    if (aqi <= 100) return AirQualityLevel.moderate;
    if (aqi <= 150) return AirQualityLevel.unhealthyForSensitive;
    if (aqi <= 200) return AirQualityLevel.unhealthy;
    if (aqi <= 300) return AirQualityLevel.veryUnhealthy;
    return AirQualityLevel.hazardous;
  }

  Widget? _getNotificationCount() {
    // Return notification badge if there are unread notifications
    return null; // For now, no notifications
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Widget classes (CommunityFeedWidget, etc.) would be implemented here
// For brevity, showing the main structure

class CommunityFeedWidget extends StatelessWidget {
  final List<AirQualityReport> reports;
  final List<CommunityUser>? nearbyUsers;
  final Function() onSubmitReport;
  final Function(String, bool) onVerifyReport;

  const CommunityFeedWidget({
    Key? key,
    required this.reports,
    this.nearbyUsers,
    required this.onSubmitReport,
    required this.onVerifyReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No reports yet'),
            Text('Be the first to submit an air quality report!'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildReportCard(context, report);
      },
    );
  }

  Widget _buildReportCard(BuildContext context, AirQualityReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getReportIcon(report.type),
                  color: _getReportColor(report.level),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AQI ${report.aqi.toStringAsFixed(0)} - ${_getLevelDescription(report.level)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatTimeAgo(report.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.address,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (report.description != null) ...[
              const SizedBox(height: 8),
              Text(
                report.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => onVerifyReport(report.reportId, true),
                  icon: const Icon(Icons.thumb_up, size: 16),
                  label: const Text('Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => onVerifyReport(report.reportId, false),
                  icon: const Icon(Icons.thumb_down, size: 16),
                  label: const Text('Dispute'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
                const Spacer(),
                Text(
                  '${report.verificationScore} votes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.official:
        return Icons.verified;
      case ReportType.community:
        return Icons.group;
      case ReportType.sensor:
        return Icons.sensors;
      case ReportType.crowdsourced:
        return Icons.people;
    }
  }

  Color _getReportColor(AirQualityLevel level) {
    switch (level) {
      case AirQualityLevel.good:
        return Colors.green;
      case AirQualityLevel.moderate:
        return Colors.yellow;
      case AirQualityLevel.unhealthyForSensitive:
        return Colors.orange;
      case AirQualityLevel.unhealthy:
        return Colors.red;
      case AirQualityLevel.veryUnhealthy:
        return Colors.purple;
      case AirQualityLevel.hazardous:
        return Colors.red.shade800;
    }
  }

  String _getLevelDescription(AirQualityLevel level) {
    switch (level) {
      case AirQualityLevel.good:
        return 'Good';
      case AirQualityLevel.moderate:
        return 'Moderate';
      case AirQualityLevel.unhealthyForSensitive:
        return 'Unhealthy for Sensitive';
      case AirQualityLevel.unhealthy:
        return 'Unhealthy';
      case AirQualityLevel.veryUnhealthy:
        return 'Very Unhealthy';
      case AirQualityLevel.hazardous:
        return 'Hazardous';
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class CommunityChallengesWidget extends StatelessWidget {
  final List<CommunityChallenge> challenges;
  final Function(String) onJoinChallenge;
  final VoidCallback onCreateChallenge;

  const CommunityChallengesWidget({
    Key? key,
    required this.challenges,
    required this.onJoinChallenge,
    required this.onCreateChallenge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Community Challenges - ${challenges.length} active'),
    );
  }
}

class CommunityEventsWidget extends StatelessWidget {
  final List<CommunityEvent> events;
  final Function(String) onRegisterForEvent;
  final VoidCallback onCreateEvent;
  final Position? currentPosition;

  const CommunityEventsWidget({
    Key? key,
    required this.events,
    required this.onRegisterForEvent,
    required this.onCreateEvent,
    this.currentPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Community Events - ${events.length} upcoming'),
    );
  }
}

class CommunityAnalyticsWidget extends StatelessWidget {
  final CommunityAnalytics analytics;
  final VoidCallback? onGenerateNew;

  const CommunityAnalyticsWidget({
    Key? key,
    required this.analytics,
    this.onGenerateNew,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Community Analytics'),
    );
  }
}
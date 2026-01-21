import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncusion_flutter_gauges/syncfusion_flutter_gauges.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../bloc/health_score_bloc.dart';
import '../../bloc/air_quality_notification_bloc.dart';
import '../../viewmodels/health_score_viewmodel.dart';
import '../../models/user_profile.dart';
import '../../models/health_profile.dart';
import '../../models/health_score_data.dart';
import '../../core/config/app_config.dart';
import '../../core/themes/app_theme.dart';
import 'components/health_score_gauge.dart';
import 'components/health_score_chart.dart';
import 'components/recommendation_card.dart';
import 'components/score_breakdown_card.dart';
import 'components/trend_analysis_card.dart';

class HealthScoreScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final HealthProfile? healthProfile;

  const HealthScoreScreen({
    Key? key,
    this.userProfile,
    this.healthProfile,
  }) : super(key: key);

  @override
  State<HealthScoreScreen> createState() => _HealthScoreScreenState();
}

class _HealthScoreScreenState extends State<HealthScoreScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
    _slideController.forward();

    // Initialize health score calculation
    _initializeHealthScore();
  }

  void _initializeHealthScore() {
    context.read<HealthScoreBloc>().add(
      HealthScoreRequested(
        userProfile: widget.userProfile,
        healthProfile: widget.healthProfile,
        includeHistorical: true,
      ),
    );

    // Start monitoring for real-time updates
    context.read<HealthScoreBloc>().add(
      const HealthScoreMonitoringStarted(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: BlocConsumer<HealthScoreBloc, HealthScoreState>(
                  listener: (context, state) {
                    if (state is HealthScoreErrorState) {
                      _showErrorSnackBar(state.error);
                    }
                  },
                  builder: (context, state) {
                    return _buildContent(state);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColorLight,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  context.read<HealthScoreBloc>().add(
                    const HealthScoreRefreshed(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Personalized Health Score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Real-time health impact assessment',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Current'),
              Tab(text: 'History'),
              Tab(text: 'Insights'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(HealthScoreState state) {
    switch (state) {
      case HealthScoreLoading():
        return const Center(
          child: CircularProgressIndicator(),
        );
      case HealthScoreSuccess():
        return _buildSuccessContent(state);
      case HealthScoreFailure():
        return _buildErrorContent(state);
      case HealthScoreErrorState():
        return _buildErrorContent(state);
      case HealthScoreInitial():
      default:
        return const Center(
          child: Text('Tap to calculate your health score'),
        );
    }
  }

  Widget _buildSuccessContent(HealthScoreSuccess state) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCurrentScoreTab(state),
        _buildHistoryTab(state),
        _buildInsightsTab(state),
      ],
    );
  }

  Widget _buildCurrentScoreTab(HealthScoreSuccess state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Health Score Gauge
          Center(
            child: HealthScoreGauge(
              score: state.healthScore.overallScore,
              size: 200,
              showLabels: true,
            ),
          ),
          const SizedBox(height: 20),
          
          // Health Status Card
          _buildHealthStatusCard(state),
          const SizedBox(height: 20),
          
          // Score Breakdown
          ScoreBreakdownCard(
            respiratoryScore: state.healthScore.respiratoryScore,
            cardiovascularScore: state.healthScore.cardiovascularScore,
            immuneScore: state.healthScore.immuneScore,
            activityImpactScore: state.healthScore.activityImpactScore,
          ),
          const SizedBox(height: 20),
          
          // Risk Category
          _buildRiskCategoryCard(state),
          const SizedBox(height: 20),
          
          // Urgent Recommendations
          if (state.getUrgentRecommendations().isNotEmpty) ...[
            _buildUrgentRecommendationsSection(state.getUrgentRecommendations()),
            const SizedBox(height: 20),
          ],
          
          // Air Quality Context
          _buildAirQualityContext(state.airQualityData),
          const SizedBox(height: 20),
          
          // Contributing Factors
          _buildContributingFactors(state.healthScore.contributingFactors),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(HealthScoreSuccess state) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Score Trends',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: HealthScoreChart(
              data: state.scoreHistory,
              height: 300,
            ),
          ),
          const SizedBox(height: 20),
          TrendAnalysisCard(
            historicalData: state.scoreHistory,
            currentScore: state.healthScore,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(HealthScoreSuccess state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalized Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Health Patterns
          _buildHealthPatternsCard(state),
          const SizedBox(height: 20),
          
          // Recommendations by Category
          _buildRecommendationsByCategory(state.healthScore.recommendations),
          const SizedBox(height: 20),
          
          // Personalized Tips
          _buildPersonalizedTipsCard(state),
          const SizedBox(height: 20),
          
          // Progress Tracking
          _buildProgressTrackingCard(state),
        ],
      ),
    );
  }

  Widget _buildErrorContent(dynamic state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to calculate health score',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              state is HealthScoreFailure 
                ? state.error 
                : state is HealthScoreErrorState 
                  ? state.error 
                  : 'An unexpected error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                _initializeHealthScore();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatusCard(HealthScoreSuccess state) {
    final viewModel = context.read<HealthScoreViewModel>();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: viewModel.healthStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.health_and_safety,
                    color: viewModel.healthStatusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Health Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        viewModel.healthStatus,
                        style: TextStyle(
                          color: viewModel.healthStatusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${state.healthScore.overallScore}/100',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: viewModel.healthStatusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              state.healthScore.scoreDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.riskLevelDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCategoryCard(HealthScoreSuccess state) {
    final riskColor = _getRiskColor(state.healthScore.riskCategory);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: riskColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Risk Assessment',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Risk Category',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      state.healthScore.riskCategory,
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Risk Level',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${(state.healthScore.riskLevel * 100).toInt()}/100',
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentRecommendationsSection(List<HealthRecommendation> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notification_important,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Urgent Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recommendations.map((rec) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RecommendationCard(
            recommendation: rec,
            showPriority: true,
            onDismiss: (id) {
              context.read<HealthScoreBloc>().add(
                HealthScoreRecommendationDismissed(recommendationId: id),
              );
            },
            onComplete: (id) {
              context.read<HealthScoreBloc>().add(
                HealthScoreRecommendationCompleted(
                  recommendationId: id,
                  shouldRecalculateScore: true,
                ),
              );
            },
          ),
        )),
      ],
    );
  }

  Widget _buildAirQualityContext(AirQualityData airQuality) {
    final aqiLevel = AQILevel.fromValue(airQuality.aqi);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.air,
                  color: aqiLevel.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Current Air Quality',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AQI: ${airQuality.aqi.toInt()}',
                        style: TextStyle(
                          color: aqiLevel.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        aqiLevel.displayName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PM2.5: ${airQuality.pm25.toStringAsFixed(1)} µg/m³',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Source: ${airQuality.source}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributingFactors(Map<String, dynamic> factors) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contributing Factors',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...factors.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatFactorKey(entry.key),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatFactorValue(entry.value),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthPatternsCard(HealthScoreSuccess state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Patterns',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Based on your current data, here are the key patterns affecting your health score:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            // Add pattern analysis logic here
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsByCategory(List<HealthRecommendation> recommendations) {
    final categories = <String, List<HealthRecommendation>>{};
    
    for (final rec in recommendations) {
      categories.putIfAbsent(rec.category, () => []).add(rec);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations by Category',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...categories.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              ...entry.value.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RecommendationCard(
                  recommendation: rec,
                  showPriority: false,
                ),
              )),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPersonalizedTipsCard(HealthScoreSuccess state) {
    final viewModel = context.read<HealthScoreViewModel>();
    final tips = viewModel.getPersonalizedTips();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalized Tips',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTrackingCard(HealthScoreSuccess state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Tracking',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Track your health score improvements over time and see the impact of your actions.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to progress tracking screen
              },
              icon: const Icon(Icons.analytics),
              label: const Text('View Detailed Progress'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    return BlocBuilder<HealthScoreBloc, HealthScoreState>(
      builder: (context, state) {
        if (state is HealthScoreSuccess && state.getUrgentRecommendations().isNotEmpty) {
          return FloatingActionButton(
            onPressed: () {
              // Show urgent recommendations or take action
              _showUrgentRecommendationsDialog(state.getUrgentRecommendations());
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.notification_important),
          );
        }
        return null;
      },
    );
  }

  void _showUrgentRecommendationsDialog(List<HealthRecommendation> recommendations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notification_important, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Urgent Action Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(rec.description),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Take action based on recommendation
            },
            child: const Text('Take Action'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            _initializeHealthScore();
          },
        ),
      ),
    );
  }

  Color _getRiskColor(String riskCategory) {
    switch (riskCategory.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.redAccent;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatFactorKey(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatFactorValue(dynamic value) {
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');
    }
    return value.toString();
  }
}
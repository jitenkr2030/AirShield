import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/themes/app_theme.dart';
import '../../features/paqg/bloc/paqg_bloc.dart';
import '../../features/prediction/bloc/prediction_bloc.dart';
import '../../features/health/bloc/health_bloc.dart';
import '../../models/air_quality_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIRSHIELD'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTheme.lightPrimaryText,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(LucideIcons.home), text: 'Home'),
            Tab(icon: Icon(LucideIcons.map), text: 'Map'),
            Tab(icon: Icon(LucideIcons.camera), text: 'Capture'),
            Tab(icon: Icon(LucideIcons.trendingUp), text: 'Predict'),
            Tab(icon: Icon(LucideIcons.users), text: 'Community'),
          ],
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.lightSecondaryText,
          indicatorColor: AppTheme.primaryBlue,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(context),
          _buildMapTab(context),
          _buildCaptureTab(context),
          _buildPredictionTab(context),
          _buildCommunityTab(context),
        ],
      ),
      floatingActionButton: _tabController.index == 2 ? 
        FloatingActionButton(
          onPressed: () => context.go('/capture/camera'),
          backgroundColor: AppTheme.primaryBlue,
          child: const Icon(LucideIcons.camera, color: Colors.white),
        ) : null,
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHealthScoreCard(context),
          const SizedBox(height: 24),
          _buildCurrentAirQualityCard(context),
          const SizedBox(height: 24),
          _buildQuickActionsCard(context),
          const SizedBox(height: 24),
          _buildRecentActivityCard(context),
          const SizedBox(height: 24),
          _buildAlertsCard(context),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return BlocBuilder<PAQGBloc, PAQGState>(
      builder: (context, paqgState) {
        return BlocBuilder<PredictionBloc, PredictionState>(
          builder: (context, predictionState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  _buildWelcomeSection(paqgState),
                  const SizedBox(height: 24),
                  
                  // Health Score Card
                  _buildHealthScoreCard(paqgState),
                  const SizedBox(height: 24),
                  
                  // Current AQI Card
                  _buildCurrentAQICard(paqgState),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  _buildQuickActionsCard(context),
                  const SizedBox(height: 24),
                  
                  // Next 3-hour forecast
                  _buildForecastCard(predictionState),
                  const SizedBox(height: 24),
                  
                  // Recent measurements
                  _buildRecentMeasurementsCard(paqgState),
                  const SizedBox(height: 24),
                  
                  // Alerts and notifications
                  _buildAlertsCard(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWelcomeSection(PAQGState paqgState) {
    String greeting = _getGreeting();
    String location = 'Unknown Location';
    
    if (paqgState is PAQGLoaded) {
      location = paqgState.locationString;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your air quality guardian at $location',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightSecondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthScoreCard(PAQGState paqgState) {
    double healthScore = 85.0;
    String scoreCategory = 'Good';
    Color scoreColor = AppTheme.good;
    bool isLoading = false;
    
    if (paqgState is PAQGLoaded) {
      healthScore = paqgState.healthScore;
      scoreCategory = paqgState.healthScoreCategory;
      scoreColor = paqgState.healthScoreColor;
      isLoading = paqgState.isLoading;
    } else if (paqgState is PAQGLoading) {
      isLoading = true;
    }
    
    return Card(
      elevation: 8,
      shadowColor: const Color(0x146C7896),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.activity, color: scoreColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Health Score',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoading)
                        const CircularProgressIndicator()
                      else ...[
                        Text(
                          healthScore.toInt().toString(),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scoreCategory,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getHealthScoreDescription(scoreCategory),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                _buildCircularProgressIndicator(healthScore, scoreColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAQICard(PAQGState paqgState) {
    double aqi = 75.0;
    String aqiCategory = 'Moderate';
    Color aqiColor = AppTheme.moderate;
    double pm25 = 25.0;
    bool isLoading = false;
    
    if (paqgState is PAQGLoaded) {
      aqi = paqgState.airQualityData.aqi;
      aqiCategory = paqgState.aqiCategory;
      aqiColor = paqgState.aqiColor;
      pm25 = paqgState.airQualityData.pm25;
      isLoading = paqgState.isLoading;
    } else if (paqgState is PAQGLoading) {
      isLoading = true;
    }
    
    return Card(
      elevation: 8,
      shadowColor: const Color(0x146C7896),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.wind, color: aqiColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Current Air Quality',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AQI: ${aqi.round()}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: aqiColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aqiCategory,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: aqiColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'PM2.5: ${pm25.round()} μg/m³',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                _buildAQIColorIndicator(aqiColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: const Color(0x146C7896),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: LucideIcons.map,
                    label: 'Check Air Map',
                    color: AppTheme.primaryBlue,
                    onTap: () => context.go('/map'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: LucideIcons.camera,
                    label: 'Capture Smog',
                    color: AppTheme.primaryBlue,
                    onTap: () => context.go('/capture'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: LucideIcons.trendingUp,
                    label: 'View Forecast',
                    color: AppTheme.primaryBlue,
                    onTap: () => context.go('/prediction'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: LucideIcons.route,
                    label: 'Safe Routes',
                    color: AppTheme.primaryBlue,
                    onTap: () => context.go('/map/safe-routes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(PredictionState predictionState) {
    return Card(
      elevation: 8,
      shadowColor: const Color(0x146C7896),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.clock, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Next 3 Hours',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/prediction'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (predictionState is PredictionLoaded) ...[
              _buildForecastItem('In 1 hour', predictionState.nextHourPredictions),
              const SizedBox(height: 12),
              _buildForecastItem('In 3 hours', predictionState.nextThreeHourPredictions),
            ] else if (predictionState is PredictionLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              const Text('No forecast data available'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMeasurementsCard(PAQGState paqgState) {
    return Card(
      elevation: 8,
      shadowColor: const Color(0x146C7896),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.history, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Recent Measurements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/profile/health/history'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (paqgState is PAQGLoaded) ...[
              _buildMeasurementItem('Current', paqgState.airQualityData.aqi, true),
              const SizedBox(height: 12),
              _buildMeasurementItem('1 hour ago', 78.0, false),
              const SizedBox(height: 12),
              _buildMeasurementItem('2 hours ago', 82.0, false),
            ] else if (paqgState is PAQGLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              const Text('No recent measurements'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Card(
      elevation: 8,
      shadowColor: const Color(0x146C7896),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.bell, color: AppTheme.primaryBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Alerts & Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/home/alerts'),
                  child: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sample alerts - in real app, these would come from the state
            _buildAlertItem('High PM2.5 Expected', 'In 2 hours, PM2.5 may reach 180 μg/m³', true),
            const SizedBox(height: 12),
            _buildAlertItem('Safe Time for Exercise', 'Next 30 minutes have good air quality', false),
          ],
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildCircularProgressIndicator(double value, Color color) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CircularProgressIndicator(
        value: value / 100,
        strokeWidth: 6,
        backgroundColor: Colors.grey.shade300,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildAQIColorIndicator(Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(LucideIcons.droplets, color: color, size: 24),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForecastItem(String timeLabel, List<dynamic> predictions) {
    if (predictions.isEmpty) {
      return _buildForecastTimeItem(timeLabel, 'No data', 0, AppTheme.lightSecondaryText);
    }
    
    final avgAqi = predictions
        .map((p) => p.predictedAQI)
        .reduce((a, b) => a + b) / predictions.length;
    
    final category = AppTheme.getAQICategory(avgAqi);
    final color = AppTheme.getAQIColor(avgAqi);
    
    return _buildForecastTimeItem(timeLabel, category, avgAqi, color);
  }

  Widget _buildForecastTimeItem(String timeLabel, String value, double aqi, Color color) {
    return Row(
      children: [
        Text(
          timeLabel,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${aqi.round()}: $value',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementItem(String timeLabel, double aqi, bool isCurrent) {
    final color = AppTheme.getAQIColor(aqi);
    final category = AppTheme.getAQICategory(aqi);
    
    return Row(
      children: [
        Text(
          timeLabel,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Spacer(),
        if (isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Current',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${aqi.round()}: $category',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(String title, String message, bool isWarning) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isWarning ? Icons.warning_amber : Icons.info_outline,
          color: isWarning ? AppTheme.unhealthy : AppTheme.primaryBlue,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightSecondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getHealthScoreDescription(String category) {
    switch (category) {
      case 'Excellent':
        return 'Your air quality exposure is minimal';
      case 'Good':
        return 'Air quality is generally safe';
      case 'Fair':
        return 'Some exposure to air pollutants';
      case 'Poor':
        return 'High pollution exposure detected';
      case 'Very Poor':
        return 'Dangerous levels of air pollution';
      default:
        return 'Health score calculation in progress';
    }
  }

  Widget _buildMapTab(BuildContext context) {
    return const Center(
      child: Text('Map Tab - Coming Soon'),
    );
  }

  Widget _buildCaptureTab(BuildContext context) {
    return const Center(
      child: Text('Capture Tab - Coming Soon'),
    );
  }

  Widget _buildPredictionTab(BuildContext context) {
    return const Center(
      child: Text('Prediction Tab - Coming Soon'),
    );
  }

  Widget _buildCommunityTab(BuildContext context) {
    return const Center(
      child: Text('Community Tab - Coming Soon'),
    );
  }
}
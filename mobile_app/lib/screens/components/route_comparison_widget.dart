import 'package:flutter/material.dart';
import '../../models/route_planning_data.dart';

class RouteComparisonWidget extends StatelessWidget {
  final List<RouteOption> routes;
  final RouteComparison? comparison;
  final RouteOption? selectedRoute;
  final Function(RouteOption) onRouteSelected;

  const RouteComparisonWidget({
    Key? key,
    required this.routes,
    this.comparison,
    this.selectedRoute,
    required this.onRouteSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No routes available'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          if (comparison != null) _buildRecommendedRoute(context, comparison!.recommendedRoute),
          const SizedBox(height: 16),
          ...routes.map((route) => _buildRouteCard(context, route)).toList(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route Comparison',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Compare ${routes.length} route options based on air quality, time, and health impact',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedRoute(BuildContext context, RouteOption? route) {
    if (route == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recommended Route',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                route.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildMetricsRow(context, route),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, RouteOption route) {
    final isSelected = selectedRoute?.routeId == route.routeId;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected 
          ? Theme.of(context).primaryColor.withOpacity(0.05)
          : Theme.of(context).cardColor,
      child: InkWell(
        onTap: () => onRouteSelected(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRouteHeader(context, route, isSelected),
              const SizedBox(height: 12),
              _buildMetricsRow(context, route),
              const SizedBox(height: 12),
              _buildAirQualityIndicator(context, route),
              const SizedBox(height: 12),
              if (route.warnings.isNotEmpty) _buildWarnings(context, route),
              const SizedBox(height: 12),
              _buildHealthRecommendations(context, route),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteHeader(BuildContext context, RouteOption route, bool isSelected) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getRouteModeColor(route.segments.first.mode).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getRouteModeIcon(route.segments.first.mode),
                size: 16,
                color: _getRouteModeColor(route.segments.first.mode),
              ),
              const SizedBox(width: 4),
              Text(
                _getRouteModeName(route.segments.first.mode),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getRouteModeColor(route.segments.first.mode),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (isSelected)
          Icon(
            Icons.check_circle,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
      ],
    );
  }

  Widget _buildMetricsRow(BuildContext context, RouteOption route) {
    return Row(
      children: [
        Expanded(
          child: _buildMetric(
            context,
            icon: Icons.straighten,
            label: 'Distance',
            value: '${route.distance.toStringAsFixed(1)} km',
            color: Colors.blue,
          ),
        ),
        Expanded(
          child: _buildMetric(
            context,
            icon: Icons.access_time,
            label: 'Time',
            value: '${route.duration} min',
            color: Colors.orange,
          ),
        ),
        Expanded(
          child: _buildMetric(
            context,
            icon: Icons.air,
            label: 'Air Quality',
            value: '${route.airQualityScore.toStringAsFixed(0)}/100',
            color: _getAirQualityColor(route.airQualityScore),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAirQualityIndicator(BuildContext context, RouteOption route) {
    final score = route.airQualityScore;
    Color color;
    String label;
    
    if (score >= 80) {
      color = Colors.green;
      label = 'Excellent';
    } else if (score >= 60) {
      color = Colors.lightGreen;
      label = 'Good';
    } else if (score >= 40) {
      color = Colors.orange;
      label = 'Moderate';
    } else if (score >= 20) {
      color = Colors.red;
      label = 'Poor';
    } else {
      color = Colors.red.shade800;
      label = 'Very Poor';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Air Quality Score: ${score.toStringAsFixed(0)}/100',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Overall air quality rating: $label',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarnings(BuildContext context, RouteOption route) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.amber.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Warnings',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...route.warnings.map((warning) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    warning,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildHealthRecommendations(BuildContext context, RouteOption route) {
    if (route.metrics.healthRecommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.health_and_safety,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Health Recommendations',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...route.metrics.healthRecommendations.take(2).map((recommendation) => 
            _buildRecommendationItem(context, recommendation)
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(BuildContext context, HealthRecommendation recommendation) {
    final priorityColor = _getPriorityColor(recommendation.priority);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  recommendation.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAirQualityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.red;
    return Colors.red.shade800;
  }

  Color _getRouteModeColor(RouteMode mode) {
    switch (mode) {
      case RouteMode.driving:
        return Colors.blue;
      case RouteMode.walking:
        return Colors.green;
      case RouteMode.cycling:
        return Colors.orange;
      case RouteMode.transit:
        return Colors.purple;
      case RouteMode.mixed:
        return Colors.teal;
    }
  }

  IconData _getRouteModeIcon(RouteMode mode) {
    switch (mode) {
      case RouteMode.driving:
        return Icons.directions_car;
      case RouteMode.walking:
        return Icons.directions_walk;
      case RouteMode.cycling:
        return Icons.directions_bike;
      case RouteMode.transit:
        return Icons.directions_transit;
      case RouteMode.mixed:
        return Icons.route;
    }
  }

  String _getRouteModeName(RouteMode mode) {
    switch (mode) {
      case RouteMode.driving:
        return 'Drive';
      case RouteMode.walking:
        return 'Walk';
      case RouteMode.cycling:
        return 'Bike';
      case RouteMode.transit:
        return 'Transit';
      case RouteMode.mixed:
        return 'Mixed';
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
      case Priority.critical:
        return Colors.red.shade800;
    }
  }
}

// Extension to add copyWith method to RoutePreferences
extension RoutePreferencesExtension on RoutePreferences {
  RoutePreferences copyWith({
    bool? prioritizeAirQuality,
    bool? prioritizeSpeed,
    bool? prioritizeCost,
    bool? prioritizeHealth,
    Set<RouteMode>? preferredModes,
    double? maxTravelTime,
    double? maxPollutionExposure,
  }) {
    return RoutePreferences(
      prioritizeAirQuality: prioritizeAirQuality ?? this.prioritizeAirQuality,
      prioritizeSpeed: prioritizeSpeed ?? this.prioritizeSpeed,
      prioritizeCost: prioritizeCost ?? this.prioritizeCost,
      prioritizeHealth: prioritizeHealth ?? this.prioritizeHealth,
      preferredModes: preferredModes ?? this.preferredModes,
      maxTravelTime: maxTravelTime ?? this.maxTravelTime,
      maxPollutionExposure: maxPollutionExposure ?? this.maxPollutionExposure,
    );
  }
}
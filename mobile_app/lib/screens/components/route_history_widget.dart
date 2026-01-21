import 'package:flutter/material.dart';
import '../../models/route_planning_data.dart';

class RouteHistoryWidget extends StatefulWidget {
  final List<RouteHistory> history;
  final Function(RouteOption) onRouteSelected;

  const RouteHistoryWidget({
    Key? key,
    required this.history,
    required this.onRouteSelected,
  }) : super(key: key);

  @override
  State<RouteHistoryWidget> createState() => _RouteHistoryWidgetState();
}

class _RouteHistoryWidgetState extends State<RouteHistoryWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'frequency', 'air_quality'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilterBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRecentRoutesTab(),
              _buildFrequentRoutesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
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
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search routes...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  setState(() {
                    _sortBy = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'date',
                    child: Row(
                      children: [
                        Icon(Icons.date_range),
                        SizedBox(width: 8),
                        Text('Sort by Date'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'frequency',
                    child: Row(
                      children: [
                        Icon(Icons.repeat),
                        SizedBox(width: 8),
                        Text('Sort by Frequency'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'air_quality',
                    child: Row(
                      children: [
                        Icon(Icons.air),
                        SizedBox(width: 8),
                        Text('Sort by Air Quality'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 32,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.history),
                  text: 'Recent',
                ),
                Tab(
                  icon: Icon(Icons.star),
                  text: 'Frequent',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRoutesTab() {
    if (widget.history.isEmpty) {
      return const _buildEmptyState();
    }

    final filteredHistory = _getFilteredAndSortedHistory();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        final historyEntry = filteredHistory[index];
        return _buildHistoryCard(context, historyEntry, index);
      },
    );
  }

  Widget _buildFrequentRoutesTab() {
    // Group routes by origin-destination pair and count frequency
    final routeFrequency = <String, int>{};
    final routeGroups = <String, List<RouteHistory>>{};
    
    for (final entry in widget.history) {
      final key = '${entry.originalRequest.origin}_to_${entry.originalRequest.destination}';
      routeFrequency[key] = (routeFrequency[key] ?? 0) + 1;
      
      if (!routeGroups.containsKey(key)) {
        routeGroups[key] = [];
      }
      routeGroups[key]!.add(entry);
    }

    // Sort by frequency
    final sortedRoutes = routeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedRoutes.isEmpty) {
      return const _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedRoutes.length,
      itemBuilder: (context, index) {
        final entry = sortedRoutes[index];
        final routeGroup = routeGroups[entry.key]!.first;
        return _buildFrequentRouteCard(context, routeGroup, entry.value);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Route History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Plan some routes to see your history here',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, RouteHistory history, int index) {
    final route = history.selectedRoute;
    final isCompleted = history.wasCompleted;
    final age = DateTime.now().difference(history.startTime);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onRouteSelected(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, route, history, age),
              const SizedBox(height: 12),
              _buildRouteDetails(context, route),
              const SizedBox(height: 12),
              _buildStatusRow(context, history, isCompleted),
              const SizedBox(height: 12),
              _buildActionButtons(context, history, isCompleted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RouteOption route, RouteHistory history, Duration age) {
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDateTime(history.startTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _formatAge(age),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteDetails(BuildContext context, RouteOption route) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                route.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDetailChip(
                context,
                icon: Icons.straighten,
                label: '${route.distance.toStringAsFixed(1)} km',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDetailChip(
                context,
                icon: Icons.access_time,
                label: '${route.duration} min',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDetailChip(
                context,
                icon: Icons.air,
                label: '${route.airQualityScore.toStringAsFixed(0)}/100',
                color: _getAirQualityColor(route.airQualityScore),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailChip(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, RouteHistory history, bool isCompleted) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.schedule,
                size: 12,
                color: isCompleted ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                isCompleted ? 'Completed' : 'Planned',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (history.wasCompleted && history.endTime != null) ...[
          Icon(
            Icons.timer,
            size: 12,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            'Actual: ${history.actualDuration} min',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (history.actualDistance > 0) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.straighten,
            size: 12,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            'Actual: ${history.actualDistance.toStringAsFixed(1)} km',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, RouteHistory history, bool isCompleted) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: () => widget.onRouteSelected(history.selectedRoute),
            icon: const Icon(Icons.repeat, size: 16),
            label: const Text('Use Again'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton.icon(
            onPressed: () => _showRouteDetails(context, history),
            icon: const Icon(Icons.info, size: 16),
            label: const Text('Details'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequentRouteCard(BuildContext context, RouteHistory history, int frequency) {
    final route = history.selectedRoute;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onRouteSelected(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$frequency times',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailChip(
                      context,
                      icon: Icons.straighten,
                      label: '${route.distance.toStringAsFixed(1)} km',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailChip(
                      context,
                      icon: Icons.access_time,
                      label: '${route.duration} min',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailChip(
                      context,
                      icon: Icons.air,
                      label: '${route.airQualityScore.toStringAsFixed(0)}/100',
                      color: _getAirQualityColor(route.airQualityScore),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<RouteHistory> _getFilteredAndSortedHistory() {
    var filtered = widget.history.where((entry) {
      if (_searchQuery.isEmpty) return true;
      
      final route = entry.selectedRoute;
      return route.name.toLowerCase().contains(_searchQuery) ||
             entry.originalRequest.origin.toLowerCase().contains(_searchQuery) ||
             entry.originalRequest.destination.toLowerCase().contains(_searchQuery);
    }).toList();

    // Sort based on selected criteria
    switch (_sortBy) {
      case 'date':
        filtered.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case 'frequency':
        // For now, just sort by date as frequency calculation would need more data
        filtered.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case 'air_quality':
        filtered.sort((a, b) => b.selectedRoute.airQualityScore.compareTo(a.selectedRoute.airQualityScore));
        break;
    }

    return filtered;
  }

  void _showRouteDetails(BuildContext context, RouteHistory history) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildRouteDetailsBottomSheet(context, history),
    );
  }

  Widget _buildRouteDetailsBottomSheet(BuildContext context, RouteHistory history) {
    final route = history.selectedRoute;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Route Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'Route Name', route.name),
          _buildDetailRow(context, 'Distance', '${route.distance.toStringAsFixed(1)} km'),
          _buildDetailRow(context, 'Duration', '${route.duration} minutes'),
          _buildDetailRow(context, 'Air Quality Score', '${route.airQualityScore.toStringAsFixed(0)}/100'),
          if (history.wasCompleted) ...[
            _buildDetailRow(context, 'Actual Duration', '${history.actualDuration} minutes'),
            _buildDetailRow(context, 'Actual Distance', '${history.actualDistance.toStringAsFixed(1)} km'),
          ],
          _buildDetailRow(context, 'Start Time', _formatDateTime(history.startTime)),
          if (history.endTime != null)
            _buildDetailRow(context, 'End Time', _formatDateTime(history.endTime!)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRouteSelected(route);
            },
            child: const Text('Use This Route Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatAge(Duration age) {
    if (age.inDays > 0) {
      return '${age.inDays} day${age.inDays > 1 ? 's' : ''} ago';
    } else if (age.inHours > 0) {
      return '${age.inHours} hour${age.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${age.inMinutes} minute${age.inMinutes > 1 ? 's' : ''} ago';
    }
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

  Color _getAirQualityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.red;
    return Colors.red.shade800;
  }
}
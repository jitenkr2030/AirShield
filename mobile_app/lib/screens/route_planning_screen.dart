import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../bloc/route_planning_bloc.dart';
import '../../core/services/location_service.dart';
import '../../models/route_planning_data.dart';
import 'components/route_comparison_widget.dart';
import 'components/route_map_widget.dart';
import 'components/route_details_widget.dart';
import 'components/route_history_widget.dart';

class RoutePlanningScreen extends StatefulWidget {
  const RoutePlanningScreen({Key? key}) : super(key: key);

  @override
  State<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends State<RoutePlanningScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final LocationService _locationService = LocationService();
  
  Position? _currentPosition;
  bool _isCalculating = false;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkPermissionsAndInitialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    // Check location permissions
    final locationPermission = await Permission.location.request();
    final locationStatus = await Permission.location.status;
    
    setState(() {
      _hasPermissions = locationPermission.isGranted || locationStatus.isGranted;
    });
    
    if (_hasPermissions) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to get current location: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Planning'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Map'),
            Tab(icon: Icon(Icons.compare), text: 'Compare'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: _hasPermissions ? _buildMainContent() : _buildPermissionScreen(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildPermissionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Location Permission Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'AIRSHIELD needs location access to provide route planning and air quality-aware navigation.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return BlocConsumer<RoutePlanningBloc, RoutePlanningState>(
      listener: (context, state) {
        if (state is RoutePlanningError) {
          _showErrorSnackBar(state.message);
        } else if (state is RoutesCalculatedState && state.comparison != null) {
          _showSuccessSnackBar('Routes calculated successfully');
        } else if (state is RouteSelectedState) {
          _showSuccessSnackBar('Route selected');
        }
      },
      builder: (context, state) {
        return TabBarView(
          controller: _tabController,
          children: [
            _buildMapTab(state),
            _buildCompareTab(state),
            _buildHistoryTab(),
            _buildSettingsTab(),
          ],
        );
      },
    );
  }

  Widget _buildMapTab(RoutePlanningState state) {
    return Column(
      children: [
        _buildRouteInputCard(state is RoutesCalculatedState ? state.selectedRoute : null),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RouteMapWidget(
                currentPosition: _currentPosition,
                selectedRoute: state is RoutesCalculatedState ? state.selectedRoute : null,
                availableRoutes: state is RoutesCalculatedState ? state.routes : [],
                isLoading: state is RoutePlanningLoading,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompareTab(RoutePlanningState state) {
    if (state is! RoutesCalculatedState) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Calculate routes to compare options'),
          ],
        ),
      );
    }

    if (state.routes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RouteComparisonWidget(
      routes: state.routes,
      comparison: state.comparison,
      selectedRoute: state.selectedRoute,
      onRouteSelected: (route) {
        context.read<RoutePlanningBloc>().add(
          SelectRouteEvent(route),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
      builder: (context, state) {
        if (state is RouteHistoryState) {
          return RouteHistoryWidget(
            history: state.history,
            onRouteSelected: (route) {
              // Handle route selection from history
            },
          );
        }

        // Load history
        context.read<RoutePlanningBloc>().add(const GetRouteHistoryEvent());
        
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
      builder: (context, state) {
        final preferences = state is RoutePreferencesState 
            ? state.preferences 
            : const RoutePreferences();
            
        return _buildPreferencesForm(preferences);
      },
    );
  }

  Widget _buildRouteInputCard(RouteOption? selectedRoute) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.directions, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Plan Your Route',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _originController,
            label: 'Origin',
            icon: Icons.my_location,
            onTap: _setCurrentLocationAsOrigin,
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _destinationController,
            label: 'Destination',
            icon: Icons.location_on,
            onTap: _showLocationPicker,
          ),
          const SizedBox(height: 16),
          _buildTransportModeSelector(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCalculating ? null : _calculateRoutes,
                  icon: _isCalculating 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.route),
                  label: Text(_isCalculating ? 'Calculating...' : 'Calculate Routes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (selectedRoute != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _tabController.animateTo(1); // Switch to compare tab
                  },
                  icon: const Icon(Icons.compare_arrows),
                  tooltip: 'Compare Routes',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: onTap != null 
            ? IconButton(
                icon: const Icon(Icons.gps_fixed),
                onPressed: onTap,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      onTap: onTap,
      readOnly: true,
    );
  }

  Widget _buildTransportModeSelector() {
    return BlocBuilder<RoutePlanningBloc, RoutePlanningState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModeButton(Icons.directions_car, 'Drive', RouteMode.driving, state),
            _buildModeButton(Icons.directions_walk, 'Walk', RouteMode.walking, state),
            _buildModeButton(Icons.directions_bike, 'Bike', RouteMode.cycling, state),
            _buildModeButton(Icons.directions_transit, 'Transit', RouteMode.transit, state),
          ],
        );
      },
    );
  }

  Widget _buildModeButton(IconData icon, String label, RouteMode mode, RoutePlanningState state) {
    // For simplicity, using driving mode as default
    final bool isSelected = mode == RouteMode.driving;
    
    return GestureDetector(
      onTap: () {
        // Update route mode in preferences
        final preferences = RoutePreferences(
          prioritizeAirQuality: true,
          prioritizeHealth: true,
        );
        context.read<RoutePlanningBloc>().add(
          UpdateRoutePreferencesEvent(preferences),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _tabController.animateTo(0); // Switch to map tab
      },
      child: const Icon(Icons.map),
    );
  }

  Widget _buildPreferencesForm(RoutePreferences preferences) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('Route Preferences'),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Prioritize Air Quality',
            subtitle: 'Choose routes with cleaner air',
            value: preferences.prioritizeAirQuality,
            onChanged: (value) {
              _updatePreferences(preferences.copyWith(
                prioritizeAirQuality: value,
              ));
            },
          ),
          _buildSwitchTile(
            title: 'Prioritize Health',
            subtitle: 'Minimize health impact',
            value: preferences.prioritizeHealth,
            onChanged: (value) {
              _updatePreferences(preferences.copyWith(
                prioritizeHealth: value,
              ));
            },
          ),
          _buildSwitchTile(
            title: 'Prioritize Speed',
            subtitle: 'Choose fastest route',
            value: preferences.prioritizeSpeed,
            onChanged: (value) {
              _updatePreferences(preferences.copyWith(
                prioritizeSpeed: value,
              ));
            },
          ),
          _buildSwitchTile(
            title: 'Prioritize Cost',
            subtitle: 'Choose most economical route',
            value: preferences.prioritizeCost,
            onChanged: (value) {
              _updatePreferences(preferences.copyWith(
                prioritizeCost: value,
              ));
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Advanced Settings'),
          const SizedBox(height: 16),
          _buildSliderTile(
            title: 'Max Travel Time',
            subtitle: 'Maximum acceptable travel time',
            value: preferences.maxTravelTime,
            min: 30,
            max: 300,
            divisions: 27,
            onChanged: (value) {
              _updatePreferences(preferences.copyWith(
                maxTravelTime: value,
              ));
            },
          ),
          _buildSliderTile(
            title: 'Max Pollution Exposure',
            subtitle: 'Maximum acceptable pollution exposure',
            value: preferences.maxPollutionExposure,
            min: 10,
            max: 100,
            divisions: 9,
            onChanged: (value) {
              _updatePreferences(preferences.copyWith(
                maxPollutionExposure: value,
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(subtitle),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
            Text('${value.toInt()} min'),
          ],
        ),
      ),
    );
  }

  void _setCurrentLocationAsOrigin() {
    if (_currentPosition != null) {
      _originController.text = 'Current Location';
    } else {
      _getCurrentLocation().then((_) {
        if (_currentPosition != null) {
          _originController.text = 'Current Location';
        }
      });
    }
  }

  void _showLocationPicker() {
    // Show location picker dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Destination'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Address'),
              onTap: () {
                Navigator.pop(context);
                _showSearchDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Pick from Map'),
              onTap: () {
                Navigator.pop(context);
                _showMapPicker();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Address'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter address',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            _destinationController.text = value;
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showMapPicker() {
    // Show map for location selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Map picker not implemented in this demo'),
      ),
    );
  }

  void _calculateRoutes() {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      _showErrorSnackBar('Please set origin and destination');
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    final routeRequest = RouteRequest(
      origin: _originController.text,
      destination: _destinationController.text,
      mode: RouteMode.driving,
      departureTime: DateTime.now(),
      avoidHighPollution: true,
    );

    context.read<RoutePlanningBloc>().add(CalculateRoutesEvent(routeRequest));

    // Reset loading state after a delay (BLoC will handle the actual state)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
      }
    });
  }

  void _updatePreferences(RoutePreferences preferences) {
    context.read<RoutePlanningBloc>().add(
      UpdateRoutePreferencesEvent(preferences),
    );
  }
}
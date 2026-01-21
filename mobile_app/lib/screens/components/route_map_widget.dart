import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/route_planning_data.dart';

class RouteMapWidget extends StatefulWidget {
  final Position? currentPosition;
  final RouteOption? selectedRoute;
  final List<RouteOption> availableRoutes;
  final bool isLoading;

  const RouteMapWidget({
    Key? key,
    required this.currentPosition,
    required this.selectedRoute,
    required this.availableRoutes,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco default
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _updateMapState();
  }

  @override
  void didUpdateWidget(RouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMapState();
  }

  void _updateMapState() {
    // Update markers, polylines, and camera position based on current state
    _updateMarkers();
    _updatePolylines();
    _updateCameraPosition();
  }

  void _updateMarkers() {
    _markers.clear();
    
    // Add current location marker
    if (widget.currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(
            title: 'Current Location',
            snippet: 'Your current position',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add route destination markers
    for (int i = 0; i < widget.availableRoutes.length; i++) {
      final route = widget.availableRoutes[i];
      if (route.segments.isNotEmpty) {
        // Add destination marker
        final destinationSegment = route.segments.last;
        _markers.add(
          Marker(
            markerId: MarkerId('destination_$i'),
            position: const LatLng(37.7849, -122.4094), // Simplified coordinate
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: route.name,
            ),
            icon: _getDestinationIcon(),
          ),
        );
      }
    }

    // Add air quality zone markers
    _addAirQualityMarkers();
  }

  void _updatePolylines() {
    _polylines.clear();
    
    if (widget.selectedRoute != null) {
      _addRoutePolyline(widget.selectedRoute!, Colors.blue, true);
    } else {
      // Show all available routes with different colors
      final colors = [
        Colors.red,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.teal,
      ];
      
      for (int i = 0; i < widget.availableRoutes.length; i++) {
        final route = widget.availableRoutes[i];
        final color = colors[i % colors.length];
        _addRoutePolyline(route, color, false);
      }
    }
  }

  void _addRoutePolyline(RouteOption route, Color color, bool isSelected) {
    // Generate polyline points for the route
    final List<LatLng> points = _generatePolylinePoints(route);
    
    if (points.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_${route.routeId}'),
          points: points,
          color: color,
          width: isSelected ? 8 : 4,
          patterns: isSelected ? [] : [],
        ),
      );
    }
  }

  List<LatLng> _generatePolylinePoints(RouteOption route) {
    // In a real implementation, this would decode the actual polyline
    // For now, generate a simple route path
    final points = <LatLng>[];
    
    // Starting point (current location or default)
    LatLng startPoint = const LatLng(37.7749, -122.4194);
    if (widget.currentPosition != null) {
      startPoint = LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
    }
    points.add(startPoint);
    
    // Generate intermediate points based on route segments
    final segmentCount = route.segments.length;
    final stepLat = (37.7849 - startPoint.latitude) / (segmentCount + 1);
    final stepLng = (-122.4094 - startPoint.longitude) / (segmentCount + 1);
    
    for (int i = 0; i < segmentCount; i++) {
      final intermediatePoint = LatLng(
        startPoint.latitude + (stepLat * (i + 1)),
        startPoint.longitude + (stepLng * (i + 1)),
      );
      points.add(intermediatePoint);
    }
    
    // End point
    points.add(const LatLng(37.7849, -122.4094));
    
    return points;
  }

  void _addAirQualityMarkers() {
    // Add air quality zone markers based on route data
    if (widget.selectedRoute != null) {
      for (final segment in widget.selectedRoute!.segments) {
        for (final zone in segment.airQuality.zones) {
          _markers.add(
            Marker(
              markerId: MarkerId('aqi_${zone.zoneId}'),
              position: LatLng(zone.lat, zone.lng),
              infoWindow: InfoWindow(
                title: 'Air Quality Zone',
                snippet: 'AQI: ${zone.aqi.toStringAsFixed(0)}',
              ),
              icon: _getAirQualityIcon(zone.aqi),
            ),
          );
          
          // Add circle to show the affected area
          _circles.add(
            Circle(
              circleId: CircleId('aqi_circle_${zone.zoneId}'),
              center: LatLng(zone.lat, zone.lng),
              radius: 500, // 500 meter radius
              fillColor: _getAirQualityColor(zone.aqi).withOpacity(0.3),
              strokeColor: _getAirQualityColor(zone.aqi),
              strokeWidth: 2,
            ),
          );
        }
      }
    }
  }

  void _updateCameraPosition() {
    if (widget.currentPosition != null) {
      _initialCameraPosition = CameraPosition(
        target: LatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ),
        zoom: 12,
      );
    }
  }

  BitmapDescriptor _getCurrentLocationIcon() {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  BitmapDescriptor _getDestinationIcon() {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  BitmapDescriptor _getAirQualityIcon(double aqi) {
    return BitmapDescriptor.defaultMarkerWithHue(_getAirQualityHue(aqi));
  }

  double _getAirQualityHue(double aqi) {
    if (aqi <= 50) return BitmapDescriptor.hueGreen;
    if (aqi <= 100) return BitmapDescriptor.hueYellow;
    if (aqi <= 150) return BitmapDescriptor.hueOrange;
    if (aqi <= 200) return BitmapDescriptor.hueRed;
    return BitmapDescriptor.hueViolet;
  }

  Color _getAirQualityColor(double aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    return Colors.purple;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMapState();
  }

  void _onMarkerTap(MarkerId markerId) {
    // Handle marker tap events
    if (markerId.value == 'current_location') {
      _showCurrentLocationInfo();
    } else if (markerId.value.startsWith('destination_')) {
      _showDestinationInfo(markerId);
    } else if (markerId.value.startsWith('aqi_')) {
      _showAirQualityInfo(markerId);
    }
  }

  void _showCurrentLocationInfo() {
    if (widget.currentPosition != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Current Location: ${widget.currentPosition!.latitude.toStringAsFixed(6)}, '
            '${widget.currentPosition!.longitude.toStringAsFixed(6)}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showDestinationInfo(MarkerId markerId) {
    final routeIndex = int.parse(markerId.value.split('_')[1]);
    if (routeIndex < widget.availableRoutes.length) {
      final route = widget.availableRoutes[routeIndex];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Route: ${route.name} - ${route.distance.toStringAsFixed(1)}km, '
            '${route.duration}min',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showAirQualityInfo(MarkerId markerId) {
    if (widget.selectedRoute != null) {
      final zone = widget.selectedRoute!.segments
          .expand((segment) => segment.airQuality.zones)
          .firstWhere(
            (zone) => markerId.value == 'aqi_${zone.zoneId}',
            orElse: () => throw Exception('Zone not found'),
          );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Air Quality: AQI ${zone.aqi.toStringAsFixed(0)} - '
            '${_getAirQualityDescription(zone.aqi)}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getAirQualityDescription(double aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: _initialCameraPosition,
          markers: _markers,
          polylines: _polylines,
          circles: _circles,
          onTap: _onMapTap,
          onMarkerTap: _onMarkerTap,
          mapToolbarEnabled: false,
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          myLocationEnabled: widget.currentPosition != null,
          myLocationButtonEnabled: true,
          compassEnabled: true,
        ),
        if (widget.isLoading) _buildLoadingOverlay(),
        if (widget.selectedRoute != null) _buildRouteInfoPanel(),
        _buildMapControls(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Calculating routes...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoPanel() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.route,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.selectedRoute!.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // Clear selected route
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.straighten,
                    label: '${widget.selectedRoute!.distance.toStringAsFixed(1)} km',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.access_time,
                    label: '${widget.selectedRoute!.duration} min',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.air,
                    label: 'AQI ${widget.selectedRoute!.airQualityScore.toStringAsFixed(0)}',
                    color: _getAirQualityColor(widget.selectedRoute!.airQualityScore),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "current_location",
            mini: true,
            onPressed: () {
              if (widget.currentPosition != null) {
                _mapController.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      widget.currentPosition!.latitude,
                      widget.currentPosition!.longitude,
                    ),
                  ),
                );
              }
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "toggle_routes",
            mini: true,
            onPressed: () {
              // Toggle between showing all routes and selected route
            },
            child: const Icon(Icons.layers),
          ),
        ],
      ),
    );
  }

  void _onMapTap(LatLng position) {
    // Handle map tap events
    _showSnackBar('Tapped at: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
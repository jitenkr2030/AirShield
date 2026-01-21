import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  StreamController<Position>? _locationController;
  bool _isTracking = false;
  
  // Getters for current location
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;
  
  String? _currentAddress;
  String? get currentAddress => _currentAddress;
  
  Stream<Position> get locationStream => _locationController?.stream ?? const Stream.empty();
  bool get isTracking => _isTracking;

  LocationService();

  Future<void> requestPermissions() async {
    // Request location permissions
    final locationPermission = await Geolocator.requestPermission();
    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever) {
      throw LocationException('Location permission denied');
    }

    // Check if location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location service is disabled');
    }

    // Request background location permission for continuous tracking
    if (AppConfig.enableBluetoothSensors) {
      final backgroundPermission = await Geolocator.requestLocationPermissions();
      if (backgroundPermission == LocationPermission.denied ||
          backgroundPermission == LocationPermission.deniedForever) {
        // Background tracking will be disabled
        print('Background location permission denied');
      }
    }
  }

  Future<Position> getCurrentLocation({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await requestPermissions();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: desiredAccuracy,
        timeLimit: timeout,
      );

      _currentPosition = position;
      _currentAddress = await _getAddressFromCoordinates(position);

      return position;
    } catch (e) {
      throw LocationException('Failed to get current location: $e');
    }
  }

  Future<String> _getAddressFromCoordinates(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: AppConfig.getSetting('language', 'en'),
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
      return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    } catch (e) {
      return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    }
  }

  Future<void> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration distanceFilter = const Duration(seconds: 30),
    Duration timeFilter = const Duration(seconds: 30),
  }) async {
    if (_isTracking) {
      return; // Already tracking
    }

    try {
      _locationController = StreamController<Position>.broadcast();
      
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter.inMeters,
        ),
      ).listen(
        (Position position) async {
          _currentPosition = position;
          _currentAddress = await _getAddressFromCoordinates(position);
          _locationController?.add(position);
        },
        onError: (error) {
          print('Location tracking error: $error');
          _locationController?.addError(error);
        },
      );

      _isTracking = true;
    } catch (e) {
      throw LocationException('Failed to start location tracking: $e');
    }
  }

  Future<void> stopLocationTracking() async {
    if (!_isTracking) {
      return;
    }

    await _positionSubscription?.cancel();
    await _locationController?.close();
    
    _positionSubscription = null;
    _locationController = null;
    _isTracking = false;
  }

  Future<double> calculateDistance(Position start, Position end) async {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  Future<List<Position>> getLocationHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    // This would typically query a database or local storage
    // For now, return empty list
    return [];
  }

  Future<void> saveLocationHistory(Position position) async {
    // This would typically save to local storage or send to backend
    // Implementation depends on storage strategy
  }

  Future<bool> isInLocation({
    required double latitude,
    required double longitude,
    double radius = 1000, // meters
  }) async {
    if (_currentPosition == null) {
      await getCurrentLocation();
    }

    if (_currentPosition == null) return false;

    final distance = await calculateDistance(
      _currentPosition!,
      Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );

    return distance <= radius;
  }

  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        localeIdentifier: AppConfig.getSetting('language', 'en'),
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
      return '$latitude, $longitude';
    } catch (e) {
      return '$latitude, $longitude';
    }
  }

  Future<List<String>> searchLocations(String query) async {
    try {
      final locations = await locationFromAddress(
        query,
        localeIdentifier: AppConfig.getSetting('language', 'en'),
      );

      return locations.map((location) {
        return '${location.latitude},${location.longitude}';
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Position?> getPositionFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(
        address,
        localeIdentifier: AppConfig.getSetting('language', 'en'),
      );

      if (locations.isNotEmpty) {
        final location = locations.first;
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    } catch (e) {
      print('Error getting position from address: $e');
    }
    return null;
  }

  Future<void> checkLocationPermissions() async {
    final permission = await Geolocator.checkPermission();
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw LocationException('Location service is disabled');
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationException('Location permission denied');
    }
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Geofencing functionality
  Future<void> addGeofence({
    required String id,
    required double latitude,
    required double longitude,
    double radius = 1000,
    VoidCallback? onEnter,
    VoidCallback? onExit,
  }) async {
    // Implementation would depend on platform-specific geofencing
    // This is a placeholder for future implementation
  }

  Future<void> removeGeofence(String id) async {
    // Implementation for removing geofences
  }

  // High accuracy location for sensor data
  Future<Position> getHighAccuracyLocation() async {
    return await getCurrentLocation(
      desiredAccuracy: LocationAccuracy.best,
      timeout: const Duration(seconds: 15),
    );
  }

  // Battery optimized location tracking
  Future<void> startOptimizedTracking() async {
    await startLocationTracking(
      accuracy: LocationAccuracy.medium,
      distanceFilter: const Duration(minutes: 1),
      timeFilter: const Duration(minutes: 2),
    );
  }

  void dispose() {
    stopLocationTracking();
  }
}

class LocationException implements Exception {
  final String message;
  
  LocationException(this.message);
  
  @override
  String toString() => 'LocationException: $message';
}

// Location accuracy levels
enum LocationAccuracyLevel {
  low,
  medium,
  high,
  best,
}

extension LocationAccuracyLevelExtension on LocationAccuracyLevel {
  LocationAccuracy get geolocatorAccuracy {
    switch (this) {
      case LocationAccuracyLevel.low:
        return LocationAccuracy.low;
      case LocationAccuracyLevel.medium:
        return LocationAccuracy.medium;
      case LocationAccuracyLevel.high:
        return LocationAccuracy.high;
      case LocationAccuracyLevel.best:
        return LocationAccuracy.best;
    }
  }
}
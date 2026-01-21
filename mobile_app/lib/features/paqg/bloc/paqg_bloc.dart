import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/air_quality_data.dart';
import '../../core/services/api_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/bluetooth_service.dart';
import '../../core/services/storage_service.dart';

part 'paqg_event.dart';
part 'paqg_state.dart';

class PAQGBloc extends Bloc<PAQGEvent, PAQGState> {
  final ApiService _apiService;
  final LocationService _locationService;
  final BluetoothService _bluetoothService;
  final StorageService _storageService;
  
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<AirQualityData>? _sensorSubscription;
  StreamSubscription<Position>? _positionSubscription;

  PAQGBloc(
    this._apiService,
    this._locationService,
    this._bluetoothService,
    this._storageService,
  ) : super(PAQGInitial()) {
    on<InitializePAQG>(_onInitializePAQG);
    on<LoadCurrentAQIData>(_onLoadCurrentAQIData);
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<UpdateLocation>(_onUpdateLocation);
    on<UpdateAirQualityData>(_onUpdateAirQualityData);
    on<ConnectSensor>(_onConnectSensor);
    on<DisconnectSensor>(_onDisconnectSensor);
    on<SensorDataReceived>(_onSensorDataReceived);
    on<UpdateHealthScore>(_onUpdateHealthScore);
    on<SubmitSensorData>(_onSubmitSensorData);
    on<RefreshData>(_onRefreshData);
    on<SetSensorThreshold>(_onSetSensorThreshold);
    on<CalibrateSensor>(_onCalibrateSensor);
  }

  Future<void> _onInitializePAQG(
    InitializePAQG event,
    Emitter<PAQGState> emit,
  ) async {
    emit(PAQGLoading());
    
    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      
      // Load current air quality data
      final airQualityData = await _apiService.getCurrentAQIData(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      // Start location tracking
      if (_locationService.isTracking) {
        await _locationService.stopLocationTracking();
      }
      await _locationService.startLocationTracking();
      
      // Start listening to location updates
      _locationSubscription = _locationService.locationStream.listen(
        (Position position) {
          add(UpdateLocation(position));
        },
        onError: (error) {
          emit(PAQGError('Location tracking error: $error'));
        },
      );
      
      emit(PAQGLoaded(
        currentLocation: position,
        airQualityData: airQualityData,
        healthScore: 85.0, // Calculate based on air quality
        isTracking: true,
        connectedSensor: null,
      ));
      
    } catch (e) {
      emit(PAQGError('Failed to initialize PAQG: $e'));
    }
  }

  Future<void> _onLoadCurrentAQIData(
    LoadCurrentAQIData event,
    Emitter<PAQGState> emit,
  ) async {
    if (state is! PAQGLoaded) return;
    
    final currentState = state as PAQGLoaded;
    
    try {
      emit(currentState.copyWith(isLoading: true));
      
      final airQualityData = await _apiService.getCurrentAQIData(
        latitude: currentState.currentLocation.latitude,
        longitude: currentState.currentLocation.longitude,
      );
      
      emit(currentState.copyWith(
        airQualityData: airQualityData,
        isLoading: false,
      ));
      
    } catch (e) {
      emit(currentState.copyWith(
        error: 'Failed to load air quality data: $e',
        isLoading: false,
      ));
    }
  }

  Future<void> _onStartLocationTracking(
    StartLocationTracking event,
    Emitter<PAQGState> emit,
  ) async {
    try {
      await _locationService.startLocationTracking();
      
      if (state is PAQGLoaded) {
        final currentState = state as PAQGLoaded;
        emit(currentState.copyWith(isTracking: true));
      }
    } catch (e) {
      emit(PAQGError('Failed to start location tracking: $e'));
    }
  }

  Future<void> _onStopLocationTracking(
    StopLocationTracking event,
    Emitter<PAQGState> emit,
  ) async {
    try {
      await _locationService.stopLocationTracking();
      
      if (state is PAQGLoaded) {
        final currentState = state as PAQGLoaded;
        emit(currentState.copyWith(isTracking: false));
      }
    } catch (e) {
      emit(PAQGError('Failed to stop location tracking: $e'));
    }
  }

  void _onUpdateLocation(
    UpdateLocation event,
    Emitter<PAQGState> emit,
  ) async {
    if (state is! PAQGLoaded) return;
    
    final currentState = state as PAQGLoaded;
    emit(currentState.copyWith(currentLocation: event.position));
    
    // Load air quality data for new location
    add(LoadCurrentAQIData());
  }

  void _onUpdateAirQualityData(
    UpdateAirQualityData event,
    Emitter<PAQGState> emit,
  ) async {
    if (state is! PAQGLoaded) return;
    
    final currentState = state as PAQGLoaded;
    final newAirQualityData = event.airQualityData;
    
    // Calculate new health score based on air quality
    final newHealthScore = _calculateHealthScore(newAirQualityData);
    
    emit(currentState.copyWith(
      airQualityData: newAirQualityData,
      healthScore: newHealthScore,
    ));
    
    // Save to local storage
    await _storageService.saveMeasurement(newAirQualityData);
    
    // Check for alerts
    _checkForAlerts(newAirQualityData, currentState);
  }

  Future<void> _onConnectSensor(
    ConnectSensor event,
    Emitter<PAQGState> emit,
  ) async {
    if (state is! PAQGLoaded) return;
    
    try {
      final currentState = state as PAQGLoaded;
      emit(currentState.copyWith(isConnectingSensor: true));
      
      // Scan for sensors
      await _bluetoothService.startScanning(timeout: const Duration(seconds: 10));
      
      // Find air quality sensor (simplified logic)
      final sensors = _bluetoothService.scanResults
          .where((result) => _isAirQualityDevice(result.device))
          .toList();
      
      if (sensors.isEmpty) {
        emit(currentState.copyWith(
          error: 'No air quality sensors found',
          isConnectingSensor: false,
        ));
        return;
      }
      
      // Connect to the first sensor found
      final sensor = sensors.first.device;
      await _bluetoothService.connectToDevice(sensor);
      
      // Setup sensor data notifications
      await _bluetoothService.setupSensorNotifications(
        sensor,
        onDataReceived: (AirQualityData data) {
          add(SensorDataReceived(data));
        },
      );
      
      emit(currentState.copyWith(
        connectedSensor: sensor,
        isConnectingSensor: false,
        isSensorConnected: true,
      ));
      
    } catch (e) {
      if (state is PAQGLoaded) {
        final currentState = state as PAQGLoaded;
        emit(currentState.copyWith(
          error: 'Failed to connect sensor: $e',
          isConnectingSensor: false,
        ));
      }
    }
  }

  Future<void> _onDisconnectSensor(
    DisconnectSensor event,
    Emitter<PAQGState> emit,
  ) async {
    if (state is! PAQGLoaded) return;
    
    try {
      final currentState = state as PAQGLoaded;
      
      if (currentState.connectedSensor != null) {
        await _bluetoothService.disconnectDevice(currentState.connectedSensor!);
      }
      
      emit(currentState.copyWith(
        connectedSensor: null,
        isSensorConnected: false,
      ));
      
    } catch (e) {
      emit(PAQGError('Failed to disconnect sensor: $e'));
    }
  }

  void _onSensorDataReceived(
    SensorDataReceived event,
    Emitter<PAQGState> emit,
  ) {
    add(UpdateAirQualityData(event.data));
  }

  Future<void> _onUpdateHealthScore(
    UpdateHealthScore event,
    Emitter<PAQGState> emit,
  ) async {
    if (state is! PAQGLoaded) return;
    
    final currentState = state as PAQGLoaded;
    final newHealthScore = _calculateHealthScore(currentState.airQualityData);
    
    emit(currentState.copyWith(healthScore: newHealthScore));
  }

  Future<void> _onSubmitSensorData(
    SubmitSensorData event,
    Emitter<PAQGState> emit,
  ) async {
    try {
      await _apiService.submitSensorData(event.data);
      // Data submitted successfully
    } catch (e) {
      // Store locally for later sync
      await _storageService.saveMeasurement(event.data);
    }
  }

  Future<void> _onRefreshData(
    RefreshData event,
    Emitter<PAQGState> emit,
  ) async {
    add(LoadCurrentAQIData());
  }

  Future<void> _onSetSensorThreshold(
    SetSensorThreshold event,
    Emitter<PAQGState> emit,
  ) async {
    if (state is! PAQGLoaded) return;
    
    try {
      final currentState = state as PAQGLoaded;
      
      if (currentState.connectedSensor != null) {
        await _bluetoothService.updateSensorSettings(
          currentState.connectedSensor!,
          alertThreshold: event.threshold.toInt(),
        );
      }
      
      // Store threshold preference
      await _storageService.setInt('sensor_alert_threshold', event.threshold.toInt());
      
    } catch (e) {
      emit(PAQGError('Failed to set sensor threshold: $e'));
    }
  }

  Future<void> _onCalibrateSensor(
    CalibrateSensor event,
    Emitter<PAQGState> emit,
  ) async {
    if (state is! PAQGLoaded) return;
    
    try {
      final currentState = state as PAQGLoaded;
      
      if (currentState.connectedSensor != null) {
        await _bluetoothService.calibrateSensor(
          currentState.connectedSensor!,
          event.referenceValue,
        );
      }
      
      emit(PAQGCalibrated(event.referenceValue));
      
    } catch (e) {
      emit(PAQGError('Failed to calibrate sensor: $e'));
    }
  }

  // Helper methods
  bool _isAirQualityDevice(BluetoothDevice device) {
    final deviceName = device.name.toLowerCase();
    final id = device.id.id.toLowerCase();
    
    return deviceName.contains('pm') ||
           deviceName.contains('sensor') ||
           deviceName.contains('air') ||
           deviceName.contains('quality') ||
           deviceName.contains('aqi') ||
           id.contains('pm') ||
           id.contains('sensor');
  }

  double _calculateHealthScore(AirQualityData airQualityData) {
    // Calculate health score based on AQI and exposure time
    double baseScore = 100.0;
    final aqi = airQualityData.aqi;
    
    // Deduct points based on AQI level
    if (aqi > 50) baseScore -= (aqi - 50) * 0.3;
    if (aqi > 100) baseScore -= (aqi - 100) * 0.5;
    if (aqi > 150) baseScore -= (aqi - 150) * 0.8;
    if (aqi > 200) baseScore -= (aqi - 200) * 1.2;
    
    return baseScore.clamp(0.0, 100.0);
  }

  void _checkForAlerts(AirQualityData airQualityData, PAQGLoaded currentState) {
    // Check for high pollution alert
    if (airQualityData.aqi > 150) {
      // High pollution - could emit an alert state
      print('High pollution alert: AQI ${airQualityData.aqi}');
    }
    
    // Check for dangerous pollution
    if (airQualityData.aqi > 300) {
      // Dangerous pollution - immediate alert
      print('Dangerous pollution alert: AQI ${airQualityData.aqi}');
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _sensorSubscription?.cancel();
    _positionSubscription?.cancel();
    return super.close();
  }
}
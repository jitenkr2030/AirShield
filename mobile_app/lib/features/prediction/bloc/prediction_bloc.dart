import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/air_quality_data.dart';
import '../../models/prediction_data.dart';
import '../../core/services/api_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/ml_service.dart';

part 'prediction_event.dart';
part 'prediction_state.dart';

class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  final ApiService _apiService;
  final LocationService _locationService;
  final MLService _mlService;
  
  StreamSubscription<Position>? _locationSubscription;
  Timer? _predictionTimer;

  PredictionBloc(
    this._apiService,
    this._locationService,
    this._mlService,
  ) : super(PredictionInitial()) {
    on<LoadPredictions>(_onLoadPredictions);
    on<UpdateLocation>(_onUpdateLocation);
    on<LoadMicroZoneForecast>(_onLoadMicroZoneForecast);
    on<CalculateSafeRoutes>(_onCalculateSafeRoutes);
    on<RefreshPredictions>(_onRefreshPredictions);
    on<UpdatePredictionSettings>(_onUpdatePredictionSettings);
    on<SetPredictionRadius>(_onSetPredictionRadius);
    on<EnableRealTimeUpdates>(_onEnableRealTimeUpdates);
    on<DisableRealTimeUpdates>(_onDisableRealTimeUpdates);
    on<LoadHistoricalData>(_onLoadHistoricalData);
    on<ExportPredictionData>(_onExportPredictionData);
  }

  Future<void> _onLoadPredictions(
    LoadPredictions event,
    Emitter<PredictionState> emit,
  ) async {
    emit(PredictionLoading());
    
    try {
      final position = await _locationService.getCurrentLocation();
      
      // Load current predictions
      final predictions = await _apiService.getPredictionForecast(
        latitude: position.latitude,
        longitude: position.longitude,
        hours: 12,
      );
      
      // Load micro-zone data
      final microZoneData = await _apiService.getMicroZoneForecast(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: 2.0,
      );
      
      // Load current air quality for comparison
      final currentAQIData = await _apiService.getCurrentAQIData(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      emit(PredictionLoaded(
        currentLocation: position,
        predictions: predictions,
        microZoneData: microZoneData,
        currentAQIData: currentAQIData,
        isRealTimeEnabled: false,
        predictionRadius: 2.0,
      ));
      
      // Start real-time updates if enabled
      if (event.enableRealTime) {
        _startRealTimeUpdates(position);
      }
      
    } catch (e) {
      emit(PredictionError('Failed to load predictions: $e'));
    }
  }

  void _onUpdateLocation(
    UpdateLocation event,
    Emitter<PredictionState> emit,
  ) async {
    if (state is! PredictionLoaded) return;
    
    final currentState = state as PredictionLoaded;
    
    // Update location and refresh predictions
    add(LoadPredictions(
      latitude: event.position.latitude,
      longitude: event.position.longitude,
    ));
    
    // Stop real-time updates for old location
    _stopRealTimeUpdates();
  }

  Future<void> _onLoadMicroZoneForecast(
    LoadMicroZoneForecast event,
    Emitter<PredictionState> emit,
  ) async {
    if (state is! PredictionLoaded) return;
    
    try {
      final currentState = state as PredictionLoaded;
      emit(currentState.copyWith(isLoadingMicroZone: true));
      
      final microZoneData = await _apiService.getMicroZoneForecast(
        latitude: event.latitude,
        longitude: event.longitude,
        radius: event.radius,
      );
      
      emit(currentState.copyWith(
        microZoneData: microZoneData,
        isLoadingMicroZone: false,
      ));
      
    } catch (e) {
      if (state is PredictionLoaded) {
        final currentState = state as PredictionLoaded;
        emit(currentState.copyWith(
          error: 'Failed to load micro-zone data: $e',
          isLoadingMicroZone: false,
        ));
      }
    }
  }

  Future<void> _onCalculateSafeRoutes(
    CalculateSafeRoutes event,
    Emitter<PredictionState> emit,
  ) async {
    if (state is! PredictionLoaded) return;
    
    try {
      final currentState = state as PredictionLoaded;
      emit(currentState.copyWith(isCalculatingRoutes: true));
      
      final routes = await _apiService.getSafeRoutes(
        startLocation: event.from,
        endLocation: event.to,
        routeType: event.routeType,
        alternatives: 3,
      );
      
      emit(currentState.copyWith(
        safeRoutes: routes,
        isCalculatingRoutes: false,
      ));
      
    } catch (e) {
      if (state is PredictionLoaded) {
        final currentState = state as PredictionLoaded;
        emit(currentState.copyWith(
          error: 'Failed to calculate safe routes: $e',
          isCalculatingRoutes: false,
        ));
      }
    }
  }

  Future<void> _onRefreshPredictions(
    RefreshPredictions event,
    Emitter<PredictionState> emit,
  ) async {
    if (state is! PredictionLoaded) return;
    
    final currentState = state as PredictionLoaded;
    add(LoadPredictions(
      latitude: currentState.currentLocation.latitude,
      longitude: currentState.currentLocation.longitude,
    ));
  }

  Future<void> _onUpdatePredictionSettings(
    UpdatePredictionSettings event,
    Emitter<PredictionState> emit,
  ) async {
    if (state is! PredictionLoaded) return;
    
    final currentState = state as PredictionLoaded;
    emit(currentState.copyWith(
      predictionSettings: event.settings,
    ));
  }

  void _onSetPredictionRadius(
    SetPredictionRadius event,
    Emitter<PredictionState> emit,
  ) async {
    if (state is! PredictionLoaded) return;
    
    final currentState = state as PredictionLoaded;
    
    emit(currentState.copyWith(
      predictionRadius: event.radius,
    ));
    
    // Reload micro-zone data with new radius
    add(LoadMicroZoneForecast(
      latitude: currentState.currentLocation.latitude,
      longitude: currentState.currentLocation.longitude,
      radius: event.radius,
    ));
  }

  void _onEnableRealTimeUpdates(
    EnableRealTimeUpdates event,
    Emitter<PredictionState> emit,
  ) async {
    if (state is! PredictionLoaded) return;
    
    final currentState = state as PredictionLoaded;
    
    // Stop existing timer if any
    _stopRealTimeUpdates();
    
    _predictionTimer = Timer.periodic(
      const Duration(minutes: 15),
      (timer) {
        if (state is PredictionLoaded) {
          final updatedState = state as PredictionLoaded;
          add(LoadPredictions(
            latitude: updatedState.currentLocation.latitude,
            longitude: updatedState.currentLocation.longitude,
          ));
        }
      },
    );
    
    emit(currentState.copyWith(
      isRealTimeEnabled: true,
      lastUpdateTime: DateTime.now(),
    ));
  }

  void _onDisableRealTimeUpdates(
    DisableRealTimeUpdates event,
    Emitter<PredictionState> emit,
  ) async {
    if (state is! PredictionLoaded) return;
    
    final currentState = state as PredictionLoaded;
    _stopRealTimeUpdates();
    
    emit(currentState.copyWith(isRealTimeEnabled: false));
  }

  void _onLoadHistoricalData(
    LoadHistoricalData event,
    Emitter<PredictionState> emit,
  ) async {
    if (state is! PredictionLoaded) return;
    
    try {
      final currentState = state as PredictionLoaded;
      emit(currentState.copyWith(isLoadingHistorical: true));
      
      final historicalData = await _apiService.getAQIHistory(
        latitude: event.latitude,
        longitude: event.longitude,
        startDate: event.startDate,
        endDate: event.endDate,
        limit: event.limit,
      );
      
      emit(currentState.copyWith(
        historicalData: historicalData,
        isLoadingHistorical: false,
      ));
      
    } catch (e) {
      if (state is PredictionLoaded) {
        final currentState = state as PredictionLoaded;
        emit(currentState.copyWith(
          error: 'Failed to load historical data: $e',
          isLoadingHistorical: false,
        ));
      }
    }
  }

  Future<void> _onExportPredictionData(
    ExportPredictionData event,
    Emitter<PredictionState> emit,
  ) async {
    if (state is! PredictionLoaded) return;
    
    try {
      final currentState = state as PredictionLoaded;
      emit(currentState.copyWith(isExporting: true));
      
      // Prepare export data
      final exportData = {
        'location': currentState.currentLocation,
        'predictions': currentState.predictions.map((p) => p.toJson()).toList(),
        'micro_zone': currentState.microZoneData?.toJson(),
        'exported_at': DateTime.now().toIso8601String(),
        'settings': currentState.predictionSettings,
      };
      
      // Save to file (simplified)
      // In a real app, this would save to device storage or share
      print('Export data: ${exportData.toString()}');
      
      emit(currentState.copyWith(
        isExporting: false,
        exportSuccess: true,
      ));
      
      // Reset export success flag after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (state is PredictionLoaded) {
          final stateAfterDelay = state as PredictionLoaded;
          emit(stateAfterDelay.copyWith(exportSuccess: false));
        }
      });
      
    } catch (e) {
      if (state is PredictionLoaded) {
        final currentState = state as PredictionLoaded;
        emit(currentState.copyWith(
          error: 'Failed to export data: $e',
          isExporting: false,
        ));
      }
    }
  }

  // Helper methods
  void _startRealTimeUpdates(Position position) {
    _locationSubscription = _locationService.locationStream.listen(
      (Position newPosition) {
        // Check if location has changed significantly
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );
        
        if (distance > 100) { // 100 meters
          add(UpdateLocation(newPosition));
        }
      },
    );
  }

  void _stopRealTimeUpdates() {
    _predictionTimer?.cancel();
    _predictionTimer = null;
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  @override
  Future<void> close() {
    _stopRealTimeUpdates();
    return super.close();
  }
}
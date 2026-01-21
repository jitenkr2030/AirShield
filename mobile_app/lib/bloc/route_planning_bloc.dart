import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/route_planning_data.dart';
import '../services/route_planning_service.dart';

abstract class RoutePlanningEvent {}

class CalculateRoutesEvent extends RoutePlanningEvent {
  final RouteRequest routeRequest;
  
  const CalculateRoutesEvent(this.routeRequest);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculateRoutesEvent && runtimeType == other.runtimeType && routeRequest == other.routeRequest;
  
  @override
  int get hashCode => routeRequest.hashCode;
}

class CompareRoutesEvent extends RoutePlanningEvent {
  final List<RouteOption> routes;
  final RoutePreferences preferences;
  
  const CompareRoutesEvent(this.routes, this.preferences);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompareRoutesEvent &&
          runtimeType == other.runtimeType &&
          routes == other.routes &&
          preferences == other.preferences;
  
  @override
  int get hashCode => routes.hashCode ^ preferences.hashCode;
}

class SelectRouteEvent extends RoutePlanningEvent {
  final RouteOption selectedRoute;
  
  const SelectRouteEvent(this.selectedRoute);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectRouteEvent && runtimeType == other.runtimeType && selectedRoute == other.selectedRoute;
  
  @override
  int get hashCode => selectedRoute.hashCode;
}

class UpdateRoutePreferencesEvent extends RoutePlanningEvent {
  final RoutePreferences preferences;
  
  const UpdateRoutePreferencesEvent(this.preferences);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateRoutePreferencesEvent && runtimeType == other.runtimeType && preferences == other.preferences;
  
  @override
  int get hashCode => preferences.hashCode;
}

class GetRouteHistoryEvent extends RoutePlanningEvent {
  final int limit;
  
  const GetRouteHistoryEvent([this.limit = 10]);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetRouteHistoryEvent && runtimeType == other.runtimeType && limit == other.limit;
  
  @override
  int get hashCode => limit.hashCode;
}

class ClearRouteDataEvent extends RoutePlanningEvent {}

abstract class RoutePlanningState {}

class RoutePlanningInitial extends RoutePlanningState {}

class RoutePlanningLoading extends RoutePlanningState {}

class RoutesCalculatedState extends RoutePlanningState {
  final List<RouteOption> routes;
  final RouteComparison? comparison;
  final RouteOption? selectedRoute;
  
  const RoutesCalculatedState({
    required this.routes,
    this.comparison,
    this.selectedRoute,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutesCalculatedState &&
          runtimeType == other.runtimeType &&
          routes == other.routes &&
          comparison == other.comparison &&
          selectedRoute == other.selectedRoute;
  
  @override
  int get hashCode => routes.hashCode ^ comparison.hashCode ^ selectedRoute.hashCode;
}

class RouteComparisonState extends RoutePlanningState {
  final RouteComparison comparison;
  final RouteOption? recommendedRoute;
  
  const RouteComparisonState({
    required this.comparison,
    this.recommendedRoute,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteComparisonState &&
          runtimeType == other.runtimeType &&
          comparison == other.comparison &&
          recommendedRoute == other.recommendedRoute;
  
  @override
  int get hashCode => comparison.hashCode ^ recommendedRoute.hashCode;
}

class RouteSelectedState extends RoutePlanningState {
  final RouteOption selectedRoute;
  final List<RouteHistory> routeHistory;
  
  const RouteSelectedState({
    required this.selectedRoute,
    required this.routeHistory,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteSelectedState &&
          runtimeType == other.runtimeType &&
          selectedRoute == other.selectedRoute &&
          routeHistory == other.routeHistory;
  
  @override
  int get hashCode => selectedRoute.hashCode ^ routeHistory.hashCode;
}

class RouteHistoryState extends RoutePlanningState {
  final List<RouteHistory> history;
  
  const RouteHistoryState(this.history);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteHistoryState && runtimeType == other.runtimeType && history == other.history;
  
  @override
  int get hashCode => history.hashCode;
}

class RoutePreferencesState extends RoutePlanningState {
  final RoutePreferences preferences;
  
  const RoutePreferencesState(this.preferences);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutePreferencesState && runtimeType == other.runtimeType && preferences == other.preferences;
  
  @override
  int get hashCode => preferences.hashCode;
}

class RoutePlanningError extends RoutePlanningState {
  final String message;
  final String? details;
  
  const RoutePlanningError(this.message, {this.details});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutePlanningError && runtimeType == other.runtimeType && message == other.message && details == other.details;
  
  @override
  int get hashCode => message.hashCode ^ (details?.hashCode ?? 0);
}

class RoutePlanningBloc extends Bloc<RoutePlanningEvent, RoutePlanningState> {
  final RoutePlanningService _routePlanningService;
  
  RoutePreferences _currentPreferences = const RoutePreferences();
  List<RouteHistory> _routeHistory = [];
  RouteOption? _selectedRoute;
  
  RoutePlanningBloc(this._routePlanningService) : super(RoutePlanningInitial()) {
    on<CalculateRoutesEvent>(_onCalculateRoutes);
    on<CompareRoutesEvent>(_onCompareRoutes);
    on<SelectRouteEvent>(_onSelectRoute);
    on<UpdateRoutePreferencesEvent>(_onUpdatePreferences);
    on<GetRouteHistoryEvent>(_onGetRouteHistory);
    on<ClearRouteDataEvent>(_onClearData);
  }

  Future<void> _onCalculateRoutes(
    CalculateRoutesEvent event,
    Emitter<RoutePlanningState> emit,
  ) async {
    emit(RoutePlanningLoading());
    
    try {
      // Calculate routes using the service
      final routes = await _routePlanningService.calculateRoutes(event.routeRequest);
      
      // Automatically compare routes if there are multiple options
      RouteComparison? comparison;
      if (routes.length > 1) {
        comparison = await _routePlanningService.compareRoutes(routes, _currentPreferences);
      }
      
      // Check if current selected route is still available
      RouteOption? updatedSelectedRoute = _selectedRoute;
      if (_selectedRoute != null) {
        final matchingRoute = routes.firstWhere(
          (route) => route.routeId == _selectedRoute!.routeId,
          orElse: () => routes.first, // Fallback to first route if not found
        );
        updatedSelectedRoute = matchingRoute;
      }
      
      emit(RoutesCalculatedState(
        routes: routes,
        comparison: comparison,
        selectedRoute: updatedSelectedRoute,
      ));
    } catch (e) {
      emit(RoutePlanningError(
        'Failed to calculate routes',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onCompareRoutes(
    CompareRoutesEvent event,
    Emitter<RoutePlanningState> emit,
  ) async {
    try {
      // Use the service to compare routes
      final comparison = await _routePlanningService.compareRoutes(event.routes, event.preferences);
      
      emit(RouteComparisonState(
        comparison: comparison,
        recommendedRoute: comparison.recommendedRoute,
      ));
    } catch (e) {
      emit(RoutePlanningError(
        'Failed to compare routes',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onSelectRoute(
    SelectRouteEvent event,
    Emitter<RoutePlanningState> emit,
  ) async {
    try {
      _selectedRoute = event.selectedRoute;
      
      // Add to route history
      final historyEntry = RouteHistory(
        routeId: 'history_${DateTime.now().millisecondsSinceEpoch}',
        originalRequest: const RouteRequest(
          origin: '',
          destination: '',
          mode: RouteMode.driving,
          departureTime: null,
        ),
        selectedRoute: event.selectedRoute,
        startTime: DateTime.now(),
        wasCompleted: false,
      );
      
      _routeHistory.insert(0, historyEntry);
      
      // Keep only the last 50 entries
      if (_routeHistory.length > 50) {
        _routeHistory = _routeHistory.take(50).toList();
      }
      
      emit(RouteSelectedState(
        selectedRoute: event.selectedRoute,
        routeHistory: List.unmodifiable(_routeHistory),
      ));
    } catch (e) {
      emit(RoutePlanningError(
        'Failed to select route',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onUpdatePreferences(
    UpdateRoutePreferencesEvent event,
    Emitter<RoutePlanningState> emit,
  ) async {
    try {
      _currentPreferences = event.preferences;
      
      emit(RoutePreferencesState(_currentPreferences));
    } catch (e) {
      emit(RoutePlanningError(
        'Failed to update preferences',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onGetRouteHistory(
    GetRouteHistoryEvent event,
    Emitter<RoutePlanningState> emit,
  ) async {
    try {
      // In a real implementation, this would load from storage/database
      final history = _routeHistory.take(event.limit).toList();
      
      emit(RouteHistoryState(List.unmodifiable(history)));
    } catch (e) {
      emit(RoutePlanningError(
        'Failed to get route history',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onClearData(
    ClearRouteDataEvent event,
    Emitter<RoutePlanningState> emit,
  ) async {
    try {
      _routeHistory.clear();
      _selectedRoute = null;
      
      emit(RoutePlanningInitial());
    } catch (e) {
      emit(RoutePlanningError(
        'Failed to clear data',
        details: e.toString(),
      ));
    }
  }

  // Public getters for current state
  RoutePreferences get currentPreferences => _currentPreferences;
  RouteOption? get selectedRoute => _selectedRoute;
  List<RouteHistory> get routeHistory => List.unmodifiable(_routeHistory);
}
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/wearable_device_data.dart';
import '../core/services/wearable_device_service.dart';

abstract class WearableDeviceEvent {}

class DiscoverDevicesEvent extends WearableDeviceEvent {}

class ConnectToDeviceEvent extends WearableDeviceEvent {
  final WearableDevice device;
  
  const ConnectToDeviceEvent(this.device);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectToDeviceEvent && runtimeType == other.runtimeType && device == other.device;
  
  @override
  int get hashCode => device.hashCode;
}

class DisconnectDeviceEvent extends WearableDeviceEvent {
  final String deviceId;
  
  const DisconnectDeviceEvent(this.deviceId);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisconnectDeviceEvent && runtimeType == other.runtimeType && deviceId == other.deviceId;
  
  @override
  int get hashCode => deviceId.hashCode;
}

class DeviceDataReceivedEvent extends WearableDeviceEvent {
  final DeviceData data;
  
  const DeviceDataReceivedEvent(this.data);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceDataReceivedEvent && runtimeType == other.runtimeType && data == other.data;
  
  @override
  int get hashCode => data.hashCode;
}

class DeviceAlertReceivedEvent extends WearableDeviceEvent {
  final Alert alert;
  
  const DeviceAlertReceivedEvent(this.alert);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceAlertReceivedEvent && runtimeType == other.runtimeType && alert == other.alert;
  
  @override
  int get hashCode => alert.hashCode;
}

class UpdateDeviceSettingsEvent extends WearableDeviceEvent {
  final String deviceId;
  final WearableSettings settings;
  
  const UpdateDeviceSettingsEvent(this.deviceId, this.settings);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateDeviceSettingsEvent &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          settings == other.settings;
  
  @override
  int get hashCode => deviceId.hashCode ^ settings.hashCode;
}

class GenerateAnalyticsEvent extends WearableDeviceEvent {
  final String deviceId;
  final DateTime period;
  
  const GenerateAnalyticsEvent(this.deviceId, this.period);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerateAnalyticsEvent &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          period == other.period;
  
  @override
  int get hashCode => deviceId.hashCode ^ period.hashCode;
}

class SyncDeviceDataEvent extends WearableDeviceEvent {
  final String deviceId;
  
  const SyncDeviceDataEvent(this.deviceId);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncDeviceDataEvent && runtimeType == other.runtimeType && deviceId == other.deviceId;
  
  @override
  int get hashCode => deviceId.hashCode;
}

class ClearDeviceDataEvent extends WearableDeviceEvent {
  final String deviceId;
  
  const ClearDeviceDataEvent(this.deviceId);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClearDeviceDataEvent && runtimeType == other.runtimeType && deviceId == other.deviceId;
  
  @override
  int get hashCode => deviceId.hashCode;
}

abstract class WearableDeviceState {}

class WearableDeviceInitial extends WearableDeviceState {}

class WearableDeviceLoading extends WearableDeviceState {}

class DevicesDiscoveredState extends WearableDeviceState {
  final List<WearableDevice> devices;
  
  const DevicesDiscoveredState(this.devices);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DevicesDiscoveredState && runtimeType == other.runtimeType && devices == other.devices;
  
  @override
  int get hashCode => devices.hashCode;
}

class DeviceConnectedState extends WearableDeviceState {
  final WearableDevice device;
  final List<WearableDevice> connectedDevices;
  
  const DeviceConnectedState({
    required this.device,
    required this.connectedDevices,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceConnectedState &&
          runtimeType == other.runtimeType &&
          device == other.device &&
          connectedDevices == other.connectedDevices;
  
  @override
  int get hashCode => device.hashCode ^ connectedDevices.hashCode;
}

class DeviceDisconnectedState extends WearableDeviceState {
  final String deviceId;
  final List<WearableDevice> connectedDevices;
  
  const DeviceDisconnectedState({
    required this.deviceId,
    required this.connectedDevices,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceDisconnectedState &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          connectedDevices == other.connectedDevices;
  
  @override
  int get hashCode => deviceId.hashCode ^ connectedDevices.hashCode;
}

class DeviceDataState extends WearableDeviceState {
  final String deviceId;
  final DeviceData data;
  final Map<String, DeviceData> allDeviceData;
  
  const DeviceDataState({
    required this.deviceId,
    required this.data,
    required this.allDeviceData,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceDataState &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          data == other.data &&
          allDeviceData == other.allDeviceData;
  
  @override
  int get hashCode => deviceId.hashCode ^ data.hashCode ^ allDeviceData.hashCode;
}

class DeviceAlertState extends WearableDeviceState {
  final Alert alert;
  final List<Alert> allAlerts;
  
  const DeviceAlertState({
    required this.alert,
    required this.allAlerts,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceAlertState &&
          runtimeType == other.runtimeType &&
          alert == other.alert &&
          allAlerts == other.allAlerts;
  
  @override
  int get hashCode => alert.hashCode ^ allAlerts.hashCode;
}

class DeviceAnalyticsState extends WearableDeviceState {
  final String deviceId;
  final WearableAnalytics analytics;
  
  const DeviceAnalyticsState({
    required this.deviceId,
    required this.analytics,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceAnalyticsState &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          analytics == other.analytics;
  
  @override
  int get hashCode => deviceId.hashCode ^ analytics.hashCode;
}

class DeviceSettingsState extends WearableDeviceState {
  final String deviceId;
  final WearableSettings settings;
  
  const DeviceSettingsState({
    required this.deviceId,
    required this.settings,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceSettingsState &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          settings == other.settings;
  
  @override
  int get hashCode => deviceId.hashCode ^ settings.hashCode;
}

class WearableDeviceError extends WearableDeviceState {
  final String message;
  final String? details;
  
  const WearableDeviceError(this.message, {this.details});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WearableDeviceError && runtimeType == other.runtimeType && message == other.message && details == other.details;
  
  @override
  int get hashCode => message.hashCode ^ (details?.hashCode ?? 0);
}

class WearableDeviceBloc extends Bloc<WearableDeviceEvent, WearableDeviceState> {
  final WearableDeviceService _wearableDeviceService;
  
  // Internal state tracking
  final List<WearableDevice> _discoveredDevices = [];
  final List<WearableDevice> _connectedDevices = [];
  final Map<String, DeviceData> _deviceData = {};
  final List<Alert> _alerts = [];
  final Map<String, WearableSettings> _deviceSettings = {};
  final Map<String, WearableAnalytics> _analytics = {};
  
  StreamSubscription? _dataSubscription;
  StreamSubscription? _alertSubscription;
  
  WearableDeviceBloc(this._wearableDeviceService) : super(WearableDeviceInitial()) {
    on<DiscoverDevicesEvent>(_onDiscoverDevices);
    on<ConnectToDeviceEvent>(_onConnectToDevice);
    on<DisconnectDeviceEvent>(_onDisconnectDevice);
    on<DeviceDataReceivedEvent>(_onDeviceDataReceived);
    on<DeviceAlertReceivedEvent>(_onDeviceAlertReceived);
    on<UpdateDeviceSettingsEvent>(_onUpdateDeviceSettings);
    on<GenerateAnalyticsEvent>(_onGenerateAnalytics);
    on<SyncDeviceDataEvent>(_onSyncDeviceData);
    on<ClearDeviceDataEvent>(_onClearDeviceData);
    
    // Start listening to service streams
    _startServiceStreams();
  }

  void _startServiceStreams() {
    // Listen to data stream from service
    _dataSubscription = _wearableDeviceService.dataStream.listen((data) {
      add(DeviceDataReceivedEvent(data));
    });
    
    // Listen to alert stream from service
    _alertSubscription = _wearableDeviceService.alertStream.listen((alert) {
      add(DeviceAlertReceivedEvent(alert));
    });
  }

  Future<void> _onDiscoverDevices(
    DiscoverDevicesEvent event,
    Emitter<WearableDeviceState> emit,
  ) async {
    emit(WearableDeviceLoading());
    
    try {
      final devices = await _wearableDeviceService.discoverDevices();
      _discoveredDevices.clear();
      _discoveredDevices.addAll(devices);
      
      emit(DevicesDiscoveredState(List.unmodifiable(_discoveredDevices)));
    } catch (e) {
      emit(WearableDeviceError(
        'Failed to discover devices',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onConnectToDevice(
    ConnectToDeviceEvent event,
    Emitter<WearableDeviceState> emit,
  ) async {
    emit(WearableDeviceLoading());
    
    try {
      final success = await _wearableDeviceService.connectToDevice(event.device);
      
      if (success) {
        // Update connected devices list
        if (!_connectedDevices.any((d) => d.deviceId == event.device.deviceId)) {
          _connectedDevices.add(event.device);
        }
        
        // Update device status
        final updatedDevice = event.device.copyWith(
          isConnected: true,
          lastSyncTime: DateTime.now(),
          status: DeviceStatus.connected,
        );
        
        emit(DeviceConnectedState(
          device: updatedDevice,
          connectedDevices: List.unmodifiable(_connectedDevices),
        ));
      } else {
        emit(WearableDeviceError(
          'Failed to connect to device: ${event.device.name}',
        ));
      }
    } catch (e) {
      emit(WearableDeviceError(
        'Connection error',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onDisconnectDevice(
    DisconnectDeviceEvent event,
    Emitter<WearableDeviceState> emit,
  ) async {
    try {
      await _wearableDeviceService.disconnectDevice(event.deviceId);
      
      // Remove from connected devices
      _connectedDevices.removeWhere((d) => d.deviceId == event.deviceId);
      
      // Remove device data
      _deviceData.remove(event.deviceId);
      
      emit(DeviceDisconnectedState(
        deviceId: event.deviceId,
        connectedDevices: List.unmodifiable(_connectedDevices),
      ));
    } catch (e) {
      emit(WearableDeviceError(
        'Failed to disconnect device',
        details: e.toString(),
      ));
    }
  }

  void _onDeviceDataReceived(
    DeviceDataReceivedEvent event,
    Emitter<WearableDeviceState> emit,
  ) {
    try {
      // Update device data cache
      _deviceData[event.data.deviceId] = event.data;
      
      emit(DeviceDataState(
        deviceId: event.data.deviceId,
        data: event.data,
        allDeviceData: Map.unmodifiable(_deviceData),
      ));
    } catch (e) {
      emit(WearableDeviceError(
        'Failed to process device data',
        details: e.toString(),
      ));
    }
  }

  void _onDeviceAlertReceived(
    DeviceAlertReceivedEvent event,
    Emitter<WearableDeviceState> emit,
  ) {
    try {
      // Add to alerts list (keep only last 100 alerts)
      _alerts.insert(0, event.alert);
      if (_alerts.length > 100) {
        _alerts.removeRange(100, _alerts.length);
      }
      
      emit(DeviceAlertState(
        alert: event.alert,
        allAlerts: List.unmodifiable(_alerts),
      ));
    } catch (e) {
      emit(WearableDeviceError(
        'Failed to process device alert',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateDeviceSettings(
    UpdateDeviceSettingsEvent event,
    Emitter<WearableDeviceState> emit,
  ) async {
    try {
      // Update settings cache
      _deviceSettings[event.deviceId] = event.settings;
      
      // In a real implementation, you would update the device settings
      // For now, just emit the updated settings state
      emit(DeviceSettingsState(
        deviceId: event.deviceId,
        settings: event.settings,
      ));
    } catch (e) {
      emit(WearableDeviceError(
        'Failed to update device settings',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onGenerateAnalytics(
    GenerateAnalyticsEvent event,
    Emitter<WearableDeviceState> emit,
  ) async {
    emit(WearableDeviceLoading());
    
    try {
      final analytics = await _wearableDeviceService.generateAnalytics(event.deviceId, event.period);
      _analytics[event.deviceId] = analytics;
      
      emit(DeviceAnalyticsState(
        deviceId: event.deviceId,
        analytics: analytics,
      ));
    } catch (e) {
      emit(WearableDeviceError(
        'Failed to generate analytics',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onSyncDeviceData(
    SyncDeviceDataEvent event,
    Emitter<WearableDeviceState> emit,
  ) async {
    try {
      // In a real implementation, this would trigger a sync with the service
      // For now, just emit a success state
      emit(WearableDeviceLoading());
      
      // Simulate sync delay
      await Future.delayed(const Duration(seconds: 2));
      
      emit(DeviceDataState(
        deviceId: event.deviceId,
        data: _deviceData[event.deviceId] ?? const DeviceData(
          deviceId: '',
          timestamp: null,
          rawData: {},
        ),
        allDeviceData: Map.unmodifiable(_deviceData),
      ));
    } catch (e) {
      emit(WearableDeviceError(
        'Failed to sync device data',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onClearDeviceData(
    ClearDeviceDataEvent event,
    Emitter<WearableDeviceState> emit,
  ) async {
    try {
      _deviceData.remove(event.deviceId);
      _analytics.remove(event.deviceId);
      _deviceSettings.remove(event.deviceId);
      
      emit(DeviceDataState(
        deviceId: event.deviceId,
        data: const DeviceData(
          deviceId: '',
          timestamp: null,
          rawData: {},
        ),
        allDeviceData: Map.unmodifiable(_deviceData),
      ));
    } catch (e) {
      emit(WearableDeviceError(
        'Failed to clear device data',
        details: e.toString(),
      ));
    }
  }

  // Public getters for current state
  List<WearableDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  List<WearableDevice> get connectedDevices => List.unmodifiable(_connectedDevices);
  Map<String, DeviceData> get deviceData => Map.unmodifiable(_deviceData);
  List<Alert> get alerts => List.unmodifiable(_alerts);
  Map<String, WearableSettings> get deviceSettings => Map.unmodifiable(_deviceSettings);
  Map<String, WearableAnalytics> get analytics => Map.unmodifiable(_analytics);
  
  bool get hasConnectedDevices => _connectedDevices.isNotEmpty;
  bool get hasAlerts => _alerts.isNotEmpty;
  int get connectedDeviceCount => _connectedDevices.length;
  int get totalAlertsCount => _alerts.length;

  @override
  Future<void> close() {
    _dataSubscription?.cancel();
    _alertSubscription?.cancel();
    return super.close();
  }
}
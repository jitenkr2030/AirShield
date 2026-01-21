import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_blue/flutter_blue.dart';
import '../config/app_config.dart';
import '../models/air_quality_data.dart';

class BluetoothService {
  late final FlutterBlue _flutterBlue;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<BluetoothDevice>>? _connectedDevicesSubscription;
  
  List<BluetoothDevice> _connectedDevices = [];
  List<ScanResult> _scanResults = [];
  
  // Getters
  List<BluetoothDevice> get connectedDevices => _connectedDevices;
  List<ScanResult> get scanResults => _scanResults;
  bool get isScanning => _scanSubscription != null;

  // Device characteristics UUIDs (common PM2.5 sensor characteristics)
  static const String _serviceUUID = "0000180F-0000-1000-8000-00805F9B34FB"; // Battery Service
  static const String _pm25ServiceUUID = "0000181D-0000-1000-8000-00805F9B34FB"; // PM2.5 Service
  static const String _pm25CharacteristicUUID = "00001821-0000-1000-8000-00805F9B34FB";
  static const String _temperatureCharacteristicUUID = "00001822-0000-1000-8000-00805F9B34FB";
  static const String _humidityCharacteristicUUID = "00001823-0000-1000-8000-00805F9B34FB";

  BluetoothService() {
    _flutterBlue = FlutterBlue.instance;
  }

  Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw BluetoothException('Bluetooth not supported on this platform');
    }

    // Check if Bluetooth is available
    if (!await _flutterBlue.isSupported) {
      throw BluetoothException('Bluetooth not supported on this device');
    }

    // Request Bluetooth permissions for Android
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    // Listen for connected devices
    _connectedDevicesSubscription = _flutterBlue.connectedDevices.listen((devices) {
      _connectedDevices = devices;
      print('Connected devices updated: ${devices.length}');
    });

    print('Bluetooth service initialized');
  }

  Future<void> _requestAndroidPermissions() async {
    // Request Bluetooth permissions for Android 12+
    // This would be handled by permission_handler in a real implementation
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final devices = await _flutterBlue.bondedDevices.toList();
      return devices.where((device) => _isAirQualityDevice(device)).toList();
    } catch (e) {
      throw BluetoothException('Failed to get bonded devices: $e');
    }
  }

  Future<void> startScanning({
    Duration timeout = const Duration(seconds: 10),
    List<String>? withServices,
    bool allowDuplicates = false,
  }) async {
    if (_scanSubscription != null) {
      await stopScanning();
    }

    try {
      final scanSettings = ScanSettings(
        services: withServices ?? [_pm25ServiceUUID],
        allowDuplicates: allowDuplicates,
      );

      _scanSubscription = _flutterBlue.scan(
        timeout: timeout,
        scanSettings: scanSettings,
      ).listen((results) {
        _scanResults = results.where((result) => 
          _isAirQualityDevice(result.device)
        ).toList();
      }, onError: (error) {
        print('Scanning error: $error');
        _scanSubscription = null;
      });

      print('Started scanning for air quality sensors');
    } catch (e) {
      throw BluetoothException('Failed to start scanning: $e');
    }
  }

  Future<void> stopScanning() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _scanResults.clear();
    print('Stopped scanning');
  }

  bool _isAirQualityDevice(BluetoothDevice device) {
    final deviceName = device.name.toLowerCase();
    final id = device.id.id.toLowerCase();
    
    // Common air quality sensor patterns
    return deviceName.contains('pm') ||
           deviceName.contains('sensor') ||
           deviceName.contains('air') ||
           deviceName.contains('quality') ||
           deviceName.contains('aqi') ||
           id.contains('pm') ||
           id.contains('sensor');
  }

  Future<BluetoothConnection> connectToDevice(BluetoothDevice device) async {
    try {
      print('Connecting to device: ${device.name}');
      
      await device.connect(autoConnect: false);
      
      // Wait for connection state change
      final connectionState = await device.state.first;
      if (connectionState == BluetoothConnectionState.connected) {
        print('Successfully connected to ${device.name}');
        _connectedDevices.add(device);
        return BluetoothConnection(device);
      } else {
        throw BluetoothException('Failed to establish connection');
      }
    } catch (e) {
      throw BluetoothException('Failed to connect to device: $e');
    }
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      _connectedDevices.remove(device);
      print('Disconnected from ${device.name}');
    } catch (e) {
      throw BluetoothException('Failed to disconnect device: $e');
    }
  }

  Future<List<BluetoothService>> discoverServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      return services.where((service) => 
        service.serviceUuid == _pm25ServiceUUID ||
        service.serviceUuid == _serviceUUID
      ).toList();
    } catch (e) {
      throw BluetoothException('Failed to discover services: $e');
    }
  }

  Future<AirQualityData?> readSensorData(BluetoothDevice device) async {
    try {
      final services = await discoverServices(device);
      
      for (final service in services) {
        if (service.serviceUuid == _pm25ServiceUUID) {
          for (final characteristic in service.characteristics) {
            if (characteristic.properties.read) {
              final value = await characteristic.read();
              return _parseSensorData(value, device);
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      throw BluetoothException('Failed to read sensor data: $e');
    }
  }

  Future<void> setupSensorNotifications(BluetoothDevice device, {
    required Function(AirQualityData) onDataReceived,
  }) async {
    try {
      final services = await discoverServices(device);
      
      for (final service in services) {
        if (service.serviceUuid == _pm25ServiceUUID) {
          for (final characteristic in service.characteristics) {
            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
              
              characteristic.value.listen((data) {
                final sensorData = _parseSensorData(data, device);
                if (sensorData != null) {
                  onDataReceived(sensorData);
                }
              });
            }
          }
        }
      }
    } catch (e) {
      throw BluetoothException('Failed to setup notifications: $e');
    }
  }

  AirQualityData? _parseSensorData(Uint8List data, BluetoothDevice device) {
    try {
      // Common sensor data parsing patterns
      // This is a simplified parser - real implementation would depend on sensor specification
      
      if (data.length < 8) return null;
      
      // Extract values (endianness depends on sensor)
      final pm25Value = _extractValue(data, 0, 4);
      final temperatureValue = _extractValue(data, 4, 2);
      final humidityValue = _extractValue(data, 6, 2);
      
      if (pm25Value <= 0) return null;
      
      final now = DateTime.now();
      final aqi = _calculateAQI(pm25Value);
      
      return AirQualityData(
        id: 'sensor_${device.id}',
        latitude: 0.0, // Would be set from GPS
        longitude: 0.0,
        pm25: pm25Value.toDouble(),
        pm10: pm25Value * 1.2, // Estimated PM10 from PM2.5
        aqi: aqi.toDouble(),
        temperature: temperatureValue.toDouble(),
        humidity: humidityValue.toDouble(),
        source: 'bluetooth_sensor_${device.id}',
        timestamp: now,
        metadata: {
          'device_name': device.name,
          'device_id': device.id,
          'battery_level': 100, // Would read from battery service
        },
      );
    } catch (e) {
      print('Error parsing sensor data: $e');
      return null;
    }
  }

  double _extractValue(Uint8List data, int start, int length) {
    if (data.length < start + length) return 0.0;
    
    int value = 0;
    for (int i = 0; i < length; i++) {
      value |= (data[start + i] << (8 * i));
    }
    return value.toDouble();
  }

  double _calculateAQI(double pm25) {
    // Simplified AQI calculation for PM2.5
    // Based on EPA breakpoints
    
    if (pm25 <= 12.0) return _linearScale(pm25, 0, 12, 0, 50);
    if (pm25 <= 35.4) return _linearScale(pm25, 12.1, 35.4, 51, 100);
    if (pm25 <= 55.4) return _linearScale(pm25, 35.5, 55.4, 101, 150);
    if (pm25 <= 150.4) return _linearScale(pm25, 55.5, 150.4, 151, 200);
    if (pm25 <= 250.4) return _linearScale(pm25, 150.5, 250.4, 201, 300);
    return _linearScale(pm25, 250.5, 500, 301, 500);
  }

  double _linearScale(double value, double inMin, double inMax, double outMin, double outMax) {
    final normalized = (value - inMin) / (inMax - inMin);
    return outMin + (normalized * (outMax - outMin));
  }

  Future<void> calibrateSensor(BluetoothDevice device, double referenceValue) async {
    try {
      // Send calibration command to sensor
      // Implementation depends on sensor protocol
      print('Calibrating sensor ${device.name} with reference value: $referenceValue');
    } catch (e) {
      throw BluetoothException('Failed to calibrate sensor: $e');
    }
  }

  Future<void> updateSensorSettings(BluetoothDevice device, {
    double? measurementInterval,
    bool? autoCalibrate,
    int? alertThreshold,
  }) async {
    try {
      // Send settings update command
      final settings = <String, dynamic>{};
      if (measurementInterval != null) settings['interval'] = measurementInterval;
      if (autoCalibrate != null) settings['auto_calibrate'] = autoCalibrate;
      if (alertThreshold != null) settings['alert_threshold'] = alertThreshold;
      
      print('Updating sensor settings: $settings');
    } catch (e) {
      throw BluetoothException('Failed to update sensor settings: $e');
    }
  }

  Future<BatteryLevel> readBatteryLevel(BluetoothDevice device) async {
    try {
      final services = await discoverServices(device);
      
      for (final service in services) {
        if (service.serviceUuid == _serviceUUID) { // Battery service
          for (final characteristic in service.characteristics) {
            if (characteristic.properties.read && 
                characteristic.characteristicUuid == "00002A19-0000-1000-8000-00805F9B34FB") {
              final data = await characteristic.read();
              if (data.isNotEmpty) {
                return BatteryLevel(data.first);
              }
            }
          }
        }
      }
      
      return BatteryLevel(100); // Default to full battery
    } catch (e) {
      throw BluetoothException('Failed to read battery level: $e');
    }
  }

  Future<void> bondDevice(BluetoothDevice device) async {
    try {
      final result = await device.createBond();
      if (!result) {
        throw BluetoothException('Failed to bond with device');
      }
      print('Successfully bonded with ${device.name}');
    } catch (e) {
      throw BluetoothException('Failed to bond with device: $e');
    }
  }

  Future<void> unBondDevice(BluetoothDevice device) async {
    try {
      final result = await device.removeBond();
      if (!result) {
        throw BluetoothException('Failed to unbind device');
      }
      print('Successfully unpaired ${device.name}');
    } catch (e) {
      throw BluetoothException('Failed to unbind device: $e');
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectedDevicesSubscription?.cancel();
    stopScanning();
    print('Bluetooth service disposed');
  }
}

class BluetoothConnection {
  final BluetoothDevice device;
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;
  
  BluetoothConnection(this.device);
  
  void markConnected() => _isConnected = true;
  void markDisconnected() => _isConnected = false;
}

class BluetoothException implements Exception {
  final String message;
  
  BluetoothException(this.message);
  
  @override
  String toString() => 'BluetoothException: $message';
}

class BatteryLevel {
  final int percentage;
  
  BatteryLevel(this.percentage);
  
  bool get isLow => percentage < 20;
  bool get isMedium => percentage >= 20 && percentage < 50;
  bool get isHigh => percentage >= 50 && percentage < 80;
  bool get isFull => percentage >= 80;
}
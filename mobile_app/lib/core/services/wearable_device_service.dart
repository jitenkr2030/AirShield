import 'dart:async';
import 'dart:io';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:health/health.dart';
import 'package:sensors/sensors.dart';
import '../models/wearable_device_data.dart';
import 'bluetooth_service.dart'; // Assuming this exists
import 'notification_service.dart'; // Assuming this exists

class WearableDeviceService {
  static const String TAG = 'WearableDeviceService';
  
  late final FlutterBlue _flutterBlue;
  late final Health _health;
  late final BluetoothService _bluetoothService;
  late final NotificationService _notificationService;
  
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _sensorSubscription;
  
  final List<WearableDevice> _connectedDevices = [];
  final Map<String, DeviceData> _deviceData = {};
  final Map<String, SyncSchedule> _syncSchedules = {};
  final StreamController<DeviceData> _dataController = StreamController.broadcast();
  final StreamController<Alert> _alertController = StreamController.broadcast();

  WearableDeviceService() {
    _flutterBlue = FlutterBlue.instance;
    _health = Health();
    _bluetoothService = BluetoothService();
    _notificationService = NotificationService();
  }

  // Device Discovery and Connection
  Future<List<WearableDevice>> discoverDevices() async {
    try {
      await _requestBluetoothPermissions();
      await _requestHealthPermissions();
      
      final devices = <WearableDevice>[];
      
      // Scan for Bluetooth devices
      final bluetoothDevices = await _scanBluetoothDevices();
      devices.addAll(bluetoothDevices);
      
      // Get health platform devices
      final healthDevices = await _getHealthPlatformDevices();
      devices.addAll(healthDevices);
      
      // Remove duplicates based on device ID
      final uniqueDevices = _removeDuplicateDevices(devices);
      
      return uniqueDevices;
    } catch (e) {
      throw Exception('Failed to discover devices: $e');
    }
  }

  Future<List<WearableDevice>> _scanBluetoothDevices() async {
    final devices = <WearableDevice>[];
    
    return await _flutterBlue.startScan(timeout: const Duration(seconds: 10))
      .asStream()
      .expand((_) => [])
      .where((result) => _isWearableDevice(result.device))
      .asyncMap((result) => _createDeviceFromBluetoothResult(result.device))
      .take(20) // Limit to 20 devices
      .toList();
  }

  bool _isWearableDevice(BluetoothDevice device) {
    final deviceName = device.name.toLowerCase();
    
    // Check for common wearable device names
    return deviceName.contains('apple watch') ||
           deviceName.contains('fitbit') ||
           deviceName.contains('garmin') ||
           deviceName.contains('samsung watch') ||
           deviceName.contains('huawei watch') ||
           deviceName.contains('fitness') ||
           deviceName.contains('tracker');
  }

  Future<WearableDevice> _createDeviceFromBluetoothResult(BluetoothDevice device) async {
    // Detect device type based on advertisement data
    final deviceType = _detectDeviceType(device.name);
    final platform = _detectPlatform(device.name);
    
    return WearableDevice(
      deviceId: device.id.toString(),
      name: device.name.isNotEmpty ? device.name : 'Unknown Device',
      type: deviceType,
      platform: platform,
      manufacturer: _detectManufacturer(device.name),
      model: _extractModel(device.name),
      firmwareVersion: '1.0.0', // Would need to read from device
      capabilities: _getDeviceCapabilities(deviceType),
      status: DeviceStatus.disconnected,
      pairingCode: _generatePairingCode(),
    );
  }

  DeviceType _detectDeviceType(String deviceName) {
    final name = deviceName.toLowerCase();
    
    if (name.contains('watch')) return DeviceType.smartwatch;
    if (name.contains('fitbit') || name.contains('tracker')) return DeviceType.fitnessTracker;
    if (name.contains('band')) return DeviceType.smartBand;
    if (name.contains('heart')) return DeviceType.heartRateMonitor;
    if (name.contains('health')) return DeviceType.healthMonitor;
    
    return DeviceType.smartwatch; // Default
  }

  DevicePlatform _detectPlatform(String deviceName) {
    final name = deviceName.toLowerCase();
    
    if (name.contains('apple')) return DevicePlatform.appleWatch;
    if (name.contains('samsung')) return DevicePlatform.samsungWatch;
    if (name.contains('huawei')) return DevicePlatform.huaweiWatch;
    if (name.contains('fitbit')) return DevicePlatform.fitbit;
    if (name.contains('garmin')) return DevicePlatform.garmin;
    
    return DevicePlatform.other;
  }

  String _detectManufacturer(String deviceName) {
    final name = deviceName.toLowerCase();
    
    if (name.contains('apple')) return 'Apple';
    if (name.contains('samsung')) return 'Samsung';
    if (name.contains('huawei')) return 'Huawei';
    if (name.contains('fitbit')) return 'Fitbit';
    if (name.contains('garmin')) return 'Garmin';
    
    return 'Unknown';
  }

  String _extractModel(String deviceName) {
    // Extract model number from device name
    final parts = deviceName.split(' ');
    if (parts.length > 1) {
      return parts.last;
    }
    return 'Unknown';
  }

  List<DeviceCapability> _getDeviceCapabilities(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.smartwatch:
        return [
          DeviceCapability.heartRate,
          DeviceCapability.steps,
          DeviceCapability.sleepTracking,
          DeviceCapability.notifications,
          DeviceCapability.gpsTracking,
        ];
      case DeviceType.fitnessTracker:
        return [
          DeviceCapability.steps,
          DeviceCapability.heartRate,
          DeviceCapability.sleepTracking,
          DeviceCapability.activityTracking,
        ];
      case DeviceType.heartRateMonitor:
        return [DeviceCapability.heartRate];
      case DeviceType.healthMonitor:
        return [
          DeviceCapability.heartRate,
          DeviceCapability.bloodOxygen,
          DeviceCapability.breathingRate,
          DeviceCapability.temperature,
        ];
      default:
        return [DeviceCapability.steps];
    }
  }

  String _generatePairingCode() {
    // Generate a simple 4-digit pairing code
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return random.toString().padLeft(4, '0');
  }

  List<WearableDevice> _removeDuplicateDevices(List<WearableDevice> devices) {
    final uniqueDevices = <String, WearableDevice>{};
    
    for (final device in devices) {
      final key = device.name.toLowerCase();
      if (!uniqueDevices.containsKey(key)) {
        uniqueDevices[key] = device;
      }
    }
    
    return uniqueDevices.values.toList();
  }

  Future<List<WearableDevice>> _getHealthPlatformDevices() async {
    final devices = <WearableDevice>[];
    
    try {
      // Get Apple Health (iOS) or Google Fit (Android) devices
      final healthDevices = await _health.getHealthDevicesFromPlatform();
      
      for (final healthDevice in healthDevices) {
        final device = WearableDevice(
          deviceId: healthDevice.toString(),
          name: 'Health Device',
          type: DeviceType.healthMonitor,
          platform: Platform.isIOS ? DevicePlatform.appleWatch : DevicePlatform.androidWear,
          manufacturer: 'Platform',
          model: 'Unknown',
          firmwareVersion: '1.0.0',
          capabilities: [DeviceCapability.heartRate, DeviceCapability.steps],
          status: DeviceStatus.disconnected,
        );
        
        devices.add(device);
      }
    } catch (e) {
      // Health platform access failed, continue with other methods
    }
    
    return devices;
  }

  Future<void> _requestBluetoothPermissions() async {
    // Request necessary permissions for Bluetooth scanning
    // Implementation depends on platform-specific requirements
  }

  Future<void> _requestHealthPermissions() async {
    // Request health data permissions
    await _health.requestAuthorization([
      HealthDataType.HEART_RATE,
      HealthDataType.STEPS,
      HealthDataType.SLEEP,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.BODY_TEMPERATURE,
    ]);
  }

  // Device Connection Management
  Future<bool> connectToDevice(WearableDevice device) async {
    try {
      final connectResult = await _bluetoothService.connectToDevice(device.deviceId);
      
      if (connectResult) {
        _connectedDevices.add(device);
        await _setupDeviceConnection(device);
        await _initializeDeviceSync(device);
        
        _updateDeviceStatus(device, DeviceStatus.connected);
        _showConnectionNotification(device, true);
        
        return true;
      }
      
      return false;
    } catch (e) {
      _updateDeviceStatus(device, DeviceStatus.error);
      _showConnectionNotification(device, false, error: e.toString());
      return false;
    }
  }

  Future<void> disconnectDevice(String deviceId) async {
    try {
      await _bluetoothService.disconnectDevice(deviceId);
      
      final deviceIndex = _connectedDevices.indexWhere((d) => d.deviceId == deviceId);
      if (deviceIndex != -1) {
        _connectedDevices.removeAt(deviceIndex);
      }
      
      _deviceData.remove(deviceId);
      _syncSchedules.remove(deviceId);
      
      final device = WearableDevice(
        deviceId: deviceId,
        name: 'Unknown',
        type: DeviceType.smartwatch,
        platform: DevicePlatform.other,
        manufacturer: 'Unknown',
        model: 'Unknown',
        firmwareVersion: '1.0.0',
        capabilities: [],
        status: DeviceStatus.disconnected,
      );
      
      _showConnectionNotification(device, false);
    } catch (e) {
      throw Exception('Failed to disconnect device: $e');
    }
  }

  Future<void> _setupDeviceConnection(WearableDevice device) async {
    // Setup connection-specific configurations
    await _setupDataStreams(device);
    await _setupAlerts(device);
    await _setupNotifications(device);
  }

  Future<void> _setupDataStreams(WearableDevice device) async {
    // Start listening to device data streams based on capabilities
    for (final capability in device.capabilities) {
      switch (capability) {
        case DeviceCapability.heartRate:
          _startHeartRateMonitoring(device);
          break;
        case DeviceCapability.steps:
          _startStepCounting(device);
          break;
        case DeviceCapability.sleepTracking:
          _startSleepMonitoring(device);
          break;
        case DeviceCapability.location:
          _startLocationTracking(device);
          break;
        case DeviceCapability.airQuality:
          _startAirQualityMonitoring(device);
          break;
        default:
          break;
      }
    }
  }

  void _startHeartRateMonitoring(WearableDevice device) {
    // Setup heart rate data collection
    final stream = _health.streamHealthData(
      dataType: HealthDataType.HEART_RATE,
      deviceId: device.deviceId,
    );
    
    stream.listen((data) async {
      final processedData = ProcessedMetrics(
        heartRate: data.value,
        timestamp: DateTime.now(),
      );
      
      await _processDeviceData(device, processedData);
    });
  }

  void _startStepCounting(WearableDevice device) {
    final stream = _health.streamHealthData(
      dataType: HealthDataType.STEPS,
      deviceId: device.deviceId,
    );
    
    stream.listen((data) async {
      final processedData = ProcessedMetrics(
        steps: data.value.toInt(),
        distance: data.value.toInt() * 0.75, // Average step length
        timestamp: DateTime.now(),
      );
      
      await _processDeviceData(device, processedData);
    });
  }

  void _startSleepMonitoring(WearableDevice device) {
    // Sleep monitoring setup
    // Implementation for sleep data collection
  }

  void _startLocationTracking(WearableDevice device) {
    // Location tracking setup for GPS-enabled devices
    // Implementation for location-based health correlation
  }

  void _startAirQualityMonitoring(WearableDevice device) {
    // Air quality sensor monitoring if device has this capability
    // Implementation for air quality sensor data
  }

  // Data Processing and Analysis
  Future<void> _processDeviceData(WearableDevice device, ProcessedMetrics data) async {
    try {
      final deviceData = DeviceData(
        deviceId: device.deviceId,
        timestamp: DateTime.now(),
        rawData: data.toJson(),
        processedMetrics: data,
        dataQuality: _assessDataQuality(data),
      );
      
      // Store data
      _deviceData[device.deviceId] = deviceData;
      
      // Emit data stream
      _dataController.add(deviceData);
      
      // Check for health correlations
      await _analyzeHealthCorrelation(device, data);
      
      // Check for alerts
      await _checkForAlerts(device, data);
      
      // Sync to cloud if configured
      await _syncDeviceData(device, data);
    } catch (e) {
      // Handle data processing error
      print('Error processing device data: $e');
    }
  }

  QualityScore _assessDataQuality(ProcessedMetrics data) {
    // Assess quality of incoming device data
    if (data.heartRate != null) {
      if (data.heartRate! < 30 || data.heartRate! > 220) {
        return QualityScore.poor;
      }
      if (data.heartRate! < 50 || data.heartRate! > 180) {
        return QualityScore.fair;
      }
    }
    
    if (data.steps != null) {
      if (data.steps! < 0 || data.steps! > 100000) {
        return QualityScore.poor;
      }
    }
    
    return QualityScore.good;
  }

  Future<void> _analyzeHealthCorrelation(WearableDevice device, ProcessedMetrics data) async {
    try {
      // Get current air quality for correlation analysis
      final currentAQI = await _getCurrentAirQualityIndex();
      
      if (currentAQI != null && data.heartRate != null) {
        final correlation = HealthCorrelation(
          correlationId: 'corr_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          airQualityIndex: currentAQI,
          heartRateChange: _calculateHeartRateChange(data.heartRate!),
          stressChange: data.stressLevel ?? 0.0,
          breathingRateChange: data.breathingRate ?? 0.0,
          symptoms: _identifySymptoms(currentAQI, data),
          contributingFactors: _identifyContributingFactors(currentAQI, data),
          analysis: _generateCorrelationAnalysis(currentAQI, data),
        );
        
        // Store correlation for trend analysis
        await _storeHealthCorrelation(correlation);
      }
    } catch (e) {
      // Handle correlation analysis error
    }
  }

  Future<double?> _getCurrentAirQualityIndex() async {
    // Get current air quality from service
    // This would integrate with your air quality service
    return 75.0; // Placeholder
  }

  double _calculateHeartRateChange(double currentHeartRate) {
    // Calculate percentage change from personal baseline
    final baseline = 70.0; // Would get from user profile
    return ((currentHeartRate - baseline) / baseline) * 100;
  }

  List<String> _identifySymptoms(double aqi, ProcessedMetrics data) {
    final symptoms = <String>[];
    
    if (aqi > 150 && data.heartRate! > 100) {
      symptoms.add('Increased heart rate');
    }
    
    if (aqi > 100 && (data.breathingRate ?? 0) > 20) {
      symptoms.add('Rapid breathing');
    }
    
    if (data.stressLevel != null && data.stressLevel! > 7) {
      symptoms.add('High stress level');
    }
    
    return symptoms;
  }

  List<String> _identifyContributingFactors(double aqi, ProcessedMetrics data) {
    final factors = <String>[];
    
    if (aqi > 100) factors.add('Poor air quality');
    
    if (data.heartRate! > 90) factors.add('Physical activity');
    
    if (data.steps != null && data.steps! > 5000) {
      factors.add('Active movement');
    }
    
    return factors;
  }

  String _generateCorrelationAnalysis(double aqi, ProcessedMetrics data) {
    final analysis = StringBuffer();
    
    if (aqi > 100) {
      analysis.write('Air quality index of $aqi may be contributing to elevated vital signs. ');
    }
    
    if (data.heartRate != null && data.heartRate! > 90) {
      analysis.write('Heart rate is elevated at ${data.heartRate} bpm. ');
    }
    
    if (data.stressLevel != null && data.stressLevel! > 7) {
      analysis.write('Stress levels are high. Consider relaxation techniques. ');
    }
    
    analysis.write('Continue monitoring for patterns and consider consulting healthcare provider if symptoms persist.');
    
    return analysis.toString();
  }

  Future<void> _storeHealthCorrelation(HealthCorrelation correlation) async {
    // Store correlation in local database for trend analysis
    // Implementation would save to SQLite or similar
  }

  // Alert System
  Future<void> _checkForAlerts(WearableDevice device, ProcessedMetrics data) async {
    final alerts = <Alert>[];
    
    // Heart rate alerts
    if (data.heartRate != null) {
      if (data.heartRate! < 50) {
        alerts.add(Alert(
          alertId: 'hr_low_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.healthMetric,
          title: 'Low Heart Rate',
          message: 'Heart rate of ${data.heartRate} bpm detected',
          priority: Priority.medium,
          timestamp: DateTime.now(),
          source: device.name,
        ));
      } else if (data.heartRate! > 120) {
        alerts.add(Alert(
          alertId: 'hr_high_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.healthMetric,
          title: 'High Heart Rate',
          message: 'Heart rate of ${data.heartRate} bpm detected',
          priority: Priority.high,
          timestamp: DateTime.now(),
          source: device.name,
        ));
      }
    }
    
    // Air quality health alerts
    final currentAQI = await _getCurrentAirQualityIndex();
    if (currentAQI != null) {
      if (currentAQI > 150) {
        alerts.add(Alert(
          alertId: 'aqi_emergency_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.airQuality,
          title: 'Unhealthy Air Quality',
          message: 'AQI of $currentAQI detected. Limit outdoor activities.',
          priority: Priority.critical,
          timestamp: DateTime.now(),
          actions: ['Stay indoors', 'Use air purifier', 'Monitor symptoms'],
        ));
      }
    }
    
    // Emit alerts
    for (final alert in alerts) {
      _alertController.add(alert);
      
      // Send notification if enabled
      final device = _connectedDevices.firstWhere(
        (d) => d.deviceId == device.deviceId,
        orElse: () => throw Exception('Device not found'),
      );
      
      if (device.isConnected) {
        await _notificationService.sendWearableAlert(alert);
      }
    }
  }

  // Sync Management
  Future<void> _initializeDeviceSync(WearableDevice device) async {
    final syncSchedule = SyncSchedule(
      scheduleId: 'sync_${device.deviceId}',
      deviceId: device.deviceId,
      lastSync: DateTime.now(),
      nextSync: DateTime.now().add(const Duration(minutes: 5)),
      syncFrequency: 5,
      isActive: true,
      dataTypes: device.capabilities.map((c) => c.toString()).toList(),
    );
    
    _syncSchedules[device.deviceId] = syncSchedule;
    
    // Start sync timer
    _startSyncTimer(device.deviceId);
  }

  void _startSyncTimer(String deviceId) {
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      final schedule = _syncSchedules[deviceId];
      if (schedule?.isActive == true && DateTime.now().isAfter(schedule!.nextSync)) {
        await _syncDeviceBySchedule(schedule);
      }
    });
  }

  Future<void> _syncDeviceData(WearableDevice device, ProcessedMetrics data) async {
    try {
      // Sync data to cloud service
      // Implementation would send data to your backend
      print('Syncing device data for ${device.name}');
    } catch (e) {
      // Handle sync error
      final schedule = _syncSchedules[device.deviceId];
      if (schedule != null) {
        _syncSchedules[device.deviceId] = schedule.copyWith(syncError: e.toString());
      }
    }
  }

  Future<void> _syncDeviceBySchedule(SyncSchedule schedule) async {
    try {
      // Perform full device sync based on schedule
      // Implementation would sync all data types specified in schedule
      
      final updatedSchedule = SyncSchedule(
        scheduleId: schedule.scheduleId,
        deviceId: schedule.deviceId,
        lastSync: DateTime.now(),
        nextSync: DateTime.now().add(Duration(minutes: schedule.syncFrequency)),
        syncFrequency: schedule.syncFrequency,
        isActive: schedule.isActive,
        dataTypes: schedule.dataTypes,
      );
      
      _syncSchedules[schedule.deviceId] = updatedSchedule;
    } catch (e) {
      final schedule = _syncSchedules[schedule.deviceId];
      if (schedule != null) {
        _syncSchedules[schedule.deviceId] = schedule.copyWith(syncError: e.toString());
      }
    }
  }

  // Analytics and Insights
  Future<WearableAnalytics> generateAnalytics(
    String deviceId, 
    DateTime period,
  ) async {
    try {
      // Get health trend data
      final healthTrend = await _calculateHealthTrend(deviceId, period);
      
      // Calculate air quality impact
      final airQualityImpact = await _calculateAirQualityImpact(deviceId, period);
      
      // Generate recommendations
      final recommendations = await _generateDeviceRecommendations(deviceId, period);
      
      // Calculate metrics summary
      final metricsSummary = await _calculateMetricsSummary(deviceId, period);
      
      return WearableAnalytics(
        analyticsId: 'analytics_${DateTime.now().millisecondsSinceEpoch}',
        deviceId: deviceId,
        period: period,
        healthTrend: healthTrend,
        airQualityImpact: airQualityImpact,
        recommendations: recommendations,
        metricsSummary: metricsSummary,
      );
    } catch (e) {
      throw Exception('Failed to generate analytics: $e');
    }
  }

  Future<HealthTrend> _calculateHealthTrend(String deviceId, DateTime period) async {
    // Analyze health metrics over the specified period
    // Implementation would analyze historical data
    return HealthTrend(
      overall: TrendDirection.stable,
      improvementScore: 65.0,
      metrics: [
        TrendMetric(
          metricName: 'Heart Rate',
          direction: TrendDirection.stable,
          changePercentage: 2.5,
          description: 'Slight increase in average heart rate',
        ),
        TrendMetric(
          metricName: 'Steps',
          direction: TrendDirection.improving,
          changePercentage: 15.0,
          description: 'Improved daily step count',
        ),
      ],
    );
  }

  Future<AirQualityImpact> _calculateAirQualityImpact(String deviceId, DateTime period) async {
    // Analyze air quality impact on health metrics
    return AirQualityImpact(
      exposureScore: 45.0,
      impactLevel: ImpactLevel.low,
      affectedMetrics: ['Heart Rate', 'Stress Level'],
      mitigationActions: [
        'Monitor air quality before outdoor activities',
        'Consider indoor exercise during high pollution periods',
        'Use air purifiers indoors',
      ],
    );
  }

  Future<List<Recommendation>> _generateDeviceRecommendations(
    String deviceId, 
    DateTime period,
  ) async {
    // Generate personalized recommendations based on data analysis
    return [
      Recommendation(
        id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Optimize Exercise Timing',
        description: 'Your heart rate responds better to exercise during cleaner air periods.',
        category: RecommendationCategory.health,
        priority: Priority.medium,
        actions: [
          'Check AQI before outdoor exercise',
          'Consider indoor alternatives during high pollution',
          'Time exercise for morning hours when air is typically cleaner',
        ],
      ),
    ];
  }

  Future<Map<String, double>> _calculateMetricsSummary(
    String deviceId, 
    DateTime period,
  ) async {
    // Calculate summary statistics for the period
    return {
      'averageHeartRate': 72.5,
      'maxHeartRate': 145.0,
      'averageSteps': 8500.0,
      'totalDistance': 6.5,
      'averageSleep': 7.2,
      'stressLevel': 4.5,
    };
  }

  // Utility Methods
  void _updateDeviceStatus(WearableDevice device, DeviceStatus status) {
    final index = _connectedDevices.indexWhere((d) => d.deviceId == device.deviceId);
    if (index != -1) {
      _connectedDevices[index] = _connectedDevices[index].copyWith(status: status);
    }
  }

  void _showConnectionNotification(WearableDevice device, bool connected, {String? error}) {
    final title = connected ? 'Device Connected' : 'Connection Failed';
    final message = connected 
        ? '${device.name} successfully connected' 
        : 'Failed to connect to ${device.name}${error != null ? ': $error' : ''}';
    
    // Send notification to user
    _notificationService.showConnectionNotification(title, message);
  }

  // Public Stream Accessors
  Stream<DeviceData> get dataStream => _dataController.stream;
  Stream<Alert> get alertStream => _alertController.stream;
  
  List<WearableDevice> get connectedDevices => List.unmodifiable(_connectedDevices);
  Map<String, DeviceData> get deviceData => Map.unmodifiable(_deviceData);
  
  // Cleanup
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _sensorSubscription?.cancel();
    _dataController.close();
    _alertController.close();
  }
}

// Extension for WearableDevice
extension WearableDeviceExtension on WearableDevice {
  WearableDevice copyWith({
    String? deviceId,
    String? name,
    DeviceType? type,
    DevicePlatform? platform,
    String? manufacturer,
    String? model,
    String? firmwareVersion,
    bool? isConnected,
    DateTime? lastSyncTime,
    List<DeviceCapability>? capabilities,
    DeviceStatus? status,
    String? pairingCode,
  }) {
    return WearableDevice(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      type: type ?? this.type,
      platform: platform ?? this.platform,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      isConnected: isConnected ?? this.isConnected,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      capabilities: capabilities ?? this.capabilities,
      status: status ?? this.status,
      pairingCode: pairingCode ?? this.pairingCode,
    );
  }
}

// Extension for SyncSchedule
extension SyncScheduleExtension on SyncSchedule {
  SyncSchedule copyWith({
    String? scheduleId,
    String? deviceId,
    DateTime? lastSync,
    DateTime? nextSync,
    int? syncFrequency,
    bool? isActive,
    List<String>? dataTypes,
    String? syncError,
  }) {
    return SyncSchedule(
      scheduleId: scheduleId ?? this.scheduleId,
      deviceId: deviceId ?? this.deviceId,
      lastSync: lastSync ?? this.lastSync,
      nextSync: nextSync ?? this.nextSync,
      syncFrequency: syncFrequency ?? this.syncFrequency,
      isActive: isActive ?? this.isActive,
      dataTypes: dataTypes ?? this.dataTypes,
      syncError: syncError ?? this.syncError,
    );
  }
}
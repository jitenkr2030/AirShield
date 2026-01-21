import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/wearable_device_bloc.dart';
import '../../models/wearable_device_data.dart';
import 'components/device_list_widget.dart';
import 'components/device_connection_widget.dart';
import 'components/device_data_widget.dart';
import 'components/device_analytics_widget.dart';
import 'components/device_settings_widget.dart';

class WearableDeviceScreen extends StatefulWidget {
  const WearableDeviceScreen({Key? key}) : super(key: key);

  @override
  State<WearableDeviceScreen> createState() => _WearableDeviceScreenState();
}

class _WearableDeviceScreenState extends State<WearableDeviceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Start device discovery when screen loads
    Future.microtask(() {
      context.read<WearableDeviceBloc>().add(DiscoverDevicesEvent());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wearable Integration'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.devices), text: 'Devices'),
            Tab(icon: Icon(Icons.link), text: 'Connect'),
            Tab(icon: Icon(Icons.data_usage), text: 'Data'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WearableDeviceBloc>().add(DiscoverDevicesEvent());
            },
            tooltip: 'Refresh Devices',
          ),
        ],
      ),
      body: BlocConsumer<WearableDeviceBloc, WearableDeviceState>(
        listener: (context, state) {
          if (state is WearableDeviceError) {
            _showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildDevicesTab(state),
              _buildConnectTab(state),
              _buildDataTab(state),
              _buildAnalyticsTab(state),
              _buildSettingsTab(state),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(state),
    );
  }

  Widget _buildDevicesTab(WearableDeviceState state) {
    if (state is DevicesDiscoveredState) {
      return DeviceListWidget(
        discoveredDevices: state.devices,
        connectedDevices: context.read<WearableDeviceBloc>().connectedDevices,
        onConnectToDevice: (device) {
          context.read<WearableDeviceBloc>().add(ConnectToDeviceEvent(device));
        },
        onDisconnectDevice: (deviceId) {
          context.read<WearableDeviceBloc>().add(DisconnectDeviceEvent(deviceId));
        },
      );
    }

    if (state is WearableDeviceLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Discovering devices...'),
          ],
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No devices discovered yet'),
          SizedBox(height: 8),
          Text('Pull to refresh or check device compatibility'),
        ],
      ),
    );
  }

  Widget _buildConnectTab(WearableDeviceState state) {
    if (state is DeviceConnectedState) {
      return DeviceConnectionWidget(
        device: state.device,
        isConnecting: false,
        onDisconnect: () {
          context.read<WearableDeviceBloc>().add(
            DisconnectDeviceEvent(state.device.deviceId),
          );
        },
      );
    }

    if (state is DeviceConnectedState || state is DevicesDiscoveredState) {
      final devices = state is DeviceConnectedState 
          ? [state.device]
          : state is DevicesDiscoveredState 
              ? state.devices 
              : [];
              
      return DeviceConnectionWidget(
        device: devices.isNotEmpty ? devices.first : null,
        isConnecting: state is WearableDeviceLoading,
        onConnect: devices.isNotEmpty ? () {
          context.read<WearableDeviceBloc>().add(ConnectToDeviceEvent(devices.first));
        } : null,
        onRefresh: () {
          context.read<WearableDeviceBloc>().add(DiscoverDevicesEvent());
        },
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No device connected'),
          SizedBox(height: 8),
          Text('Connect a wearable device to get started'),
        ],
      ),
    );
  }

  Widget _buildDataTab(WearableDeviceState state) {
    if (state is DeviceDataState) {
      return DeviceDataWidget(
        deviceId: state.deviceId,
        data: state.data,
        allDeviceData: state.allDeviceData,
        onSync: () {
          context.read<WearableDeviceBloc>().add(
            SyncDeviceDataEvent(state.deviceId),
          );
        },
        onClearData: () {
          _showClearDataDialog(state.deviceId);
        },
      );
    }

    if (state is DeviceDataState || state is DeviceConnectedState) {
      return DeviceDataWidget(
        deviceId: state is DeviceConnectedState ? state.device.deviceId : '',
        data: state is DeviceDataState ? state.data : const DeviceData(
          deviceId: '',
          timestamp: null,
          rawData: {},
        ),
        allDeviceData: state is DeviceDataState ? state.allDeviceData : {},
        onSync: state is DeviceConnectedState ? () {
          context.read<WearableDeviceBloc>().add(
            SyncDeviceDataEvent(state.device.deviceId),
          );
        } : null,
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.data_usage, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No data available'),
          SizedBox(height: 8),
          Text('Connect a device to view real-time data'),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(WearableDeviceState state) {
    if (state is DeviceAnalyticsState) {
      return DeviceAnalyticsWidget(
        deviceId: state.deviceId,
        analytics: state.analytics,
        onGenerateNew: () {
          context.read<WearableDeviceBloc>().add(
            GenerateAnalyticsEvent(
              state.deviceId,
              DateTime.now(),
            ),
          );
        },
      );
    }

    if (state is DeviceConnectedState || state is DeviceDataState) {
      final deviceId = state is DeviceConnectedState 
          ? state.device.deviceId 
          : state is DeviceDataState 
              ? state.deviceId 
              : '';

      return DeviceAnalyticsWidget(
        deviceId: deviceId,
        analytics: const WearableAnalytics(
          analyticsId: '',
          deviceId: '',
          period: null,
          healthTrend: HealthTrend(
            overall: TrendDirection.stable,
            improvementScore: 0.0,
            metrics: [],
          ),
          airQualityImpact: AirQualityImpact(
            exposureScore: 0.0,
            impactLevel: ImpactLevel.minimal,
            affectedMetrics: [],
            mitigationActions: [],
          ),
          recommendations: [],
          metricsSummary: {},
        ),
        onGenerateNew: deviceId.isNotEmpty ? () {
          context.read<WearableDeviceBloc>().add(
            GenerateAnalyticsEvent(deviceId, DateTime.now()),
          );
        } : null,
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No analytics available'),
          SizedBox(height: 8),
          Text('Generate analytics from device data'),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(WearableDeviceState state) {
    if (state is DeviceSettingsState) {
      return DeviceSettingsWidget(
        deviceId: state.deviceId,
        settings: state.settings,
        onUpdateSettings: (settings) {
          context.read<WearableDeviceBloc>().add(
            UpdateDeviceSettingsEvent(state.deviceId, settings),
          );
        },
      );
    }

    if (state is DeviceConnectedState) {
      return DeviceSettingsWidget(
        deviceId: state.device.deviceId,
        settings: const WearableSettings(
          deviceId: '',
          enableRealTimeSync: true,
          enableNotifications: true,
          enableHealthAlerts: true,
          notificationTypes: [],
          enableDataExport: false,
          enableVibration: true,
          syncInterval: 5.0,
          customSettings: {},
        ),
        onUpdateSettings: (settings) {
          context.read<WearableDeviceBloc>().add(
            UpdateDeviceSettingsEvent(state.device.deviceId, settings),
          );
        },
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No settings available'),
          SizedBox(height: 8),
          Text('Connect a device to configure settings'),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(WearableDeviceState state) {
    if (state is DeviceConnectedState) {
      return FloatingActionButton(
        onPressed: () {
          context.read<WearableDeviceBloc>().add(
            SyncDeviceDataEvent(state.device.deviceId),
          );
        },
        child: const Icon(Icons.sync),
        tooltip: 'Sync Device Data',
      );
    }

    if (state is DevicesDiscoveredState || state is WearableDeviceInitial) {
      return FloatingActionButton(
        onPressed: () {
          context.read<WearableDeviceBloc>().add(DiscoverDevicesEvent());
        },
        child: const Icon(Icons.search),
        tooltip: 'Discover Devices',
      );
    }

    return null;
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

  void _showClearDataDialog(String deviceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Device Data'),
        content: const Text(
          'Are you sure you want to clear all device data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<WearableDeviceBloc>().add(
                ClearDeviceDataEvent(deviceId),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// Tab-specific widgets
class DeviceListWidget extends StatelessWidget {
  final List<WearableDevice> discoveredDevices;
  final List<WearableDevice> connectedDevices;
  final Function(WearableDevice) onConnectToDevice;
  final Function(String) onDisconnectDevice;

  const DeviceListWidget({
    Key? key,
    required this.discoveredDevices,
    required this.connectedDevices,
    required this.onConnectToDevice,
    required this.onDisconnectDevice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Connected Devices', connectedDevices.length),
          if (connectedDevices.isNotEmpty) ...[
            ...connectedDevices.map((device) => _buildConnectedDeviceCard(context, device)),
            const SizedBox(height: 24),
          ],
          _buildSectionHeader('Discovered Devices', discoveredDevices.length),
          if (discoveredDevices.isNotEmpty) ...[
            ...discoveredDevices.map((device) => _buildDiscoveredDeviceCard(context, device)),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.device_unknown, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No devices discovered'),
                    Text(
                      'Make sure your wearable device is in pairing mode',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDeviceCard(BuildContext context, WearableDevice device) {
    return Card(
      child: ListTile(
        leading: _buildDeviceIcon(device.type, true),
        title: Text(device.name),
        subtitle: Text('${device.manufacturer} • ${device.model}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'disconnect') {
                  onDisconnectDevice(device.deviceId);
                } else if (value == 'settings') {
                  // Navigate to settings
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'disconnect',
                  child: Row(
                    children: [
                      Icon(Icons.link_off),
                      SizedBox(width: 8),
                      Text('Disconnect'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveredDeviceCard(BuildContext context, WearableDevice device) {
    return Card(
      child: ListTile(
        leading: _buildDeviceIcon(device.type, false),
        title: Text(device.name),
        subtitle: Text('${device.manufacturer} • ${device.model}'),
        trailing: ElevatedButton.icon(
          onPressed: () => onConnectToDevice(device),
          icon: const Icon(Icons.link),
          label: const Text('Connect'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon(DeviceType type, bool isConnected) {
    IconData icon;
    
    switch (type) {
      case DeviceType.smartwatch:
        icon = Icons.watch;
        break;
      case DeviceType.fitnessTracker:
        icon = Icons.fitness_center;
        break;
      case DeviceType.smartBand:
        icon = Icons.wrist;
        break;
      case DeviceType.heartRateMonitor:
        icon = Icons.heart_broken;
        break;
      case DeviceType.healthMonitor:
        icon = Icons.monitor_heart;
        break;
      case DeviceType.airQualitySensor:
        icon = Icons.air;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isConnected ? Colors.green : Colors.grey,
        size: 24,
      ),
    );
  }
}

// Additional widget classes (DeviceConnectionWidget, DeviceDataWidget, etc.) would be implemented similarly
// For brevity, showing the main structure here

class DeviceConnectionWidget extends StatelessWidget {
  final WearableDevice? device;
  final bool isConnecting;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onRefresh;

  const DeviceConnectionWidget({
    Key? key,
    required this.device,
    required this.isConnecting,
    this.onConnect,
    this.onDisconnect,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (device == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No device connected'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.search),
              label: const Text('Discover Devices'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.watch, size: 120, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            device!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('${device!.manufacturer} • ${device!.model}'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Connected',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Sync'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: onDisconnect,
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeviceDataWidget extends StatelessWidget {
  final String deviceId;
  final DeviceData data;
  final Map<String, DeviceData> allDeviceData;
  final VoidCallback? onSync;
  final VoidCallback? onClearData;

  const DeviceDataWidget({
    Key? key,
    required this.deviceId,
    required this.data,
    required this.allDeviceData,
    this.onSync,
    this.onClearData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Device Data View - Device: $deviceId'),
    );
  }
}

class DeviceAnalyticsWidget extends StatelessWidget {
  final String deviceId;
  final WearableAnalytics analytics;
  final VoidCallback? onGenerateNew;

  const DeviceAnalyticsWidget({
    Key? key,
    required this.deviceId,
    required this.analytics,
    this.onGenerateNew,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Analytics View - Device: $deviceId'),
    );
  }
}

class DeviceSettingsWidget extends StatelessWidget {
  final String deviceId;
  final WearableSettings settings;
  final Function(WearableSettings) onUpdateSettings;

  const DeviceSettingsWidget({
    Key? key,
    required this.deviceId,
    required this.settings,
    required this.onUpdateSettings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Settings View - Device: $deviceId'),
    );
  }
}
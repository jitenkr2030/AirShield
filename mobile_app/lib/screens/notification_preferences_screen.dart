import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notification_preferences_viewmodel.dart';
import '../core/services/smart_notification_service.dart';

/// Notification Preferences Screen
/// Allows users to configure smart notification settings
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  late NotificationPreferencesViewModel _viewModel;
  NotificationSeverity _selectedSeverity = NotificationSeverity.high;
  NotificationContext _selectedContext = NotificationContext.airQuality;

  @override
  void initState() {
    super.initState();
    _viewModel = NotificationPreferencesViewModel();
    _viewModel.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ChangeNotifierProvider.value(
        value: _viewModel,
        child: Consumer<NotificationPreferencesViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainToggleSection(viewModel),
                  const SizedBox(height: 24),
                  _buildQuietHoursSection(viewModel),
                  const SizedBox(height: 24),
                  _buildNotificationFilterSection(viewModel),
                  const SizedBox(height: 24),
                  _buildLocationPreferencesSection(viewModel),
                  const SizedBox(height: 24),
                  _buildTestingSection(viewModel),
                  const SizedBox(height: 24),
                  _buildActionButtons(viewModel),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainToggleSection(NotificationPreferencesViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable intelligent notification filtering to reduce noise while ensuring critical alerts reach you.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Smart Notifications'),
              subtitle: const Text('Use AI-powered filtering for better notification experience'),
              value: viewModel.smartNotificationsEnabled,
              onChanged: viewModel.setSmartNotificationsEnabled,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSection(NotificationPreferencesViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiet Hours',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.quietHoursDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Quiet Hours'),
              subtitle: const Text('Silence non-urgent notifications during specified hours'),
              value: viewModel.quietHoursEnabled,
              onChanged: viewModel.setQuietHoursEnabled,
              contentPadding: EdgeInsets.zero,
            ),
            if (viewModel.quietHoursEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      label: 'Start Time',
                      hour: viewModel.quietStartHour,
                      onTimeChanged: viewModel.setQuietStartHour,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeSelector(
                      label: 'End Time',
                      hour: viewModel.quietEndHour,
                      onTimeChanged: viewModel.setQuietEndHour,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required int hour,
    required Function(int) onTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _showTimePicker(hour, onTimeChanged),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatTime(hour)),
                const Icon(Icons.access_time, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationFilterSection(NotificationPreferencesViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Filters',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('High Priority Only'),
              subtitle: const Text('Show only critical and high priority notifications'),
              value: viewModel.highPriorityOnly,
              onChanged: viewModel.setHighPriorityOnly,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Activity-Based Filtering'),
              subtitle: const Text('Adjust notifications based on your current activity'),
              value: viewModel.activityBasedNotifications,
              onChanged: viewModel.setActivityBasedNotifications,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            Text(
              'Commute Radius',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: viewModel.selectedRadiusIndex >= 0 ? viewModel.selectedRadiusIndex : 1,
              items: viewModel.commuteRadiusOptions.asMap().entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (index) {
                if (index != null) {
                  viewModel.setCommuteRadiusByIndex(index);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Notification Radius',
                hintText: 'How far from home/work to receive location-based alerts',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPreferencesSection(NotificationPreferencesViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set your home and work locations for location-aware notifications.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Location-Aware Alerts'),
              subtitle: const Text('Receive notifications based on your current location'),
              value: viewModel.locationAwareAlerts,
              onChanged: viewModel.setLocationAwareAlerts,
              contentPadding: EdgeInsets.zero,
            ),
            if (viewModel.locationAwareAlerts) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _setLocation('home', viewModel),
                      icon: const Icon(Icons.home),
                      label: const Text('Set Home'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _setLocation('work', viewModel),
                      icon: const Icon(Icons.work),
                      label: const Text('Set Work'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestingSection(NotificationPreferencesViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Test how your notification settings filter different types of alerts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<NotificationSeverity>(
                    value: _selectedSeverity,
                    items: viewModel.availableSeverities.map((severity) {
                      return DropdownMenuItem<NotificationSeverity>(
                        value: severity,
                        child: Text(severity.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (severity) {
                      if (severity != null) {
                        setState(() {
                          _selectedSeverity = severity;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Severity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<NotificationContext>(
                    value: _selectedContext,
                    items: viewModel.availableContexts.map((context) {
                      return DropdownMenuItem<NotificationContext>(
                        value: context,
                        child: Text(context.name.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (context) {
                      if (context != null) {
                        setState(() {
                          _selectedContext = context;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Context',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _testNotification(viewModel),
                icon: const Icon(Icons.send),
                label: const Text('Test Filter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(NotificationPreferencesViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: viewModel.resetToDefaults,
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Defaults'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showHelpDialog(context),
            icon: const Icon(Icons.help),
            label: const Text('Help'),
          ),
        ),
      ],
    );
  }

  void _showTimePicker(int currentHour, Function(int) onTimeChanged) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
    );
    
    if (picked != null) {
      onTimeChanged(picked.hour);
    }
  }

  String _formatTime(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:00 $period';
  }

  Future<void> _setLocation(String type, NotificationPreferencesViewModel viewModel) async {
    // This would typically open a map selector or use current location
    // For now, we'll use a simple dialog
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set $type Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g., 37.7749',
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'e.g., -122.4194',
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Extract values and pop
              Navigator.of(context).pop({
                'lat': 37.7749, // Placeholder
                'lng': -122.4194, // Placeholder
              });
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (type == 'home') {
        await viewModel.setHomeLocation(result['lat']!, result['lng']!);
      } else {
        await viewModel.setWorkLocation(result['lat']!, result['lng']!);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type[0].toUpperCase()}${type.substring(1)} location updated'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _testNotification(NotificationPreferencesViewModel viewModel) async {
    try {
      final result = await viewModel.testNotificationFiltering(
        severity: _selectedSeverity,
        context: _selectedContext,
        title: 'Test Alert',
        message: 'This is a test notification to verify filtering',
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Filter Test Result'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTestResult('Show Notification', result['should_show'].toString()),
                _buildTestResult('Reason', result['reason']),
                _buildTestResult('Quiet Hours Active', result['is_quiet_hours'].toString()),
                _buildTestResult('User Activity', result['user_activity']),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTestResult(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smart Notifications Help'),
        content: const SingleChildScrollView(
          child: Text(
            'Smart Notifications help reduce notification fatigue while ensuring you receive important alerts. \n\n'
            '• Quiet Hours: Silences non-urgent notifications during sleep/work hours\n'
            '• High Priority Only: Shows only critical and high priority alerts\n'
            '• Activity-Based: Adjusts notifications based on your current activity\n'
            '• Location-Aware: Sends alerts based on your proximity to home/work\n'
            '• Commute Radius: Controls how far you need to be from configured locations\n\n'
            'Critical alerts (hazardous air quality) will always break through quiet hours.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
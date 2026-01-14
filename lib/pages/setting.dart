import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/shared.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Modern Color Palette
  final Color primaryColor = const Color(0xFF4361EE); // Modern blue
  final Color secondaryColor = const Color(0xFF3A0CA3); // Dark blue
  final Color accentColor = const Color(0xFF4CC9F0); // Light blue
  final Color successColor = const Color(0xFF06D6A0); // Green
  final Color warningColor = const Color(0xFFFFD166); // Yellow
  final Color errorColor = const Color(0xFFEF476F); // Red
  final Color backgroundColor = const Color(0xFFF8F9FF); // Light background
  final Color cardColor = Colors.white;
  final Color textPrimary = const Color(0xFF2B2D42);
  final Color textSecondary = const Color(0xFF8D99AE);
  final Color borderColor = const Color(0xFFE9ECEF);

  static const String baseUrl =
      'https://uncollapsable-overfly-blaine.ngrok-free.dev/api';
  String? _token;

  // Settings state
  Map<String, dynamic> settings = {
    'general': {
      'site_name': 'HydroGrow Admin',
      'timezone': 'Asia/Jakarta',
      'maintenance_mode': false,
      'language': 'English',
    },
    'notifications': {
      'email_alerts': true,
      'push_notifications': true,
      'critical_alerts': true,
      'daily_reports': false,
      'weekly_summary': true,
    },
    'sensors': {
      'update_interval': 10,
      'temperature_threshold': 30.0,
      'humidity_threshold': 80.0,
      'ph_min': 6.0,
      'ph_max': 7.5,
      'auto_calibration': true,
    },
    'security': {
      'two_factor_auth': false,
      'session_timeout': 30,
      'login_attempts': 5,
      'password_expiry': 90,
    },
    'appearance': {
      'theme': 'light',
      'accent_color': '#4361EE',
      'font_size': 'medium',
    },
  };

  bool isLoading = false;
  bool hasUnsavedChanges = false;
  int _selectedCategory = 0;

  final List<Map<String, dynamic>> categories = [
    {'label': 'General', 'icon': Icons.settings_rounded},
    {'label': 'Notifications', 'icon': Icons.notifications_rounded},
    {'label': 'Sensors', 'icon': Icons.sensors_rounded},
    {'label': 'Security', 'icon': Icons.security_rounded},
    {'label': 'Appearance', 'icon': Icons.palette_rounded},
    {'label': 'System', 'icon': Icons.info_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _token = await SharedService.getToken();
    // TODO: Load settings from API
    // await _loadSettings();
  }

  Future<void> _saveSettings() async {
    setState(() => isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Settings saved successfully'),
            ],
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      setState(() {
        hasUnsavedChanges = false;
        isLoading = false;
      });
    } catch (e) {
      print('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Error saving settings: $e'),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      setState(() => isLoading = false);
    }
  }

  void _updateSetting(String category, String key, dynamic value) {
    setState(() {
      settings[category][key] = value;
      hasUnsavedChanges = true;
    });
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.restore_rounded,
                color: errorColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Reset Settings',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reset all settings to default values? This action cannot be undone.',
          style: TextStyle(
            color: textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToDefaults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      settings = {
        'general': {
          'site_name': 'HydroGrow Admin',
          'timezone': 'Asia/Jakarta',
          'maintenance_mode': false,
          'language': 'English',
        },
        'notifications': {
          'email_alerts': true,
          'push_notifications': true,
          'critical_alerts': true,
          'daily_reports': false,
          'weekly_summary': true,
        },
        'sensors': {
          'update_interval': 10,
          'temperature_threshold': 30.0,
          'humidity_threshold': 80.0,
          'ph_min': 6.0,
          'ph_max': 7.5,
          'auto_calibration': true,
        },
        'security': {
          'two_factor_auth': false,
          'session_timeout': 30,
          'login_attempts': 5,
          'password_expiry': 90,
        },
        'appearance': {
          'theme': 'light',
          'accent_color': '#4361EE',
          'font_size': 'medium',
        },
      };
      hasUnsavedChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.restore_page_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Settings reset to defaults'),
          ],
        ),
        backgroundColor: warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return _settingsSection(
      title: 'General Settings',
      icon: Icons.settings_rounded,
      children: [
        _textSetting(
          label: 'Site Name',
          value: settings['general']['site_name'],
          onChanged: (value) => _updateSetting('general', 'site_name', value),
        ),
        _dropdownSetting(
          label: 'Timezone',
          value: settings['general']['timezone'],
          options: const [
            'Asia/Jakarta',
            'UTC',
            'America/New_York',
            'Europe/London',
            'Asia/Singapore',
            'Australia/Sydney',
          ],
          onChanged: (value) => _updateSetting('general', 'timezone', value),
        ),
        _dropdownSetting(
          label: 'Language',
          value: settings['general']['language'],
          options: const ['English', 'Indonesia', 'Spanish', 'French', 'German'],
          onChanged: (value) => _updateSetting('general', 'language', value),
        ),
        _switchSetting(
          label: 'Maintenance Mode',
          value: settings['general']['maintenance_mode'],
          onChanged: (value) => _updateSetting('general', 'maintenance_mode', value),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return _settingsSection(
      title: 'Notifications',
      icon: Icons.notifications_rounded,
      children: [
        _switchSetting(
          label: 'Email Alerts',
          value: settings['notifications']['email_alerts'],
          onChanged: (value) => _updateSetting('notifications', 'email_alerts', value),
        ),
        _switchSetting(
          label: 'Push Notifications',
          value: settings['notifications']['push_notifications'],
          onChanged: (value) => _updateSetting('notifications', 'push_notifications', value),
        ),
        _switchSetting(
          label: 'Critical Alerts',
          value: settings['notifications']['critical_alerts'],
          onChanged: (value) => _updateSetting('notifications', 'critical_alerts', value),
        ),
        _switchSetting(
          label: 'Daily Reports',
          value: settings['notifications']['daily_reports'],
          onChanged: (value) => _updateSetting('notifications', 'daily_reports', value),
        ),
        _switchSetting(
          label: 'Weekly Summary',
          value: settings['notifications']['weekly_summary'],
          onChanged: (value) => _updateSetting('notifications', 'weekly_summary', value),
        ),
      ],
    );
  }

  Widget _buildSensorSettings() {
    return _settingsSection(
      title: 'Sensor Settings',
      icon: Icons.sensors_rounded,
      children: [
        _sliderSetting(
          label: 'Update Interval',
          value: settings['sensors']['update_interval'].toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          unit: 's',
          onChanged: (value) => _updateSetting('sensors', 'update_interval', value.toInt()),
        ),
        _sliderSetting(
          label: 'Temperature Threshold',
          value: settings['sensors']['temperature_threshold'].toDouble(),
          min: 20,
          max: 40,
          divisions: 20,
          unit: '°C',
          onChanged: (value) => _updateSetting('sensors', 'temperature_threshold', value),
        ),
        _sliderSetting(
          label: 'Humidity Threshold',
          value: settings['sensors']['humidity_threshold'].toDouble(),
          min: 40,
          max: 90,
          divisions: 25,
          unit: '%',
          onChanged: (value) => _updateSetting('sensors', 'humidity_threshold', value),
        ),
        _rangeSliderSetting(
          label: 'pH Range',
          minValue: settings['sensors']['ph_min'].toDouble(),
          maxValue: settings['sensors']['ph_max'].toDouble(),
          min: 4.0,
          max: 9.0,
          divisions: 50,
          onChanged: (min, max) {
            _updateSetting('sensors', 'ph_min', min);
            _updateSetting('sensors', 'ph_max', max);
          },
        ),
        _switchSetting(
          label: 'Auto Calibration',
          value: settings['sensors']['auto_calibration'],
          onChanged: (value) => _updateSetting('sensors', 'auto_calibration', value),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return _settingsSection(
      title: 'Security',
      icon: Icons.security_rounded,
      children: [
        _switchSetting(
          label: 'Two-Factor Authentication',
          value: settings['security']['two_factor_auth'],
          onChanged: (value) => _updateSetting('security', 'two_factor_auth', value),
        ),
        _sliderSetting(
          label: 'Session Timeout',
          value: settings['security']['session_timeout'].toDouble(),
          min: 5,
          max: 120,
          divisions: 23,
          unit: 'min',
          onChanged: (value) => _updateSetting('security', 'session_timeout', value.toInt()),
        ),
        _sliderSetting(
          label: 'Max Login Attempts',
          value: settings['security']['login_attempts'].toDouble(),
          min: 3,
          max: 10,
          divisions: 7,
          onChanged: (value) => _updateSetting('security', 'login_attempts', value.toInt()),
        ),
        _sliderSetting(
          label: 'Password Expiry',
          value: settings['security']['password_expiry'].toDouble(),
          min: 30,
          max: 180,
          divisions: 15,
          unit: 'days',
          onChanged: (value) => _updateSetting('security', 'password_expiry', value.toInt()),
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return _settingsSection(
      title: 'Appearance',
      icon: Icons.palette_rounded,
      children: [
        _dropdownSetting(
          label: 'Theme',
          value: settings['appearance']['theme'],
          options: const ['Light', 'Dark', 'Auto'],
          onChanged: (value) => _updateSetting('appearance', 'theme', value?.toLowerCase()),
        ),
        _dropdownSetting(
          label: 'Accent Color',
          value: 'Blue',
          options: const ['Blue', 'Green', 'Purple', 'Orange', 'Red'],
          onChanged: (value) {
            // Handle color change
          },
        ),
        _dropdownSetting(
          label: 'Font Size',
          value: settings['appearance']['font_size'],
          options: const ['Small', 'Medium', 'Large', 'Extra Large'],
          onChanged: (value) => _updateSetting('appearance', 'font_size', value?.toLowerCase()),
        ),
      ],
    );
  }

  Widget _buildSystemSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'System Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _infoRow('App Version', '1.0.0'),
          _infoRow('Last Backup', 'Jan 15, 2024 10:30 AM'),
          _infoRow('Database Size', '25.4 MB'),
          _infoRow('Server Status', 'Online', status: true),
          _infoRow('Last Updated', 'Just now'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.backup_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text('Creating backup...'),
                          ],
                        ),
                        backgroundColor: primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.backup_rounded, size: 20),
                  label: const Text('Create Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.restore_rounded, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            const Text('Restore functionality coming soon'),
                          ],
                        ),
                        backgroundColor: backgroundColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.restore_rounded, size: 20, color: primaryColor),
                  label: Text(
                    'Restore',
                    style: TextStyle(color: primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _textSetting({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: TextEditingController(text: value),
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: TextStyle(color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownSetting({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              isExpanded: true,
              underline: const SizedBox(),
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(
                    option,
                    style: TextStyle(color: textPrimary),
                  ),
                );
              }).toList(),
              icon: Icon(Icons.arrow_drop_down_rounded, color: textSecondary),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchSetting({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
            trackColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return primaryColor.withOpacity(0.5);
              }
              return textSecondary.withOpacity(0.3);
            }),
          ),
        ],
      ),
    );
  }

  Widget _sliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    String unit = '',
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                '${value.toStringAsFixed(unit == '°C' ? 1 : 0)}$unit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: primaryColor,
            inactiveColor: borderColor,
            thumbColor: primaryColor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$min$unit',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
              Text(
                '$max$unit',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeSliderSetting({
    required String label,
    required double minValue,
    required double maxValue,
    required double min,
    required double max,
    required int divisions,
    required Function(double, double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                '${minValue.toStringAsFixed(1)} - ${maxValue.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RangeSlider(
            values: RangeValues(minValue, maxValue),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (values) => onChanged(values.start, values.end),
            activeColor: primaryColor,
            inactiveColor: borderColor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                min.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
              Text(
                max.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool? status}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: status ? successColor.withOpacity(0.1) : errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: status ? successColor.withOpacity(0.2) : errorColor.withOpacity(0.2),
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: status ? successColor : errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (hasUnsavedChanges)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: warningColor.withOpacity(0.2)),
              ),
              child: Text(
                'Unsaved',
                style: TextStyle(
                  fontSize: 12,
                  color: warningColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.restore_rounded, color: errorColor),
              onPressed: _showResetDialog,
              tooltip: 'Reset to defaults',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Category Tabs
          Container(
            height: 72,
            color: cardColor,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == index;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = index);
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 24 : 8,
                      right: index == categories.length - 1 ? 24 : 0,
                      top: 12,
                      bottom: 12,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? primaryColor : borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          category['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category['label'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildSelectedContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: hasUnsavedChanges
          ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(top: BorderSide(color: borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      isLoading ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSelectedContent() {
    switch (_selectedCategory) {
      case 0:
        return _buildGeneralSettings();
      case 1:
        return _buildNotificationSettings();
      case 2:
        return _buildSensorSettings();
      case 3:
        return _buildSecuritySettings();
      case 4:
        return _buildAppearanceSettings();
      case 5:
        return _buildSystemSettings();
      default:
        return _buildGeneralSettings();
    }
  }
}
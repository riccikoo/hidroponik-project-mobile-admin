import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../services/shared.dart';
import '../models/sensor_model.dart';
import 'user.dart';
import 'sensor.dart';
import 'analytics.dart';
import 'setting.dart';
import 'log.dart';
import 'messages.dart';
import 'splash_screen.dart';
import 'login.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Modern Color Palette - Professional & Clean
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

  // State variables
  int _selectedIndex = 0;
  Timer? _refreshTimer;
  String? _token;

  // Sensor data
  double temperature = 0;
  double humidity = 0;
  double phLevel = 0;
  double ecLevel = 0;
  double lightIntensity = 0;
  double waterLevel = 0;
  List<SensorData> allSensors = [];

  // Admin stats
  int activeUsers = 0;
  int totalMessages = 0;
  bool systemOnline = true;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  // Weather data
  Map<String, dynamic>? weatherData;
  bool weatherLoading = false;
  String selectedCity = 'Bandung';
  final Map<String, String> locations = {
    'Bandung': '32.73.19.1001',
    'Jakarta': '31.71.04.1001',
    'Surabaya': '35.78.13.1001',
    'Yogyakarta': '34.71.05.1001',
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    _token = await SharedService.getToken();

    if (_token == null || _token!.isEmpty) {
      _handleTokenError('Session expired. Please login again.');
      return;
    }

    await _loadAllData();
    _fetchWeatherData();

    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadAllData();
    });
  }

  void _handleTokenError(String message) {
    setState(() {
      hasError = true;
      errorMessage = message;
      isLoading = false;
    });

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  Future<void> _loadAllData() async {
    if (_token == null || _token!.isEmpty) {
      _handleTokenError('No authentication token found');
      return;
    }

    try {
      setState(() {
        hasError = false;
        errorMessage = '';
      });

      await Future.wait([_loadDashboardStats(), _loadSensorDataFallback()]);

      setState(() => isLoading = false);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Failed to load data: $e';
      });
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final url = Uri.parse('https://uncollapsable-overfly-blaine.ngrok-free.dev/api/admin/dashboard/stats');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);

          if (data['status'] == true) {
            final stats = data['data'] as Map<String, dynamic>? ?? {};

            setState(() {
              // User Statistics
              final users = stats['users'] as Map<String, dynamic>? ?? {};
              activeUsers = (users['active'] as int?) ?? 1;
              if (activeUsers == 1) {
                activeUsers = (users['total'] as int?) ?? 1;
              }

              // Messages
              final messages = stats['messages'] as Map<String, dynamic>?;
              totalMessages =
                  messages?['unread'] as int? ??
                  messages?['total_today'] as int? ??
                  0;

              // Sensor Statistics
              final sensorStats =
                  stats['sensors'] as Map<String, dynamic>? ?? {};
              final sensorReadings =
                  sensorStats['latest_readings'] as Map<String, dynamic>? ?? {};

              // Update nilai sensor
              temperature = _getSensorValue(sensorReadings, 'dht_temp');
              humidity = _getSensorValue(sensorReadings, 'dht_humid');
              phLevel = _getSensorValue(sensorReadings, 'ph');
              ecLevel = _getSensorValue(sensorReadings, 'ec');
              lightIntensity = _getSensorValue(sensorReadings, 'ldr');
              waterLevel = _getSensorValue(sensorReadings, 'ultrasonic');

              // System Status
              final system = stats['system'] as Map<String, dynamic>? ?? {};
              systemOnline = (system['status'] as String?) == 'online';

              // Update allSensors
              _updateAllSensorsFromReadings(sensorReadings);
            });
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ JSON Parse Error: $e');
          }
        }
      }

      // Handle error responses
      if (response.statusCode == 401) {
        _handleTokenError('Session expired. Please login again.');
        return;
      } else if (response.statusCode == 403) {
        _handleTokenError('Access denied. Admin permission required.');
        return;
      }

      _useFallbackData();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading dashboard stats: $e');
      }
      _useFallbackData();
    }
  }

  double _getSensorValue(Map<String, dynamic> readings, String sensorName) {
    try {
      final sensorData = readings[sensorName] as Map<String, dynamic>?;
      if (sensorData == null) return 0.0;

      final value = sensorData['value'];
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;

      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  void _useFallbackData() {
    setState(() {
      activeUsers = 1;
      totalMessages = 0;
      systemOnline = allSensors.isNotEmpty;
    });
  }

  void _updateAllSensorsFromReadings(Map<String, dynamic> readings) {
    List<SensorData> updatedSensors = [];
    final now = DateTime.now();

    readings.forEach((sensorName, data) {
      if (data != null && data['value'] != null) {
        try {
          final timestamp = data['timestamp'] != null
              ? DateTime.parse(data['timestamp'])
              : now;

          final sensorData = SensorData(
            sensorName: sensorName,
            value: (data['value'] as num).toDouble(),
            timestamp: timestamp,
          );
          updatedSensors.add(sensorData);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing sensor $sensorName: $e');
          }
        }
      }
    });

    if (updatedSensors.isNotEmpty) {
      setState(() {
        allSensors = updatedSensors;
      });
    }
  }

  Future<void> _loadSensorDataFallback() async {
    try {
      final url = Uri.parse('https://uncollapsable-overfly-blaine.ngrok-free.dev/api/get_sensor_data');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List data = jsonData['data'] ?? [];

        final List<SensorData> sensors = data
            .map((e) => SensorData.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        setState(() {
          allSensors = sensors;
          temperature = _getLatestValue('dht_temp');
          humidity = _getLatestValue('dht_humid');
          phLevel = _getLatestValue('ph');
          ecLevel = _getLatestValue('ec');
          lightIntensity = _getLatestValue('ldr');
          waterLevel = _getLatestValue('ultrasonic');
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading fallback sensor data: $e');
      }
    }
  }

  double _getLatestValue(String sensorName) {
    final items = allSensors.where((e) => e.sensorName == sensorName).toList();
    if (items.isNotEmpty) {
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items.first.value;
    }
    return 0.0;
  }

  int _getTotalSensors() {
    int count = 0;
    if (temperature > 0) count++;
    if (humidity > 0) count++;
    if (phLevel > 0) count++;
    if (ecLevel > 0) count++;
    if (lightIntensity > 0) count++;
    if (waterLevel > 0) count++;

    if (count == 0 && allSensors.isNotEmpty) {
      final uniqueSensors = allSensors.map((e) => e.sensorName).toSet();
      return uniqueSensors.length;
    }

    return count;
  }

  String _getSystemStatus() {
    if (isLoading) return 'Loading...';
    if (hasError) return 'Error';
    return systemOnline ? 'Online' : 'Offline';
  }

  Color _getSystemStatusColor() {
    if (isLoading) return textSecondary;
    if (hasError) return errorColor;
    return systemOnline ? successColor : errorColor;
  }

  String _getLastUpdateTime() {
    if (allSensors.isEmpty) {
      return 'No data';
    }

    final latest = allSensors.reduce(
      (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
    );

    final difference = DateTime.now().difference(latest.timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _fetchWeatherData() async {
    setState(() => weatherLoading = true);

    try {
      final adm4Code = locations[selectedCity]!;
      final response = await http.get(
        Uri.parse(
          'https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=$adm4Code',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          weatherData = data;
          weatherLoading = false;
        });
      } else {
        setState(() => weatherLoading = false);
      }
    } catch (e) {
      if (kDebugMode) print('Weather error: $e');
      setState(() => weatherLoading = false);
    }
  }

  int? _getCurrentWeatherCode() {
    if (weatherData == null) return null;
    final data = weatherData!['data'];
    if (data == null || data.isEmpty) return null;
    final cuacaList = data[0]['cuaca'] ?? [];
    if (cuacaList.isEmpty || cuacaList[0].isEmpty) return null;
    return cuacaList[0][0]['weather'] as int?;
  }

  String _getWeatherDesc(int? code) {
    if (code == null) return 'Unknown';
    if (code == 0) return 'Sunny';
    if (code == 1) return 'Mostly Clear';
    if (code == 2) return 'Partly Cloudy';
    if (code == 3) return 'Cloudy';
    if (code >= 60 && code <= 63) return 'Rainy';
    if (code >= 95 && code <= 97) return 'Thunderstorm';
    return 'Cloudy';
  }

  Future<void> _manualRefresh() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadAllData();
  }

  Future<void> _logout() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: errorColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from admin account?',
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                elevation: 2,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (!confirm) return;

    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  // Navigation handling
  final List<Widget> _pages = [
    const SizedBox(),
    const UsersPage(),
    const SensorDetailPage(sensorName: 'dht_temp', displayName: 'Temperature'),
    const AnalyticsPage(),
    const MessagesPage(),
    const SettingsPage(),
    const LogsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && !hasError) {
      return const SplashScreen();
    }

    if (hasError && !isLoading) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _selectedIndex == 0 ? _buildHomePage() : _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: List.generate(5, (index) {
              bool isSelected = _selectedIndex == index;
              String label = _getNavLabel(index);
              IconData icon = _getNavIcon(index);
              
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onItemTapped(index),
                    highlightColor: primaryColor.withOpacity(0.1),
                    splashColor: primaryColor.withOpacity(0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: isSelected
                              ? BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                )
                              : null,
                          child: Icon(
                            icon,
                            color: isSelected ? Colors.white : textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? primaryColor : textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _getNavLabel(int index) {
    switch (index) {
      case 0: return 'Home';
      case 1: return 'Users';
      case 2: return 'Sensors';
      case 3: return 'Analytics';
      case 4: return 'Messages';
      default: return '';
    }
  }

  IconData _getNavIcon(int index) {
    switch (index) {
      case 0: return Icons.home_rounded;
      case 1: return Icons.people_rounded;
      case 2: return Icons.sensors_rounded;
      case 3: return Icons.analytics_rounded;
      case 4: return Icons.message_rounded;
      default: return Icons.home_rounded;
    }
  }

  Widget _buildHomePage() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: primaryColor,
          expandedHeight: 160,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HydroGrow',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Admin Dashboard',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _manualRefresh,
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              Stack(
                                children: [
                                  IconButton(
                                    onPressed: () => _onItemTapped(4),
                                    icon: Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  if (totalMessages > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: errorColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Center(
                                          child: Text(
                                            totalMessages > 9 ? '9+' : totalMessages.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getSystemStatusColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getSystemStatus(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${_getTotalSensors()} sensors • $activeUsers users',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _statCard(
                Icons.people_rounded,
                "Active Users",
                activeUsers.toString(),
                color: accentColor,
              ),
              _statCard(
                Icons.sensors_rounded,
                "Total Sensors",
                _getTotalSensors().toString(),
                color: successColor,
              ),
              _statCard(
                Icons.message_rounded,
                "Messages",
                totalMessages.toString(),
                color: warningColor,
              ),
              _statCard(
                Icons.wifi_tethering_rounded,
                "System Status",
                _getSystemStatus(),
                color: _getSystemStatusColor(),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Weather Section
          _buildWeatherSection(),

          const SizedBox(height: 32),

          // Live Sensor Data
          _buildSectionTitle("Live Sensor Data"),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _sensorCard(
                "Temperature",
                "${temperature.toStringAsFixed(1)}°C",
                Icons.thermostat_rounded,
                Colors.red,
              ),
              _sensorCard(
                "Humidity",
                "${humidity.toStringAsFixed(1)}%",
                Icons.water_drop_rounded,
                Colors.blue,
              ),
              _sensorCard(
                "Light",
                "${lightIntensity.toStringAsFixed(0)} Lux",
                Icons.wb_sunny_rounded,
                Colors.orange,
              ),
              _sensorCard(
                "Water Level",
                "${waterLevel.toStringAsFixed(0)}%",
                Icons.waves_rounded,
                accentColor,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Quick Actions
          _buildSectionTitle("Quick Actions"),
          const SizedBox(height: 16),
          Column(
            children: [
              _actionTile(
                icon: Icons.people_outline_rounded,
                title: "User Management",
                subtitle: "Manage system users & permissions",
                color: primaryColor,
                onTap: () => _onItemTapped(1),
              ),
              const SizedBox(height: 12),
              _actionTile(
                icon: Icons.sensors_rounded,
                title: "Sensor Dashboard",
                subtitle: "Detailed sensor analytics",
                color: successColor,
                badgeCount: _getTotalSensors(),
                onTap: () => _onItemTapped(2),
              ),
              const SizedBox(height: 12),
              _actionTile(
                icon: Icons.analytics_rounded,
                title: "Analytics Center",
                subtitle: "Performance reports & insights",
                color: accentColor,
                onTap: () => _onItemTapped(3),
              ),
              const SizedBox(height: 12),
              _actionTile(
                icon: Icons.settings_rounded,
                title: "System Settings",
                subtitle: "Configure system parameters",
                color: warningColor,
                onTap: () => _onItemTapped(5),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // System Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "System Information",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Last updated: ${_getLastUpdateTime()}",
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'LOGOUT',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _statCard(IconData icon, String title, String value, {required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: weatherLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
                const SizedBox(width: 12),
                Text(
                  'Loading weather...',
                  style: TextStyle(color: textSecondary),
                ),
              ],
            )
          : weatherData != null
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cloud_rounded,
                        color: accentColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCity,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getWeatherDesc(_getCurrentWeatherCode()),
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${weatherData!['data'][0]['cuaca'][0][0]['t'] ?? '--'}°',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Celsius',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, color: textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Weather unavailable',
                      style: TextStyle(color: textSecondary),
                    ),
                  ],
                ),
    );
  }

  Widget _sensorCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Icon(icon, color: color, size: 22),
                    if (badgeCount != null && badgeCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: errorColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: cardColor, width: 2),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              badgeCount > 9 ? '9+' : badgeCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [errorColor, warningColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: _manualRefresh,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: primaryColor),
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
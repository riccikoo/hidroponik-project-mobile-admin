import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../services/shared.dart';
import '../models/sensor_model.dart';
import 'package:intl/intl.dart';

class SensorDetailPage extends StatefulWidget {
  final String sensorName;
  final String displayName;

  const SensorDetailPage({
    super.key,
    required this.sensorName,
    required this.displayName,
  });

  @override
  State<SensorDetailPage> createState() => _SensorDetailPageState();
}

class _SensorDetailPageState extends State<SensorDetailPage> {
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

  List<SensorData> sensorHistory = [];
  bool isLoading = true;
  Timer? _refreshTimer;
  String selectedTimeRange = '24h'; // 24h, 7d, 30d
  Map<String, dynamic> sensorStats = {};
  double currentValue = 0.0;
  bool isOnline = true;

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
    await _loadSensorData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadSensorData();
    });
  }

  Future<void> _loadSensorData() async {
    if (_token == null) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/admin/sensor-data?sensor=${widget.sensorName}&hours=${_getHoursFromRange()}&limit=100',
        ),
        headers: {
          'Authorization': 'Bearer $_token',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
      );

      print('Sensor data response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final List<SensorData> history = (data['data'] as List)
              .map((e) => SensorData.fromJson(e))
              .toList();

          setState(() {
            sensorHistory = history;
            if (history.isNotEmpty) {
              currentValue = history.first.value;
              _calculateStats();
            }
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading sensor data: $e');
    }

    // Fallback dummy data
    _useDummyData();
  }

  void _useDummyData() {
    final now = DateTime.now();
    final List<SensorData> dummyData = [];

    double baseValue = _getBaseValueForSensor();

    for (int i = 0; i < 50; i++) {
      final time = now.subtract(Duration(minutes: i * 10));
      final variation = (i % 10) - 5.0;
      final value = baseValue + variation;

      dummyData.add(
        SensorData(
          sensorName: widget.sensorName,
          value: value > 0 ? value : 0.1,
          timestamp: time,
        ),
      );
    }

    setState(() {
      sensorHistory = dummyData;
      currentValue = dummyData.isNotEmpty ? dummyData.first.value : 0.0;
      _calculateStats();
      isLoading = false;
    });
  }

  double _getBaseValueForSensor() {
    switch (widget.sensorName) {
      case 'dht_temp':
        return 25.0;
      case 'dht_humid':
        return 65.0;
      case 'ph':
        return 6.8;
      case 'ec':
        return 1.5;
      case 'ldr':
        return 500.0;
      case 'ultrasonic':
        return 75.0;
      default:
        return 50.0;
    }
  }

  int _getHoursFromRange() {
    switch (selectedTimeRange) {
      case '24h':
        return 24;
      case '7d':
        return 168; // 24 * 7
      case '30d':
        return 720; // 24 * 30
      default:
        return 24;
    }
  }

  void _calculateStats() {
    if (sensorHistory.isEmpty) {
      sensorStats = {
        'min': 0.0,
        'max': 0.0,
        'avg': 0.0,
        'latest': 0.0,
        'trend': 'stable',
      };
      return;
    }

    final values = sensorHistory.map((e) => e.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final latest = sensorHistory.first.value;

    String trend = 'stable';
    if (sensorHistory.length >= 3) {
      final recentAvg =
          sensorHistory.take(3).map((e) => e.value).reduce((a, b) => a + b) / 3;
      final olderAvg =
          sensorHistory
              .skip(3)
              .take(3)
              .map((e) => e.value)
              .reduce((a, b) => a + b) /
          3;

      if (recentAvg > olderAvg + 0.5) trend = 'rising';
      if (recentAvg < olderAvg - 0.5) trend = 'falling';
    }

    final lastUpdate = sensorHistory.first.timestamp;
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    isOnline = lastUpdate.isAfter(fiveMinutesAgo);

    setState(() {
      sensorStats = {
        'min': min,
        'max': max,
        'avg': avg,
        'latest': latest,
        'trend': trend,
      };
    });
  }

  Color _getValueColor(double value) {
    switch (widget.sensorName) {
      case 'dht_temp':
        if (value > 30) return errorColor;
        if (value < 20) return accentColor;
        return successColor;
      case 'dht_humid':
        if (value > 80) return warningColor;
        if (value < 40) return warningColor;
        return successColor;
      case 'ph':
        if (value < 6.0 || value > 7.5) return errorColor;
        return successColor;
      case 'ec':
        if (value < 1.0 || value > 2.0) return warningColor;
        return successColor;
      case 'ultrasonic':
        if (value < 20) return errorColor;
        if (value < 50) return warningColor;
        return successColor;
      default:
        return primaryColor;
    }
  }

  String _getUnit() {
    switch (widget.sensorName) {
      case 'dht_temp':
        return '°C';
      case 'dht_humid':
        return '%';
      case 'ph':
        return 'pH';
      case 'ec':
        return 'mS/cm';
      case 'ldr':
        return 'Lux';
      case 'ultrasonic':
        return '%';
      default:
        return 'unit';
    }
  }

  String _getOptimalRange() {
    switch (widget.sensorName) {
      case 'dht_temp':
        return '20-30°C';
      case 'dht_humid':
        return '40-80%';
      case 'ph':
        return '6.0-7.5';
      case 'ec':
        return '1.0-2.0 mS/cm';
      case 'ldr':
        return '>300 Lux';
      case 'ultrasonic':
        return '>50%';
      default:
        return 'N/A';
    }
  }

  bool _isValueOptimal(double value) {
    switch (widget.sensorName) {
      case 'dht_temp':
        return value >= 20 && value <= 30;
      case 'dht_humid':
        return value >= 40 && value <= 80;
      case 'ph':
        return value >= 6.0 && value <= 7.5;
      case 'ec':
        return value >= 1.0 && value <= 2.0;
      case 'ldr':
        return value > 300;
      case 'ultrasonic':
        return value > 50;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.displayName,
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, color: primaryColor),
              onPressed: _loadSensorData,
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading sensor data...',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Current Value Card
                  _buildCurrentValueCard(),
                  const SizedBox(height: 24),

                  // Time Range Selector
                  _buildTimeRangeSelector(),
                  const SizedBox(height: 24),

                  // Stats Grid
                  _buildStatsGrid(),
                  const SizedBox(height: 32),

                  // Chart Section
                  Container(
                    padding: const EdgeInsets.all(20),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Historical Data',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                '${sensorHistory.length} readings',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: _buildChart(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Recent Readings Table
                  Container(
                    padding: const EdgeInsets.all(20),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Readings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: primaryColor.withOpacity(0.2)),
                              ),
                              child: Text(
                                'Last 10 readings',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ..._buildRecentReadings(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sensor Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withOpacity(0.1)),
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
                            _getSensorIcon(),
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
                                'Sensor Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Optimal range: ${_getOptimalRange()} • Unit: ${_getUnit()}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentValueCard() {
    final isOptimal = _isValueOptimal(currentValue);
    final valueColor = _getValueColor(currentValue);

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current Reading',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOnline
                      ? successColor.withOpacity(0.1)
                      : errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline
                        ? successColor.withOpacity(0.2)
                        : errorColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? successColor : errorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 13,
                        color: isOnline ? successColor : errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${currentValue.toStringAsFixed(widget.sensorName == 'ph' || widget.sensorName == 'ec' ? 2 : 1)}${_getUnit()}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: valueColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isOptimal
                            ? successColor.withOpacity(0.1)
                            : warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOptimal
                              ? successColor.withOpacity(0.2)
                              : warningColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOptimal
                                ? Icons.check_circle_rounded
                                : Icons.warning_rounded,
                            size: 16,
                            color: isOptimal ? successColor : warningColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOptimal ? 'Optimal' : 'Needs Attention',
                            style: TextStyle(
                              fontSize: 14,
                              color: isOptimal ? successColor : warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: valueColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getSensorIcon(),
                    size: 40,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Optimal range: ${_getOptimalRange()}',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'Time Range',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _timeRangeButton('24h'),
              _timeRangeButton('7d'),
              _timeRangeButton('30d'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeRangeButton(String range) {
    final isSelected = selectedTimeRange == range;

    return GestureDetector(
      onTap: () {
        setState(() => selectedTimeRange = range);
        _loadSensorData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
          ),
        ),
        child: Text(
          range,
          style: TextStyle(
            color: isSelected ? Colors.white : textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _statCard(
          title: 'Minimum',
          value: sensorStats['min']?.toStringAsFixed(1) ?? '0.0',
          unit: _getUnit(),
          icon: Icons.arrow_downward_rounded,
          color: accentColor,
        ),
        _statCard(
          title: 'Maximum',
          value: sensorStats['max']?.toStringAsFixed(1) ?? '0.0',
          unit: _getUnit(),
          icon: Icons.arrow_upward_rounded,
          color: errorColor,
        ),
        _statCard(
          title: 'Average',
          value: sensorStats['avg']?.toStringAsFixed(1) ?? '0.0',
          unit: _getUnit(),
          icon: Icons.timeline_rounded,
          color: primaryColor,
        ),
        _statCard(
          title: 'Trend',
          value: sensorStats['trend'] ?? 'stable',
          unit: '',
          icon: _getTrendIcon(),
          color: _getTrendColor(),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (sensorHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No data available',
              style: TextStyle(
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final spots = sensorHistory
        .asMap()
        .map((i, data) => MapEntry(i, FlSpot(i.toDouble(), data.value)))
        .values
        .toList()
        .reversed
        .toList();

    final valueColor = _getValueColor(currentValue);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: borderColor,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == spots.length - 1) {
                  final index = value.toInt();
                  if (index < sensorHistory.length) {
                    final time = sensorHistory[index].timestamp;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${value.toInt()}${_getUnit()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        minX: 0,
        maxX: spots.length > 1 ? spots.length - 1 : 1,
        minY: (sensorStats['min'] ?? 0) * 0.9,
        maxY: (sensorStats['max'] ?? 1) * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: valueColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: valueColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentReadings() {
    final recentReadings = sensorHistory.take(10).toList();

    return recentReadings.map((data) {
      final isOptimal = _isValueOptimal(data.value);
      final valueColor = _getValueColor(data.value);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: valueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getSensorIcon(),
                size: 20,
                color: valueColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(data.timestamp),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd').format(data.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${data.value.toStringAsFixed(widget.sensorName == 'ph' || widget.sensorName == 'ec' ? 2 : 1)}${_getUnit()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: valueColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOptimal
                              ? successColor.withOpacity(0.1)
                              : warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isOptimal
                                ? successColor.withOpacity(0.2)
                                : warningColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          isOptimal ? 'Optimal' : 'Check',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOptimal ? successColor : warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  IconData _getSensorIcon() {
    switch (widget.sensorName) {
      case 'dht_temp':
        return Icons.thermostat_rounded;
      case 'dht_humid':
        return Icons.water_drop_rounded;
      case 'ph':
        return Icons.science_rounded;
      case 'ec':
        return Icons.bolt_rounded;
      case 'ldr':
        return Icons.light_mode_rounded;
      case 'ultrasonic':
        return Icons.waves_rounded;
      default:
        return Icons.sensors_rounded;
    }
  }

  IconData _getTrendIcon() {
    final trend = sensorStats['trend'] ?? 'stable';
    switch (trend) {
      case 'rising':
        return Icons.trending_up_rounded;
      case 'falling':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  Color _getTrendColor() {
    final trend = sensorStats['trend'] ?? 'stable';
    switch (trend) {
      case 'rising':
        return successColor;
      case 'falling':
        return warningColor;
      default:
        return primaryColor;
    }
  }
}
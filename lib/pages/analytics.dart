import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/shared.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // Modern Color Palette (sama dengan halaman lain)
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

  // Analytics data
  Map<String, dynamic> analyticsData = {};
  bool isLoading = true;
  String selectedPeriod = 'week'; // day, week, month, year
  String selectedMetric = 'overview'; // overview, sensors, users, system

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _token = await SharedService.getToken();
    await _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/analytics?period=$selectedPeriod'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            analyticsData = data['data'];
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading analytics: $e');
    }

    // Fallback dummy data
    _useDummyData();
  }

  void _useDummyData() {
    setState(() {
      analyticsData = {
        'overview': {
          'total_readings': 12560,
          'avg_temperature': 26.5,
          'avg_humidity': 68.2,
          'system_uptime': 99.8,
          'alerts_count': 12,
          'growth_rate': '+2.3%',
        },
        'sensors': {
          'temperature': {
            'avg': 26.5,
            'min': 22.1,
            'max': 31.2,
            'trend': 'stable',
            'data': [24.5, 25.2, 26.8, 27.1, 26.3, 25.9, 26.5],
          },
          'humidity': {
            'avg': 68.2,
            'min': 58.4,
            'max': 78.9,
            'trend': 'rising',
            'data': [65.2, 66.8, 67.1, 68.4, 69.2, 68.8, 68.2],
          },
          'ph': {
            'avg': 6.8,
            'min': 6.2,
            'max': 7.1,
            'trend': 'stable',
            'data': [6.7, 6.8, 6.9, 6.8, 6.7, 6.8, 6.8],
          },
          'light': {
            'avg': 520.5,
            'min': 210.2,
            'max': 850.3,
            'trend': 'rising',
            'data': [480.2, 520.1, 510.8, 525.3, 530.6, 515.2, 520.5],
          },
        },
        'users': {
          'total': 3,
          'active': 2,
          'new_this_week': 1,
          'avg_session': '12m 30s',
          'activity_trend': [5, 8, 12, 10, 15, 18, 20],
        },
        'system': {
          'uptime': '99.8%',
          'avg_response': '145ms',
          'error_rate': '0.2%',
          'data_volume': '2.5GB',
          'performance_trend': [95, 96, 98, 99, 99, 99.5, 99.8],
        },
        'alerts': [
          {
            'type': 'warning',
            'message': 'High temperature detected',
            'time': '2 hours ago',
            'sensor': 'dht_temp',
          },
          {
            'type': 'info',
            'message': 'System backup completed',
            'time': '5 hours ago',
            'source': 'system',
          },
          {
            'type': 'error',
            'message': 'Database connection timeout',
            'time': '1 day ago',
            'source': 'database',
          },
        ],
      };
      isLoading = false;
    });
  }

  Widget _buildOverview() {
    final overview = analyticsData['overview'] ?? {};

    return Column(
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
            _metricCard(
              title: 'Total Readings',
              value: '${overview['total_readings'] ?? 0}',
              subtitle: 'Sensor data points',
              icon: Icons.data_usage,
              color: accentColor,
              trend: '+12%',
            ),
            _metricCard(
              title: 'Avg Temperature',
              value:
                  '${overview['avg_temperature']?.toStringAsFixed(1) ?? '0.0'}°C',
              subtitle: 'Optimal range',
              icon: Icons.thermostat,
              color: errorColor,
              trend: 'stable',
            ),
            _metricCard(
              title: 'Avg Humidity',
              value:
                  '${overview['avg_humidity']?.toStringAsFixed(1) ?? '0.0'}%',
              subtitle: 'Within range',
              icon: Icons.water_drop,
              color: primaryColor,
              trend: '+2%',
            ),
            _metricCard(
              title: 'System Uptime',
              value:
                  '${overview['system_uptime']?.toStringAsFixed(1) ?? '0.0'}%',
              subtitle: 'Last 7 days',
              icon: Icons.timeline,
              color: successColor,
              trend: '99.9%',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Growth Chart
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Growth Analysis',
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
                      color: successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: successColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      overview['growth_rate'] ?? '+0.0%',
                      style: TextStyle(
                        color: successColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 3),
                          FlSpot(1, 5),
                          FlSpot(2, 8),
                          FlSpot(3, 12),
                          FlSpot(4, 15),
                          FlSpot(5, 18),
                          FlSpot(6, 22),
                        ],
                        isCurved: true,
                        color: primaryColor,
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          color: primaryColor.withOpacity(0.1),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorAnalytics() {
    final sensors = analyticsData['sensors'] ?? {};

    return Column(
      children: [
        // Sensor Performance Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _sensorMetric(
              name: 'Temperature',
              data: sensors['temperature'] ?? {},
              unit: '°C',
              color: errorColor,
            ),
            _sensorMetric(
              name: 'Humidity',
              data: sensors['humidity'] ?? {},
              unit: '%',
              color: primaryColor,
            ),
            _sensorMetric(
              name: 'pH Level',
              data: sensors['ph'] ?? {},
              unit: 'pH',
              color: successColor,
            ),
            _sensorMetric(
              name: 'Light',
              data: sensors['light'] ?? {},
              unit: 'Lux',
              color: warningColor,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Sensor Comparison Chart
        Container(
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
              Text(
                'Sensor Performance Comparison',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: 85,
                            color: errorColor,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                        showingTooltipIndicators: [0],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: 92,
                            color: primaryColor,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                        showingTooltipIndicators: [0],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: 78,
                            color: successColor,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                        showingTooltipIndicators: [0],
                      ),
                      BarChartGroupData(
                        x: 3,
                        barRods: [
                          BarChartRodData(
                            toY: 95,
                            color: warningColor,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                        showingTooltipIndicators: [0],
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const labels = ['Temp', 'Humid', 'pH', 'Light'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[value.toInt()],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            );
                          },
                          interval: 25,
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: borderColor,
                          strokeWidth: 1,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserAnalytics() {
    final users = analyticsData['users'] ?? {};
    final activityTrend = List<int>.from(users['activity_trend'] ?? [1, 2, 3]);

    return Column(
      children: [
        // User Stats
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _userStat(
                    'Total Users',
                    users['total']?.toString() ?? '0',
                    Icons.people,
                  ),
                  _userStat(
                    'Active',
                    users['active']?.toString() ?? '0',
                    Icons.check_circle,
                  ),
                  _userStat(
                    'New',
                    users['new_this_week']?.toString() ?? '0',
                    Icons.person_add,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: borderColor),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Avg Session Duration',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    users['avg_session'] ?? '0m',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // User Activity Chart
        Container(
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
              Text(
                'User Activity Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: borderColor,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            return value.toInt() < days.length
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      days[value.toInt()],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  )
                                : const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
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
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: activityTrend.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value.toDouble(),
                          );
                        }).toList(),
                        isCurved: true,
                        color: secondaryColor,
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          color: secondaryColor.withOpacity(0.1),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemAnalytics() {
    final system = analyticsData['system'] ?? {};

    return Column(
      children: [
        // System Performance
        Container(
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
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _systemMetric(
                    'Uptime',
                    system['uptime'] ?? '0%',
                    Icons.timeline,
                    successColor,
                  ),
                  _systemMetric(
                    'Avg Response',
                    system['avg_response'] ?? '0ms',
                    Icons.speed,
                    primaryColor,
                  ),
                  _systemMetric(
                    'Error Rate',
                    system['error_rate'] ?? '0%',
                    Icons.error,
                    errorColor,
                  ),
                  _systemMetric(
                    'Data Volume',
                    system['data_volume'] ?? '0GB',
                    Icons.storage,
                    accentColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: borderColor),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Performance Score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [successColor, Colors.green],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'A+',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Alerts List
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Alerts',
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
                      color: warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: warningColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      '${(analyticsData['alerts'] ?? []).length} alerts',
                      style: TextStyle(
                        color: warningColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._buildAlertsList(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAlertsList() {
    final alerts = List<Map<String, dynamic>>.from(
      analyticsData['alerts'] ?? [],
    );

    if (alerts.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: successColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No alerts in selected period',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Everything is running smoothly',
                style: TextStyle(
                  color: textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return alerts.take(5).map((alert) {
      final type = alert['type'] ?? 'info';
      Color color;
      IconData icon;

      switch (type) {
        case 'error':
          color = errorColor;
          icon = Icons.error_outline_rounded;
          break;
        case 'warning':
          color = warningColor;
          icon = Icons.warning_amber_rounded;
          break;
        default:
          color = primaryColor;
          icon = Icons.info_outline_rounded;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert['message'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (alert['sensor'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            alert['sensor'],
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (alert['source'] != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            alert['source'],
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        alert['time'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
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

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trend.contains('+')
                        ? successColor.withOpacity(0.1)
                        : trend.contains('-')
                        ? errorColor.withOpacity(0.1)
                        : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: trend.contains('+')
                          ? successColor.withOpacity(0.2)
                          : trend.contains('-')
                          ? errorColor.withOpacity(0.2)
                          : primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        trend.contains('+')
                            ? Icons.trending_up_rounded
                            : trend.contains('-')
                            ? Icons.trending_down_rounded
                            : Icons.trending_flat_rounded,
                        size: 12,
                        color: trend.contains('+')
                            ? successColor
                            : trend.contains('-')
                            ? errorColor
                            : primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 12,
                          color: trend.contains('+')
                              ? successColor
                              : trend.contains('-')
                              ? errorColor
                              : primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sensorMetric({
    required String name,
    required Map<String, dynamic> data,
    required String unit,
    required Color color,
  }) {
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSensorIcon(name),
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${data['avg']?.toStringAsFixed(1) ?? '0.0'}$unit',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Min',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['min']?.toStringAsFixed(1) ?? '0.0'}$unit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Max',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['max']?.toStringAsFixed(1) ?? '0.0'}$unit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trend',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTrendColor(
                          data['trend'] ?? 'stable',
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getTrendColor(
                            data['trend'] ?? 'stable',
                          ).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getTrendIcon(data['trend'] ?? 'stable'),
                            size: 12,
                            color: _getTrendColor(data['trend'] ?? 'stable'),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['trend'] ?? 'stable',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getTrendColor(data['trend'] ?? 'stable'),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _userStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _systemMetric(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSensorIcon(String sensorName) {
    switch (sensorName.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'ph level':
        return Icons.science;
      case 'light':
        return Icons.wb_sunny;
      default:
        return Icons.sensors;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'rising':
        return Icons.trending_up_rounded;
      case 'falling':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'rising':
        return successColor;
      case 'falling':
        return errorColor;
      default:
        return primaryColor;
    }
  }

  Widget _periodSelector() {
    const periods = [
      {'label': 'Today', 'value': 'day'},
      {'label': 'Week', 'value': 'week'},
      {'label': 'Month', 'value': 'month'},
      {'label': 'Year', 'value': 'year'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((period) {
          final isSelected = selectedPeriod == period['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => selectedPeriod = period['value']!);
                  _loadAnalyticsData();
                }
              },
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : textPrimary,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _metricSelector() {
    const metrics = [
      {'label': 'Overview', 'value': 'overview', 'icon': Icons.dashboard},
      {'label': 'Sensors', 'value': 'sensors', 'icon': Icons.sensors},
      {'label': 'Users', 'value': 'users', 'icon': Icons.people},
      {'label': 'System', 'value': 'system', 'icon': Icons.computer},
    ];

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: metrics.map((metric) {
          final isSelected = selectedMetric == metric['value'];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => selectedMetric = metric['value']! as String);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      metric['icon'] as IconData,
                      size: 20,
                      color: isSelected ? Colors.white : textSecondary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      metric['label']! as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Analytics Dashboard',
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
          IconButton(
            icon: Icon(Icons.download_rounded, color: primaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Export functionality coming soon',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            tooltip: 'Export',
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh',
          ),
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
                    'Loading analytics...',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  Text(
                    'Select Period',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _periodSelector(),
                  const SizedBox(height: 24),

                  // Metric Selector
                  _metricSelector(),
                  const SizedBox(height: 24),

                  // Selected Content
                  if (selectedMetric == 'overview') _buildOverview(),
                  if (selectedMetric == 'sensors') _buildSensorAnalytics(),
                  if (selectedMetric == 'users') _buildUserAnalytics(),
                  if (selectedMetric == 'system') _buildSystemAnalytics(),

                  const SizedBox(height: 32),

                  // Summary Card
                  Container(
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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.insights_rounded,
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
                                'Analytics Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last updated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: Colors.white,
                                size: 8,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Live',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
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
}
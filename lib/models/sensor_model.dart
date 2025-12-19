class SensorData {
  final String sensorName;
  final double value;
  final DateTime timestamp;

  SensorData({
    required this.sensorName,
    required this.value,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      sensorName: json['sensor_name'],
      value: double.parse(json['value'].toString()),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

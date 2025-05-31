// models/performance_point.dart
class PerformancePoint {
  final DateTime date;
  final double value;

  PerformancePoint({
    required this.date,
    required this.value,
  });

  // Optional: If JSON serialization is needed directly from this model elsewhere
  factory PerformancePoint.fromJson(Map<String, dynamic> json) {
    return PerformancePoint(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
    };
  }
}

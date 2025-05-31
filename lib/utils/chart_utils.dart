import 'package:intl/intl.dart'; // For date formatting, if needed for more complex scenarios
import '../models/performance_point.dart'; // Import the common PerformancePoint

/// Formats the date to be displayed on the chart's bottom axis.
///
/// Adjusts the format based on the selected timeframe to avoid clutter.
String getChartDateLabel(DateTime date, String selectedTimeframe) {
  switch (selectedTimeframe) {
    case '1W':
      return DateFormat('E').format(date); // e.g., Mon
    case '1M':
    case '3M':
      return DateFormat('d MMM').format(date); // e.g., 15 Jan
    case '6M':
    case '1Y':
      return DateFormat('MMM yy').format(date); // e.g., Jan 23
    case 'All':
      return DateFormat('yyyy').format(date); // e.g., 2023
    default:
      return DateFormat('d MMM').format(date);
  }
}

/// Normalizes a list of [PerformancePoint] data to start at a common baseline (e.g., 100%).
///
/// This is useful for comparing relative performance.
/// Returns a new list of [PerformancePoint] with normalized values.
/// If the input data is empty or the first value is zero or less, returns the original data or an empty list.
List<PerformancePoint> normalizePerformanceDataToHundred(List<PerformancePoint> data) {
  if (data.isEmpty) {
    return [];
  }

  final double baseValue = data.first.value;
  if (baseValue <= 0) {
    // Cannot normalize if base value is zero or negative, return as is or empty
    // depending on desired behavior. Returning a copy with original values for now.
    return List<PerformancePoint>.from(data.map((p) => PerformancePoint(date: p.date, value: p.value)));
  }

  return data.map((point) {
    return PerformancePoint(
      date: point.date,
      value: (point.value / baseValue) * 100,
    );
  }).toList();
}

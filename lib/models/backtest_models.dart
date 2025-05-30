// models/backtest_models.dart
import 'dart:convert';

class BacktestStrategy {
  final String? id; // MongoDB ObjectId (null for new strategies)
  final String name;
  final String description;
  final List<dynamic> indicators; // Technical indicators used
  final List<Map<String, dynamic>> buyConditions;
  final List<Map<String, dynamic>> sellConditions;
  final Map<String, dynamic>? performance; // Null for new strategies
  final String?
      notes; // Optional notes field added for specific strategy information

  BacktestStrategy({
    this.id,
    required this.name,
    required this.description,
    required this.indicators,
    required this.buyConditions,
    required this.sellConditions,
    this.performance,
    this.notes,
  });

  // MongoDB integration: Handle ObjectId correctly
  factory BacktestStrategy.fromJson(Map<String, dynamic> json) {
    String? id;

    // Handle MongoDB's _id object
    if (json.containsKey('_id') && json['_id'] != null) {
      if (json['_id'] is Map && json['_id'].containsKey('\$oid')) {
        id = json['_id']['\$oid'];
      } else {
        id = json['_id'].toString();
      }
    }

    // Handle indicators format - ensure it's a List of Maps or strings
    List<dynamic> indicators = [];
    if (json.containsKey('indicators')) {
      if (json['indicators'] is List) {
        indicators = json['indicators'];
      }
    }

    // Handle conditions - ensure they're Lists of Maps using helper method
    List<Map<String, dynamic>> buyConditions =
        _parseConditions(json['buy_conditions']);
    List<Map<String, dynamic>> sellConditions =
        _parseConditions(json['sell_conditions']);

    return BacktestStrategy(
      id: id,
      name: json['name'] ?? 'Unnamed Strategy',
      description: json['description'] ?? '',
      indicators: indicators,
      buyConditions: buyConditions,
      sellConditions: sellConditions,
      performance: json['performance'],
      notes: json['notes'],
    );
  }

  // Helper method to safely parse conditions from JSON
  static List<Map<String, dynamic>> _parseConditions(dynamic conditionsJson) {
    if (conditionsJson == null) return [];

    try {
      if (conditionsJson is List) {
        return List<Map<String, dynamic>>.from(conditionsJson.map((condition) =>
            condition is Map<String, dynamic>
                ? condition
                : Map<String, dynamic>.from(condition)));
      }
    } catch (e) {
      print('Error parsing conditions: $e');
    }

    return [];
  }

  Map<String, dynamic> toJson() {
    // Ensure data is correctly formatted before sending
    final Map<String, dynamic> result = {
      'name': name,
      'description': description,
      'indicators': indicators,
      'buy_conditions': buyConditions,
      'sell_conditions': sellConditions,
      // Don't send performance, this is calculated server-side
    };

    // Add ID if present (for updates)
    if (id != null) {
      result['id'] = id;
    }

    // Add notes if present
    if (notes != null) {
      result['notes'] = notes;
    }

    // Debug: test the JSON is valid
    try {
      // Test if the object can be properly serialized
      final jsonString = json.encode(result);
      final decodedBack = json.decode(jsonString);

      // If two-way conversion works, the data is compatible
      print('Strategy JSON conversion successful: ${name}');
    } catch (e) {
      print('WARNING: Strategy JSON conversion error: $e');
    }

    return result;
  }

  // Deep copy helper
  BacktestStrategy copyWith({
    String? id,
    String? name,
    String? description,
    List<dynamic>? indicators,
    List<Map<String, dynamic>>? buyConditions,
    List<Map<String, dynamic>>? sellConditions,
    Map<String, dynamic>? performance,
    String? notes,
  }) {
    return BacktestStrategy(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      indicators: indicators ?? List.from(this.indicators),
      buyConditions: buyConditions ?? List.from(this.buyConditions),
      sellConditions: sellConditions ?? List.from(this.sellConditions),
      performance: performance ?? this.performance,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'BacktestStrategy(name: $name, indicators: ${indicators.length}, buyConditions: ${buyConditions.length}, sellConditions: ${sellConditions.length})';
  }
}

class BacktestResult {
  final Map<String, dynamic> performanceMetrics;
  final List<Map<String, dynamic>> equityCurve;
  final List<Map<String, dynamic>> tradeHistory;

  BacktestResult({
    required this.performanceMetrics,
    required this.equityCurve,
    required this.tradeHistory,
  });

  factory BacktestResult.fromJson(Map<String, dynamic> json) {
    // Handle various possible field names for metrics
    Map<String, dynamic> metrics = {};
    if (json.containsKey('metrics') && json['metrics'] is Map) {
      metrics =
          _processSpecialValues(Map<String, dynamic>.from(json['metrics']));
    } else if (json.containsKey('performance_metrics') &&
        json['performance_metrics'] is Map) {
      metrics = _processSpecialValues(
          Map<String, dynamic>.from(json['performance_metrics']));
    }

    // Handle equity curve with both camelCase and snake_case keys
    List<Map<String, dynamic>> equityCurve = [];
    if (json.containsKey('equityCurve') && json['equityCurve'] is List) {
      equityCurve = List<Map<String, dynamic>>.from(json['equityCurve'].map(
          (e) =>
              e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}));
    } else if (json.containsKey('equity_curve') &&
        json['equity_curve'] is List) {
      equityCurve = List<Map<String, dynamic>>.from(json['equity_curve'].map(
          (e) =>
              e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}));
    }

    // Handle trade history with both camelCase and snake_case keys
    List<Map<String, dynamic>> tradeHistory = [];
    if (json.containsKey('tradeHistory') && json['tradeHistory'] is List) {
      tradeHistory = List<Map<String, dynamic>>.from(json['tradeHistory'].map(
          (e) =>
              e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}));
    } else if (json.containsKey('trade_history') &&
        json['trade_history'] is List) {
      tradeHistory = List<Map<String, dynamic>>.from(json['trade_history'].map(
          (e) =>
              e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}));
    }

    return BacktestResult(
      performanceMetrics: metrics,
      equityCurve: equityCurve,
      tradeHistory: tradeHistory,
    );
  }

  // Helper to process special values like "Infinity" in metrics
  static Map<String, dynamic> _processSpecialValues(
      Map<String, dynamic> metrics) {
    final result = Map<String, dynamic>.from(metrics);
    // Convert string representations of special values back to their numeric form
    metrics.forEach((key, value) {
      if (value == "Infinity") {
        result[key] = double.infinity;
      } else if (value == "-Infinity") {
        result[key] = double.negativeInfinity;
      } else if (value == "NaN" || value == null) {
        result[key] = 0.0; // Replace NaN with 0 or another sensible default
      }
    });
    return result;
  }

  // Helper to safely get numeric values from metrics
  static double safeGetDouble(
      Map<String, dynamic> metrics, String key, double defaultValue) {
    final value = metrics[key];
    if (value == null) return defaultValue;

    if (value is num) return value.toDouble();
    if (value is String) {
      if (value == "Infinity") return double.infinity;
      if (value == "-Infinity") return double.negativeInfinity;
      if (value == "NaN") return 0.0; // or another default

      try {
        return double.parse(value);
      } catch (_) {
        return defaultValue;
      }
    }

    return defaultValue;
  }

  // Format value for display, handling special cases like Infinity
  static String formatMetricValue(dynamic value, [int decimals = 2]) {
    if (value == null) return '0.0';

    if (value == double.infinity || value == "Infinity") {
      return "∞"; // Infinity symbol
    } else if (value == double.negativeInfinity || value == "-Infinity") {
      return "-∞"; // Negative infinity symbol
    } else if (value == "NaN") {
      return "0.0";
    }

    try {
      if (value is num) {
        return value.toStringAsFixed(decimals);
      } else if (value is String) {
        return double.parse(value).toStringAsFixed(decimals);
      }
    } catch (_) {}

    return value.toString();
  }

  // Convert to JSON - useful for debugging
  Map<String, dynamic> toJson() {
    return {
      'performanceMetrics': performanceMetrics,
      'equityCurve': equityCurve,
      'tradeHistory': tradeHistory,
    };
  }

  // Results summary
  String get summary {
    final totalReturn =
        safeGetDouble(performanceMetrics, 'total_return_pct', 0.0);
    final winRate = safeGetDouble(performanceMetrics, 'win_rate_pct', 0.0);
    final totalTrades = performanceMetrics['total_trades'] ?? 0;

    return 'Total Return: ${formatMetricValue(totalReturn)}%, Win Rate: ${formatMetricValue(winRate)}%, Trades: $totalTrades';
  }
}

class TechnicalIndicator {
  final String abbr; // Abbreviation (MA, RSI, etc.)
  final String name; // Full name
  final List<String> params; // Parameter names
  final Map<String, dynamic> values; // Parameter values

  TechnicalIndicator({
    required this.abbr,
    required this.name,
    required this.params,
    this.values = const {},
  });

  factory TechnicalIndicator.fromJson(Map<String, dynamic> json) {
    return TechnicalIndicator(
      abbr: json['abbr'] ?? '',
      name: json['name'] ?? '',
      params: List<String>.from(json['params'] ?? []),
      values: json['values'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'abbr': abbr,
      'name': name,
      'params': params,
      'values': values,
    };
  }

  // Get a simple representation (e.g., 'MA_50' or 'RSI_14')
  String getSimpleRepresentation() {
    if (values.isEmpty || params.isEmpty) {
      return abbr;
    }

    // Get first parameter value (usually period)
    final firstParam = params.first;
    final firstValue = values[firstParam];

    if (firstValue != null) {
      return '${abbr}_$firstValue';
    }

    return abbr;
  }

  @override
  String toString() {
    return getSimpleRepresentation();
  }
}

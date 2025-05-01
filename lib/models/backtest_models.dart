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

  BacktestStrategy({
    this.id,
    required this.name,
    required this.description,
    required this.indicators,
    required this.buyConditions,
    required this.sellConditions,
    this.performance,
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

    // Handle indicators format - ensure it's a List of Maps
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
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      indicators: indicators,
      buyConditions: buyConditions,
      sellConditions: sellConditions,
      performance: json['performance'],
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
      // performance kısmını göndermeyin, bu sunucu tarafında hesaplanır
    };

    // Debug için JSON'ı konsola yazdır
    try {
      // Objenin geçerli bir JSON olup olmadığını test et
      final jsonString = json.encode(result);
      final decodedBack = json.decode(jsonString);

      // İki taraflı dönüşüm çalışıyorsa, veri uyumlu demektir
      print('Strateji JSON dönüşümü başarılı: ${name}');
    } catch (e) {
      print('UYARI: Strateji JSON dönüşümünde hata: $e');
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
  }) {
    return BacktestStrategy(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      indicators: indicators ?? List.from(this.indicators),
      buyConditions: buyConditions ?? List.from(this.buyConditions),
      sellConditions: sellConditions ?? List.from(this.sellConditions),
      performance: performance ?? this.performance,
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
    // Handle performance metrics
    final Map<String, dynamic> metrics = json['performance_metrics'] ?? {};

    // Handle equity curve - ensure it's a List of Maps
    List<Map<String, dynamic>> equityCurve = [];
    if (json.containsKey('equity_curve') && json['equity_curve'] is List) {
      equityCurve = List<Map<String, dynamic>>.from(json['equity_curve']);
    }

    // Handle trade history - ensure it's a List of Maps
    List<Map<String, dynamic>> tradeHistory = [];
    if (json.containsKey('trade_history') && json['trade_history'] is List) {
      tradeHistory = List<Map<String, dynamic>>.from(json['trade_history']);
    }

    return BacktestResult(
      performanceMetrics: metrics,
      equityCurve: equityCurve,
      tradeHistory: tradeHistory,
    );
  }

  // Sonuçların özeti
  String get summary {
    final totalReturn = performanceMetrics['total_return_pct'] ?? 0.0;
    final winRate = performanceMetrics['win_rate_pct'] ?? 0.0;
    final totalTrades = performanceMetrics['total_trades'] ?? 0;

    return 'Toplam Getiri: ${totalReturn.toStringAsFixed(2)}%, Kazanç Oranı: ${winRate.toStringAsFixed(2)}%, İşlemler: $totalTrades';
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

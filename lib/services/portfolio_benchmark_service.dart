// services/portfolio_benchmark_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/portfolio.dart';
import '../src/config.dart';

/// Service for handling benchmark comparisons for portfolios
class PortfolioBenchmarkService {
  // Base URL for the API
  final String _baseUrl;
  // constructor: eğer baseUrl verilmezse Config.baseUrl kullanılır
  PortfolioBenchmarkService({String? baseUrl})
      : _baseUrl = baseUrl ?? Config.baseUrl;
  static String get baseUrl => Config.baseUrl;

  /// Get benchmark performance data for comparison with portfolio
  /// Benchmarks include major indices like S&P 500, NASDAQ, etc.
  static Future<List<BenchmarkData>> getBenchmarkPerformance(
    String timeframe,
    List<String> benchmarks,
  ) async {
    try {
      // Construct benchmark string for API
      final benchmarksStr = benchmarks.join(',');

      final response = await http.get(
        Uri.parse(
            '$baseUrl/benchmark/performance?timeframe=$timeframe&benchmarks=$benchmarksStr'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          List<dynamic> benchmarkList = jsonData['data'];
          return benchmarkList
              .map((data) => BenchmarkData.fromJson(data))
              .toList();
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to load benchmark data');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for development
      return _getMockBenchmarkData(timeframe, benchmarks);
    }
  }

  static Future<List<BenchmarkData>> getNormalizedBenchmarkPerformance(
    String timeframe,
    List<String> benchmarks,
  ) async {
    try {
      // Construct benchmark string for API
      final benchmarksStr = benchmarks.join(',');

      final response = await http.get(
        Uri.parse(
            '$baseUrl/benchmark/normalized-performance?timeframe=$timeframe&benchmarks=$benchmarksStr'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          List<dynamic> benchmarkList = jsonData['data'];
          return benchmarkList
              .map((data) => BenchmarkData.fromJson(data))
              .toList();
        } else {
          throw Exception(jsonData['message'] ??
              'Failed to load normalized benchmark data');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Return mock normalized data for development
      return _getMockNormalizedBenchmarkData(timeframe, benchmarks);
    }
  }

  /// Generate mock normalized benchmark data (starts at 100%)
  static List<BenchmarkData> _getMockNormalizedBenchmarkData(
    String timeframe,
    List<String> benchmarks,
  ) {
    final List<BenchmarkData> result = [];
    final now = DateTime.now();

    // Number of data points based on timeframe
    int dataPoints = _getDataPointsForTimeframe(timeframe);

    for (String benchmark in benchmarks) {
      // Select return pattern based on benchmark
      bool isPositive =
          benchmark.contains('SP500') || benchmark.contains('NASDAQ');
      bool isVolatile =
          benchmark.contains('CRYPTO') || benchmark.contains('VIX');

      List<PerformancePoint> data = [];
      double value = 100.0; // Starting value (normalized to 100%)

      for (int i = 0; i < dataPoints; i++) {
        // Generate movement with properties matching the benchmark type
        double volatilityFactor = isVolatile ? 2.0 : 1.0;
        double directionBias = isPositive ? 0.15 : -0.05;

        // Realistic movement: smaller percentage changes from 100% baseline
        double movementPercent =
            (directionBias + (0.3 - (i % 7) / 15)) * volatilityFactor;
        value = value * (1 + movementPercent / 100); // Apply percentage change

        // Prevent going too low (below 50% would be extreme)
        if (value < 50) value = 50;

        // Calculate date based on timeframe and point index
        DateTime date = _getDateForDataPoint(now, timeframe, i, dataPoints);

        // Add data point
        data.add(PerformancePoint(
          date: date,
          value: value,
        ));
      }

      // Calculate return as difference from 100%
      double returnPercent = 0.0;
      if (data.isNotEmpty) {
        returnPercent = data.last.value - 100.0; // Convert 105% to +5%
      }

      result.add(BenchmarkData(
        id: benchmark.startsWith('CUSTOM_')
            ? benchmark
            : 'benchmark_$benchmark',
        name: _getBenchmarkName(benchmark),
        symbol: benchmark,
        timeframe: timeframe,
        data: data,
        returnPercent: returnPercent,
      ));
    }

    return result;
  }

  /// Compare portfolio performance against selected benchmarks
  /// Returns comparative metrics like alpha, beta, correlation, etc.
  static Future<PortfolioBenchmarkMetrics> compareToBenchmark(
    String portfolioId,
    String benchmarkId,
    String timeframe,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/portfolio/$portfolioId/compare-to-benchmark/$benchmarkId?timeframe=$timeframe'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['metrics'] != null) {
          return PortfolioBenchmarkMetrics.fromJson(jsonData['metrics']);
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to load comparison metrics');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for development
      return _getMockComparisonMetrics(portfolioId, benchmarkId);
    }
  }

  /// Get available benchmarks that can be used for comparison
  static Future<List<BenchmarkInfo>> getAvailableBenchmarks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/benchmarks'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['benchmarks'] != null) {
          List<dynamic> benchmarkList = jsonData['benchmarks'];
          return benchmarkList
              .map((data) => BenchmarkInfo.fromJson(data))
              .toList();
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to load available benchmarks');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for development
      return _getAvailableBenchmarks();
    }
  }

  // --- MOCK DATA HELPERS ---

  /// Generate mock benchmark data
  static List<BenchmarkData> _getMockBenchmarkData(
    String timeframe,
    List<String> benchmarks,
  ) {
    final List<BenchmarkData> result = [];
    final now = DateTime.now();

    // Number of data points based on timeframe
    int dataPoints = _getDataPointsForTimeframe(timeframe);

    for (String benchmark in benchmarks) {
      // Select return pattern based on benchmark
      bool isPositive =
          benchmark.contains('SP500') || benchmark.contains('NASDAQ');
      bool isVolatile =
          benchmark.contains('CRYPTO') || benchmark.contains('VIX');

      List<PerformancePoint> data = [];
      double value = 100.0; // Starting value (normalized to 100)

      for (int i = 0; i < dataPoints; i++) {
        // Generate movement with properties matching the benchmark type
        double volatilityFactor = isVolatile ? 2.0 : 1.0;
        double directionBias = isPositive ? 0.2 : -0.1;

        // Movement formula to create somewhat realistic patterns
        double movement =
            (directionBias + (0.5 - (i % 7) / 10)) * volatilityFactor;
        value = value + movement;

        // Prevent going too low
        if (value < 10) value = 10;

        // Calculate date based on timeframe and point index
        DateTime date = _getDateForDataPoint(now, timeframe, i, dataPoints);

        // Add data point
        data.add(PerformancePoint(
          date: date,
          value: value,
        ));
      }

      result.add(BenchmarkData(
        id: 'benchmark_$benchmark',
        name: _getBenchmarkName(benchmark),
        symbol: benchmark,
        timeframe: timeframe,
        data: data,
        returnPercent: _calculateReturnPercent(data),
      ));
    }

    return result;
  }

  /// Generate mock comparison metrics
  static PortfolioBenchmarkMetrics _getMockComparisonMetrics(
    String portfolioId,
    String benchmarkId,
  ) {
    // Generate metrics based on benchmark ID for varied results
    final isRiskyBenchmark =
        benchmarkId.contains('CRYPTO') || benchmarkId.contains('VIX');
    final isPortfolioOutperforming = portfolioId.contains('portfolio1');

    return PortfolioBenchmarkMetrics(
      alpha: isPortfolioOutperforming ? 3.42 : -1.87,
      beta: isRiskyBenchmark ? 0.72 : 1.18,
      correlation: isRiskyBenchmark ? 0.45 : 0.85,
      rSquared: isRiskyBenchmark ? 0.28 : 0.72,
      sharpeRatio: isPortfolioOutperforming ? 1.62 : 0.95,
      treynorRatio: isPortfolioOutperforming ? 8.37 : 3.45,
      trackingError: isRiskyBenchmark ? 12.45 : 4.28,
      informationRatio: isPortfolioOutperforming ? 0.87 : -0.32,
      excessReturn: isPortfolioOutperforming ? 8.74 : -2.36,
      portfolioReturn: isPortfolioOutperforming ? 12.45 : 4.78,
      benchmarkReturn: 6.82,
    );
  }

  /// Get list of available benchmarks
  static List<BenchmarkInfo> _getAvailableBenchmarks() {
    return [
      BenchmarkInfo(
        id: 'SP500',
        name: 'S&P 500',
        symbol: '^GSPC',
        description: 'Index of 500 leading U.S. publicly traded companies',
        category: 'Equity',
        region: 'US',
      ),
      BenchmarkInfo(
        id: 'NASDAQ',
        name: 'NASDAQ Composite',
        symbol: '^IXIC',
        description: 'Index of all stocks listed on the NASDAQ stock market',
        category: 'Equity',
        region: 'US',
      ),
      BenchmarkInfo(
        id: 'DOW',
        name: 'Dow Jones Industrial Average',
        symbol: '^DJI',
        description:
            'Price-weighted average of 30 significant stocks traded on the NYSE and NASDAQ',
        category: 'Equity',
        region: 'US',
      ),
      BenchmarkInfo(
        id: 'BIST100',
        name: 'BIST 100',
        symbol: '^XU100',
        description: 'Benchmark index for Borsa Istanbul',
        category: 'Equity',
        region: 'Turkey',
      ),
      BenchmarkInfo(
        id: 'GOLD',
        name: 'Gold',
        symbol: 'GC=F',
        description: 'Gold futures price',
        category: 'Commodity',
        region: 'Global',
      ),
      BenchmarkInfo(
        id: 'USDTRY',
        name: 'USD/TRY',
        symbol: 'USDTRY=X',
        description: 'US Dollar to Turkish Lira exchange rate',
        category: 'Currency',
        region: 'Turkey',
      ),
      BenchmarkInfo(
        id: 'BITCOIN',
        name: 'Bitcoin',
        symbol: 'BTC-USD',
        description: 'Bitcoin to US Dollar',
        category: 'Crypto',
        region: 'Global',
      ),
      BenchmarkInfo(
        id: 'VIX',
        name: 'CBOE Volatility Index',
        symbol: '^VIX',
        description: 'Market expectation of 30-day forward-looking volatility',
        category: 'Volatility',
        region: 'US',
      ),
    ];
  }

  /// Helper function to get benchmark name from symbol
  static String _getBenchmarkName(String symbol) {
    switch (symbol) {
      case 'SP500':
      case '^GSPC':
        return 'S&P 500';
      case 'NASDAQ':
      case '^IXIC':
        return 'NASDAQ Composite';
      case 'DOW':
      case '^DJI':
        return 'Dow Jones';
      case 'BIST100':
      case '^XU100':
        return 'BIST 100';
      case 'GOLD':
      case 'GC=F':
        return 'Gold';
      case 'USDTRY':
      case 'USDTRY=X':
        return 'USD/TRY';
      case 'BITCOIN':
      case 'BTC-USD':
        return 'Bitcoin';
      case 'VIX':
      case '^VIX':
        return 'VIX';
      default:
        return symbol;
    }
  }

  /// Calculate return percentage between first and last data points
  static double _calculateReturnPercent(List<PerformancePoint> data) {
    if (data.isEmpty || data.length < 2) return 0.0;

    final firstValue = data.first.value;
    final lastValue = data.last.value;

    if (firstValue <= 0) return 0.0;

    return ((lastValue / firstValue) - 1) * 100;
  }

  /// Get appropriate date for data point based on timeframe
  static DateTime _getDateForDataPoint(
    DateTime now,
    String timeframe,
    int pointIndex,
    int totalPoints,
  ) {
    // Calculate date interval based on timeframe
    int intervalDays;
    switch (timeframe) {
      case '1W':
        intervalDays = 1;
        break;
      case '1M':
        intervalDays = 2;
        break;
      case '3M':
        intervalDays = 6;
        break;
      case '6M':
        intervalDays = 12;
        break;
      case '1Y':
        intervalDays = 30;
        break;
      case 'All':
        intervalDays = 60;
        break;
      default:
        intervalDays = 2;
    }

    return now
        .subtract(Duration(days: (totalPoints - pointIndex) * intervalDays));
  }

  /// Get number of data points for a timeframe
  static int _getDataPointsForTimeframe(String timeframe) {
    switch (timeframe) {
      case '1W':
        return 7;
      case '1M':
        return 15;
      case '3M':
        return 15;
      case '6M':
        return 15;
      case '1Y':
        return 12;
      case 'All':
        return 10;
      default:
        return 15;
    }
  }
}

/// Class to store performance data for a benchmark
class BenchmarkData {
  final String id;
  final String name;
  final String symbol;
  final String timeframe;
  final List<PerformancePoint> data;
  final double returnPercent;

  BenchmarkData({
    required this.id,
    required this.name,
    required this.symbol,
    required this.timeframe,
    required this.data,
    this.returnPercent = 0.0,
  });

  factory BenchmarkData.fromJson(Map<String, dynamic> json) {
    return BenchmarkData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      timeframe: json['timeframe'] ?? '',
      data: (json['data'] as List<dynamic>)
          .map((pointJson) => PerformancePoint.fromJson(pointJson))
          .toList(),
      returnPercent: json['return_percent']?.toDouble() ?? 0.0,
    );
  }
}

/// Class to store a point in the performance chart
class PerformancePoint {
  final DateTime date;
  final double value;

  PerformancePoint({
    required this.date,
    required this.value,
  });

  factory PerformancePoint.fromJson(Map<String, dynamic> json) {
    return PerformancePoint(
      date: DateTime.parse(json['date']),
      value: json['value'].toDouble(),
    );
  }
}

/// Class to store benchmark information
class BenchmarkInfo {
  final String id;
  final String name;
  final String symbol;
  final String description;
  final String category;
  final String region;

  BenchmarkInfo({
    required this.id,
    required this.name,
    required this.symbol,
    required this.description,
    required this.category,
    required this.region,
  });

  factory BenchmarkInfo.fromJson(Map<String, dynamic> json) {
    return BenchmarkInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      region: json['region'] ?? '',
    );
  }
}

/// Class to store metrics comparing portfolio to benchmark
class PortfolioBenchmarkMetrics {
  final double alpha; // Jensen's Alpha
  final double beta; // Beta coefficient (volatility compared to benchmark)
  final double correlation; // Correlation coefficient
  final double
      rSquared; // R-squared (percent of variance explained by benchmark)
  final double sharpeRatio; // Risk-adjusted return
  final double treynorRatio; // Return per unit of market risk
  final double
      trackingError; // Standard deviation of return differences (portfolio vs benchmark)
  final double informationRatio; // Return above benchmark per unit of risk
  final double excessReturn; // Portfolio return minus benchmark return
  final double portfolioReturn; // Portfolio total return percentage
  final double benchmarkReturn; // Benchmark total return percentage

  PortfolioBenchmarkMetrics({
    required this.alpha,
    required this.beta,
    required this.correlation,
    required this.rSquared,
    required this.sharpeRatio,
    required this.treynorRatio,
    required this.trackingError,
    required this.informationRatio,
    required this.excessReturn,
    required this.portfolioReturn,
    required this.benchmarkReturn,
  });

  factory PortfolioBenchmarkMetrics.fromJson(Map<String, dynamic> json) {
    return PortfolioBenchmarkMetrics(
      alpha: json['alpha']?.toDouble() ?? 0.0,
      beta: json['beta']?.toDouble() ?? 0.0,
      correlation: json['correlation']?.toDouble() ?? 0.0,
      rSquared: json['r_squared']?.toDouble() ?? 0.0,
      sharpeRatio: json['sharpe_ratio']?.toDouble() ?? 0.0,
      treynorRatio: json['treynor_ratio']?.toDouble() ?? 0.0,
      trackingError: json['tracking_error']?.toDouble() ?? 0.0,
      informationRatio: json['information_ratio']?.toDouble() ?? 0.0,
      excessReturn: json['excess_return']?.toDouble() ?? 0.0,
      portfolioReturn: json['portfolio_return']?.toDouble() ?? 0.0,
      benchmarkReturn: json['benchmark_return']?.toDouble() ?? 0.0,
    );
  }
}

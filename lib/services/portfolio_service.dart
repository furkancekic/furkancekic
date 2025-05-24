// services/portfolio_service.dart - Updated addPosition method
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/portfolio.dart';
import '../models/position.dart';
import '../models/transaction.dart';
import '../src/config.dart';

class PortfolioService {
  // Base URL for the API
  final String _baseUrl;
  // constructor: eğer baseUrl verilmezse Config.baseUrl kullanılır
  PortfolioService({String? baseUrl}) : _baseUrl = baseUrl ?? Config.baseUrl;
  static String get baseUrl => Config.baseUrl;

  // --- PORTFOLIO OPERATIONS ---

  /// Get all portfolios for the current user
  static Future<List<Portfolio>> getPortfolios() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/portfolios'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['portfolios'] != null) {
          final List<dynamic> portfoliosJson = jsonData['portfolios'];
          return portfoliosJson
              .map((json) => Portfolio.fromJson(json))
              .toList();
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load portfolios');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for now (for development)
      return _getMockPortfolios();
    }
  }

  /// Get a specific portfolio by ID
  static Future<Portfolio> getPortfolio(String portfolioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/portfolios/$portfolioId'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['portfolio'] != null) {
          return Portfolio.fromJson(jsonData['portfolio']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load portfolio');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for now (for development)
      final mockPortfolios = _getMockPortfolios();
      final portfolio = mockPortfolios.firstWhere(
        (p) => p.id == portfolioId,
        orElse: () => throw Exception('Portfolio not found'),
      );
      return portfolio;
    }
  }

  /// Get normalized portfolio performance data (percentage-based, cash-flow adjusted)
  static Future<PerformanceData> getNormalizedPortfolioPerformance(
    String portfolioId,
    String timeframe,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/portfolios/$portfolioId/normalized-performance?timeframe=$timeframe'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          return PerformanceData.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ??
              'Failed to load normalized performance data');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Return mock normalized data for development
      return PerformanceData(
        timeframe: timeframe,
        data: _generateMockNormalizedPerformancePoints(timeframe),
      );
    }
  }

  /// Get normalized total performance for all portfolios combined
  static Future<PerformanceData> getNormalizedTotalPortfoliosPerformance(
      String timeframe) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/portfolios/normalized-total-performance?timeframe=$timeframe'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          return PerformanceData.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ??
              'Failed to load normalized total performance data');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Return mock normalized data for development
      return PerformanceData(
        timeframe: timeframe,
        data: _generateMockNormalizedPerformancePoints(timeframe),
      );
    }
  }

  /// Generate mock normalized performance points (starts at 100%, shows percentage gains)
  static List<PerformancePoint> _generateMockNormalizedPerformancePoints(
      String timeframe) {
    final int dataPoints = _getDataPointsForTimeframe(timeframe);
    final now = DateTime.now();
    final List<PerformancePoint> points = [];

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

    // Start at 100 (representing 100% or 0% gain)
    double currentValue = 100.0;

    for (int i = 0; i < dataPoints; i++) {
      final date =
          now.subtract(Duration(days: (dataPoints - i) * intervalDays));

      // Generate realistic stock-like returns (small percentage changes)
      final random = (DateTime.now().millisecondsSinceEpoch + i) % 100;
      final change = (random - 50) / 200.0; // +/- 0.25% per period roughly
      currentValue = currentValue * (1 + change);

      // Keep within reasonable bounds (80% to 120% for mock data)
      currentValue = currentValue.clamp(80.0, 120.0);

      points.add(PerformancePoint(
        date: date,
        value: currentValue,
      ));
    }

    return points;
  }

  /// Create a new portfolio
  static Future<void> createPortfolio({
    required String name,
    String description = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/portfolios'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] != 'success') {
          throw Exception(jsonData['message'] ?? 'Failed to create portfolio');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // For now, pretend it was successful (for development)
      // Later implement actual error handling
      return;
    }
  }

  /// Update an existing portfolio
  static Future<void> updatePortfolio({
    required String portfolioId,
    required String name,
    String? description,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/portfolios/$portfolioId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          if (description != null) 'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] != 'success') {
          throw Exception(jsonData['message'] ?? 'Failed to update portfolio');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // For now, pretend it was successful (for development)
      return;
    }
  }

  /// Delete a portfolio
  static Future<void> deletePortfolio(String portfolioId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/portfolios/$portfolioId'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] != 'success') {
          throw Exception(jsonData['message'] ?? 'Failed to delete portfolio');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // For now, pretend it was successful (for development)
      return;
    }
  }

  // --- POSITION OPERATIONS ---

  /// Get a specific position by ID
  static Future<Position> getPosition({
    required String portfolioId,
    required String positionId,
    String timeframe = '1M',
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/portfolios/$portfolioId/positions/$positionId?timeframe=$timeframe'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['position'] != null) {
          return Position.fromJson(jsonData['position']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load position');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for now (for development)
      final mockPortfolios = _getMockPortfolios();
      final portfolio = mockPortfolios.firstWhere(
        (p) => p.id == portfolioId,
        orElse: () => throw Exception('Portfolio not found'),
      );

      final position = portfolio.positions.firstWhere(
        (p) => p.id == positionId,
        orElse: () => throw Exception('Position not found'),
      );

      // Add mock performance data based on timeframe
      position.performanceData = _generateMockPerformanceData(timeframe);

      return position;
    }
  }

  static Future<PerformanceData> getTotalPortfoliosPerformance(
      String timeframe) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/portfolios/total-performance?timeframe=$timeframe'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          return PerformanceData.fromJson(jsonData['data']);
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to load total performance data');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for now (for development)
      return PerformanceData(
        timeframe: timeframe,
        data: _generateMockPerformancePoints(timeframe),
      );
    }
  }

  static Future<double?> getHistoricalPrice(
      String ticker, DateTime date) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/stock-historical-price?ticker=$ticker&date=${date.toIso8601String()}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success' && jsonData['price'] != null) {
          return jsonData['price'].toDouble();
        }
      }
      return null;
    } catch (e) {
      print('Error fetching historical price: $e');
      return null;
    }
  }

  /// UPDATED: Add a new position to a portfolio with flexible price parameter
  static Future<void> addPosition({
    required String portfolioId,
    required String ticker,
    required double quantity,
    double? price, // Now optional - server will fetch historical price if null
    required DateTime date,
    String? notes,
  }) async {
    try {
      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'ticker': ticker,
        'quantity': quantity,
        'date': date.toIso8601String(),
      };

      // Only add price if provided (manual mode)
      if (price != null) {
        requestBody['price'] = price;
      }

      // Add notes if provided
      if (notes != null && notes.isNotEmpty) {
        requestBody['notes'] = notes;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/portfolios/$portfolioId/positions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] != 'success') {
          throw Exception(jsonData['message'] ?? 'Failed to add position');
        }
      } else {
        // Parse error response for better error messages
        String errorMessage = 'Server returned ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Use default error message if parsing fails
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Re-throw the exception to show the actual error to user
      throw Exception('Failed to add position: $e');
    }
  }

  /// Update an existing position
  static Future<void> updatePosition({
    required String portfolioId,
    required String positionId,
    double? quantity,
    double? price,
    DateTime? date,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (quantity != null) updateData['quantity'] = quantity;
      if (price != null) updateData['price'] = price;
      if (date != null) updateData['date'] = date.toIso8601String();
      if (notes != null) updateData['notes'] = notes;

      final response = await http.put(
        Uri.parse('$baseUrl/portfolios/$portfolioId/positions/$positionId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] != 'success') {
          throw Exception(jsonData['message'] ?? 'Failed to update position');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // For now, pretend it was successful (for development)
      return;
    }
  }

  /// Delete a position
  static Future<void> deletePosition({
    required String portfolioId,
    required String positionId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/portfolios/$portfolioId/positions/$positionId'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] != 'success') {
          throw Exception(jsonData['message'] ?? 'Failed to delete position');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // For now, pretend it was successful (for development)
      return;
    }
  }

  // --- TRANSACTION OPERATIONS ---

  /// Add a transaction to a position
  static Future<void> addTransaction({
    required String portfolioId,
    required String positionId,
    required TransactionType type,
    required double quantity,
    required double price,
    required DateTime date,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$baseUrl/portfolios/$portfolioId/positions/$positionId/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'type': type.toString().split('.').last, // Convert enum to string
          'quantity': quantity,
          'price': price,
          'date': date.toIso8601String(),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] != 'success') {
          throw Exception(jsonData['message'] ?? 'Failed to add transaction');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // For now, pretend it was successful (for development)
      return;
    }
  }

  /// Delete a transaction
  static Future<void> deleteTransaction({
    required String portfolioId,
    required String positionId,
    required String transactionId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '$baseUrl/portfolios/$portfolioId/positions/$positionId/transactions/$transactionId'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] != 'success') {
          throw Exception(
              jsonData['message'] ?? 'Failed to delete transaction');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // For now, pretend it was successful (for development)
      return;
    }
  }

  // --- PERFORMANCE DATA ---

  /// Get portfolio performance data
  static Future<PerformanceData> getPortfolioPerformance(
    String portfolioId,
    String timeframe,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/portfolios/$portfolioId/performance?timeframe=$timeframe'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          return PerformanceData.fromJson(jsonData['data']);
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to load performance data');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for now (for development)
      return PerformanceData(
        timeframe: timeframe,
        data: _generateMockPerformancePoints(timeframe),
      );
    }
  }

  // --- BENCHMARK COMPARISON FEATURE ---

  /// Get benchmark performance data
  static Future<BenchmarkPerformanceData> getBenchmarkPerformance(
    String benchmarkTicker,
    String timeframe,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/benchmark-performance?ticker=$benchmarkTicker&timeframe=$timeframe'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          return BenchmarkPerformanceData.fromJson(jsonData['data']);
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to load benchmark data');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for now (for development)
      return BenchmarkPerformanceData(
        ticker: benchmarkTicker,
        name: _getBenchmarkName(benchmarkTicker),
        timeframe: timeframe,
        data: _generateMockPerformancePoints(timeframe),
        startValue: 100.0,
        endValue: 105.0,
        percentChange: 5.0,
      );
    }
  }

  // Helper method to get benchmark name
  static String _getBenchmarkName(String ticker) {
    switch (ticker) {
      case '^GSPC':
        return 'S&P 500';
      case '^IXIC':
        return 'NASDAQ';
      case '^DJI':
        return 'Dow Jones';
      case '^RUT':
        return 'Russell 2000';
      case '^XU100':
        return 'BIST 100';
      case 'SPY':
        return 'S&P 500 ETF';
      case 'QQQ':
        return 'NASDAQ 100 ETF';
      default:
        return ticker;
    }
  }

  // --- HELPER METHODS FOR MOCK DATA ---

  /// Generate mock performance data
  static List<double> _generateMockPerformanceData(String timeframe) {
    final random = DateTime.now().millisecondsSinceEpoch % 2 == 0;
    final int dataPoints = _getDataPointsForTimeframe(timeframe);
    final List<double> data = [];

    double value = 100.0;
    for (int i = 0; i < dataPoints; i++) {
      // Generate random price movements (slightly biased upward if random is true)
      final movement = random
          ? (0.5 - (10 + i).remainder(7) / 10)
          : (-0.5 + (10 + i).remainder(7) / 10);
      value = value + movement;
      if (value < 10) value = 10; // Prevent going too low
      data.add(value);
    }

    return data;
  }

  /// Generate mock performance points
  static List<PerformancePoint> _generateMockPerformancePoints(
      String timeframe) {
    final data = _generateMockPerformanceData(timeframe);
    final int dataPoints = data.length;
    final now = DateTime.now();
    final List<PerformancePoint> points = [];

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

    for (int i = 0; i < dataPoints; i++) {
      final date =
          now.subtract(Duration(days: (dataPoints - i) * intervalDays));
      points.add(PerformancePoint(
        date: date,
        value: data[i],
      ));
    }

    return points;
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

  /// Generate mock portfolios for development
  static List<Portfolio> _getMockPortfolios() {
    final now = DateTime.now();

    // Portfolio 1: Tech Stocks
    final portfolio1 = Portfolio(
      id: 'portfolio1',
      name: 'Tech Portfolio',
      description: 'High-growth technology companies',
      createdAt: now.subtract(const Duration(days: 120)),
      updatedAt: now.subtract(const Duration(hours: 3)),
      positions: [
        Position(
          id: 'pos1',
          ticker: 'AAPL',
          companyName: 'Apple Inc.',
          quantity: 10.0,
          averagePrice: 175.50,
          currentPrice: 182.63,
          purchaseDate: now.subtract(const Duration(days: 60)),
          transactions: [
            Transaction(
              id: 'trans1',
              type: TransactionType.buy,
              quantity: 10.0,
              price: 175.50,
              date: now.subtract(const Duration(days: 60)),
            ),
          ],
          performanceData: _generateMockPerformanceData('1M'),
          currentValue: 1826.30,
          gainLoss: 71.30,
          gainLossPercent: 4.06,
        ),
        Position(
          id: 'pos2',
          ticker: 'MSFT',
          companyName: 'Microsoft Corporation',
          quantity: 5.0,
          averagePrice: 315.75,
          currentPrice: 338.47,
          purchaseDate: now.subtract(const Duration(days: 45)),
          transactions: [
            Transaction(
              id: 'trans2',
              type: TransactionType.buy,
              quantity: 5.0,
              price: 315.75,
              date: now.subtract(const Duration(days: 45)),
            ),
          ],
          performanceData: _generateMockPerformanceData('1M'),
          currentValue: 1692.35,
          gainLoss: 113.60,
          gainLossPercent: 7.19,
        ),
      ],
      totalValue: 3518.65,
      totalGainLoss: 184.90,
      totalGainLossPercent: 5.54,
    );

    // Portfolio 2: Dividend Stocks
    final portfolio2 = Portfolio(
      id: 'portfolio2',
      name: 'Dividend Portfolio',
      description: 'High-yield dividend stocks',
      createdAt: now.subtract(const Duration(days: 200)),
      updatedAt: now.subtract(const Duration(days: 1)),
      positions: [
        Position(
          id: 'pos3',
          ticker: 'JNJ',
          companyName: 'Johnson & Johnson',
          quantity: 8.0,
          averagePrice: 152.32,
          currentPrice: 155.67,
          purchaseDate: now.subtract(const Duration(days: 180)),
          transactions: [
            Transaction(
              id: 'trans3',
              type: TransactionType.buy,
              quantity: 8.0,
              price: 152.32,
              date: now.subtract(const Duration(days: 180)),
            ),
            Transaction(
              id: 'trans4',
              type: TransactionType.dividend,
              quantity: 0.0,
              price: 1.01,
              date: now.subtract(const Duration(days: 90)),
            ),
          ],
          performanceData: _generateMockPerformanceData('1M'),
          currentValue: 1245.36,
          gainLoss: 26.80,
          gainLossPercent: 2.20,
        ),
        Position(
          id: 'pos4',
          ticker: 'KO',
          companyName: 'The Coca-Cola Company',
          quantity: 20.0,
          averagePrice: 58.75,
          currentPrice: 61.42,
          purchaseDate: now.subtract(const Duration(days: 150)),
          transactions: [
            Transaction(
              id: 'trans5',
              type: TransactionType.buy,
              quantity: 20.0,
              price: 58.75,
              date: now.subtract(const Duration(days: 150)),
            ),
            Transaction(
              id: 'trans6',
              type: TransactionType.dividend,
              quantity: 0.0,
              price: 0.44,
              date: now.subtract(const Duration(days: 60)),
            ),
          ],
          performanceData: _generateMockPerformanceData('1M'),
          currentValue: 1228.40,
          gainLoss: 53.40,
          gainLossPercent: 4.54,
        ),
      ],
      totalValue: 2473.76,
      totalGainLoss: 80.20,
      totalGainLossPercent: 3.35,
    );

    return [portfolio1, portfolio2];
  }
}

/// Class to store performance data
class PerformanceData {
  final String timeframe;
  final List<PerformancePoint> data;

  PerformanceData({
    required this.timeframe,
    required this.data,
  });

  factory PerformanceData.fromJson(Map<String, dynamic> json) {
    return PerformanceData(
      timeframe: json['timeframe'] ?? '',
      data: (json['data'] as List<dynamic>)
          .map((pointJson) => PerformancePoint.fromJson(pointJson))
          .toList(),
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

/// Class to store benchmark performance data
class BenchmarkPerformanceData {
  final String ticker;
  final String name;
  final String timeframe;
  final List<PerformancePoint> data;
  final double startValue;
  final double endValue;
  final double percentChange;

  BenchmarkPerformanceData({
    required this.ticker,
    required this.name,
    required this.timeframe,
    required this.data,
    required this.startValue,
    required this.endValue,
    required this.percentChange,
  });

  factory BenchmarkPerformanceData.fromJson(Map<String, dynamic> json) {
    return BenchmarkPerformanceData(
      ticker: json['ticker'] ?? '',
      name: json['name'] ?? '',
      timeframe: json['timeframe'] ?? '',
      data: (json['data'] as List<dynamic>)
          .map((pointJson) => PerformancePoint.fromJson(pointJson))
          .toList(),
      startValue: (json['start_value'] ?? 0.0).toDouble(),
      endValue: (json['end_value'] ?? 0.0).toDouble(),
      percentChange: (json['percent_change'] ?? 0.0).toDouble(),
    );
  }
}

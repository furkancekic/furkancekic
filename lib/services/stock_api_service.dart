// services/stock_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../src/config.dart';

class StockApiService {
  // Base URL for the API
  final String _baseUrl;
  // constructor: eğer baseUrl verilmezse Config.baseUrl kullanılır
  StockApiService({String? baseUrl}) : _baseUrl = baseUrl ?? Config.baseUrl;
  static String get baseUrl => Config.baseUrl;

  // Get market indices data
  static Future<List<MarketIndex>> getMarketIndices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/market-indices'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['indices'] != null) {
          List<dynamic> indices = jsonData['indices'];
          return indices
              .map((index) => MarketIndex(
                    name: index['name'] ?? 'Unknown',
                    ticker: index['ticker'] ?? '',
                    value: index['value']?.toDouble() ?? 0.0,
                    // Handle both field names that might come from API
                    change: index['change']?.toDouble() ??
                        index['price_change']?.toDouble() ??
                        0.0,
                    percentChange: index['percentChange']?.toDouble() ??
                        index['price_change_percent']?.toDouble() ??
                        0.0,
                  ))
              .toList();
        }
      }

      // If API call fails, log and return sample data
      print('API call failed for market indices: ${response.statusCode}');
      return _getSampleMarketIndices();
    } catch (e) {
      print('Error fetching market indices: $e');
      return _getSampleMarketIndices();
    }
  }

  // Get watchlist stocks data
  static Future<List<StockInfo>> getWatchlistStocks() async {
    try {
      // Default watchlist tickers
      final tickers = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA'];
      final tickersStr = tickers.join(',');

      final response =
          await http.get(Uri.parse('$baseUrl/watchlist?tickers=$tickersStr'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['stocks'] != null) {
          List<dynamic> stocks = jsonData['stocks'];
          return stocks
              .map((stock) => StockInfo(
                    ticker: stock['ticker'] ?? '',
                    name: stock['name'] ?? '',
                    price: stock['price']?.toDouble() ?? 0.0,
                    // Handle both field names that might come from API
                    priceChange: stock['priceChange']?.toDouble() ??
                        stock['price_change']?.toDouble() ??
                        0.0,
                    percentChange: stock['percentChange']?.toDouble() ??
                        stock['price_change_percent']?.toDouble() ??
                        0.0,
                    chartData: (stock['chartData'] is List)
                        ? List<double>.from((stock['chartData'] as List)
                            .map((e) => double.parse(e.toString())))
                        : _generateRandomChartData(
                            stock['price']?.toDouble() ?? 100.0),
                  ))
              .toList();
        }
      }

      // If API call fails, log and return sample data
      print('API call failed for watchlist: ${response.statusCode}');
      return _getSampleWatchlistStocks();
    } catch (e) {
      print('Error fetching watchlist stocks: $e');
      return _getSampleWatchlistStocks();
    }
  }

  // Get mini chart data for a specific stock
  static Future<List<double>> getMiniChartData(String ticker) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/mini-chart?ticker=$ticker'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          List<dynamic> dataList = jsonData['data'];
          return dataList
              .map((value) => double.parse(value.toString()))
              .toList();
        }
      }

      // If API call fails, return fallback data
      print('API call failed for mini chart: ${response.statusCode}');
      return _generateRandomChartData(100.0);
    } catch (e) {
      print('Error fetching mini chart data: $e');
      return _generateRandomChartData(100.0);
    }
  }

  // Search for stocks
  static Future<List<SearchResult>> searchStocks(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final response =
          await http.get(Uri.parse('$baseUrl/search?query=$query&limit=10'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['results'] != null) {
          List<dynamic> results = jsonData['results'];
          return results
              .map((item) => SearchResult(
                    symbol: item['symbol'] ?? '',
                    name: item['name'] ?? '',
                  ))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('Error searching stocks: $e');
      return [];
    }
  }

  // Get intraday chart data for IntradayChart widget
  static Future<List<Map<String, dynamic>>> getIntradayChartData(
      String ticker) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/intraday-chart?ticker=$ticker'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          List<dynamic> data = jsonData['data'];
          return data
              .map((point) => {
                    'time': point['time'] ?? '',
                    'price': point['price']?.toDouble() ?? 0.0,
                  })
              .toList()
              .cast<Map<String, dynamic>>();
        }
      }

      // If API call fails, return fallback data
      print('API call failed for intraday chart: ${response.statusCode}');
      return _generateSampleIntradayData();
    } catch (e) {
      print('Error fetching intraday chart data: $e');
      return _generateSampleIntradayData();
    }
  }

  // Health check
  static Future<bool> isApiAvailable() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('API is not available: $e');
      return false;
    }
  }

  // Helper function to generate sample intraday data
  static List<Map<String, dynamic>> _generateSampleIntradayData() {
    final List<Map<String, dynamic>> sampleData = [];
    final now = DateTime.now();

    for (int i = 60; i >= 0; i--) {
      final time = now.subtract(Duration(minutes: i));
      final price = 100 + (i % 10) * 0.5;
      sampleData.add({
        'time': time.toString(),
        'price': price,
      });
    }

    return sampleData;
  }

  // Helper function to generate random chart data
  static List<double> _generateRandomChartData(double basePrice) {
    final List<double> data = [];
    double price = basePrice;

    for (int i = 0; i < 30; i++) {
      price = price + (0.5 - (10 + i).remainder(7) / 10);
      data.add(price);
    }

    return data;
  }

  // Helper function for sample market indices
  static List<MarketIndex> _getSampleMarketIndices() {
    return [
      MarketIndex(
          name: 'S&P 500',
          ticker: '^GSPC',
          value: 4892.38,
          change: 24.23,
          percentChange: 0.45),
      MarketIndex(
          name: 'NASDAQ',
          ticker: '^IXIC',
          value: 15647.12,
          change: -86.42,
          percentChange: -0.67),
      MarketIndex(
          name: 'DOW JONES',
          ticker: '^DJI',
          value: 34752.65,
          change: 245.87,
          percentChange: 0.82),
      MarketIndex(
          name: 'RUSSELL 2000',
          ticker: '^RUT',
          value: 2109.73,
          change: -12.45,
          percentChange: -0.58),
      MarketIndex(
          name: 'BIST 100',
          ticker: '^BIST',
          value: 9852.34,
          change: 125.67,
          percentChange: 1.29),
      MarketIndex(
          name: 'BIST 30',
          ticker: '^XU030',
          value: 4521.87,
          change: 56.78,
          percentChange: 1.27),
      MarketIndex(
          name: 'GOLD',
          ticker: 'GC=F',
          value: 2324.56,
          change: 15.78,
          percentChange: 0.68),
      MarketIndex(
          name: 'VIX',
          ticker: '^VIX',
          value: 18.45,
          change: -0.67,
          percentChange: -3.5),
    ];
  }

  static Future<StockInfo> getStockInfo(String ticker) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/stock?ticker=$ticker&timeframe=1D'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Get company info data
        final companyInfo = data['company_info'] ?? {};

        // Create StockInfo object
        return StockInfo(
          ticker: ticker,
          name: companyInfo['company_name'] ?? ticker,
          price: companyInfo['price']?.toDouble() ?? 0.0,
          priceChange: companyInfo['price_change']?.toDouble() ?? 0.0,
          percentChange: companyInfo['price_change_percent']?.toDouble() ?? 0.0,
          chartData: [], // We don't need chart data for this use case
        );
      } else {
        throw Exception('Failed to load stock info');
      }
    } catch (e) {
      print('Error fetching stock info for $ticker: $e');
      // Return a default stock info object
      return StockInfo(
        ticker: ticker,
        name: ticker,
        price: 0.0,
        priceChange: 0.0,
        percentChange: 0.0,
        chartData: [],
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getStockData(
      String ticker, String timeframe) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/stock?ticker=$ticker&timeframe=$timeframe'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['chart_data'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['chart_data']);
        }
      }

      return [];
    } catch (e) {
      print('Error fetching stock data: $e');
      return [];
    }
  }

  // Helper function for sample watchlist stocks
  static List<StockInfo> _getSampleWatchlistStocks() {
    return [
      StockInfo(
          ticker: 'AAPL',
          name: 'Apple Inc.',
          price: 182.63,
          priceChange: 3.24,
          percentChange: 1.81,
          chartData: [179.1, 179.5, 180.2, 181.4, 182.63]),
      StockInfo(
          ticker: 'MSFT',
          name: 'Microsoft Corporation',
          price: 338.47,
          priceChange: -2.15,
          percentChange: -0.63,
          chartData: [341.0, 340.5, 339.7, 338.9, 338.47]),
      StockInfo(
          ticker: 'GOOGL',
          name: 'Alphabet Inc.',
          price: 142.57,
          priceChange: 1.42,
          percentChange: 1.01,
          chartData: [140.9, 141.3, 141.8, 142.2, 142.57]),
      StockInfo(
          ticker: 'AMZN',
          name: 'Amazon.com, Inc.',
          price: 174.36,
          priceChange: -0.87,
          percentChange: -0.49,
          chartData: [175.2, 175.0, 174.7, 174.5, 174.36]),
      StockInfo(
          ticker: 'TSLA',
          name: 'Tesla, Inc.',
          price: 231.48,
          priceChange: 5.68,
          percentChange: 2.52,
          chartData: [225.6, 227.2, 228.9, 230.3, 231.48]),
    ];
  }
}

// Data models
class MarketIndex {
  final String name;
  final String ticker;
  final double value;
  final double change;
  final double percentChange;

  MarketIndex({
    required this.name,
    required this.ticker,
    required this.value,
    required this.change,
    required this.percentChange,
  });
}

class StockInfo {
  final String ticker;
  final String name;
  final double price;
  final double priceChange;
  final double percentChange;
  final List<double> chartData;

  StockInfo({
    required this.ticker,
    required this.name,
    required this.price,
    required this.priceChange,
    required this.percentChange,
    required this.chartData,
  });
}

class SearchResult {
  final String symbol;
  final String name;

  SearchResult({
    required this.symbol,
    required this.name,
  });
}

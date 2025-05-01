import 'dart:convert';
import 'package:http/http.dart' as http;

class StockApiService {
  // Base URL for the API - change to your actual server address in production
  static const String baseUrl =
      'https://confidentiality-dog-affiliates-storm.trycloudflare.com/api';

  // Get market indices data
  static Future<List<MarketIndex>> getMarketIndices() async {
    try {
      // For multiple indices, we'll call the API for each one
      // These are the tickers we want to fetch
      final tickers = [
        '^GSPC', // S&P 500
        '^IXIC', // NASDAQ
        '^DJI', // DOW JONES
        '^RUT', // RUSSELL 2000
        '^XU100', // BIST 100
        '^XU030', // BIST 30
        'GC=F', // Gold (Ons Altın)
        '^VIX', // Volatility Index
        '^N225', // Nikkei 225
        '^HSI', // Hang Seng (Hong Kong)
        '^GDAXI', // DAX
        'EURUSD=X', // EUR/USD
        'USDTRY=X' // USD/TRY
      ];

      // List to store all market index data
      List<MarketIndex> indices = [];

      // For each ticker, fetch data
      for (String ticker in tickers) {
        final response = await http
            .get(Uri.parse('$baseUrl/stock?ticker=$ticker&timeframe=1D'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Create market index object from API response
          MarketIndex index = MarketIndex(
            name: _getNameForTicker(ticker),
            ticker: ticker,
            value: data['company_info']['price']?.toDouble() ?? 0.0,
            change: data['company_info']['price_change']?.toDouble() ?? 0.0,
            percentChange:
                data['company_info']['price_change_percent']?.toDouble() ?? 0.0,
          );

          indices.add(index);
        }
      }

      return indices;
    } catch (e) {
      print('Error fetching market indices: $e');
      // Return some sample data if the API call fails
      return [
        MarketIndex(
            name: 'S&P 500',
            ticker: '^GSPC',
            value: 4892.38,
            change: 1.23,
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
            name: 'ONS ALTIN',
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
        MarketIndex(
            name: 'NIKKEI 225',
            ticker: '^N225',
            value: 38567.12,
            change: 345.21,
            percentChange: 0.90),
        MarketIndex(
            name: 'HANG SENG',
            ticker: '^HSI',
            value: 17689.45,
            change: -234.56,
            percentChange: -1.31),
        MarketIndex(
            name: 'DAX',
            ticker: '^GDAXI',
            value: 18356.78,
            change: 145.67,
            percentChange: 0.80),
        MarketIndex(
            name: 'EUR/USD',
            ticker: 'EURUSD=X',
            value: 1.0845,
            change: 0.0023,
            percentChange: 0.21),
        MarketIndex(
            name: 'USD/TRY',
            ticker: 'USDTRY=X',
            value: 31.678,
            change: 0.125,
            percentChange: 0.40),
      ];
    }
  }

  // Get watchlist stocks data
  static Future<List<StockInfo>> getWatchlistStocks() async {
    try {
      // Default watchlist tickers
      final tickers = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA'];
      List<StockInfo> stocks = [];

      for (String ticker in tickers) {
        final response = await http
            .get(Uri.parse('$baseUrl/stock?ticker=$ticker&timeframe=1D'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Get chart data for mini charts
          List<dynamic> chartData = data['chart_data'] ?? [];
          List<double> prices = [];

          // Extract closing prices for line chart
          for (var point in chartData) {
            prices.add(point['Close']?.toDouble() ?? 0.0);
          }

          // Create stock info object
          StockInfo stock = StockInfo(
            ticker: ticker,
            name: data['company_info']['company_name'] ?? 'Unknown',
            price: data['company_info']['price']?.toDouble() ?? 0.0,
            priceChange:
                data['company_info']['price_change']?.toDouble() ?? 0.0,
            percentChange:
                data['company_info']['price_change_percent']?.toDouble() ?? 0.0,
            chartData:
                prices.isNotEmpty ? prices : [0, 0, 0, 0, 0], // Fallback data
          );

          stocks.add(stock);
        }
      }

      return stocks;
    } catch (e) {
      print('Error fetching watchlist stocks: $e');
      // Return sample data if the API call fails
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

  // Get mini chart data for a specific stock
  static Future<List<double>> getMiniChartData(String ticker) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/stock?ticker=$ticker&timeframe=1D&chartType=Line'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> chartData = data['chart_data'] ?? [];
        List<double> prices = [];

        // Get the last 30 data points for a mini chart
        int dataPointsToShow = chartData.length > 30 ? 30 : chartData.length;

        for (int i = chartData.length - dataPointsToShow;
            i < chartData.length;
            i++) {
          prices.add(chartData[i]['Close']?.toDouble() ?? 0.0);
        }

        return prices;
      } else {
        throw Exception('Failed to load chart data');
      }
    } catch (e) {
      print('Error fetching mini chart data: $e');
      // Return sample data for chart
      return [100, 102, 101, 103, 102, 105, 107, 106, 108, 110];
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
        final data = json.decode(response.body);
        List<dynamic> results = data['results'] ?? [];

        return results
            .map((item) => SearchResult(
                  symbol: item['symbol'],
                  name: item['name'],
                ))
            .toList();
      } else {
        throw Exception('Failed to search stocks');
      }
    } catch (e) {
      print('Error searching stocks: $e');
      return [];
    }
  }

  // Helper function to get a readable name for market index tickers
  static String _getNameForTicker(String ticker) {
    switch (ticker) {
      case '^GSPC':
        return 'S&P 500';
      case '^IXIC':
        return 'NASDAQ';
      case '^DJI':
        return 'DOW JONES';
      case '^RUT':
        return 'RUSSELL 2000';
      case '^BIST':
        return 'BIST 100';
      case '^XU030':
        return 'BIST 30';
      case 'GC=F':
        return 'GOLD';
      case '^VIX':
        return 'VIX';
      case '^N225':
        return 'NIKKEI 225';
      case '^HSI':
        return 'HANG SENG';
      case '^GDAXI':
        return 'DAX';
      case 'EURUSD=X':
        return 'EUR/USD';
      case 'USDTRY=X':
        return 'USD/TRY';
      default:
        return ticker;
    }
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

// services/fund_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../src/config.dart';
import '../models/fund.dart';
import '../utils/logger.dart';

class FundApiService {
  static final _logger = AppLogger('FundApiService');
  static const String baseUrl = Config.baseUrl;

  /// Get all funds with pagination and filters
  static Future<List<Fund>> getFunds(Map<String, dynamic> params) async {
    try {
      final uri = Uri.parse('$baseUrl/funds').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final fundsJson = data['funds'] as List;
          return fundsJson.map((json) => Fund.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Http error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching funds: $e');
      throw Exception('Failed to fetch funds: $e');
    }
  }

  /// Get fund details by code
  static Future<Map<String, dynamic>> getFundDetails(String fundCode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/funds/$fundCode'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data['fund'];
        } else {
          throw Exception(data['message'] ?? 'Fund not found');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Fund not found');
      } else {
        throw Exception('Http error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching fund details for $fundCode: $e');
      rethrow;
    }
  }

  /// Get funds by category
  static Future<List<Fund>> getFundsByCategory(String category) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/funds/category/$category'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final fundsJson = data['funds'] as List;
          return fundsJson.map((json) => Fund.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Http error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching funds by category $category: $e');
      throw Exception('Failed to fetch funds by category: $e');
    }
  }

  /// Get historical data for a fund
  static Future<Map<String, dynamic>> getFundHistorical(
    String fundCode, {
    String timeframe = 'all',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/funds/$fundCode/historical')
          .replace(queryParameters: {'timeframe': timeframe});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Http error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching historical data for $fundCode: $e');
      throw Exception('Failed to fetch historical data: $e');
    }
  }

  /// Filter funds
  static Future<List<Fund>> filterFunds(Map<String, dynamic> filters) async {
    try {
      final uri =
          Uri.parse('$baseUrl/funds/filter').replace(queryParameters: filters);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final fundsJson = data['funds'] as List;
          return fundsJson.map((json) => Fund.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Http error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error filtering funds: $e');
      throw Exception('Failed to filter funds: $e');
    }
  }

  /// Compare funds
  static Future<Map<String, dynamic>> compareFunds(
      List<String> fundCodes) async {
    try {
      final fundsParam = fundCodes.join(',');
      final uri = Uri.parse('$baseUrl/funds/compare')
          .replace(queryParameters: {'funds': fundsParam});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data['comparison'];
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Http error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error comparing funds: $e');
      throw Exception('Failed to compare funds: $e');
    }
  }

  /// Get fund risk metrics
  static Future<Map<String, dynamic>> getFundRiskMetrics(
      String fundCode) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/funds/$fundCode/risk-metrics'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Http error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching risk metrics for $fundCode: $e');
      throw Exception('Failed to fetch risk metrics: $e');
    }
  }

  /// Get Monte Carlo simulation
  static Future<Map<String, dynamic>> getMonteCarlo(
    String fundCode, {
    int periods = 12,
    int simulations = 1000,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/funds/$fundCode/monte-carlo')
          .replace(queryParameters: {
        'periods': periods.toString(),
        'simulations': simulations.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Http error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching Monte Carlo for $fundCode: $e');
      throw Exception('Failed to fetch Monte Carlo: $e');
    }
  }

  /// Get fund categories for filter
  static Future<List<String>> getFundCategories() async {
    try {
      // This could be a separate endpoint, but for now we'll return static categories
      return [
        'Hisse Senedi Fonu',
        'Serbest Fon',
        'BES Emeklilik Fonu',
        'Para Piyasası Fonu',
        'Karma Fon',
        'Tahvil Fonu',
        'Altın Fonu',
        'Endeks Fonu',
        'Karma Fon',
        'Yabancı Menkul Kıymet Fonu',
      ];
    } catch (e) {
      _logger.severe('Error fetching fund categories: $e');
      return [];
    }
  }

  /// Search funds
  static Future<List<Fund>> searchFunds(String query) async {
    try {
      if (query.isEmpty) return [];

      final params = {'search': query, 'limit': '20'};
      return await getFunds(params);
    } catch (e) {
      _logger.severe('Error searching funds: $e');
      throw Exception('Failed to search funds: $e');
    }
  }

  /// Get top performing funds
  static Future<List<Fund>> getTopPerformingFunds({int limit = 10}) async {
    try {
      final params = {
        'sort_by': 'daily_return_desc',
        'limit': limit.toString(),
      };
      return await getFunds(params);
    } catch (e) {
      _logger.severe('Error fetching top performing funds: $e');
      throw Exception('Failed to fetch top performing funds: $e');
    }
  }

  /// Get fund market overview data
  static Future<Map<String, dynamic>> getMarketOverview() async {
    try {
      // This endpoint might not exist yet, so we'll simulate it
      final allFunds = await getFunds({'limit': '100'});

      // Calculate market statistics
      final totalFunds = allFunds.length;
      final totalMarketValue =
          allFunds.fold<double>(0.0, (sum, fund) => sum + fund.totalValue);

      final averageReturn = allFunds.isEmpty
          ? 0.0
          : allFunds.fold<double>(
                  0.0, (sum, fund) => sum + fund.dailyReturnValue) /
              allFunds.length;

      final categories = <String, int>{};
      for (final fund in allFunds) {
        final category = fund.category;
        categories[category] = (categories[category] ?? 0) + 1;
      }

      return {
        'total_funds': totalFunds,
        'total_market_value': totalMarketValue,
        'average_return': averageReturn,
        'categories': categories,
        'top_funds': allFunds.take(5).toList(),
      };
    } catch (e) {
      _logger.severe('Error fetching market overview: $e');
      throw Exception('Failed to fetch market overview: $e');
    }
  }
}


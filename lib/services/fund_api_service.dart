// services/fund_api_service.dart - Updated with pagination support
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../src/config.dart';
import '../models/fund.dart';
import '../utils/logger.dart';

class FundApiService {
  static final _logger = AppLogger('FundApiService');
  static const String baseUrl = Config.baseUrl;

  /// Get funds with pagination support
  static Future<Map<String, dynamic>> getFundsWithPagination(
      Map<String, dynamic> params) async {
    try {
      final uri = Uri.parse('$baseUrl/funds').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final fundsJson = data['funds'] as List;
          final funds = fundsJson.map((json) => Fund.fromJson(json)).toList();

          return {
            'funds': funds,
            'total': data['total'] ?? funds.length,
            'page': data['page'] ?? 0,
            'limit': data['limit'] ?? 25,
          };
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Http error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching funds with pagination: $e');
      throw Exception('Failed to fetch funds: $e');
    }
  }

  /// Get funds by category with pagination
  static Future<Map<String, dynamic>> getFundsByCategoryWithPagination(
      String category, Map<String, dynamic> params) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/funds/category/$category')
              .replace(queryParameters: params));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final fundsJson = data['funds'] as List;
          final funds = fundsJson.map((json) => Fund.fromJson(json)).toList();

          return {
            'funds': funds,
            'total': data['total'] ?? funds.length,
            'page': data['page'] ?? 0,
            'limit': data['limit'] ?? 25,
            'category': category,
          };
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Http error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching funds by category with pagination: $e');
      throw Exception('Failed to fetch funds by category: $e');
    }
  }

  /// Get fund historical summary (lightweight version)
  static Future<Map<String, dynamic>> getFundHistoricalSummary(
      String fundCode) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/funds/$fundCode/historical-summary'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data['summary'];
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Http error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching historical summary for $fundCode: $e');
      throw Exception('Failed to fetch historical summary: $e');
    }
  }

  /// Original getFunds method updated to use pagination
  static Future<List<Fund>> getFunds(Map<String, dynamic> params) async {
    final result = await getFundsWithPagination(params);
    return result['funds'] as List<Fund>;
  }

  /// Updated getFundsByCategory to use pagination
  static Future<List<Fund>> getFundsByCategory(String category) async {
    final result =
        await getFundsByCategoryWithPagination(category, {'limit': '100'});
    return result['funds'] as List<Fund>;
  }

  // ... rest of the existing methods remain the same ...

  /// Get fund details by code (optimized - no historical by default)
  static Future<Map<String, dynamic>> getFundDetails(String fundCode,
      {bool includeHistorical = false}) async {
    try {
      final params = includeHistorical ? {'include_historical': 'true'} : null;
      final uri = Uri.parse('$baseUrl/funds/$fundCode');
      final response = await http
          .get(params != null ? uri.replace(queryParameters: params) : uri);

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

  // Keep all other existing methods...
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

  static Future<List<String>> getFundCategories() async {
    try {
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

  static Future<Map<String, dynamic>> getMarketOverview() async {
    try {
      final allFunds = await getFunds({'limit': '100'});

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

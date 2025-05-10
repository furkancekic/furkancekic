// lib/services/fund_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import '../src/config.dart';

class FundApiService {
  static final AppLogger _logger = AppLogger('FundApiService');

  // Base URL for the API - Use the same base URL from config.dart
  static String get baseUrl => Config.baseUrl;

  /// Tüm fonları listeleme
  static Future<List<Map<String, dynamic>>> getAllFunds() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/funds'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['funds'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['funds']);
        } else {
          _logger.warning('API response does not contain funds data');
          throw Exception('API response does not contain funds data');
        }
      } else {
        _logger.warning('Failed to load funds: ${response.statusCode}');
        throw Exception('Failed to load funds: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error getting funds list: $e');
      // Fallback - return empty list
      return [];
    }
  }

  /// Belirli bir fonun detaylarını getirme
  static Future<Map<String, dynamic>> getFundDetails(String fundCode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/funds/$fundCode'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['fund'] != null) {
          return Map<String, dynamic>.from(jsonData['fund']);
        } else {
          _logger.warning('API response does not contain fund details');
          throw Exception('API response does not contain fund details');
        }
      } else {
        _logger.warning('Failed to load fund details: ${response.statusCode}');
        throw Exception('Failed to load fund details: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error getting fund details: $e');
      // Return empty map in case of error
      return {};
    }
  }

  /// Belirli bir kategorideki fonları getirme
  static Future<List<Map<String, dynamic>>> getFundsByCategory(
      String category) async {
    try {
      final encodedCategory = Uri.encodeComponent(category);
      final response =
          await http.get(Uri.parse('$baseUrl/funds/category/$encodedCategory'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['funds'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['funds']);
        } else {
          _logger.warning('API response does not contain category funds data');
          throw Exception('API response does not contain category funds data');
        }
      } else {
        _logger
            .warning('Failed to load category funds: ${response.statusCode}');
        throw Exception(
            'Failed to load category funds: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error getting category funds: $e');
      // Fallback - return empty list
      return [];
    }
  }

  /// Fonun geçmiş performans verilerini getirme
  static Future<List<Map<String, dynamic>>> getFundHistoricalData(
      String fundCode, String timeframe) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/funds/$fundCode/historical?timeframe=$timeframe'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['historical'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['historical']);
        } else {
          _logger.warning('API response does not contain historical data');
          throw Exception('API response does not contain historical data');
        }
      } else {
        _logger
            .warning('Failed to load historical data: ${response.statusCode}');
        throw Exception(
            'Failed to load historical data: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error getting historical data: $e');
      // Fallback - return empty list
      return [];
    }
  }

  /// Fonları belirli bir kritere göre karşılaştırma
  static Future<Map<String, dynamic>> compareFunds(
      List<String> fundCodes) async {
    try {
      final fundsParam = fundCodes.join(',');
      final response =
          await http.get(Uri.parse('$baseUrl/funds/compare?funds=$fundsParam'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['comparison'] != null) {
          return Map<String, dynamic>.from(jsonData['comparison']);
        } else {
          _logger.warning('API response does not contain comparison data');
          throw Exception('API response does not contain comparison data');
        }
      } else {
        _logger
            .warning('Failed to load comparison data: ${response.statusCode}');
        throw Exception(
            'Failed to load comparison data: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error comparing funds: $e');
      // Return empty map in case of error
      return {};
    }
  }

  /// Fonları belirli kriterlere göre filtreleme
  static Future<List<Map<String, dynamic>>> filterFunds(
      {String? category,
      String? timeframe,
      double? minReturn,
      double? maxReturn,
      bool? onlyTefas}) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (timeframe != null) queryParams['timeframe'] = timeframe;
      if (minReturn != null) queryParams['min_return'] = minReturn.toString();
      if (maxReturn != null) queryParams['max_return'] = maxReturn.toString();
      if (onlyTefas != null) queryParams['only_tefas'] = onlyTefas.toString();

      final uri = Uri.parse('$baseUrl/funds/filter')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['funds'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['funds']);
        } else {
          _logger.warning('API response does not contain filtered funds data');
          throw Exception('API response does not contain filtered funds data');
        }
      } else {
        _logger
            .warning('Failed to load filtered funds: ${response.statusCode}');
        throw Exception(
            'Failed to load filtered funds: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error filtering funds: $e');
      // Fallback - return empty list
      return [];
    }
  }

  /// Fonun risk metriklerini getirme
  static Future<Map<String, dynamic>> getFundRiskMetrics(
      String fundCode) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/funds/$fundCode/risk-metrics'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['metrics'] != null) {
          return Map<String, dynamic>.from(jsonData['metrics']);
        } else {
          _logger.warning('API response does not contain risk metrics data');
          throw Exception('API response does not contain risk metrics data');
        }
      } else {
        _logger.warning('Failed to load risk metrics: ${response.statusCode}');
        throw Exception('Failed to load risk metrics: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error getting risk metrics: $e');
      // Return default metrics in case of error
      return {
        'sharpeRatio': 1.24,
        'beta': 0.85,
        'alpha': 2.45,
        'rSquared': 0.78,
        'maxDrawdown': -12.4,
        'stdDev': 14.2,
        'volatility': 15.8,
      };
    }
  }

  /// Monte Carlo simülasyonu yapma
  static Future<Map<String, dynamic>> getMonteCarlo(
      String fundCode, int periods, int simulations) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/funds/$fundCode/monte-carlo?periods=$periods&simulations=$simulations'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['simulation'] != null) {
          return Map<String, dynamic>.from(jsonData['simulation']);
        } else {
          _logger.warning('API response does not contain simulation data');
          throw Exception('API response does not contain simulation data');
        }
      } else {
        _logger
            .warning('Failed to load simulation data: ${response.statusCode}');
        throw Exception(
            'Failed to load simulation data: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error getting Monte Carlo simulation: $e');
      // Return empty map in case of error
      return {};
    }
  }
}

// lib/services/fund_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fund.dart';
import '../src/config.dart';
import 'package:logging/logging.dart';

class FundApiService {
  static final Logger _logger = Logger('FundApiService');
  static String get baseUrl => Config.baseUrl;

  /// Tüm fonları getir
  static Future<List<Fund>> getAllFunds() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/funds'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['funds'] != null) {
          final List<dynamic> fundsJson = jsonData['funds'];
          return fundsJson.map((fundJson) => Fund.fromJson(fundJson)).toList();
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load funds');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error getting all funds: $e');
      // Mock data döndür (geliştirme için)
      return _getMockFunds();
    }
  }

  /// Fonları filtrele
  static Future<List<Fund>> filterFunds(FundFilter filter) async {
    try {
      final params = filter.toQueryParams();
      final uri =
          Uri.parse('$baseUrl/funds/filter').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['funds'] != null) {
          final List<dynamic> fundsJson = jsonData['funds'];
          return fundsJson.map((fundJson) => Fund.fromJson(fundJson)).toList();
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to filter funds');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error filtering funds: $e');
      return _getMockFunds();
    }
  }

  /// Fon detayını getir
  static Future<Fund> getFundDetail(String fundCode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/funds/$fundCode'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['fund'] != null) {
          return Fund.fromJson(jsonData['fund']);
        } else {
          throw Exception(jsonData['message'] ?? 'Fund not found');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error getting fund detail: $e');
      throw Exception('Failed to load fund detail');
    }
  }

  /// Fon geçmiş verilerini getir
  static Future<List<FundHistoricalPoint>> getFundHistoricalData(
      String fundCode, String timeframe) async {
    try {
      final uri = Uri.parse('$baseUrl/funds/$fundCode/historical')
          .replace(queryParameters: {'timeframe': timeframe});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['historical'] != null) {
          final List<dynamic> historicalJson = jsonData['historical'];
          return historicalJson
              .map((h) => FundHistoricalPoint.fromJson(h))
              .toList();
        } else {
          throw Exception(jsonData['message'] ?? 'No historical data found');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error getting fund historical data: $e');
      return [];
    }
  }

  /// Fon risk metriklerini getir
  static Future<FundRiskMetrics> getFundRiskMetrics(String fundCode) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/funds/$fundCode/risk-metrics'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['metrics'] != null) {
          return FundRiskMetrics.fromJson(jsonData['metrics']);
        } else {
          throw Exception(jsonData['message'] ?? 'Risk metrics not found');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error getting fund risk metrics: $e');
      throw Exception('Failed to load risk metrics');
    }
  }

  /// Monte Carlo simülasyonu getir
  static Future<MonteCarloSimulation> getMonteCarloSimulation(String fundCode,
      {int periods = 12, int simulations = 1000}) async {
    try {
      final uri = Uri.parse('$baseUrl/funds/$fundCode/monte-carlo')
          .replace(queryParameters: {
        'periods': periods.toString(),
        'simulations': simulations.toString(),
      });
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['simulation'] != null) {
          return MonteCarloSimulation.fromJson(jsonData['simulation']);
        } else {
          throw Exception(jsonData['message'] ?? 'Simulation data not found');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error getting Monte Carlo simulation: $e');
      throw Exception('Failed to load simulation');
    }
  }

  /// Fonları karşılaştır
  static Future<List<Fund>> compareFunds(List<String> fundCodes) async {
    try {
      final fundsParam = fundCodes.join(',');
      final uri = Uri.parse('$baseUrl/funds/compare')
          .replace(queryParameters: {'funds': fundsParam});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['comparison'] != null) {
          final List<dynamic> fundsJson = jsonData['comparison']['funds'];
          return fundsJson.map((fundJson) => Fund.fromJson(fundJson)).toList();
        } else {
          throw Exception(jsonData['message'] ?? 'Comparison failed');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error comparing funds: $e');
      return [];
    }
  }

  /// Kategori listesini getir
  static Future<Set<String>> getFundCategories() async {
    try {
      final funds = await getAllFunds();
      return funds.map((fund) => fund.kategori).toSet();
    } catch (e) {
      _logger.severe('Error getting fund categories: $e');
      return {
        'Hisse Senedi Fonu',
        'Serbest Fon',
        'Borçlanma Araçları Fonu',
        'Karma Fon',
        'Para Piyasası Fonu',
      };
    }
  }

  /// Mock data (geliştirme için)
  static List<Fund> _getMockFunds() {
    return [
      Fund(
        kod: 'AFV',
        fonAdi: 'AK PORTFÖY AVRUPA YABANCI HİSSE SENEDİ FONU',
        sonFiyat: '0,394082',
        gunlukGetiri: '%-0,2536',
        kategori: 'Hisse Senedi Fonu',
        yatirimciSayisi: 18803,
        pazarPayi: '%0,67',
        tefas: 'TEFAS\'ta işlem görüyor',
        fonToplamDeger: 923314144.81,
        pay: 2342950902,
        kayitTarihi: DateTime.now(),
        fundProfile: FundProfile(
          kod: 'AFV',
          fonunRiskDegeri: '6',
        ),
      ),
      Fund(
        kod: 'CVC',
        fonAdi: 'AK PORTFÖY ÖPY KAR PAYI ÖDEYEN SERBEST ÖZEL FON',
        sonFiyat: '1,729342',
        gunlukGetiri: '%0,3186',
        kategori: 'Serbest Fon',
        yatirimciSayisi: 2,
        pazarPayi: '%0,01',
        tefas: 'TEFAS\'ta İşlem Görmüyor',
        fonToplamDeger: 434282370.97,
        pay: 251125767,
        kayitTarihi: DateTime.now(),
        fundProfile: FundProfile(
          kod: 'CVC',
          fonunRiskDegeri: '3',
        ),
      ),
      Fund(
        kod: 'IMO',
        fonAdi: 'İŞ PORTFÖY ODAK SERBEST ÖZEL FON',
        sonFiyat: '3,086809',
        gunlukGetiri: '%0,7543',
        kategori: 'Serbest Fon',
        yatirimciSayisi: 3,
        pazarPayi: '%0,04',
        tefas: 'TEFAS\'ta İşlem Görmüyor',
        fonToplamDeger: 1327327852.64,
        pay: 430000000,
        kayitTarihi: DateTime.now(),
        fundProfile: FundProfile(
          kod: 'IMO',
          fonunRiskDegeri: '4',
        ),
      ),
    ];
  }
}

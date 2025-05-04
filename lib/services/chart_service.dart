import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/candle_data.dart';
import '../models/indicator.dart';

class ChartService {
  // API'nin base URL'i - Kendi sunucu adresinizle değiştirin
  static const String baseUrl =
      'https://feof-all-base-complimentary.trycloudflare.com/api';

  // Tarihsel veri almak için API çağrısı
  static Future<List<CandleData>> getHistoricalData(
    String ticker,
    String timeframe,
    List<String> indicators,
    List<int> maPeriods,
  ) async {
    final maPeriodsStr = maPeriods.join(',');
    final indicatorsStr = indicators.join(',');

    // “Volume” seçilmediyse showVolume=false gönder
    final showVolume = indicators.contains('Volume');

    final uri = Uri.parse(
      '$baseUrl/stock'
      '?ticker=$ticker'
      '&timeframe=$timeframe'
      '&chartType=Candle'
      '&indicators=$indicatorsStr'
      '&movingAverages=$maPeriodsStr'
      '&showVolume=$showVolume',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> raw = jsonResponse['chart_data'];
          return raw.map((e) => CandleData.fromJson(e)).toList();
        }
        throw Exception(jsonResponse['message'] ?? 'Veri alınamadı');
      }
      throw Exception('API ${response.statusCode}');
    } catch (e) {
      throw Exception('Veri alınamadı: $e');
    }
  }

  // Belirli bir göstergeyi almak için API çağrısı
  static Future<dynamic> getIndicatorData(
    String ticker,
    String timeframe,
    String indicator,
    List<int> periods,
  ) async {
    try {
      // İsteği hazırla
      final periodsStr = periods.join(',');

      final url = Uri.parse(
        '$baseUrl/indicator?ticker=$ticker&timeframe=$timeframe&indicator=$indicator&periods=$periodsStr',
      );

      final response = await http.get(url);

      // Başarılı cevap kontrolü
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data'];
        } else {
          throw Exception(
              jsonResponse['message'] ?? 'Gösterge verisi alınamadı');
        }
      } else {
        throw Exception('API isteği başarısız: ${response.statusCode}');
      }
    } catch (e) {
      print('Gösterge verisi alınırken hata: $e');
      throw Exception('Gösterge verisi alınamadı: $e');
    }
  }

  // Birden fazla göstergeyi tek seferde almak için API çağrısı
  static Future<Map<String, dynamic>> getMultipleIndicators(
    String ticker,
    String timeframe,
    List<String> indicators,
    List<int> maPeriods,
  ) async {
    try {
      // İsteği hazırla
      final indicatorsStr = indicators.join(',');
      final maPeriodsStr = maPeriods.join(',');

      final url = Uri.parse(
        '$baseUrl/indicators?ticker=$ticker&timeframe=$timeframe&indicators=$indicatorsStr&movingAverages=$maPeriodsStr',
      );

      final response = await http.get(url);

      // Başarılı cevap kontrolü
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          return jsonResponse['indicators'];
        } else {
          throw Exception(
              jsonResponse['message'] ?? 'Gösterge verileri alınamadı');
        }
      } else {
        throw Exception('API isteği başarısız: ${response.statusCode}');
      }
    } catch (e) {
      print('Gösterge verileri alınırken hata: $e');
      throw Exception('Gösterge verileri alınamadı: $e');
    }
  }

  // Backtesting için API çağrısı
  static Future<Map<String, dynamic>> runBacktest(
    String ticker,
    String strategy,
    Map<String, dynamic> parameters,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // İsteği hazırla
      final url = Uri.parse('$baseUrl/backtest');

      final Map<String, dynamic> requestBody = {
        'ticker': ticker,
        'strategy': strategy,
        'parameters': parameters,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // Başarılı cevap kontrolü
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          return jsonResponse['results'];
        } else {
          throw Exception(
              jsonResponse['message'] ?? 'Backtest çalıştırılamadı');
        }
      } else {
        throw Exception('API isteği başarısız: ${response.statusCode}');
      }
    } catch (e) {
      print('Backtest çalıştırılırken hata: $e');
      throw Exception('Backtest çalıştırılamadı: $e');
    }
  }
}

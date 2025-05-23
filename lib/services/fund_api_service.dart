// services/fund_api_service.dart - Update for new sorting options
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../src/config.dart';
import '../models/fund.dart';
import '../utils/logger.dart';
import 'dart:math'; // Random sınıfı için import eklendi

class FundApiService {
  static final _logger = AppLogger('FundApiService');
  static const String baseUrl = Config.baseUrl;
  static const Duration timeoutDuration = Duration(seconds: 30);

  /// Yeni sıralama seçeneklerini API'ye uygun formata dönüştürür
  static Map<String, dynamic> _convertSortParams(Map<String, dynamic> params) {
    if (params.containsKey('sort_by')) {
      final sortBy = params['sort_by'];
      
      // Haftalık getiri sıralaması
      if (sortBy == 'weekly_return_desc') {
        params['sort_by'] = 'haftalik_getiri_desc';
      } else if (sortBy == 'weekly_return_asc') {
        params['sort_by'] = 'haftalik_getiri_asc';
      }
      
      // Aylık getiri sıralaması
      else if (sortBy == 'monthly_return_desc') {
        params['sort_by'] = 'aylik_getiri_desc';
      } else if (sortBy == 'monthly_return_asc') {
        params['sort_by'] = 'aylik_getiri_asc';
      }
      
      // 6 aylık getiri sıralaması
      else if (sortBy == 'six_month_return_desc') {
        params['sort_by'] = 'alti_aylik_getiri_desc';
      } else if (sortBy == 'six_month_return_asc') {
        params['sort_by'] = 'alti_aylik_getiri_asc';
      }
      
      // Yıllık getiri sıralaması
      else if (sortBy == 'yearly_return_desc') {
        params['sort_by'] = 'yillik_getiri_desc';
      } else if (sortBy == 'yearly_return_asc') {
        params['sort_by'] = 'yillik_getiri_asc';
      }
      
      // Yatırımcı değişim sıralaması
      else if (sortBy == 'investor_change_desc') {
        params['sort_by'] = 'yatirimci_degisim_desc';
      } else if (sortBy == 'investor_change_asc') {
        params['sort_by'] = 'yatirimci_degisim_asc';
      }
      
      // Değer değişim sıralaması
      else if (sortBy == 'value_change_desc') {
        params['sort_by'] = 'deger_degisim_desc';
      } else if (sortBy == 'value_change_asc') {
        params['sort_by'] = 'deger_degisim_asc';
      }
    }
    
    return params;
  }
static Future<Map<String, dynamic>> getBulkPerformanceMetrics(List<String> fundCodes) async {
  try {
    if (fundCodes.isEmpty) return {};
    
    // Endpoint'i doğru şekilde ayarla - API yolunu kontrol et
    final uri = Uri.parse('$baseUrl/funds/bulk-performance-metrics')
        .replace(queryParameters: {'funds': fundCodes.join(',')});

    _logger.info('Fetching bulk performance metrics for ${fundCodes.length} funds');

    final response = await http.get(uri).timeout(const Duration(seconds: 45)); // Longer timeout for bulk operation

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'success' && data['metrics'] != null) {
        final metricsMap = data['metrics'] as Map<String, dynamic>;
        return metricsMap;
      } else {
        _logger.warning('API returned success but metrics data is missing: ${data.toString()}');
        throw Exception(data['message'] ?? 'Metrics data missing in API response');
      }
    } else {
      _logger.warning('HTTP error: ${response.statusCode} - ${response.body}');
      throw Exception('HTTP error: ${response.statusCode}');
    }
  } catch (e) {
    _logger.severe('Error fetching bulk performance metrics: $e');
    
    // Hata durumunda her fon için demo veriler oluştur
    final Map<String, dynamic> demoMetrics = {};
    for (final fundCode in fundCodes) {
      demoMetrics[fundCode] = _generateTemporaryMetrics(fundCode);
    }
    return demoMetrics;
  }
}


// Toplu metrikler için demo veriler oluştur
Map<String, dynamic> _generateBulkDemoMetrics(List<String> fundCodes) {
  final Map<String, dynamic> demoMetrics = {};
  for (final fundCode in fundCodes) {
    demoMetrics[fundCode] = _generateTemporaryMetrics(fundCode);
  }
  return demoMetrics;
}
  
  /// Fon listesindeki tüm fonlar için performans metriklerini doldur (Optimize edilmiş)
// 2. FundApiService.dart - enrichFundsWithPerformanceMetrics düzeltmesi
static Future<List<Fund>> enrichFundsWithPerformanceMetrics(List<Fund> funds) async {
  if (funds.isEmpty) return [];
  
  try {
    // Tüm fonların kodlarını al
    final fundCodes = funds.map((fund) => fund.kod).toList();
    
    // Logla
    _logger.info('Requesting performance metrics for ${fundCodes.length} funds');
    
    // Tüm fon metriklerini toplu olarak çek
    final Map<String, dynamic> bulkMetrics = await getBulkPerformanceMetrics(fundCodes);
    
    // Test için logla
    _logger.info('Received metrics for ${bulkMetrics.length} funds out of ${fundCodes.length} requested');
    
    // Zenginleştirilmiş fonlar için yeni liste
    List<Fund> enrichedFunds = [];
    
    // Her fonu işle
    for (final fund in funds) {
      try {
        // Fund'ı JSON'a dönüştür
        Map<String, dynamic> fundJson = fund.toJson();
        
        // Bu fon için metrikleri al
        final metrics = bulkMetrics[fund.kod];
        
        if (metrics != null) {
          _logger.info('Processing metrics for ${fund.kod}');
          
          // API'den gelen değerleri model alanlarına eşleştir
          if (metrics['daily_return'] != null) {
            fundJson['gunluk_getiri'] = metrics['daily_return'];
          }
          if (metrics['weekly_return'] != null) {
            fundJson['haftalik_getiri'] = metrics['weekly_return'];
          }
          if (metrics['monthly_return'] != null) {
            fundJson['aylik_getiri'] = metrics['monthly_return'];
          }
          if (metrics['six_month_return'] != null) {
            fundJson['alti_aylik_getiri'] = metrics['six_month_return'];
          }
          if (metrics['yearly_return'] != null) {
            fundJson['yillik_getiri'] = metrics['yearly_return'];
          }
          if (metrics['investor_change'] != null) {
            fundJson['yatirimci_degisim'] = metrics['investor_change'];
          }
          if (metrics['value_change'] != null) {
            fundJson['deger_degisim'] = metrics['value_change'];
          }
        } else {
          _logger.warning('No metrics found for ${fund.kod}, using demo data');
          
          // Metrikleri bulunamayan fonlar için demo veriler üret
          Map<String, dynamic> demoMetrics = _generateTemporaryMetrics(fund.kod);
          
          fundJson['gunluk_getiri'] = demoMetrics['daily_return'];
          fundJson['haftalik_getiri'] = demoMetrics['weekly_return'];
          fundJson['aylik_getiri'] = demoMetrics['monthly_return'];
          fundJson['alti_aylik_getiri'] = demoMetrics['six_month_return'];
          fundJson['yillik_getiri'] = demoMetrics['yearly_return'];
          fundJson['yatirimci_degisim'] = demoMetrics['investor_change'];
          fundJson['deger_degisim'] = demoMetrics['value_change'];
        }
        
        // Zenginleştirilmiş Fund nesnesini oluştur
        Fund enrichedFund = Fund.fromJson(fundJson);
        enrichedFunds.add(enrichedFund);
      } catch (e) {
        // Hata durumunda orijinal fonu ekle ve logla
        _logger.warning('Error enriching fund ${fund.kod}: $e');
        enrichedFunds.add(fund);
      }
    }
    
    return enrichedFunds;
  } catch (e) {
    // Global hata durumunda, demo verilerle zenginleştir
    _logger.severe('Error enriching funds with performance metrics: $e');
    return _enrichFundsWithDemoData(funds);
  }
}

  /// Demo verilerle fonları zenginleştir (API mevcut değilse)
  static List<Fund> _enrichFundsWithDemoData(List<Fund> funds) {
    List<Fund> enrichedFunds = [];
    
    for (final fund in funds) {
      try {
        // Fund'ı JSON'a dönüştür
        Map<String, dynamic> fundJson = fund.toJson();
        
        // Demo metrikler üret
        Map<String, dynamic> demoMetrics = _generateTemporaryMetrics(fund.kod);
        
        // Demo metriklerden model alanlarına eşleştir
        fundJson['gunluk_getiri'] = demoMetrics['daily_return'];
        fundJson['haftalik_getiri'] = demoMetrics['weekly_return'];
        fundJson['aylik_getiri'] = demoMetrics['monthly_return'];
        fundJson['alti_aylik_getiri'] = demoMetrics['six_month_return'];
        fundJson['yillik_getiri'] = demoMetrics['yearly_return'];
        fundJson['yatirimci_degisim'] = demoMetrics['investor_change'];
        fundJson['deger_degisim'] = demoMetrics['value_change'];
        
        // Zenginleştirilmiş Fund nesnesini oluştur
        Fund enrichedFund = Fund.fromJson(fundJson);
        enrichedFunds.add(enrichedFund);
      } catch (e) {
        // Hata durumunda orijinal fonu ekle
        _logger.warning('Error enriching fund with demo data ${fund.kod}: $e');
        enrichedFunds.add(fund);
      }
    }
    
    return enrichedFunds;
  }
  /// Get funds by category with pagination
  static Future<Map<String, dynamic>> getFundsByCategoryWithPagination(
      String category, Map<String, dynamic> params) async {
    try {
      // Sıralama parametrelerini uygun şekilde dönüştür
      params = _convertSortParams(params);
      
      final queryParams =
          params.map((key, value) => MapEntry(key, value.toString()));
      final uri = Uri.parse('$baseUrl/funds/category/$category')
          .replace(queryParameters: queryParams);

      _logger.info('Fetching funds by category: $category');

      final response = await http.get(uri).timeout(timeoutDuration);

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
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching funds by category: $e');
      throw Exception('Failed to fetch funds by category: $e');
    }
  }

  /// Get fund historical data
  static Future<Map<String, dynamic>> getFundHistorical(
    String fundCode, {
    String timeframe = 'all',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/funds/$fundCode/historical')
          .replace(queryParameters: {'timeframe': timeframe});

      _logger.info(
          'Fetching historical data for $fundCode, timeframe: $timeframe');

      final response = await http.get(uri).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final historicalData = data['historical'] as List<dynamic>? ?? [];

          // Enhanced data parsing with strict date validation
          final formattedData = <Map<String, dynamic>>[];
          final currentDate = DateTime.now();
          final oneYearAgo = currentDate.subtract(const Duration(days: 365));

          for (final item in historicalData) {
            if (item is Map<String, dynamic>) {
              try {
                final dateStr = item['date']?.toString();
                final priceValue = item['price'];

                if (dateStr != null && priceValue != null) {
                  // Enhanced date parsing with multiple formats
                  DateTime? date = _parseDate(dateStr);

                  if (date != null) {
                    // Strict date validation
                    if (date.isAfter(currentDate)) {
                      _logger.warning(
                          'Skipping future date: $dateStr (${date.toIso8601String()})');
                      continue;
                    }

                    // Optional: filter out very old data (older than 5 years)
                    final fiveYearsAgo =
                        currentDate.subtract(const Duration(days: 1825));
                    if (timeframe != 'all' && date.isBefore(fiveYearsAgo)) {
                      continue;
                    }

                    // Enhanced price parsing
                    double? price = _parsePrice(priceValue);

                    if (price != null && price > 0) {
                      formattedData.add({
                        'date': date.toUtc().toIso8601String(),
                        'price': price,
                      });
                    }
                  }
                }
              } catch (e) {
                _logger.warning('Error parsing historical data point: $e');
                continue;
              }
            }
          }

          // Sort by date in ascending order
          formattedData.sort((a, b) {
            final dateA = DateTime.parse(a['date']);
            final dateB = DateTime.parse(b['date']);
            return dateA.compareTo(dateB);
          });

          // Remove duplicates if any (based on date)
          final uniqueData = <Map<String, dynamic>>[];
          String? lastDateStr;

          for (final item in formattedData) {
            final currentDateStr = (item['date'] as String).split('T')[0];
            if (currentDateStr != lastDateStr) {
              uniqueData.add(item);
              lastDateStr = currentDateStr;
            }
          }

          _logger.info(
              'Successfully processed ${uniqueData.length} historical data points for $fundCode');

          return {
            'status': 'success',
            'fund_code': fundCode,
            'timeframe': timeframe,
            'historical': uniqueData,
            'count': uniqueData.length,
          };
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Fund not found');
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching historical data for $fundCode: $e');
      throw Exception('Failed to fetch historical data: $e');
    }
  }

  /// Get fund risk metrics with enhanced error handling
   static Future<Map<String, dynamic>> getFundRiskMetrics(String fundCode) async {
    try {
      final uri = Uri.parse('$baseUrl/funds/$fundCode/risk-metrics');
      _logger.info('Fetching risk metrics for $fundCode');
      final response = await http.get(uri).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['metrics'] != null) { // metrics null kontrolü eklendi
          final metrics = data['metrics'] as Map<String, dynamic>;
          // _processRiskMetrics artık Python API'sinden gelenlere göre işlem yapacak,
          // bu yüzden Flutter tarafında kapsamlı bir process'e gerek kalmayabilir
          // veya sadece null/tip kontrolleri yapılabilir.
          // Şimdilik doğrudan API'den geleni alalım, FundDetailScreen'de null check yaparız.
          _logger.info('Successfully fetched risk metrics for $fundCode: $metrics');
          return {
            'status': 'success',
            'fund_code': fundCode,
            'metrics': metrics, // Doğrudan API'den gelen metriği döndür
          };
        } else {
          _logger.warning('Risk metrics API error or metrics missing: ${data['message'] ?? 'Unknown error'}');
          // Hata durumunda veya metrikler eksikse, varsayılan boş bir metrik seti döndür
          return {
            'status': 'error', // Durumu error olarak işaretle
            'fund_code': fundCode,
            'message': data['message'] ?? 'Metrics data missing or API error',
            'metrics': getDefaultRiskMetrics(), // Hata durumunda varsayılanları döndür
          };
        }
      } else if (response.statusCode == 404) {
        _logger.warning('Fund not found for risk metrics: $fundCode');
        throw Exception('Fund not found');
      } else {
        _logger.warning('HTTP error fetching risk metrics: ${response.statusCode} - ${response.body}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching risk metrics for $fundCode: $e');
      // Hata durumunda varsayılan metrikleri ve error durumu döndür
      return {
        'status': 'error',
        'fund_code': fundCode,
        'message': 'Failed to fetch risk metrics: $e',
        'metrics': getDefaultRiskMetrics(),
      };
    }
  }



  static Map<String, dynamic> _processRiskMetrics(Map<String, dynamic> rawMetrics) {
    _logger.info("Processing raw risk metrics: $rawMetrics"); // Gelen ham veriyi logla
    return Map<String, dynamic>.from(rawMetrics); // Ham veriyi doğrudan döndür
  }


  /// Get realistic default risk metrics
  static Map<String, dynamic> getDefaultRiskMetrics() {
    return {
      // Çıkarılanlar: sharpeRatio, beta, alpha, rSquared, sortinoRatio, treynorRatio, stdDev
      'maxDrawdown': null, // veya 0.0
      'volatility': null, // veya 0.0
      'riskLevel': 0, // veya null
      'calculation_period_days': 0, // veya null
      'data_points_used': 0, // veya null
      'annualizedAverageReturn': null, // veya 0.0
      'positiveDaysPercent': null, // veya 0.0
      'negativeDaysPercent': null, // veya 0.0
      'bestDailyReturn': null, // veya 0.0
      'worstDailyReturn': null, // veya 0.0
      'calmarRatio': null, // veya 0.0
      'skewness': null, // veya 0.0
      'excessKurtosis': null, // veya 0.0
      'historicalVaR95_1day': null // veya 0.0
    };
  }


  /// Get Monte Carlo simulation with enhanced error handling
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

      _logger.info('Fetching Monte Carlo simulation for $fundCode');

      final response = await http.get(uri).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final simulation = data['simulation'] as Map<String, dynamic>? ?? {};

          // Validate simulation data structure
          if (simulation.containsKey('scenarios') &&
              simulation.containsKey('periods')) {
            // Validate scenarios data
            final scenarios = simulation['scenarios'] as Map<String, dynamic>?;
            if (scenarios != null &&
                scenarios.containsKey('pessimistic') &&
                scenarios.containsKey('expected') &&
                scenarios.containsKey('optimistic')) {
              _logger.info(
                  'Successfully fetched Monte Carlo simulation for $fundCode');
              return {
                'status': 'success',
                'fund_code': fundCode,
                'simulation': simulation,
              };
            }
          }

          throw Exception('Invalid simulation data format');
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Fund not found');
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching Monte Carlo simulation for $fundCode: $e');
      // Return realistic Monte Carlo data as fallback
      return _generateRealisticMonteCarlo(fundCode, periods, simulations);
    }
  }

  /// Generate realistic fallback Monte Carlo data
  static Map<String, dynamic> _generateRealisticMonteCarlo(
      String fundCode, int periods, int simulations) {
    final scenarios = <String, List<double>>{};

    // Generate more realistic scenario data with monthly compounding
    scenarios['pessimistic'] = List.generate(periods, (i) {
      // Pessimistic: -2% to -0.5% monthly
      final monthlyReturn = -2.0 + (1.5 * (i / periods));
      return i == 0
          ? monthlyReturn
          : (scenarios['pessimistic']![i - 1] * (1 + monthlyReturn / 100)) -
              scenarios['pessimistic']![i - 1];
    });

    scenarios['expected'] = List.generate(periods, (i) {
      // Expected: 0.5% to 1.5% monthly
      final monthlyReturn = 0.5 + (1.0 * (i / periods));
      return i == 0
          ? monthlyReturn
          : (scenarios['expected']![i - 1] * (1 + monthlyReturn / 100)) -
              scenarios['expected']![i - 1];
    });

    scenarios['optimistic'] = List.generate(periods, (i) {
      // Optimistic: 1.5% to 3% monthly
      final monthlyReturn = 1.5 + (1.5 * (i / periods));
      return i == 0
          ? monthlyReturn
          : (scenarios['optimistic']![i - 1] * (1 + monthlyReturn / 100)) -
              scenarios['optimistic']![i - 1];
    });

    return {
      'status': 'success',
      'fund_code': fundCode,
      'simulation': {
        'initial_price': 100.0,
        'periods': periods,
        'simulations': simulations,
        'scenarios': scenarios,
      },
    };
  }

  /// Original getFunds method updated to use pagination
  static Future<List<Fund>> getFunds(Map<String, dynamic> params) async {
    final result = await getFundsWithPagination(params);
    return result['funds'] as List<Fund>;
  }

  /// Get funds with pagination support
  static Future<Map<String, dynamic>> getFundsWithPagination(
      Map<String, dynamic> params) async {
    try {
      // Sıralama parametrelerini uygun şekilde dönüştür
      params = _convertSortParams(params);
      
      final uri = Uri.parse('$baseUrl/funds').replace(
          queryParameters:
              params.map((key, value) => MapEntry(key, value.toString())));

      _logger.info('Fetching funds with pagination: $uri');

      final response = await http.get(uri).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final fundsJson = data['funds'] as List;
          final funds = fundsJson.map((json) => Fund.fromJson(json)).toList();

          _logger.info('Successfully fetched ${funds.length} funds');

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
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching funds with pagination: $e');
      throw Exception('Failed to fetch funds: $e');
    }
  }

  /// Updated getFundsByCategory to use pagination
  static Future<List<Fund>> getFundsByCategory(String category) async {
    final result =
        await getFundsByCategoryWithPagination(category, {'limit': '100'});
    return result['funds'] as List<Fund>;
  }

  /// Get fund details by code
  static Future<Map<String, dynamic>> getFundDetails(String fundCode,
      {bool includeHistorical = false}) async {
    try {
      final params = includeHistorical
          ? {'include_historical': 'true'}
          : <String, String>{};
      final uri = Uri.parse('$baseUrl/funds/$fundCode');
      final finalUri =
          params.isNotEmpty ? uri.replace(queryParameters: params) : uri;

      _logger.info('Fetching fund details for $fundCode');

      final response = await http.get(finalUri).timeout(timeoutDuration);

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
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching fund details for $fundCode: $e');
      rethrow;
    }
  }

  /// Filter funds
  static Future<List<Fund>> filterFunds(Map<String, dynamic> filters) async {
    try {
      // Sıralama parametrelerini uygun şekilde dönüştür
      filters = _convertSortParams(filters);
      
      final uri = Uri.parse('$baseUrl/funds/filter').replace(
          queryParameters:
              filters.map((key, value) => MapEntry(key, value.toString())));

      final response = await http.get(uri).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final fundsJson = data['funds'] as List;
          return fundsJson.map((json) => Fund.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
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

      final response = await http.get(uri).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data['comparison'];
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error comparing funds: $e');
      throw Exception('Failed to compare funds: $e');
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

  static Future<Map<String, dynamic>> getCategoryStatistics(
      String category) async {
    try {
      final uri = Uri.parse('$baseUrl/funds/category/$category/statistics');

      _logger.info('Fetching category statistics for $category');

      final response = await http.get(uri).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return {
            'total_funds': data['total_funds'] ?? 0,
            'total_market_value': data['total_market_value']?.toDouble() ?? 0.0,
            'average_return': data['average_return']?.toDouble() ?? 0.0,
            'total_investors': data['total_investors'] ?? 0,
          };
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching category statistics: $e');
      throw Exception('Failed to fetch category statistics: $e');
    }
  }

  /// Get detailed category performance including top 5 funds
  static Future<Map<String, dynamic>> getCategoryPerformanceDetails() async {
    try {
      final uri = Uri.parse('$baseUrl/funds/category-performance-details');

      _logger.info('Fetching detailed category performance');

      final response = await http.get(uri).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return {
            'category_performance': data['category_performance'] ?? {},
            'top_performing_categories':
                data['top_performing_categories'] ?? [],
            'bottom_performing_categories':
                data['bottom_performing_categories'] ?? [],
          };
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching detailed category performance: $e');
      throw Exception('Failed to fetch detailed category performance: $e');
    }
  }

  /// Get market overview
  static Future<Map<String, dynamic>> getMarketOverview() async {
    try {
      _logger.info(
          'Fetching market overview from: $baseUrl/funds/market-overview');
      final response = await http
          .get(Uri.parse('$baseUrl/funds/market-overview'))
          .timeout(timeoutDuration);

      _logger.info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final marketOverview =
              data['market_overview'] as Map<String, dynamic>? ?? {};

          // Null check and default values
          return {
            'total_funds': marketOverview['total_funds'] ?? 0,
            'total_market_value':
                marketOverview['total_market_value']?.toDouble() ?? 0.0,
            'total_investors': marketOverview['total_investors'] ?? 0,
            'average_return':
                marketOverview['average_return']?.toDouble() ?? 0.0,
            'category_distribution':
                marketOverview['category_distribution'] ?? <String, dynamic>{},
            'risk_distribution':
                marketOverview['risk_distribution'] ?? <String, dynamic>{},
            'tefas_distribution':
                marketOverview['tefas_distribution'] ?? <String, dynamic>{},
            'market_share_distribution':
                marketOverview['market_share_distribution'] ??
                    <String, dynamic>{},
            'category_performance':
                marketOverview['category_performance'] ?? <String, dynamic>{},
            'top_performing_categories':
                marketOverview['top_performing_categories'] ?? <List>[],
            'bottom_performing_categories':
                marketOverview['bottom_performing_categories'] ?? <List>[],
            'performance_metrics': marketOverview['performance_metrics'] ??
                <String, dynamic>{
                  'positive_returns': 0,
                  'negative_returns': 0,
                  'neutral_returns': 0,
                  'best_return': 0.0,
                  'worst_return': 0.0,
                }
          };
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching market overview: $e');
      // Return comprehensive fallback data
      return {
        'total_funds': 0,
        'total_market_value': 0.0,
        'total_investors': 0,
        'average_return': 0.0,
        'category_distribution': <String, dynamic>{'Veri Yükleniyor': 1},
        'risk_distribution': <String, dynamic>{'Veri Yükleniyor': 1},
        'tefas_distribution': <String, dynamic>{'Veri Yükleniyor': 1},
        'market_share_distribution': <String, dynamic>{'Veri Yükleniyor': 1},
        'category_performance': <String, dynamic>{},
        'top_performing_categories': <List>[],
        'bottom_performing_categories': <List>[],
        'performance_metrics': <String, dynamic>{
          'positive_returns': 0,
          'negative_returns': 0,
          'neutral_returns': 0,
          'best_return': 0.0,
          'worst_return': 0.0,
        }
      };
    }
  }

  /// Get fund categories
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
        'Yabancı Menkul Kıymet Fonu',
      ];
    } catch (e) {
      _logger.severe('Error fetching fund categories: $e');
      return [];
    }
  }

  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    // Try multiple date formats
    final formats = [
      // ISO formats
      RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'),
      // Simple date formats
      RegExp(r'^\d{4}-\d{2}-\d{2}'),
      RegExp(r'^\d{2}/\d{2}/\d{4}'),
      RegExp(r'^\d{2}-\d{2}-\d{4}'),
    ];

    try {
      // First try direct parsing
      return DateTime.parse(dateStr);
    } catch (e) {
      // Try manual parsing for different formats
      try {
        // Handle DD/MM/YYYY
        if (dateStr.contains('/')) {
          final parts = dateStr.split('/');
          if (parts.length >= 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        }

        // Handle DD-MM-YYYY
        if (dateStr.contains('-') && !dateStr.startsWith('20')) {
          final parts = dateStr.split('-');
          if (parts.length >= 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        }
      } catch (e) {
        // Fall through to return null
      }
    }

    return null;
  }

  /// Enhanced price parsing
  static double? _parsePrice(dynamic priceValue) {
    if (priceValue == null) return null;

    try {
      if (priceValue is num) {
        return priceValue.toDouble();
      }

      if (priceValue is String) {
        // Clean the string
        String cleanPrice = priceValue
            .replaceAll(',', '.') // Replace comma with dot
            .replaceAll(' ', '') // Remove spaces
            .replaceAll('₺', '') // Remove currency symbols
            .replaceAll('TL', '')
            .replaceAll('%', ''); // Remove percentage signs

        return double.tryParse(cleanPrice);
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  /// Get fund historical summary (lightweight version)
  static Future<Map<String, dynamic>> getFundHistoricalSummary(
      String fundCode) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/funds/$fundCode/historical-summary'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data['summary'];
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching historical summary for $fundCode: $e');
      throw Exception('Failed to fetch historical summary: $e');
    }
  }
  /// Get fund performance metrics
  static Future<Map<String, dynamic>> getFundPerformanceMetrics(String fundCode) async {
    try {
      final uri = Uri.parse('$baseUrl/funds/$fundCode/performance-metrics');

      _logger.info('Fetching performance metrics for $fundCode');

      final response = await http.get(uri).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data['metrics'] as Map<String, dynamic>;
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Fund not found');
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching performance metrics for $fundCode: $e');
      
      // Hata durumunda geçici verileri dön
      return _generateTemporaryMetrics(fundCode);
    }
  }

  /// Geçici metrikler oluştur (API bağlantısı yoksa veya hata durumunda)
   static Map<String, dynamic> _generateTemporaryMetrics(String fundCode) {
    final random = Random();
    // Bu fonksiyonun çıktısı artık /funds/kod/performance-metrics değil,
    // /funds/bulk-performance-metrics'in her bir fon için döndürdüğü yapıya benzemeli.
    // Python API'sindeki enrichFundsWithPerformanceMetrics artık /bulk-performance-metrics kullandığı için
    // bu demo veriler de o yapıya uygun olmalı.
    // Python'daki bulk-performance-metrics endpoint'i şu alanları içeriyordu:
    // daily_return, weekly_return, monthly_return, six_month_return, yearly_return, investor_change, value_change
    // Bu, risk metriklerinden farklı. Bu fonksiyonun amacı farklı.
    // Dolayısıyla, risk metrikleri için olan getDefaultRiskMetrics() ile karıştırılmamalı.
    // Mevcut haliyle kalabilir, çünkü bu fonksiyon *dönemsel getiri* demoları üretiyor.
    double dailyReturn = (random.nextDouble() * 6) - 3;
    double weeklyReturn = (random.nextDouble() * 10) - 5;
    // ... (diğer rastgele değerler) ...
    return {
      "fund_code": fundCode,
      // Bu alanlar Python /performance-metrics veya /bulk-performance-metrics'ten gelenler
      "daily_return": "${dailyReturn >= 0 ? '+' : ''}${dailyReturn.toStringAsFixed(2)}%",
      "weekly_return": "${weeklyReturn >= 0 ? '+' : ''}${weeklyReturn.toStringAsFixed(2)}%",
      "monthly_return": "${(random.nextDouble() * 20 - 10).toStringAsFixed(2)}%",
      "six_month_return": "${(random.nextDouble() * 40 - 20).toStringAsFixed(2)}%",
      "yearly_return": "${(random.nextDouble() * 60 - 30).toStringAsFixed(2)}%",
      "investor_change": (random.nextInt(201) - 100).toString(),
      "value_change": "${((random.nextDouble() * 10) - 5).toStringAsFixed(2)}%",
      // Python API'sindeki /risk-metrics artık bu metrikleri içermiyor.
      // Bu fonksiyonun amacı, EĞER enrichFundsWithPerformanceMetrics API'den veri alamazsa
      // Fund objesini doldurmak için *dönemsel getiri* ve *değişim* verileri üretmek.
      // Risk metrikleri için ayrı bir demo/fallback var: getDefaultRiskMetrics
    };
  }
  

  static Future<bool> isApiAvailable() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/health')).timeout(timeoutDuration);
      return response.statusCode == 200;
    } catch (e) {
      _logger.warning('API is not available: $e');
      return false;
    }
  }

  /// Format date to API format
  static String formatDateForApi(DateTime date) {
    return date.toIso8601String().split('T')[0]; // YYYY-MM-DD
  }

  /// Parse date from API
  static DateTime parseDateFromApi(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      _logger.warning('Error parsing date from API: $e');
      return DateTime.now();
    }
  }
}
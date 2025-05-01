// -------------------------------------------------------------
// backtest_service.dart
// -------------------------------------------------------------
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/backtest_models.dart'; // Model dosyasını import et
import 'package:logging/logging.dart';

/// Backtest API hizmetlerini yöneten servis sınıfı
class BacktestService {
  // Loglama yapılandırması
  static final _logger = Logger('BacktestService');
  static bool _isInitialized = false;

  // API için baz URL - üretimde gerçek sunucu adresinizle değiştirin
   // ÖNEMLİ: Güvenlik nedeniyle bu URL'yi doğrudan koda yazmak yerine
   // yapılandırma dosyasından veya ortam değişkenlerinden okumak daha iyidir.
  static const String baseUrl = 'https://confidentiality-dog-affiliates-storm.trycloudflare.com/api'; // VERİLEN URL

  /// Statik sınıf başlatma (Loglama için)
  static void initialize() {
    if (_isInitialized) return; // Zaten başlatıldıysa tekrar yapma

    // Loglama yapılandırması (Eğer BacktestingScreen'de zaten yapılıyorsa burası isteğe bağlı)
    Logger.root.level = Level.ALL; // Tüm seviyeleri yakala
    Logger.root.onRecord.listen((record) {
       // Yalnızca bu servisle ilgili logları farklı bir formatta yazdırabiliriz
      if (record.loggerName == 'BacktestService') {
        // ignore: avoid_print
        print('[${record.level.name}] (${record.loggerName}) ${record.message}');
         if (record.error != null) { print('  ERROR: ${record.error}'); }
          if (record.stackTrace != null) { print('  STACKTRACE: ${record.stackTrace}'); }
      }
    });
     _logger.info("BacktestService başlatıldı. API URL: $baseUrl");
    _isInitialized = true;
  }

  /// Tüm mevcut stratejileri getirir
  static Future<List<BacktestStrategy>> getStrategies() async {
    final url = Uri.parse('$baseUrl/backtesting/strategies');
    _logger.info('GET isteği gönderiliyor: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15)); // Timeout eklendi

      _logger.info('Yanıt alındı: ${response.statusCode}');
       // Yanıt gövdesini logla (kısa ise tamamı, uzunsa bir kısmı)
       if (response.body.length < 500) {
          _logger.fine('Yanıt gövdesi: ${response.body}');
        } else {
           _logger.fine('Yanıt gövdesi (ilk 500 karakter): ${response.body.substring(0, 500)}...');
        }


      if (response.statusCode == 200) {
        // JSON decode etmeden önce UTF-8 kontrolü (Türkçe karakterler için önemli)
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);

        if (jsonResponse is Map && jsonResponse.containsKey('status') && jsonResponse['status'] == 'success') {
           // 'strategies' anahtarının varlığını ve tipini kontrol et
          if (jsonResponse.containsKey('strategies') && jsonResponse['strategies'] is List) {
              final List<dynamic> strategiesJson = jsonResponse['strategies'] as List;
              final strategies = strategiesJson
                  .map((json) {
                     try {
                       return BacktestStrategy.fromJson(json as Map<String, dynamic>);
                     } catch (e, stackTrace) {
                        _logger.severe('Strateji JSON ayrıştırılırken hata: $json', e, stackTrace);
                       return null; // Hatalı veriyi atla
                     }
                   })
                  .whereType<BacktestStrategy>() // Null olanları filtrele
                  .toList();

              _logger.info('${strategies.length} strateji başarıyla alındı ve ayrıştırıldı.');
              return strategies;
          } else {
             _logger.warning("API yanıtı başarılı ('status':'success') ancak 'strategies' listesi bulunamadı veya formatı yanlış.");
             throw Exception("API yanıt formatı beklenildiği gibi değil (strategies listesi eksik).");
          }
        } else {
            // Başarısız durum veya status alanı yoksa
            final errorMsg = (jsonResponse is Map && jsonResponse.containsKey('message'))
                             ? jsonResponse['message']
                             : 'API\'den başarısız veya beklenmeyen yanıt';
            _logger.warning('API hatası (status != success): $errorMsg');
            throw Exception(errorMsg);
        }
      } else {
        // HTTP 200 dışında bir durum kodu
        _logger.warning('API ${response.statusCode} kodu döndürdü. Yanıt: ${response.body}');
        throw Exception('API ${response.statusCode} kodu döndürdü.');
      }
    } on http.ClientException catch (e, stackTrace) {
        _logger.severe('Ağ hatası (ClientException): Stratejiler alınamadı.', e, stackTrace);
        throw Exception('Ağ hatası: Sunucuya ulaşılamıyor olabilir. ($e)');
    } on TimeoutException catch (e, stackTrace) {
         _logger.severe('İstek zaman aşımına uğradı: Stratejiler alınamadı.', e, stackTrace);
         throw Exception('Sunucu yanıt vermedi (zaman aşımı).');
    } catch (e, stackTrace) {
      // Diğer tüm hatalar (JSON parse hatası vb.)
      _logger.severe('Stratejiler alınırken genel hata.', e, stackTrace);
      // Hatanın türüne göre daha spesifik mesaj verilebilir
      if (e is FormatException) {
        throw Exception('API yanıtı okunamadı (geçersiz format).');
      }
       // Orijinal hatayı tekrar fırlatmak yerine daha kullanıcı dostu bir mesaj
       throw Exception('Stratejiler alınırken bir sorun oluştu.');
       // rethrow; // Eğer orijinal hatayı yukarı katmana iletmek isterseniz
    }
  }

  /// ID ile bir strateji getirir (Şu anki UI'da kullanılmıyor ama API'de var)
  static Future<BacktestStrategy> getStrategy(String id) async {
    final url = Uri.parse('$baseUrl/backtesting/strategies/$id');
     _logger.info('GET isteği gönderiliyor (tek strateji): $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
       _logger.info('Yanıt alındı: ${response.statusCode}');
       _logger.fine('Yanıt gövdesi: ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);
         if (jsonResponse is Map && jsonResponse.containsKey('status') && jsonResponse['status'] == 'success') {
           if (jsonResponse.containsKey('strategy') && jsonResponse['strategy'] is Map) {
             final strategy = BacktestStrategy.fromJson(jsonResponse['strategy'] as Map<String, dynamic>);
             _logger.info('Strateji başarıyla alındı: ${strategy.name} (ID: $id)');
             return strategy;
           } else {
              _logger.warning("API yanıtı başarılı ama 'strategy' nesnesi eksik/yanlış formatta.");
              throw Exception("API yanıt formatı beklenildiği gibi değil (strategy nesnesi eksik).");
           }
         } else {
            final errorMsg = (jsonResponse is Map && jsonResponse.containsKey('message')) ? jsonResponse['message'] : 'API\'den başarısız yanıt';
            _logger.warning('API hatası (status != success): $errorMsg');
            throw Exception(errorMsg);
         }
      } else if (response.statusCode == 404) {
         _logger.warning('Strateji bulunamadı (404): ID $id');
         throw Exception('Belirtilen ID ile strateji bulunamadı.');
      }
       else {
         _logger.warning('API ${response.statusCode} kodu döndürdü. Yanıt: ${response.body}');
         throw Exception('API ${response.statusCode} kodu döndürdü.');
      }
    } on http.ClientException catch (e, stackTrace) {
        _logger.severe('Ağ hatası (ClientException): Strateji alınamadı.', e, stackTrace);
        throw Exception('Ağ hatası: Sunucuya ulaşılamıyor olabilir. ($e)');
    } on TimeoutException catch (e, stackTrace) {
         _logger.severe('İstek zaman aşımına uğradı: Strateji alınamadı.', e, stackTrace);
         throw Exception('Sunucu yanıt vermedi (zaman aşımı).');
    } catch (e, stackTrace) {
      _logger.severe('Strateji (ID: $id) alınırken genel hata.', e, stackTrace);
       if (e is FormatException) { throw Exception('API yanıtı okunamadı (geçersiz format).'); }
      throw Exception('Strateji alınırken bir sorun oluştu.');
    }
  }

  /// Yeni bir strateji oluşturur (Şu anki UI'da tam entegre değil)
  static Future<BacktestStrategy> createStrategy(BacktestStrategy strategy) async {
    final url = Uri.parse('$baseUrl/backtesting/strategies');
     _logger.info('POST isteği gönderiliyor (yeni strateji): $url');

    try {
      // Gönderilecek JSON verisini hazırla ve logla (hassas veri olmamasına dikkat)
      final strategyJson = strategy.toJson();
       // ID varsa kaldır (yeni oluşturulacak)
       strategyJson.remove('id');
       strategyJson.remove('performance'); // Performans bilgisi gönderilmez
       final requestBody = json.encode(strategyJson);
       _logger.fine('İstek Gövdesi: $requestBody');


      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: requestBody,
      ).timeout(const Duration(seconds: 15));

       _logger.info('Yanıt alındı: ${response.statusCode}');
       _logger.fine('Yanıt gövdesi: ${response.body}');

      if (response.statusCode == 201) { // Başarılı oluşturma kodu
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);
        if (jsonResponse is Map && jsonResponse.containsKey('status') && jsonResponse['status'] == 'success') {
           if (jsonResponse.containsKey('strategy') && jsonResponse['strategy'] is Map) {
             final createdStrategy = BacktestStrategy.fromJson(jsonResponse['strategy'] as Map<String, dynamic>);
             _logger.info('Strateji başarıyla oluşturuldu: ${createdStrategy.name} (ID: ${createdStrategy.id})');
             return createdStrategy;
           } else {
              _logger.warning("API yanıtı başarılı (201) ama 'strategy' nesnesi eksik/yanlış formatta.");
              throw Exception("API yanıt formatı beklenildiği gibi değil (strategy nesnesi eksik).");
           }
         } else {
            final errorMsg = (jsonResponse is Map && jsonResponse.containsKey('message')) ? jsonResponse['message'] : 'API\'den başarısız yanıt (201)';
            _logger.warning('API hatası (status != success): $errorMsg');
            throw Exception(errorMsg);
         }
      } else {
         _logger.warning('API ${response.statusCode} kodu döndürdü. Yanıt: ${response.body}');
         // Hata mesajını ayrıştırmaya çalış
         String errorMessage = 'Strateji oluşturulamadı (${response.statusCode}).';
          try {
             final errorJson = json.decode(utf8.decode(response.bodyBytes));
             if (errorJson is Map && errorJson.containsKey('message')) {
                errorMessage = errorJson['message'];
             }
          } catch (_) {} // Ayrıştırma hatasını yoksay
          throw Exception(errorMessage);
      }
    } on http.ClientException catch (e, stackTrace) {
        _logger.severe('Ağ hatası (ClientException): Strateji oluşturulamadı.', e, stackTrace);
        throw Exception('Ağ hatası: Sunucuya ulaşılamıyor olabilir. ($e)');
    } on TimeoutException catch (e, stackTrace) {
         _logger.severe('İstek zaman aşımına uğradı: Strateji oluşturulamadı.', e, stackTrace);
         throw Exception('Sunucu yanıt vermedi (zaman aşımı).');
    } catch (e, stackTrace) {
      _logger.severe('Strateji oluşturulurken genel hata.', e, stackTrace);
       if (e is FormatException) { throw Exception('API yanıtı okunamadı (geçersiz format).'); }
      throw Exception('Strateji oluşturulurken bir sorun oluştu.');
    }
  }

  /// Mevcut bir stratejiyi günceller (Şu anki UI'da tam entegre değil)
  static Future<BacktestStrategy> updateStrategy(BacktestStrategy strategy) async {
    if (strategy.id == null || strategy.id!.isEmpty) {
      const errorMsg = 'Güncelleme için strateji ID gereklidir ve boş olamaz.';
      _logger.severe(errorMsg);
      throw ArgumentError(errorMsg);
    }

    final url = Uri.parse('$baseUrl/backtesting/strategies/${strategy.id}');
    _logger.info('PUT isteği gönderiliyor (strateji güncelleme): $url');

    try {
       final strategyJson = strategy.toJson();
       // ID ve performans alanları JSON'da olmalı ama API bunları kullanmayabilir
        strategyJson.remove('performance'); // Performans bilgisi güncellenmez
        final requestBody = json.encode(strategyJson);
        _logger.fine('İstek Gövdesi: $requestBody');

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: requestBody,
      ).timeout(const Duration(seconds: 15));

      _logger.info('Yanıt alındı: ${response.statusCode}');
      _logger.fine('Yanıt gövdesi: ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);
         if (jsonResponse is Map && jsonResponse.containsKey('status') && jsonResponse['status'] == 'success') {
           if (jsonResponse.containsKey('strategy') && jsonResponse['strategy'] is Map) {
             final updatedStrategy = BacktestStrategy.fromJson(jsonResponse['strategy'] as Map<String, dynamic>);
             _logger.info('Strateji başarıyla güncellendi: ${updatedStrategy.name} (ID: ${updatedStrategy.id})');
             return updatedStrategy;
           } else {
              _logger.warning("API yanıtı başarılı (200) ama 'strategy' nesnesi eksik/yanlış formatta.");
              throw Exception("API yanıt formatı beklenildiği gibi değil (strategy nesnesi eksik).");
           }
         } else {
            final errorMsg = (jsonResponse is Map && jsonResponse.containsKey('message')) ? jsonResponse['message'] : 'API\'den başarısız yanıt (200)';
            _logger.warning('API hatası (status != success): $errorMsg');
            throw Exception(errorMsg);
         }
      } else if (response.statusCode == 404) {
         _logger.warning('Güncellenecek strateji bulunamadı (404): ID ${strategy.id}');
         throw Exception('Güncellenecek strateji bulunamadı.');
      }
      else {
        _logger.warning('API ${response.statusCode} kodu döndürdü. Yanıt: ${response.body}');
          String errorMessage = 'Strateji güncellenemedi (${response.statusCode}).';
          try {
             final errorJson = json.decode(utf8.decode(response.bodyBytes));
             if (errorJson is Map && errorJson.containsKey('message')) {
                errorMessage = errorJson['message'];
             }
          } catch (_) {}
          throw Exception(errorMessage);
      }
    } on http.ClientException catch (e, stackTrace) {
        _logger.severe('Ağ hatası (ClientException): Strateji güncellenemedi.', e, stackTrace);
        throw Exception('Ağ hatası: Sunucuya ulaşılamıyor olabilir. ($e)');
    } on TimeoutException catch (e, stackTrace) {
         _logger.severe('İstek zaman aşımına uğradı: Strateji güncellenemedi.', e, stackTrace);
         throw Exception('Sunucu yanıt vermedi (zaman aşımı).');
    } catch (e, stackTrace) {
      _logger.severe('Strateji (ID: ${strategy.id}) güncellenirken genel hata.', e, stackTrace);
      if (e is FormatException) { throw Exception('API yanıtı okunamadı (geçersiz format).'); }
      throw Exception('Strateji güncellenirken bir sorun oluştu.');
    }
  }

  /// Bir stratejiyi siler
  static Future<bool> deleteStrategy(String id) async {
     if (id.isEmpty) {
      const errorMsg = 'Silme için strateji ID gereklidir ve boş olamaz.';
      _logger.severe(errorMsg);
      throw ArgumentError(errorMsg);
    }
    final url = Uri.parse('$baseUrl/backtesting/strategies/$id');
     _logger.info('DELETE isteği gönderiliyor (strateji silme): $url');

    try {
      final response = await http.delete(url).timeout(const Duration(seconds: 15));

      _logger.info('Yanıt alındı: ${response.statusCode}');
       _logger.fine('Yanıt gövdesi: ${response.body}'); // Genellikle boş veya kısa bir mesaj olur

      if (response.statusCode == 200 || response.statusCode == 204) { // 204 No Content de başarılı sayılabilir
        // Yanıt gövdesi varsa kontrol et
        bool success = false;
         String message = "Strateji başarıyla silindi.";
         if (response.body.isNotEmpty) {
            try {
              final decodedBody = utf8.decode(response.bodyBytes);
              final jsonResponse = json.decode(decodedBody);
              if (jsonResponse is Map && jsonResponse.containsKey('status')) {
                 success = jsonResponse['status'] == 'success';
                  if (jsonResponse.containsKey('message')) {
                     message = jsonResponse['message'];
                  }
              } else {
                 // Eğer JSON formatında değilse veya status yoksa, 200/204 yeterli kabul edilebilir
                 success = true;
              }
            } catch (e) {
               // JSON parse hatası olursa da başarılı sayalım (200/204 geldiği için)
               _logger.warning("Silme yanıtı JSON formatında değil veya ayrıştırılamadı, ancak status code ${response.statusCode} başarılı kabul ediliyor.", e);
               success = true;
            }
         } else {
             // Gövde boşsa, 200/204 başarılı demektir
             success = true;
         }


        if (success) {
          _logger.info(message);
        } else {
          _logger.warning('Strateji silinemedi (API mesajı): $message');
        }
        return success;
      } else if (response.statusCode == 404) {
         _logger.warning('Silinecek strateji bulunamadı (404): ID $id');
          throw Exception('Silinecek strateji bulunamadı.');
      }
      else {
        _logger.warning('API ${response.statusCode} kodu döndürdü. Yanıt: ${response.body}');
         String errorMessage = 'Strateji silinemedi (${response.statusCode}).';
          try {
             final errorJson = json.decode(utf8.decode(response.bodyBytes));
             if (errorJson is Map && errorJson.containsKey('message')) {
                errorMessage = errorJson['message'];
             }
          } catch (_) {}
          throw Exception(errorMessage);
      }
    } on http.ClientException catch (e, stackTrace) {
        _logger.severe('Ağ hatası (ClientException): Strateji silinemedi.', e, stackTrace);
        throw Exception('Ağ hatası: Sunucuya ulaşılamıyor olabilir. ($e)');
    } on TimeoutException catch (e, stackTrace) {
         _logger.severe('İstek zaman aşımına uğradı: Strateji silinemedi.', e, stackTrace);
         throw Exception('Sunucu yanıt vermedi (zaman aşımı).');
    } catch (e, stackTrace) {
      _logger.severe('Strateji (ID: $id) silinirken genel hata.', e, stackTrace);
       if (e is FormatException) { throw Exception('API yanıtı okunamadı (geçersiz format).'); }
      throw Exception('Strateji silinirken bir sorun oluştu.');
    }
  }

  /// Kullanılabilir teknik göstergeleri getirir (Şu an UI'da kullanılmıyor ama API'de var)
  static Future<List<Map<String, dynamic>>> getAvailableIndicators() async {
    final url = Uri.parse('$baseUrl/backtesting/indicators');
     _logger.info('GET isteği gönderiliyor (göstergeler): $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

       _logger.info('Yanıt alındı: ${response.statusCode}');
       _logger.fine('Yanıt gövdesi: ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);
        if (jsonResponse is Map && jsonResponse.containsKey('status') && jsonResponse['status'] == 'success') {
           if (jsonResponse.containsKey('indicators') && jsonResponse['indicators'] is List) {
              // Gelen listeyi doğrudan Map<String, dynamic> listesine çevir
             final indicators = List<Map<String, dynamic>>.from(
                (jsonResponse['indicators'] as List).map((item) => item as Map<String, dynamic>)
             );
             _logger.info('${indicators.length} gösterge başarıyla alındı.');
             return indicators;
           } else {
              _logger.warning("API yanıtı başarılı ama 'indicators' listesi eksik/yanlış formatta.");
              throw Exception("API yanıt formatı beklenildiği gibi değil (indicators listesi eksik).");
           }
        } else {
           final errorMsg = (jsonResponse is Map && jsonResponse.containsKey('message')) ? jsonResponse['message'] : 'API\'den başarısız yanıt';
            _logger.warning('API hatası (status != success): $errorMsg');
            throw Exception(errorMsg);
        }
      } else {
        _logger.warning('API ${response.statusCode} kodu döndürdü. Yanıt: ${response.body}');
        throw Exception('API ${response.statusCode} kodu döndürdü.');
      }
    } on http.ClientException catch (e, stackTrace) {
        _logger.severe('Ağ hatası (ClientException): Göstergeler alınamadı.', e, stackTrace);
        throw Exception('Ağ hatası: Sunucuya ulaşılamıyor olabilir. ($e)');
    } on TimeoutException catch (e, stackTrace) {
         _logger.severe('İstek zaman aşımına uğradı: Göstergeler alınamadı.', e, stackTrace);
         throw Exception('Sunucu yanıt vermedi (zaman aşımı).');
    } catch (e, stackTrace) {
      _logger.severe('Göstergeler alınırken genel hata. Varsayılan liste döndürülüyor.', e, stackTrace);
       // Hata durumunda varsayılan (placeholder) göstergeleri döndür
      return _getDefaultIndicators();
    }
  }

   // Varsayılan gösterge listesi (API çalışmazsa kullanılır)
   static List<Map<String, dynamic>> _getDefaultIndicators() {
     return [
        {'name': 'Moving Average', 'abbr': 'MA', 'params': ['Period', 'Type']},
        {'name': 'Relative Strength Index', 'abbr': 'RSI', 'params': ['Period']},
        {'name': 'MACD', 'abbr': 'MACD', 'params': ['Fast', 'Slow', 'Signal']},
        {'name': 'Bollinger Bands', 'abbr': 'BB', 'params': ['Period', 'StdDev']},
        {'name': 'ATR', 'abbr': 'ATR', 'params': ['Period']},
        {'name': 'Stochastic', 'abbr': 'STOCH', 'params': ['K', 'D', 'Smooth']},
      ];
   }


  /// Backtest çalıştırır
  static Future<BacktestResult> runBacktest({
    required String ticker,
    required String timeframe,
    required String periodStr,
    required BacktestStrategy strategy,
    double initialCapital = 10000.0,
  }) async {
    final url = Uri.parse('$baseUrl/backtesting/run');
     _logger.info('POST isteği gönderiliyor (backtest çalıştırma): $url');

    try {
      // Strateji nesnesinin JSON karşılığı (ID'siz ve performansısz)
      final strategyJson = strategy.toJson();
      strategyJson.remove('id'); // Çalıştırma için ID gönderilmez
      strategyJson.remove('performance'); // Çalıştırma için performans gönderilmez

      // İstek gövdesini oluştur
      final Map<String, dynamic> requestBody = {
        'ticker': ticker.trim().toUpperCase(), // Temizle ve büyük harf yap
        'timeframe': timeframe,
        'period': periodStr.trim(), // Temizle
        'initial_capital': initialCapital,
        'strategy': strategyJson, // Hazırlanan strateji JSON'u
      };

      // İstek gövdesini logla (hassas veri olmamasına dikkat)
      final requestBodyString = json.encode(requestBody);
       if (requestBodyString.length < 1000) {
         _logger.fine('İstek Gövdesi: $requestBodyString');
       } else {
          _logger.fine('İstek Gövdesi (ilk 1000 karakter): ${requestBodyString.substring(0, 1000)}...');
       }


      // İsteği gönder (daha uzun timeout backtest için)
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: requestBodyString,
      ).timeout(const Duration(seconds: 120)); // Backtest için daha uzun timeout (2 dakika)

       _logger.info('Yanıt alındı: ${response.statusCode}');
       // Yanıt gövdesini logla (kısa ise tamamı, uzunsa bir kısmı)
       if (response.body.length < 1000) {
          _logger.fine('Yanıt gövdesi: ${response.body}');
        } else {
           _logger.fine('Yanıt gövdesi (ilk 1000 karakter): ${response.body.substring(0, 1000)}...');
        }


      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);

        if (jsonResponse is Map && jsonResponse.containsKey('status') && jsonResponse['status'] == 'success') {
           // 'results' anahtarının varlığını ve tipini kontrol et
          if (jsonResponse.containsKey('results') && jsonResponse['results'] is Map) {
              try {
                  final result = BacktestResult.fromJson(jsonResponse['results'] as Map<String, dynamic>);
                  _logger.info('Backtest başarıyla tamamlandı. İşlem sayısı: ${result.tradeHistory.length}');
                  return result;
              } catch (e, stackTrace) {
                  _logger.severe("Backtest sonucu JSON ayrıştırılırken hata: ${jsonResponse['results']}", e, stackTrace);
                   throw Exception("Backtest sonucu okunamadı (geçersiz format).");
              }

          } else {
             _logger.warning("API yanıtı başarılı ('status':'success') ancak 'results' nesnesi bulunamadı veya formatı yanlış.");
             throw Exception("API yanıt formatı beklenildiği gibi değil (results nesnesi eksik).");
          }
        } else {
             // Başarısız durum veya status alanı yoksa
            final errorMsg = (jsonResponse is Map && jsonResponse.containsKey('message'))
                             ? jsonResponse['message']
                             : 'API\'den başarısız veya beklenmeyen backtest yanıtı';
            _logger.warning('API hatası (status != success): $errorMsg');
             // API'den gelen hata mesajını doğrudan fırlat
            throw Exception(errorMsg);
        }
      } else {
        // HTTP 200 dışında bir durum kodu
        _logger.warning('API ${response.statusCode} kodu döndürdü. Yanıt: ${response.body}');
         // Hata mesajını ayrıştırmaya çalış
         String errorMessage = 'Backtest çalıştırılamadı (${response.statusCode}).';
          try {
             final errorJson = json.decode(utf8.decode(response.bodyBytes));
             if (errorJson is Map && errorJson.containsKey('message')) {
                errorMessage = errorJson['message'];
             } else if (errorJson is Map && errorJson.containsKey('error')) { // Bazen 'error' anahtarı kullanılır
                 errorMessage = errorJson['error'];
             }
          } catch (_) {} // Ayrıştırma hatasını yoksay
          throw Exception(errorMessage);
      }
    } on http.ClientException catch (e, stackTrace) {
        _logger.severe('Ağ hatası (ClientException): Backtest çalıştırılamadı.', e, stackTrace);
        throw Exception('Ağ hatası: Sunucuya ulaşılamıyor olabilir. ($e)');
    } on TimeoutException catch (e, stackTrace) {
         _logger.severe('İstek zaman aşımına uğradı: Backtest çalıştırılamadı.', e, stackTrace);
         throw Exception('Backtest sunucudan yanıt alamadı (zaman aşımı). İşlem uzun sürmüş olabilir.');
    } catch (e, stackTrace) {
      // Diğer tüm hatalar (JSON parse hatası vb.)
      _logger.severe('Backtest çalıştırılırken genel hata.', e, stackTrace);
       if (e is FormatException) { throw Exception('API yanıtı okunamadı (geçersiz format).'); }
       // Orijinal hatayı fırlatmak yerine daha kullanıcı dostu bir mesaj
       throw Exception('Backtest çalıştırılırken bilinmeyen bir sorun oluştu.');
       // rethrow; // Eğer orijinal hatayı yukarı katmana iletmek isterseniz
    }
  }
}


// -------------------------------------------------------------
// models/backtest_models.dart (Varsayılan Tanımlar)
// -------------------------------------------------------------
// Bu dosyanın projenizde zaten var olduğunu varsayıyoruz.
// Eğer yoksa veya eksikse, aşağıdaki gibi temel tanımları ekleyebilirsiniz.

class BacktestStrategy {
  final String? id; // ID backend tarafından atanır, oluştururken null olabilir
  final String name;
  final String description;
  final List<Map<String, dynamic>> indicators; // Gösterge tanımları
  final List<Map<String, dynamic>> buyConditions; // Alım koşulları
  final List<Map<String, dynamic>> sellConditions; // Satım koşulları
  final Map<String, dynamic>? performance; // Son test performansı (opsiyonel)

  BacktestStrategy({
    this.id,
    required this.name,
    required this.description,
    required this.indicators,
    required this.buyConditions,
    required this.sellConditions,
    this.performance,
  });

  // JSON'dan nesne oluşturma
 factory BacktestStrategy.fromJson(Map<String, dynamic> json) {
    // Null ve tip kontrolleri ekleyerek daha sağlam hale getirelim
    return BacktestStrategy(
      id: json['id'] as String?, // ID null olabilir
      name: json['name'] as String? ?? 'İsimsiz Strateji', // name null ise varsayılan ata
      description: json['description'] as String? ?? '', // description null ise boş ata
      // Listelerin null olup olmadığını ve elemanlarının Map olup olmadığını kontrol et
      indicators: (json['indicators'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [], // indicators null ise boş liste ata
      buyConditions: (json['buy_conditions'] as List?)
           ?.map((e) => e as Map<String, dynamic>)
           .toList() ?? [], // buy_conditions null ise boş liste ata
      sellConditions: (json['sell_conditions'] as List?)
           ?.map((e) => e as Map<String, dynamic>)
           .toList() ?? [], // sell_conditions null ise boş liste ata
       performance: json['performance'] is Map<String, dynamic>
          ? json['performance'] as Map<String, dynamic>
          : null, // performance Map değilse veya yoksa null ata
    );
  }


  // Nesneyi JSON'a çevirme
   Map<String, dynamic> toJson() {
     return {
       // ID sadece varsa eklenir (güncelleme için)
       if (id != null) 'id': id,
       'name': name,
       'description': description,
       'indicators': indicators,
       // API'nin beklediği anahtar isimleri kullanılır (buy_conditions, sell_conditions)
       'buy_conditions': buyConditions,
       'sell_conditions': sellConditions,
       // Performans sadece okunur, gönderilmez (genellikle)
       // if (performance != null) 'performance': performance,
     };
   }
}

class BacktestResult {
  final Map<String, dynamic> performanceMetrics; // Tüm performans metrikleri
  final List<Map<String, dynamic>> equityCurve; // Varlık eğrisi verileri (tarih, değer)
  final List<Map<String, dynamic>> tradeHistory; // İşlem geçmişi detayları

  BacktestResult({
    required this.performanceMetrics,
    required this.equityCurve,
    required this.tradeHistory,
  });

 // JSON'dan nesne oluşturma
  factory BacktestResult.fromJson(Map<String, dynamic> json) {
    // Null ve tip kontrolleri
    return BacktestResult(
      performanceMetrics: json['performance_metrics'] is Map<String, dynamic>
          ? json['performance_metrics'] as Map<String, dynamic>
          : {}, // performance_metrics yoksa veya Map değilse boş Map ata
       equityCurve: (json['equity_curve'] as List?)
           ?.map((e) => e as Map<String, dynamic>)
           .toList() ?? [], // equity_curve yoksa veya Liste değilse boş Liste ata
       tradeHistory: (json['trade_history'] as List?)
           ?.map((e) => e as Map<String, dynamic>)
           .toList() ?? [], // trade_history yoksa veya Liste değilse boş Liste ata
    );
  }


  // Nesneyi JSON'a çevirme (Genellikle okunur, yazılmaz)
  Map<String, dynamic> toJson() {
    return {
      'performance_metrics': performanceMetrics,
      'equity_curve': equityCurve,
      'trade_history': tradeHistory,
    };
  }
}
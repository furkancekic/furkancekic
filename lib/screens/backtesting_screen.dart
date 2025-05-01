// backtesting_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Varsayılan tema dosyası
import '../models/backtest_models.dart'; // Model dosyası
import '../services/backtest_service.dart'; // Servis dosyası
import 'dart:math';
import 'package:logging/logging.dart'; // Loglama için eklendi

// Varsayılan AppTheme (Eğer dosyanız yoksa geçici olarak ekleyin)
class AppTheme {
  static const Color backgroundColor = Color(0xFF121829);
  static const Color cardColor = Color(0xFF1A2033);
  static const Color accentColor = Color(0xFF00AEEF); // Örnek Vurgu Rengi
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color positiveColor = Colors.greenAccent;
  static const Color negativeColor = Colors.redAccent;
}

class BacktestingScreen extends StatefulWidget {
  const BacktestingScreen({Key? key}) : super(key: key);

  @override
  State<BacktestingScreen> createState() => _BacktestingScreenState();
}

class _BacktestingScreenState extends State<BacktestingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _tickerController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  String _selectedTimeframe = '1D';
  final List<String> _timeframes = ['1D', '1H', '30m', '15m', '5m', '1m'];

  List<BacktestStrategy> _strategies = [];
  int _selectedStrategyIndex = -1; // Başlangıçta hiçbir strateji seçili değil
  bool _isLoading = true;
  BacktestResult? _lastResult;

  // Loglama için
  final _logger = Logger('BacktestingScreen');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tickerController.text = 'AAPL'; // Varsayılan ticker
    _periodController.text = '1 Year'; // Varsayılan periyot
    _loadStrategies();
    BacktestService.initialize(); // Servis loglamasını başlat
    _setupLogging(); // Ekran loglamasını başlat
  }

  void _setupLogging() {
    Logger.root.level = Level.ALL; // Tüm log seviyelerini yakala
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print(
          '${record.level.name}: ${record.time}: (${record.loggerName}) ${record.message}');
      if (record.error != null) {
        // ignore: avoid_print
        print('ERROR: ${record.error}');
      }
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('STACKTRACE: ${record.stackTrace}');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tickerController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  Future<void> _loadStrategies() async {
    _logger.info("Stratejiler yükleniyor...");
    setState(() {
      _isLoading = true;
      _strategies = []; // Yükleme başlarken listeyi temizle
      _selectedStrategyIndex = -1; // Seçimi sıfırla
    });

    try {
      final strategies = await BacktestService.getStrategies();
      setState(() {
        _strategies = strategies;
        // Eğer stratejiler varsa ilkini seçili yap
        if (_strategies.isNotEmpty) {
          _selectedStrategyIndex = 0;
          _logger
              .info("İlk strateji seçildi: ${_strategies[0].name}");
        } else {
          _logger.warning("Hiç strateji bulunamadı.");
        }
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _logger.severe("Stratejiler yüklenirken hata oluştu", e, stackTrace);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stratejiler yüklenirken hata: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  Future<void> _runBacktest() async {
    // ÖNEMLİ: Seçili bir strateji var mı kontrol et
    if (_selectedStrategyIndex < 0 ||
        _selectedStrategyIndex >= _strategies.length) {
      _logger.warning(
          "Backtest çalıştırma denemesi ancak geçerli bir strateji seçilmemiş. Seçili index: $_selectedStrategyIndex, Strateji sayısı: ${_strategies.length}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir strateji seçin.'),
          backgroundColor: AppTheme.negativeColor,
        ),
      );
      return;
    }

    // ÖNEMLİ: Mevcut seçili indekse göre stratejiyi alıyoruz.
    // Bu değişken, setState çağrılsa bile bu fonksiyon bloğu içinde aynı kalır.
    final int strategyIndexToRun = _selectedStrategyIndex;
    final BacktestStrategy selectedStrategy = _strategies[strategyIndexToRun];

    _logger.info(
        "Backtest başlatılıyor. Seçilen Strateji Index: $strategyIndexToRun, Strateji Adı: ${selectedStrategy.name}, Strateji ID: ${selectedStrategy.id ?? 'ID Yok'}");

    // Strateji detaylarını logla (API'ye gönderilecek olan)
    _logger.fine("Gönderilecek Strateji Detayları: ${selectedStrategy.toJson()}");

    setState(() {
      _isLoading = true; // Yükleme animasyonunu başlat
      _lastResult = null; // Eski sonucu temizle
    });

    // İsteğe bağlı: Onay dialogu
    // _confirmStrategy(selectedStrategy); // Eğer onay isteniyorsa açılabilir

    try {
      final ticker = _tickerController.text.trim().toUpperCase();
      final period = _periodController.text.trim();
      final timeframe = _selectedTimeframe;

      if (ticker.isEmpty) {
        throw Exception("Hisse/Sembol boş olamaz.");
      }
      if (period.isEmpty) {
        throw Exception("Backtest periyodu boş olamaz.");
      }

      // API çağrısı için parametreleri logla
      _logger.info(
          "BacktestService.runBacktest çağrılıyor. Ticker: $ticker, Timeframe: $timeframe, Period: $period, Strateji Adı: ${selectedStrategy.name}");

      // ÖNEMLİ: Doğrudan seçilen strateji nesnesi ile API çağrısı yapıyoruz
      final result = await BacktestService.runBacktest(
        ticker: ticker,
        timeframe: timeframe,
        periodStr: period,
        strategy: selectedStrategy, // Yerel değişkendeki stratejiyi kullan
      );

      _logger.info(
          "Backtest başarıyla tamamlandı. Toplam Getiri: ${result.performanceMetrics['total_return_pct']}%");

      setState(() {
        _lastResult = result;
        _isLoading = false;
      });

      // Sonuçlar sekmesine geç
      _tabController.animateTo(2);

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('${selectedStrategy.name} backtesti tamamlandı.'),
             backgroundColor: AppTheme.positiveColor.withOpacity(0.8),
           ),
         );
       }


    } catch (e, stackTrace) {
      _logger.severe("Backtest çalıştırılırken hata oluştu", e, stackTrace);
      setState(() {
        _isLoading = false; // Hata durumunda yüklemeyi durdur
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backtest hatası: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  // Strateji seçimi için RadioListTile yerine kullanılacak widget
  Widget _buildStrategySelectionCard(BacktestStrategy strategy, int index) {
     final isSelected = index == _selectedStrategyIndex;
     return Padding(
       padding: const EdgeInsets.only(bottom: 12),
       child: Card(
         elevation: isSelected ? 4 : 1,
         shadowColor: isSelected ? AppTheme.accentColor.withOpacity(0.5) : Colors.black.withOpacity(0.2),
         color: isSelected
             ? AppTheme.accentColor.withOpacity(0.15)
             : AppTheme.cardColor,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(12),
           side: BorderSide(
             color: isSelected ? AppTheme.accentColor : Colors.transparent,
             width: 1.5,
           ),
         ),
         child: InkWell(
           onTap: () {
             _logger.info(
                 "Strateji seçildi. Index: $index, Ad: ${strategy.name}");
             setState(() {
               _selectedStrategyIndex = index;
             });
           },
           borderRadius: BorderRadius.circular(12),
           child: Padding(
             padding: const EdgeInsets.all(16),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Flexible(
                       child: Text(
                         strategy.name,
                         style: TextStyle(
                           fontSize: 17,
                           fontWeight: FontWeight.bold,
                           color: isSelected ? AppTheme.accentColor : AppTheme.textPrimary,
                         ),
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                     // Diğer ikonlar (düzenle/sil) buraya eklenebilir
                     Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.edit_note, // Düzenleme ikonu
                              color: AppTheme.accentColor.withOpacity(0.7),
                              size: 22,
                            ),
                            tooltip: "Stratejiyi Düzenle",
                            onPressed: () {
                              // TODO: Strateji düzenleme ekranına git
                              _logger.info("Düzenle butonu tıklandı: ${strategy.name}");
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Düzenleme özelliği yakında eklenecektir.')),
                               );
                              // Örnek: _navigateToEditStrategy(strategy);
                              // Şimdilik sadece 2. sekmeye gitsin
                               // _tabController.animateTo(1);
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                             constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.delete_outline, // Silme ikonu
                              color: AppTheme.negativeColor.withOpacity(0.7),
                              size: 20,
                            ),
                             tooltip: "Stratejiyi Sil",
                            onPressed: () {
                              // TODO: Strateji silme işlemi
                              _logger.warning("Sil butonu tıklandı: ${strategy.name}");
                              _confirmDeleteStrategy(strategy.id ?? '', strategy.name);
                            },
                          ),
                        ],
                      ),
                   ],
                 ),
                 const SizedBox(height: 8),
                 Text(
                   strategy.description,
                   style: const TextStyle(
                     fontSize: 13,
                     color: AppTheme.textSecondary,
                   ),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                 ),
                 const SizedBox(height: 12),
                 // Koşul chipleri
                 _buildConditionChipsForRow(strategy),

                 // Eğer varsa performans metrikleri
                 if (strategy.performance != null &&
                     strategy.performance!.isNotEmpty) ...[
                   const SizedBox(height: 16),
                   _buildMiniPerformanceRow(strategy.performance!),
                 ],

                  // Çalıştır butonu (her kart için ayrı)
                  // Her kartta buton olması kafa karıştırıcı olabilir,
                  // bunun yerine seçili olanı çalıştırmak için tek bir global buton daha iyi olabilir.
                  // Ama istenirse bu da açılabilir:
                  /*
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('BU STRATEJİYİ ÇALIŞTIR'),
                      onPressed: () {
                        // Önce bu stratejiyi seçili yap, sonra çalıştır
                        setState(() {
                          _selectedStrategyIndex = index;
                        });
                        _runBacktest();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? AppTheme.accentColor : AppTheme.cardColor.withBlue(50),
                        foregroundColor: isSelected ? Colors.black : AppTheme.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  */
               ],
             ),
           ),
         ),
       ),
     );
  }

  // Strateji silme onayı
  Future<void> _confirmDeleteStrategy(String strategyId, String strategyName) async {
    if (strategyId.isEmpty) {
      _logger.severe("Silinmek istenen stratejinin ID'si boş.");
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Strateji ID bulunamadı, silinemiyor.'), backgroundColor: AppTheme.negativeColor),
       );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Stratejiyi Sil', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '"$strategyName" adlı stratejiyi kalıcı olarak silmek istediğinizden emin misiniz?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.negativeColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteStrategy(strategyId);
    }
  }

  // Stratejiyi silen fonksiyon
  Future<void> _deleteStrategy(String strategyId) async {
    _logger.info("Strateji siliniyor: ID $strategyId");
    setState(() { _isLoading = true; });

    try {
      final success = await BacktestService.deleteStrategy(strategyId);
      if (success) {
        _logger.info("Strateji başarıyla silindi: ID $strategyId");
        // Listeyi yeniden yükle
        await _loadStrategies(); // Bu _isLoading'i false yapar
         if(mounted){
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Strateji başarıyla silindi.'), backgroundColor: AppTheme.positiveColor),
           );
         }
      } else {
        _logger.warning("Strateji silinemedi: ID $strategyId");
        if(mounted){
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Strateji silinirken bir hata oluştu.'), backgroundColor: AppTheme.negativeColor),
           );
        }
         setState(() { _isLoading = false; });
      }
    } catch (e, stackTrace) {
      _logger.severe("Strateji silinirken kritik hata: ID $strategyId", e, stackTrace);
       if(mounted){
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Strateji silinirken hata: $e'), backgroundColor: AppTheme.negativeColor),
           );
        }
      setState(() { _isLoading = false; });
    }
  }


  // Koşul chiplerini tek satırda gösteren yardımcı widget
  Widget _buildConditionChipsForRow(BacktestStrategy strategy) {
     final buyConditions = strategy.buyConditions.map(
       (c) => _buildConditionChip('AL', _formatCondition(c), AppTheme.positiveColor)
     ).toList();
      final sellConditions = strategy.sellConditions.map(
       (c) => _buildConditionChip('SAT', _formatCondition(c), AppTheme.negativeColor)
     ).toList();

     // Hepsini birleştir
     final allChips = [...buyConditions, ...sellConditions];

      if (allChips.isEmpty) {
        return const SizedBox.shrink(); // Eğer koşul yoksa boş widget döndür
      }

      return Wrap(
        spacing: 6.0, // Chipler arası yatay boşluk
        runSpacing: 4.0, // Satırlar arası dikey boşluk
        children: allChips,
      );
  }

   // Mini performans satırı
  Widget _buildMiniPerformanceRow(Map<String, dynamic> performance) {
    // Metrikleri alırken null kontrolü yap
    final String returnStr = performance.containsKey('return')
        ? '${(performance['return'] as num?)?.toStringAsFixed(1) ?? 'N/A'}%'
        : 'N/A';
    final String sharpeStr = performance.containsKey('sharpe')
        ? (performance['sharpe'] as num?)?.toStringAsFixed(2) ?? 'N/A'
        : 'N/A';
    final String drawdownStr = performance.containsKey('drawdown')
        ? '${(performance['drawdown'] as num?)?.toStringAsFixed(1) ?? 'N/A'}%'
        : 'N/A';
     final String tradesStr = performance.containsKey('trades')
        ? (performance['trades'] as num?)?.toString() ?? 'N/A'
        : 'N/A';

     final bool isPositiveReturn = performance.containsKey('return') && (performance['return'] as num? ?? 0) >= 0;


    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMiniMetric('Getiri', returnStr, isPositiveReturn ? AppTheme.positiveColor : AppTheme.negativeColor),
        _buildMiniMetric('Sharpe', sharpeStr, Colors.amber.shade700),
        _buildMiniMetric('Max DD', drawdownStr, AppTheme.negativeColor),
        _buildMiniMetric('İşlem', tradesStr, AppTheme.accentColor),
      ],
    );
  }

  // Mini metrik widget'ı
  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }


  // EKSTRA: Hangi stratejinin çalıştırıldığını onaylamak için bir dialog (isteğe bağlı)
  void _confirmStrategy(BacktestStrategy strategy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text("Strateji Onayı",
            style: TextStyle(color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Aşağıdaki strateji için backtest çalıştırılacak:",
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strategy.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      strategy.description,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Göstergeler: ${strategy.indicators.length}",
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    Text(
                      "Alım Koşulları: ${strategy.buyConditions.length}",
                      style: const TextStyle(color: AppTheme.positiveColor),
                    ),
                    Text(
                      "Satım Koşulları: ${strategy.sellConditions.length}",
                      style: const TextStyle(color: AppTheme.negativeColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Hisse: ${_tickerController.text.toUpperCase()}",
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              Text(
                "Zaman Dilimi: $_selectedTimeframe",
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              Text(
                "Period: ${_periodController.text}",
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.pop(context);
               // Çalıştırmayı iptal et, _isLoading'i false yap
                setState(() => _isLoading = false);
                _logger.info("Kullanıcı backtest onayını iptal etti.");
            },
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Onay verildi, zaten _runBacktest içindeyiz, devam etmesi lazım.
              // Ancak dialog asenkron çalıştığı için _runBacktest'i tekrar çağırmak yerine
              // _runBacktest içinde dialog sonucunu beklemek daha doğru olur.
              // Şimdiki yapıda dialog sadece bilgi amaçlı, işlemi durdurmuyor.
               _logger.info("Kullanıcı backtest'i onayladı.");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.black,
            ),
            child: const Text("Onayla ve Çalıştır"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Arka plan gradient'i
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              Color(0xFF101624), // Biraz daha koyu alt renk
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Özel App Bar
              _buildCustomAppBar(),

              // Tab Bar
              _buildTabBar(),

              // Ana İçerik Alanı
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentColor,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStrategiesTab(),
                          _buildStrategyBuilderTab(), // Oluşturucu Sekmesi
                          _buildResultsTab(),       // Sonuçlar Sekmesi
                        ],
                      ),
              ),

              // Alt Kısım: Seçili Stratejiyi Çalıştırma Butonu (Stratejiler sekmesindeyken)
              // Sadece ilk sekmedeyken ve bir strateji seçiliyken göster
               AnimatedSwitcher(
                 duration: const Duration(milliseconds: 300),
                 transitionBuilder: (child, animation) {
                   return SizeTransition(sizeFactor: animation, child: child);
                 },
                 child: (_tabController.index == 0 && _selectedStrategyIndex != -1 && !_isLoading)
                     ? _buildRunSelectedStrategyButton()
                     : const SizedBox.shrink(), // Diğer sekmelerde veya seçim yoksa gizle
               ),
            ],
          ),
        ),
      ),
    );
  }

   // Özel App Bar Widget'ı
  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(
            Icons.analytics_outlined, // Daha uygun bir ikon
            color: AppTheme.accentColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Strateji Backtesting',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
           // Yenile butonu eklendi
           IconButton(
             tooltip: "Stratejileri Yenile",
             icon: const Icon(Icons.refresh, color: AppTheme.accentColor),
             onPressed: _isLoading ? null : _loadStrategies, // Yüklenirken deaktif
           ),
          // Diğer ikonlar (kaydet, paylaş vb.) buraya eklenebilir
          /*
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.accentColor),
            onPressed: () {
               _logger.info("Kaydet butonu tıklandı (işlev atanmadı).");
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.accentColor),
            onPressed: () {
               _logger.info("Paylaş butonu tıklandı (işlev atanmadı).");
            },
          ),
           */
        ],
      ),
    );
  }

  // Tab Bar Widget'ı
  Widget _buildTabBar() {
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 45, // Sekme yüksekliğini ayarla
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: AppTheme.textSecondary.withOpacity(0.8),
          indicator: BoxDecoration(
             borderRadius: BorderRadius.circular(10), // Yuvarlak kenarlı gösterge
             color: AppTheme.accentColor.withOpacity(0.2),
             border: Border.all(color: AppTheme.accentColor)
          ),
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: const [
            Tab(text: 'Stratejiler'),
            Tab(text: 'Oluşturucu'), // İkinci sekme adı
            Tab(text: 'Sonuçlar'),
          ],
        ),
      ),
    );
  }


  // Stratejiler Sekmesi İçeriği
  Widget _buildStrategiesTab() {
    if (_strategies.isEmpty && !_isLoading) {
      return Center(
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Icon(Icons.search_off, size: 60, color: AppTheme.textSecondary),
             const SizedBox(height: 16),
             const Text(
               'Hiç kayıtlı strateji bulunamadı.',
               style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
             ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Yeni Strateji Oluştur'),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppTheme.accentColor,
                   foregroundColor: Colors.black,
                 ),
                onPressed: () => _tabController.animateTo(1),
              ),
              const SizedBox(height: 10),
               TextButton.icon(
                 icon: const Icon(Icons.refresh, size: 18, color: AppTheme.accentColor,),
                 label: const Text('Yeniden Dene', style: TextStyle(color: AppTheme.accentColor)),
                 onPressed: _loadStrategies,
               ),
           ],
        )
      );
    }

    // Strateji varsa listeyi göster
    return ListView(
       padding: const EdgeInsets.all(16),
      children: [
        // Başlık ve Yeni Strateji Butonu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(
              'Kayıtlı Stratejiler (${_strategies.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Yeni Oluştur'),
              onPressed: () {
                _logger.info("Yeni Strateji Oluştur butonuna tıklandı.");
                _tabController.animateTo(1); // Oluşturucu sekmesine git
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor.withOpacity(0.15),
                foregroundColor: AppTheme.accentColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(8),
                   side: const BorderSide(color: AppTheme.accentColor)
                 ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Strateji Kartları Listesi
        ...List.generate(
          _strategies.length,
          (index) => _buildStrategySelectionCard(_strategies[index], index),
        ),

        // Liste sonuna boşluk
         const SizedBox(height: 80),
      ],
    );
  }

  // Seçili Stratejiyi Çalıştır Butonu (Ekranın altında)
   Widget _buildRunSelectedStrategyButton() {
     // _selectedStrategyIndex'in geçerli olduğundan emin ol
     if (_selectedStrategyIndex < 0 || _selectedStrategyIndex >= _strategies.length) {
       return const SizedBox.shrink(); // Eğer geçerli değilse butonu gösterme
     }
     final selectedStrategyName = _strategies[_selectedStrategyIndex].name;

     return Container(
       padding: const EdgeInsets.all(16.0),
       decoration: BoxDecoration(
         color: AppTheme.cardColor.withOpacity(0.95),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.3),
             blurRadius: 10,
             spreadRadius: 2,
           )
         ],
         borderRadius: const BorderRadius.only(
           topLeft: Radius.circular(20),
           topRight: Radius.circular(20),
         )
       ),
       child: ElevatedButton.icon(
         icon: const Icon(Icons.play_circle_fill, color: Colors.black),
         label: Text(
           '"$selectedStrategyName" İÇİN BACKTEST ÇALIŞTIR',
           style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
           overflow: TextOverflow.ellipsis,
         ),
         style: ElevatedButton.styleFrom(
           backgroundColor: AppTheme.accentColor,
           minimumSize: const Size(double.infinity, 50), // Buton yüksekliği
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
           ),
         ),
         onPressed: _isLoading ? null : _runBacktest, // Yüklenirken butonu deaktif et
       ),
     );
   }


   // Strateji Oluşturucu Sekmesi İçeriği
   Widget _buildStrategyBuilderTab() {
     // TODO: Bu sekmenin içeriğini gerçek strateji oluşturma bileşenleriyle doldurun.
     // Şimdilik yapılandırma ve çalıştırma butonlarını içeriyor.

     return SingleChildScrollView( // Kaydırılabilir olması için
       padding: const EdgeInsets.all(16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           // Strateji Yapılandırma Bölümü
           Card(
             color: AppTheme.cardColor,
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(16),
             ),
             child: Padding(
               padding: const EdgeInsets.all(16),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text(
                     'Backtest Parametreleri',
                     style: TextStyle(
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                       color: AppTheme.textPrimary,
                     ),
                   ),
                   const SizedBox(height: 20),

                   // Hisse Senedi Giriş
                   TextField(
                     controller: _tickerController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                     decoration: InputDecoration(
                       labelText: 'Hisse/Sembol',
                       labelStyle: const TextStyle(color: AppTheme.textSecondary),
                       prefixIcon: const Icon(Icons.search, color: AppTheme.accentColor),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.accentColor),
                           borderRadius: BorderRadius.circular(10)
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundColor.withOpacity(0.5),
                     ),
                      onChanged: (value) => _tickerController.text = value.toUpperCase(), // Otomatik büyük harf
                   ),
                   const SizedBox(height: 16),

                   // Zaman Aralığı Seçimi
                   _buildTimeframeSelector(),
                   const SizedBox(height: 16),

                   // Backtest Periyodu
                   TextField(
                     controller: _periodController,
                     style: const TextStyle(color: AppTheme.textPrimary),
                     decoration: InputDecoration(
                       labelText: 'Backtest Periyodu',
                       labelStyle: const TextStyle(color: AppTheme.textSecondary),
                       prefixIcon: const Icon(Icons.date_range, color: AppTheme.accentColor),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.accentColor),
                           borderRadius: BorderRadius.circular(10)
                        ),
                       hintText: 'Örn: 1 Year, 6 Months, 90 Days',
                        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                         filled: true,
                        fillColor: AppTheme.backgroundColor.withOpacity(0.5),
                     ),
                   ),
                 ],
               ),
             ),
           ),

           const SizedBox(height: 24),

            // Strateji Tanımı Alanı (Gerçek oluşturucu buraya gelecek)
            const Text(
              'Strateji Tanımı (Yakında)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: AppTheme.cardColor,
                 borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3))
               ),
              child: const Center(
                child: Text(
                  'Burada göstergeleri ve koşulları\n sürükleyip bırakarak veya seçerek\n yeni stratejiler oluşturabileceksiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                ),
              ),
            ),

           const SizedBox(height: 24),

           // Butonlar (Oluştur ve Çalıştır)
           Row(
             children: [
               Expanded(
                 child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle, size: 20),
                   label: const Text('YENİ STRATEJİ OLUŞTUR'),
                   onPressed: () {
                      // TODO: Yeni strateji oluşturma mantığını ekle
                       _logger.info("Yeni Strateji Oluştur butonu (Oluşturucu sekmesi) tıklandı.");
                      ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Strateji oluşturma özelliği yakında eklenecektir.')),
                     );
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppTheme.positiveColor.withOpacity(0.8),
                     foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                 ),
               ),
               /* Belki kaydet butonu daha mantıklı olabilir
               const SizedBox(width: 12),
               Expanded(
                 child: ElevatedButton.icon(
                    icon: Icon(Icons.play_arrow, size: 20, color: Colors.black,),
                   label: const Text('BACKTEST ÇALIŞTIR'),
                   // Bu sekmede hangi stratejinin çalışacağı belli olmadığı için
                   // butonu deaktif edebilir veya son seçileni çalıştırabiliriz.
                   // Şimdilik son seçili stratejiyi (varsa) çalıştırsın.
                   onPressed: (_selectedStrategyIndex != -1 && !_isLoading) ? _runBacktest : null,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppTheme.accentColor,
                     foregroundColor: Colors.black,
                     minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),

                 ),
               ),
               */
             ],
           ),
            const SizedBox(height: 20), // Alt boşluk
         ],
       ),
     );
   }


   // Zaman Dilimi Seçici Widget'ı
  Widget _buildTimeframeSelector() {
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'Zaman Dilimi:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
        SizedBox(
          height: 40, // Butonların yüksekliği
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _timeframes.length,
            itemBuilder: (context, index) {
              final timeframe = _timeframes[index];
              final isSelected = timeframe == _selectedTimeframe;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: OutlinedButton(
                  onPressed: () {
                    _logger.fine("Zaman dilimi seçildi: $timeframe");
                    setState(() {
                      _selectedTimeframe = timeframe;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
                    backgroundColor: isSelected ? AppTheme.accentColor.withOpacity(0.1) : AppTheme.backgroundColor.withOpacity(0.3),
                    side: BorderSide(
                      color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary.withOpacity(0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    timeframe,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  // Sonuçlar Sekmesi İçeriği
  Widget _buildResultsTab() {
    if (_isLoading && _lastResult == null) {
       // Eğer hala yükleniyorsa ve hiç sonuç yoksa (ilk çalıştırma)
       return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
     }

    if (_lastResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.hourglass_empty, size: 60, color: AppTheme.textSecondary.withOpacity(0.5)),
             const SizedBox(height: 16),
             const Text(
              'Henüz backtest sonucu yok.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bir strateji seçip "Backtest Çalıştır" butonuna basın.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
             const SizedBox(height: 20),
             ElevatedButton.icon(
               icon: const Icon(Icons.arrow_back),
               label: const Text("Stratejilere Dön"),
               style: ElevatedButton.styleFrom(
                 backgroundColor: AppTheme.accentColor,
                 foregroundColor: Colors.black
               ),
               onPressed: () => _tabController.animateTo(0),
             )
          ],
        ),
      );
    }

    // Sonuç varsa göster
    final result = _lastResult!;
    final metrics = result.performanceMetrics;
     // Strateji adını bulmaya çalış
     String strategyName = "Bilinmeyen Strateji";
     if (_selectedStrategyIndex >= 0 && _selectedStrategyIndex < _strategies.length) {
       strategyName = _strategies[_selectedStrategyIndex].name;
     } else if (metrics.containsKey('strategy_name')) {
         strategyName = metrics['strategy_name']; // API'den geliyorsa
     }


    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve Strateji Adı
          Row(
             crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.bar_chart_rounded, // Grafik ikonu
                color: AppTheme.accentColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded( // Başlığın taşmasını engelle
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_tickerController.text.toUpperCase()} Backtest Sonuçları',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                       overflow: TextOverflow.ellipsis,
                    ),
                     const SizedBox(height: 4),
                    Text(
                      'Strateji: $strategyName', // Çalıştırılan stratejinin adı
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Özet Performans Kartları
          _buildPerformanceSummaryCards(metrics),
          const SizedBox(height: 24),

          // Varlık Eğrisi Başlığı ve Grafiği
          const Text(
            'Varlık Eğrisi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 250, // Grafik yüksekliği
            padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8, left: 4), // Kenar boşlukları
            decoration: BoxDecoration(
              color: AppTheme.cardColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withOpacity(0.2),
                   blurRadius: 5,
                   offset: const Offset(0, 2),
                 )
               ]
            ),
            child: result.equityCurve.length > 1 // En az 2 nokta varsa çiz
                ? CustomPaint(
                    painter: EquityCurvePainter(
                      equityCurve: result.equityCurve,
                      initialValue: metrics['initial_capital'] ?? 10000.0, // Başlangıç sermayesi
                       benchmarkValue: metrics['buy_and_hold_return_pct'] ?? 0.0, // Buy&Hold getirisi (varsa)
                    ),
                    size: const Size(double.infinity, double.infinity),
                  )
                : const Center(child: Text("Grafik için yeterli veri yok.", style: TextStyle(color: AppTheme.textSecondary))),
          ),
           const SizedBox(height: 24),

          // İşlem Geçmişi Başlığı ve Listesi
          const Text(
            'İşlem Geçmişi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildTradeHistorySection(result.tradeHistory),

          const SizedBox(height: 20), // En alta boşluk
        ],
      ),
    );
  }

  // İşlem Geçmişi Bölümü Widget'ı
  Widget _buildTradeHistorySection(List<Map<String, dynamic>> trades) {
    if (trades.isEmpty) {
      return Card(
        color: AppTheme.cardColor,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
         child: const Padding(
           padding: EdgeInsets.all(20.0),
           child: Center(
             child: Text(
               'Bu backtestte hiç işlem yapılmadı.',
               style: TextStyle(color: AppTheme.textSecondary),
             ),
           ),
         ),
      );
    }

    // İlk 5 işlemi göster, kalanı için buton
    final visibleTrades = trades.take(5).toList();

    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0), // Üst ve alt boşluk
        child: Column(
          children: [
             // Başlık satırı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                 children: const [
                    SizedBox(width: 25, child: Text('#', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 3, child: Text('Giriş / Çıkış Tarihi', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Giriş / Çıkış Fiyatı', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Getiri %', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
              ),
            ),
             const Divider(color: AppTheme.backgroundColor, height: 1),

            // İşlem satırları
            ...List.generate(
              visibleTrades.length,
              (index) => _buildTradeHistoryItem(visibleTrades[index], index),
            ),

             // Tüm işlemleri göster butonu (eğer 5'ten fazla varsa)
            if (trades.length > 5)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: TextButton(
                  onPressed: () {
                    // TODO: Tüm işlemleri gösteren ayrı bir ekran veya dialog aç
                    _logger.info("Tüm İşlemleri Görüntüle tıklandı.");
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Tüm ${trades.length} işlemi gösteren ekran yakında.')),
                     );
                  },
                  child: Text(
                    'Tüm ${trades.length} İşlemi Görüntüle',
                    style: const TextStyle(color: AppTheme.accentColor),
                  ),
                ),
             ),
          ],
        ),
      ),
    );
  }


  // Tek bir işlem satırını oluşturan widget
  Widget _buildTradeHistoryItem(Map<String, dynamic> trade, int index) {
    // Null kontrolleri ile değerleri al
    final num? returnPct = trade['return_pct'] as num?;
    final bool isPositive = returnPct != null && returnPct >= 0;
    final Color returnColor = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;
    final String returnText = returnPct != null
        ? '${isPositive ? '+' : ''}${returnPct.toStringAsFixed(2)}%'
        : 'N/A';

    final String entryDate = _formatTradeDate(trade['entry_date'] as String?);
    final String exitDate = _formatTradeDate(trade['exit_date'] as String?);
    final String entryPrice = (trade['entry_price'] as num?)?.toStringAsFixed(2) ?? 'N/A';
    final String exitPrice = (trade['exit_price'] as num?)?.toStringAsFixed(2) ?? 'N/A';


    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
       decoration: BoxDecoration(
        // Her satır arasına ince bir çizgi
         border: index > 0
             ? Border(
                 top: BorderSide(
                   color: AppTheme.backgroundColor.withOpacity(0.5),
                   width: 0.5,
                 ),
               )
             : null,
       ),
      child: Row(
        children: [
          // İşlem Numarası
          SizedBox(
            width: 25, // Sabit genişlik
            child: Text(
              '#${index + 1}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                 fontSize: 12,
              ),
            ),
          ),
          //const SizedBox(width: 8), // Numaradan sonra boşluk

          // İşlem Tarihleri (Alt alta)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entryDate, // Giriş Tarihi
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
                 const SizedBox(height: 2),
                Text(
                  exitDate, // Çıkış Tarihi
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Fiyatlar (Alt alta)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$$entryPrice', // Giriş Fiyatı
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
                 const SizedBox(height: 2),
                Text(
                  '\$$exitPrice', // Çıkış Fiyatı
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Getiri (Ortalanmış Kapsül)
          Expanded(
            flex: 2,
            child: Center( // Kapsülü ortalamak için
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: returnColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  // border: Border.all(color: returnColor.withOpacity(0.5), width: 0.5)
                ),
                child: Text(
                  returnText,
                  style: TextStyle(
                    color: returnColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Performans Özet Kartları Widget'ı
  Widget _buildPerformanceSummaryCards(Map<String, dynamic> metrics) {
    // Null kontrolleri ile değerleri al ve varsayılan ata
    final double totalReturn = (metrics['total_return_pct'] as num?)?.toDouble() ?? 0.0;
    final double annualizedReturn = (metrics['annualized_return_pct'] as num?)?.toDouble() ?? 0.0;
    final double maxDrawdown = (metrics['max_drawdown_pct'] as num?)?.toDouble() ?? 0.0;
    final double winRate = (metrics['win_rate_pct'] as num?)?.toDouble() ?? 0.0;
    final double sharpeRatio = (metrics['sharpe_ratio'] as num?)?.toDouble() ?? 0.0;
     final double sortinoRatio = (metrics['sortino_ratio'] as num?)?.toDouble() ?? 0.0; // Ekstra metrik
    final int totalTrades = (metrics['total_trades'] as num?)?.toInt() ?? 0;
     final String avgTradeReturn = (metrics['average_trade_return_pct'] as num?)?.toStringAsFixed(2) ?? 'N/A'; // Ekstra metrik


    final bool isTotalReturnPositive = totalReturn >= 0;
    final bool isAnnualizedReturnPositive = annualizedReturn >= 0;

    // Kartları 2xN grid yapısında oluştur
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Toplam Getiri',
                '${isTotalReturnPositive ? '+' : ''}${totalReturn.toStringAsFixed(2)}%',
                isTotalReturnPositive ? Icons.trending_up : Icons.trending_down,
                isTotalReturnPositive ? AppTheme.positiveColor : AppTheme.negativeColor,
                 tooltip: "Backtest periyodu boyunca toplam getiri yüzdesi."
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Yıllık Getiri',
                '${isAnnualizedReturnPositive ? '+' : ''}${annualizedReturn.toStringAsFixed(2)}%',
                Icons.calendar_today,
                isAnnualizedReturnPositive ? AppTheme.positiveColor : AppTheme.negativeColor,
                 tooltip: "Yıllık bazda ortalama getiri yüzdesi."
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Maks. Düşüş (MDD)',
                '${maxDrawdown.toStringAsFixed(2)}%', // Genellikle negatiftir ama işareti olmadan gösterilir
                Icons.arrow_downward,
                AppTheme.negativeColor,
                 tooltip: "Varlık eğrisindeki zirveden dibe en büyük düşüş yüzdesi."
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Kazanç Oranı',
                '${winRate.toStringAsFixed(1)}%',
                Icons.emoji_events_outlined, // Farklı bir ikon
                AppTheme.accentColor,
                 tooltip: "Kârlı kapatılan işlemlerin toplam işlemlere oranı."
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Sharpe Oranı',
                sharpeRatio.toStringAsFixed(2),
                Icons.speed, // Hız ikonu
                Colors.amber.shade600,
                tooltip: "Risk ayarlı getiriyi ölçer (Yüksek daha iyi)."
              ),
            ),
             const SizedBox(width: 12),
             Expanded(
              child: _buildMetricCard(
                'Sortino Oranı', // Ekstra Metrik
                sortinoRatio.toStringAsFixed(2),
                Icons.filter_tilt_shift, // Farklı bir ikon
                 Colors.purple.shade300,
                 tooltip: "Aşağı yönlü riske göre ayarlanmış getiriyi ölçer (Yüksek daha iyi)."
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
         Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Toplam İşlem',
                totalTrades.toString(),
                Icons.swap_horiz,
                AppTheme.accentColor.withOpacity(0.8),
                 tooltip: "Backtest boyunca yapılan toplam alım-satım çifti sayısı."
              ),
            ),
             const SizedBox(width: 12),
             Expanded(
              child: _buildMetricCard(
                'Ort. İşlem Getirisi', // Ekstra Metrik
                '$avgTradeReturn%',
                Icons.calculate_outlined,
                double.tryParse(avgTradeReturn) == null ? AppTheme.textSecondary : (double.parse(avgTradeReturn) >= 0 ? AppTheme.positiveColor : AppTheme.negativeColor),
                 tooltip: "Tek bir işlemin ortalama getiri yüzdesi."
              ),
            ),
          ],
        ),
      ],
    );
  }


  // Tek bir metrik kartını oluşturan widget
  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {String? tooltip}) {
     Widget cardContent = Card(
      elevation: 2,
       shadowColor: Colors.black.withOpacity(0.3),
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // side: BorderSide(color: color.withOpacity(0.2)) // İsteğe bağlı kenarlık
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
           mainAxisAlignment: MainAxisAlignment.center, // İçeriği dikeyde ortala
           mainAxisSize: MainAxisSize.min, // Kartın içeriğe göre boyutlanmasını sağla
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // İkonu sağa yasla
              children: [
                 Flexible( // Başlığın taşmasını engelle
                   child: Text(
                     title,
                     style: const TextStyle(
                       fontSize: 13,
                       color: AppTheme.textSecondary,
                     ),
                      overflow: TextOverflow.ellipsis,
                   ),
                 ),
                 Icon(icon, color: color.withOpacity(0.8), size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20, // Değeri daha büyük yap
                fontWeight: FontWeight.bold,
                color: color,
              ),
               maxLines: 1, // Tek satıra sığdır
                overflow: TextOverflow.ellipsis, // Taşarsa ... ile göster
            ),
          ],
        ),
      ),
    );

     // Eğer tooltip varsa, Tooltip widget'ı ile sar
     if (tooltip != null && tooltip.isNotEmpty) {
       return Tooltip(
         message: tooltip,
         preferBelow: false, // Tooltip'i genellikle üstte göster
          waitDuration: const Duration(milliseconds: 500), // Göstermeden önce bekleme süresi
          textStyle: const TextStyle(fontSize: 12, color: Colors.black),
           decoration: BoxDecoration(
             color: AppTheme.accentColor.withOpacity(0.9),
             borderRadius: BorderRadius.circular(4),
           ),
         child: cardContent,
       );
     } else {
       return cardContent;
     }
  }


  // Koşul etiketini oluşturan metot (Daha küçük ve kompakt)
  Widget _buildConditionChip(String type, String condition, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Daha küçük padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12), // Daha yuvarlak kenar
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10, // Daha küçük font
            ),
          ),
          const SizedBox(width: 4), // Daha az boşluk
          Flexible( // Metnin taşmasını engelle
            child: Text(
              condition,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10), // Daha küçük font
              overflow: TextOverflow.ellipsis, // Taşarsa kes
            ),
          ),
        ],
      ),
    );
  }

  // Koşul metnini formatlayan metot
  String _formatCondition(Map<String, dynamic> condition) {
    final indicator1 = condition['indicator'] ?? '?';
    final operator = _formatOperator(condition['operator'] ?? '?');
    String value = '?';

    if (condition.containsKey('value') && condition['value'] != null) {
      // Sayısal değeri formatla (eğer sayıysa)
       if (condition['value'] is num) {
          value = (condition['value'] as num).toStringAsFixed(1); // Virgülden sonra 1 basamak
       } else {
          value = condition['value'].toString();
       }
    } else if (condition.containsKey('indicator2') && condition['indicator2'] != null) {
      value = condition['indicator2'].toString(); // Diğer gösterge adı
    }

    // Kırılma operatörleri için farklı format
    if (operator.contains('kırılması')) {
       return '$indicator1 $value değerini $operator';
    }

    return '$indicator1 $operator $value';
  }

  // Operatörü daha okunabilir formata çeviren yardımcı metot
  String _formatOperator(String op) {
    switch (op.toLowerCase()) {
      case '>': return '>';
      case '<': return '<';
      case '=': case '==': return '='; // Eşitlik
      case '>=': return '≥'; // Büyük veya eşit
      case '<=': return '≤'; // Küçük veya eşit
      case 'crosses': return 'kesişmesi'; // Genel kesişme
      case 'crosses_above': return 'yukarı kırılması';
      case 'crosses_below': return 'aşağı kırılması';
      case '!=': return '≠'; // Eşit değil
      default: return op; // Bilinmeyen operatörü olduğu gibi döndür
    }
  }

  // Metrik sütun oluşturma metodunu (Mini versiyon)
  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), // Daha küçük
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14, // Biraz daha küçük
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // İşlem tarihini formatlayan yardımcı metot (Null kontrolü eklendi)
  String _formatTradeDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) {
      return 'N/A'; // Eğer tarih yoksa
    }
    try {
      final date = DateTime.parse(isoDate);
      // Yıl-Ay-Gün formatı
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
       // Alternatif: Gün/Ay/Yıl
      // return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
       _logger.warning("Tarih formatlama hatası: $isoDate", e);
      return isoDate; // Hata olursa orijinal string'i döndür
    }
  }
}


// Varlık eğrisi için özel çizim sınıfı (Geliştirilmiş)
class EquityCurvePainter extends CustomPainter {
  final List<Map<String, dynamic>> equityCurve;
  final dynamic initialValue;
  final double benchmarkValue; // Buy and Hold getirisi (%)

  EquityCurvePainter({
    required this.equityCurve,
    required this.initialValue,
    this.benchmarkValue = 0.0, // Opsiyonel
  });

  @override
  void paint(Canvas canvas, Size size) {
    // En az iki nokta gerekli
    if (equityCurve.length < 2) {
        // Yetersiz veri mesajı çiz
         final textPainter = TextPainter(
           text: const TextSpan(text: 'Grafik için yeterli veri yok', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
           textDirection: TextDirection.ltr,
           textAlign: TextAlign.center,
         )..layout(minWidth: size.width);
         textPainter.paint(canvas, Offset(0, size.height / 2 - textPainter.height / 2));
        return;
    }

    final double actualInitialCapital = (initialValue is num ? (initialValue as num).toDouble() : 10000.0).toDouble();

    // Min/Max değerleri bul (hem strateji hem benchmark için)
    double minValue = actualInitialCapital; // Başlangıç sermayesi minimum olabilir
    double maxValue = actualInitialCapital; // Başlangıç sermayesi maksimum olabilir

    List<double> strategyValues = [];
     List<double> benchmarkValues = []; // Benchmark (Buy&Hold) değerleri


    // Strateji değerlerini işle
    for (var point in equityCurve) {
      final value = (point['value'] is num ? (point['value'] as num).toDouble() : actualInitialCapital).toDouble();
      strategyValues.add(value);
      if (value < minValue) minValue = value;
      if (value > maxValue) maxValue = value;
    }

    // Benchmark değerlerini hesapla (varsa)
     if (benchmarkValue != 0.0 && equityCurve.isNotEmpty) {
       final double totalReturnFactor = 1.0 + (benchmarkValue / 100.0);
        final int numPoints = equityCurve.length;

        // Basit lineer enterpolasyon ile benchmark eğrisi oluştur
        for (int i = 0; i < numPoints; i++) {
           double progress = i / (numPoints - 1);
           double benchmarkCurrentValue = actualInitialCapital * (1 + (totalReturnFactor - 1) * progress);
           benchmarkValues.add(benchmarkCurrentValue);
            if (benchmarkCurrentValue < minValue) minValue = benchmarkCurrentValue;
            if (benchmarkCurrentValue > maxValue) maxValue = benchmarkCurrentValue;
        }
     }


    // Değer aralığına padding ekle
    final range = maxValue - minValue;
     // Eğer range çok küçükse (veya 0 ise), varsayılan bir aralık kullan
     final effectiveRange = (range <= 1e-6) ? actualInitialCapital * 0.2 : range; // Başlangıç sermayesinin %20'si kadar
     minValue = max(0, minValue - effectiveRange * 0.1); // %10 aşağı padding, 0'ın altına inme
     maxValue = maxValue + effectiveRange * 0.1; // %10 yukarı padding
     final finalRange = maxValue - minValue; // Nihai aralık


    // Boyaları tanımla
    final Paint linePaint = Paint()
      ..color = AppTheme.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 // Biraz daha ince çizgi
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.accentColor.withOpacity(0.4), // Biraz daha az opak
          AppTheme.accentColor.withOpacity(0.05), // Daha şeffaf alt kısım
        ],
         stops: const [0.0, 0.9] // Geçiş noktaları
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

     final Paint benchmarkLinePaint = Paint()
      ..color = Colors.orange.withOpacity(0.7) // Benchmark için turuncu
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
       ..strokeCap = StrokeCap.round
       ..isAntiAlias = true;


     final Paint initialCapitalLinePaint = Paint()
      ..color = AppTheme.textSecondary.withOpacity(0.5) // Başlangıç çizgisi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.butt;


    final Paint gridPaint = Paint()
      ..color = AppTheme.textSecondary.withOpacity(0.15) // Daha soluk grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;


    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    // ---- Çizim Başlıyor ----

    // 1. Grid Çizgileri ve Y Eksen Etiketleri
    const int gridLines = 5; // Yatay çizgi sayısı (0 dahil)
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height - (i / gridLines) * size.height;
      // Yatay grid çizgisi
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      // Y ekseni etiketi
      final value = minValue + (i / gridLines) * finalRange;
      textPainter.text = TextSpan(
        text: _formatAxisValue(value), // Formatlı değer
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
      );
      textPainter.layout();
       // Etiketi çizginin biraz üstüne ve sola hizalı çiz
      textPainter.paint(canvas, Offset(5, y - textPainter.height - 2));
    }

    // 2. Başlangıç Sermayesi Çizgisi
    // finalRange'in 0 olmadığından emin ol
     if (finalRange > 1e-6) {
        final initialY = size.height - ((actualInitialCapital - minValue) / finalRange) * size.height;
        // Kesik çizgi efekti için Path kullan
         Path initialLinePath = Path();
         const double dashWidth = 4.0;
         const double dashSpace = 3.0;
         double startX = 0;
         while (startX < size.width) {
            initialLinePath.moveTo(startX, initialY);
            initialLinePath.lineTo(startX + dashWidth, initialY);
            startX += dashWidth + dashSpace;
         }
         canvas.drawPath(initialLinePath, initialCapitalLinePaint);

          // Başlangıç değeri etiketi (opsiyonel)
         /*
          textPainter.text = TextSpan(
            text: _formatAxisValue(actualInitialCapital),
            style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 9),
          );
          textPainter.layout();
           textPainter.paint(canvas, Offset(size.width - textPainter.width - 5, initialY - textPainter.height - 2));
           */
      }


    // 3. Varlık Eğrisi ve Dolgusu
    final Path linePath = Path();
    final Path fillPath = Path();
    final double xStep = size.width / (strategyValues.length - 1);

     // Başlangıç noktaları
     double startX = 0;
     double startY = size.height; // Varsayılan olarak alt
     if (finalRange > 1e-6) {
         startY = size.height - ((strategyValues[0] - minValue) / finalRange) * size.height;
     }


    linePath.moveTo(startX, startY);
    fillPath.moveTo(startX, size.height); // Dolgu alttan başlar
    fillPath.lineTo(startX, startY);

    // Eğri noktalarını ekle
    for (int i = 1; i < strategyValues.length; i++) {
      final x = i * xStep;
      double y = size.height; // Varsayılan olarak alt
       if (finalRange > 1e-6) {
         y = size.height - ((strategyValues[i] - minValue) / finalRange) * size.height;
       }
      linePath.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    // Dolguyu kapat
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Dolguyu ve çizgiyi çiz
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);


     // 4. Benchmark (Buy & Hold) Eğrisi (varsa)
     if (benchmarkValues.isNotEmpty && benchmarkValues.length == strategyValues.length && finalRange > 1e-6) {
        final Path benchmarkPath = Path();
        double benchStartY = size.height - ((benchmarkValues[0] - minValue) / finalRange) * size.height;
        benchmarkPath.moveTo(0, benchStartY);

        for (int i = 1; i < benchmarkValues.length; i++) {
           final x = i * xStep;
           final y = size.height - ((benchmarkValues[i] - minValue) / finalRange) * size.height;
           benchmarkPath.lineTo(x, y);
        }
         canvas.drawPath(benchmarkPath, benchmarkLinePaint);
     }


     // 5. Başlangıç ve Bitiş Noktaları (İsteğe Bağlı)
      /*
     final Paint markerPaint = Paint()..color = AppTheme.accentColor;
     final Paint markerInnerPaint = Paint()..color = AppTheme.cardColor; // İç renk

     // Başlangıç noktası
     canvas.drawCircle(Offset(startX, startY), 5, markerPaint);
     canvas.drawCircle(Offset(startX, startY), 3, markerInnerPaint);

     // Bitiş noktası
     double endX = size.width;
      double endY = size.height;
      if (finalRange > 1e-6) {
          endY = size.height - ((strategyValues.last - minValue) / finalRange) * size.height;
      }
      canvas.drawCircle(Offset(endX, endY), 5, markerPaint);
      canvas.drawCircle(Offset(endX, endY), 3, markerInnerPaint);
      */

  }

   // Eksen değerlerini formatlamak için yardımcı fonksiyon
   String _formatAxisValue(double value) {
     if (value >= 1000000) {
       return '\$${(value / 1000000).toStringAsFixed(1)}M'; // Milyon
     } else if (value >= 1000) {
       return '\$${(value / 1000).toStringAsFixed(1)}K'; // Bin
     } else {
       return '\$${value.toStringAsFixed(0)}'; // Normal değer
     }
   }


  @override
  bool shouldRepaint(covariant EquityCurvePainter oldDelegate) {
    // Veri değiştiğinde yeniden çiz
    return oldDelegate.equityCurve != equityCurve ||
           oldDelegate.initialValue != initialValue ||
            oldDelegate.benchmarkValue != benchmarkValue;
  }
}
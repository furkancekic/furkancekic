import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'dart:math' as math;
import '../services/fund_api_service.dart'; // API servisini import et

class FundDetailScreen extends StatefulWidget {
  final Map<String, dynamic> fund; // Bu hala başlangıç için temel bilgileri taşıyabilir

  const FundDetailScreen({Key? key, required this.fund}) : super(key: key);

  @override
  State<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends State<FundDetailScreen>
    with SingleTickerProviderStateMixin {
  String _selectedTimeframe = '1M';
  late TabController _tabController;
  int _selectedComparisonFund = -1;
  bool _showBenchmark = false;

  // API'den gelen verileri tutmak için state değişkenleri
  Map<String, dynamic> _fetchedFundDetails = {};
  List<Map<String, dynamic>> _historicalChartData = [];
  Map<String, dynamic> _riskMetricsData = {};
  Map<String, dynamic> _monteCarloData = {}; // Monte Carlo verisi için
  List<Map<String, dynamic>> _fetchedComparisonFunds = []; // API'den gelecek benzer fonlar

  // Yüklenme durumları için flag'ler
  bool _isLoadingDetails = true;
  bool _isLoadingChart = true;
  bool _isLoadingMetrics = true;
  bool _isLoadingMonteCarlo = true;
  bool _isLoadingComparisonFunds = true;


  final List<String> _timeframes = [
    '1H',
    '1D',
    '1W',
    '1M',
    '3M',
    '6M',
    '1Y',
    'Max'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAllData(); // Başlangıçta tüm verileri çek
  }

  Future<void> _fetchAllData() async {
    if (widget.fund['kod'] == null) {
      setState(() {
        _isLoadingDetails = false;
        _isLoadingChart = false;
        _isLoadingMetrics = false;
        _isLoadingMonteCarlo = false;
        _isLoadingComparisonFunds = false;
        // Hata mesajı gösterilebilir
      });
      return;
    }
    await _fetchFundDetails();
    await _fetchHistoricalData(_selectedTimeframe); // Başlangıç zaman aralığı ile
    await _fetchRiskMetrics();
    await _fetchMonteCarlo();
    // Örnek olarak aynı kategorideki fonları çekelim (veya API'nizde benzer fonlar endpoint'i varsa onu kullanın)
    // Bu kısım API'nizin "benzer fonlar" için nasıl bir yapı sunduğuna bağlı
    if (_fetchedFundDetails['kategori'] != null) {
      await _fetchComparisonFundsByCategory(_fetchedFundDetails['kategori']);
    } else {
       setState(() => _isLoadingComparisonFunds = false);
    }
  }

  Future<void> _fetchFundDetails() async {
    setState(() => _isLoadingDetails = true);
    try {
      final details = await FundApiService.getFundDetails(widget.fund['kod']);
      setState(() {
        _fetchedFundDetails = details;
        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() => _isLoadingDetails = false);
      // Hata yönetimi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fon detayları yüklenemedi: $e')),
      );
    }
  }

  Future<void> _fetchHistoricalData(String timeframe) async {
    setState(() => _isLoadingChart = true);
    try {
      final historicalData = await FundApiService.getFundHistoricalData(
          widget.fund['kod'], timeframe);
      setState(() {
        _historicalChartData = historicalData;
        _isLoadingChart = false;
      });
    } catch (e) {
      setState(() => _isLoadingChart = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geçmiş veriler yüklenemedi: $e')),
      );
    }
  }

  Future<void> _fetchRiskMetrics() async {
    setState(() => _isLoadingMetrics = true);
    try {
      final metrics = await FundApiService.getFundRiskMetrics(widget.fund['kod']);
      setState(() {
        _riskMetricsData = metrics;
        _isLoadingMetrics = false;
      });
    } catch (e) {
      setState(() => _isLoadingMetrics = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Risk metrikleri yüklenemedi: $e')),
      );
    }
  }

   Future<void> _fetchMonteCarlo() async {
    setState(() => _isLoadingMonteCarlo = true);
    try {
      // API'nizdeki parametrelere göre period ve simulation değerlerini ayarlayın
      // Örnek: 1 yıl (12 periyot), 1000 simülasyon
      final monteCarlo = await FundApiService.getMonteCarlo(widget.fund['kod'], 12, 1000);
      setState(() {
        _monteCarloData = monteCarlo;
        _isLoadingMonteCarlo = false;
      });
    } catch (e) {
      setState(() => _isLoadingMonteCarlo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Monte Carlo simülasyonu yüklenemedi: $e')),
      );
    }
  }

  Future<void> _fetchComparisonFundsByCategory(String category) async {
    setState(() => _isLoadingComparisonFunds = true);
    try {
      final funds = await FundApiService.getFundsByCategory(category);
      // Mevcut fonu listeden çıkaralım
      setState(() {
        _fetchedComparisonFunds = funds.where((f) => f['kod'] != widget.fund['kod']).toList();
        _isLoadingComparisonFunds = false;
      });
    } catch (e) {
      setState(() => _isLoadingComparisonFunds = false);
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Benzer fonlar yüklenemedi: $e')),
      );
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final accent = ext?.accentColor ?? AppTheme.accentColor;
    final textPrimary = ext?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = ext?.textSecondary ?? AppTheme.textSecondary;
    final cardColor = ext?.cardColor ?? AppTheme.cardColor;
    final cardColorLight = ext?.cardColorLight ?? AppTheme.cardColorLight;
    final posColor = ext?.positiveColor ?? AppTheme.positiveColor;
    final negColor = ext?.negativeColor ?? AppTheme.negativeColor;

    // API'den gelen veriyi kullan
    final String fundCodeToDisplay = _fetchedFundDetails['kod'] ?? widget.fund['kod'] ?? 'Fon Detayı';
    final dailyReturn = _parseDailyReturn(_fetchedFundDetails['gunluk_getiri'] ?? widget.fund['gunluk_getiri'] ?? '0%');
    final isPositiveReturn = dailyReturn >= 0;
    final returnColor = isPositiveReturn ? posColor : negColor;

    final bgGradientColors = ext?.gradientBackgroundColors ??
        [
          Theme.of(context).scaffoldBackgroundColor,
          Theme.of(context).scaffoldBackgroundColor,
        ];

    return Scaffold(
      appBar: AppBar(
        title: Text(fundCodeToDisplay), // API'den gelen kodu kullan
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: accent),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.share, color: accent),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoadingDetails // Ana yükleme durumu kontrolü
          ? Center(child: CircularProgressIndicator(color: accent))
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: bgGradientColors,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFundHeader(
                          textPrimary, textSecondary, returnColor, isPositiveReturn),
                      const SizedBox(height: 16),
                      _buildTimeframeSelector(accent, cardColor),
                      const SizedBox(height: 16),
                      _isLoadingChart
                          ? SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: accent)))
                          : _buildPriceChart(cardColor, accent, returnColor),
                      const SizedBox(height: 24),
                      _buildTabBar(accent, textPrimary),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 600, // İçerik arttığı için yüksekliği ayarlayın
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(cardColor, textPrimary, textSecondary,
                                accent, posColor, negColor),
                            _buildDistributionTab(
                                cardColor, textPrimary, textSecondary, accent),
                            _isLoadingMetrics || _isLoadingMonteCarlo // Performans tabı için yükleme kontrolü
                                ? Center(child: CircularProgressIndicator(color: accent))
                                : _buildPerformanceTab(cardColor, textPrimary,
                                    textSecondary, accent, posColor, negColor),
                            _isLoadingComparisonFunds
                                ? Center(child: CircularProgressIndicator(color: accent))
                                : _buildComparisonTab(cardColor, textPrimary, textSecondary,
                                    accent, posColor, negColor, cardColorLight),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'buy',
              onPressed: () {},
              backgroundColor: posColor,
              label: const Text('SATIN AL'),
              icon: const Icon(Icons.add_shopping_cart),
            ),
            const SizedBox(width: 12),
            FloatingActionButton(
              heroTag: 'alert',
              onPressed: () {},
              backgroundColor: accent,
              child: const Icon(Icons.notifications_active),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundHeader(Color textPrimary, Color textSecondary,
      Color returnColor, bool isPositiveReturn) {
    // API'den gelen verileri kullan
    final fundName = _fetchedFundDetails['fon_adi'] ?? widget.fund['fon_adi'] ?? 'Fon Adı';
    final fundCode = _fetchedFundDetails['kod'] ?? widget.fund['kod'] ?? 'KOD';
    final tefasStatus = _fetchedFundDetails['tefas'] ?? widget.fund['tefas'] ?? '';
    final lastPrice = _fetchedFundDetails['son_fiyat']?.toString().replaceAll(',', '.') ?? widget.fund['son_fiyat']?.toString().replaceAll(',', '.') ?? '0.00';
    final dailyChange = _fetchedFundDetails['gunluk_getiri'] ?? widget.fund['gunluk_getiri'] ?? '0%';
    final totalValue = _fetchedFundDetails['fon_toplam_deger'] ?? widget.fund['fon_toplam_deger'] ?? 0;
    final investorCount = _fetchedFundDetails['yatirimci_sayisi'] ?? widget.fund['yatirimci_sayisi'] ?? 0;
    final category = _fetchedFundDetails['kategori'] ?? widget.fund['kategori'] ?? 'Bilinmiyor';
    final categoryRank = _fetchedFundDetails['kategori_drecece'] ?? widget.fund['kategori_drecece'];


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlowingText(
          fundName,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              fundCode,
              style:
                  TextStyle(color: textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tefasStatus.contains('işlem görüyor')
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tefasStatus.contains('işlem görüyor')
                    ? 'TEFAS'
                    : 'TEFAS DIŞI',
                style: TextStyle(
                  fontSize: 10,
                  color: tefasStatus.contains('işlem görüyor')
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fiyat',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '₺$lastPrice',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Günlük Değişim',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isPositiveReturn
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: returnColor,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dailyChange,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: returnColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fon Büyüklüğü: ₺${_formatCurrency(totalValue)}',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            Text(
              'Yatırımcı: $investorCount',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kategori: $category',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            if (categoryRank != null)
              Text(
                'Sıralama: $categoryRank',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector(Color accent, Color cardColor) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: _timeframes.map((timeframe) {
          final isSelected = timeframe == _selectedTimeframe;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTimeframe != timeframe) { // Sadece değişirse API çağır
                    setState(() {
                    _selectedTimeframe = timeframe;
                    });
                    _fetchHistoricalData(timeframe); // Seçilen zaman aralığı için veriyi çek
                }
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  timeframe,
                  style: TextStyle(
                    color: isSelected ? Colors.white : accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceChart(Color cardColor, Color accent, Color lineColor) {
    // API'den gelen _historicalChartData'yı kullan
    final List<FlSpot> spots = [];
    final List<String> bottomTitles = [];

    if (_historicalChartData.isNotEmpty) {
      // API'den gelen veri zaten timeframe'e göre filtrelenmiş olmalı
      // Eğer API endpoint'i timeframe parametresi almıyorsa, burada _filterDataByTimeframe kullanılabilir.
      // FundApiService.getFundHistoricalData zaten timeframe alıyor.

      for (int i = 0; i < _historicalChartData.length; i++) {
        final item = _historicalChartData[i];
        // API'nizin 'price' ve 'date' anahtarlarını kontrol edin
        final price = (item['price'] is String ? double.tryParse(item['price']) : item['price'])?.toDouble() ?? 0.0;
        spots.add(FlSpot(i.toDouble(), price));

        if (i % (_historicalChartData.length ~/ 5).clamp(1, 7) == 0 || i == _historicalChartData.length - 1) { // Daha dinamik etiketleme
          final dateStr = item['date'].toString(); // API'nizin tarih formatını kontrol edin
          try {
            final date = DateTime.parse(dateStr);
            bottomTitles.add('${date.day}/${date.month}');
          } catch (e) {
             bottomTitles.add(''); // Hatalı tarih formatı
          }
        } else {
          bottomTitles.add('');
        }
      }
    }

    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
      bottomTitles.add('');
    }

    return FuturisticCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (Grafik başlığı ve ikonlar aynı kalabilir)
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fiyat Grafiği',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.candlestick_chart, color: accent, size: 16),
                  const SizedBox(width: 4),
                  Icon(Icons.bar_chart, color: accent, size: 16),
                  const SizedBox(width: 4),
                  Icon(Icons.show_chart,
                      color: accent.withOpacity(0.5), size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                // ... (gridData, titlesData, borderData aynı kalabilir, min/max X/Y spotlara göre ayarlanacak)
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: (_getMaxY(spots) - _getMinY(spots)) / 4, // Dinamik interval
                  verticalInterval: (spots.length -1) / 5, // Dinamik interval
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 &&
                            index < bottomTitles.length &&
                            bottomTitles[index].isNotEmpty) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              bottomTitles[index],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                         if (spots.isEmpty || (spots.length == 1 && spots.first.y == 0)) { // Veri yoksa veya sadece (0,0) ise
                            return const SizedBox();
                          }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toStringAsFixed(spots.any((s) => s.y < 10) ? 2 : 1), // Ondalık hassasiyeti
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                       interval: (_getMaxY(spots) - _getMinY(spots)) / 4, // Dinamik interval
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: 0,
                maxX: spots.isNotEmpty ? spots.length - 1.0 : 0,
                minY: _getMinY(spots),
                maxY: _getMaxY(spots),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.2),
                    ),
                  ),
                  if (_showBenchmark)
                    LineChartBarData(
                      spots: _getBenchmarkSpots(spots.length, _getMinY(spots), _getMaxY(spots)), // Benchmark'ı ana grafiğe göre ayarla
                      isCurved: true,
                      color: Colors.white.withOpacity(0.7),
                      barWidth: 1,
                      isStrokeCapRound: true,
                      dashArray: [5, 5],
                      dotData: FlDotData(
                        show: false,
                      ),
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: cardColor.withOpacity(0.8),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final date = barSpot.x.toInt() < bottomTitles.length && bottomTitles[barSpot.x.toInt()].isNotEmpty
                            ? bottomTitles[barSpot.x.toInt()]
                            : '';
                        return LineTooltipItem(
                          '${date.isNotEmpty ? '$date: ' : ''}${barSpot.y.toStringAsFixed(4)}',
                          TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            // ... (Benchmark toggle aynı kalabilir)
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                setState(() {
                  _showBenchmark = !_showBenchmark;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _showBenchmark
                      ? accent.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accent.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.show_chart,
                      color: accent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'BIST 100', // Benchmark adı API'den gelebilir
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showBenchmark
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: accent,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color accent, Color textPrimary) {
    // Aynı kalabilir
    return TabBar(
      controller: _tabController,
      indicatorColor: accent,
      labelColor: accent,
      unselectedLabelColor: textPrimary,
      tabs: const [
        Tab(text: 'Genel Bakış'),
        Tab(text: 'Dağılım'),
        Tab(text: 'Performans'),
        Tab(text: 'Karşılaştırma'),
      ],
    );
  }

  Widget _buildOverviewTab(Color cardColor, Color textPrimary,
      Color textSecondary, Color accent, Color posColor, Color negColor) {
    // API'den gelen _fetchedFundDetails içindeki 'fund_profile'ı kullan
    final fundProfile = _fetchedFundDetails['fund_profile'] as Map<String, dynamic>? ?? {};
    final risk = int.tryParse(fundProfile['Fonun Risk Değeri']?.toString() ?? '0') ?? 0;

    final dynamic rawGirisKomisyonu = fundProfile['Giriş Komisyonu'];
    final String girisKomisyonuDisplayValue =
        (rawGirisKomisyonu is String && rawGirisKomisyonu.isNotEmpty)
            ? rawGirisKomisyonu
            : 'Yok';

    final dynamic rawCikisKomisyonu = fundProfile['Çıkış Komisyonu'];
    final String cikisKomisyonuDisplayValue =
        (rawCikisKomisyonu is String && rawCikisKomisyonu.isNotEmpty)
            ? rawCikisKomisyonu
            : 'Yok';
    
    if (_isLoadingDetails) {
        return Center(child: CircularProgressIndicator(color: accent));
    }
    if (fundProfile.isEmpty && _fetchedFundDetails.isNotEmpty && _fetchedFundDetails['kod'] == null) { // Eğer detaylar boşsa ve ana fon bilgisi de yoksa
        return const Center(child: Text("Fon profili bilgisi bulunamadı."));
    }


    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        FuturisticCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Risk Değeri',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final isActive = index + 1 <= risk;
                  final color = index < 3
                      ? posColor
                      : (index < 5 ? Colors.amber : negColor);

                  return Container(
                    width: 36,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? color : color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Düşük Risk', style: TextStyle(fontSize: 12)),
                  Text('Yüksek Risk', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FuturisticCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fon Özellikleri',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                  'ISIN Kodu',
                  fundProfile['ISIN Kodu']?.toString() ?? 'Bilgi yok',
                  textPrimary,
                  textSecondary),
              const SizedBox(height: 8),
              _buildInfoRow(
                  'İşlem Başlangıç Saati',
                  fundProfile['İşlem Başlangıç Saati']?.toString() ??
                      'Bilgi yok',
                  textPrimary,
                  textSecondary),
              const SizedBox(height: 8),
              _buildInfoRow(
                  'Son İşlem Saati',
                  fundProfile['Son İşlem Saati']?.toString() ??
                      'Bilgi yok',
                  textPrimary,
                  textSecondary),
              const SizedBox(height: 8),
              _buildInfoRow(
                  'Fon Alış Valörü',
                  fundProfile['Fon Alış Valörü']?.toString() ??
                      'Bilgi yok',
                  textPrimary,
                  textSecondary),
              const SizedBox(height: 8),
              _buildInfoRow(
                  'Fon Satış Valörü',
                  fundProfile['Fon Satış Valörü']?.toString() ??
                      'Bilgi yok',
                  textPrimary,
                  textSecondary),
              const SizedBox(height: 8),
              _buildInfoRow(
                  'Min. Alış İşlem Miktarı',
                  fundProfile['Min. Alış İşlem Miktarı']?.toString() ??
                      'Bilgi yok',
                  textPrimary,
                  textSecondary),
              const SizedBox(height: 8),
              _buildInfoRow(
                  'Min. Satış İşlem Miktarı',
                  fundProfile['Min. Satış İşlem Miktarı']?.toString() ??
                      'Bilgi yok',
                  textPrimary,
                  textSecondary),
              const SizedBox(height: 8),
              _buildInfoRow('Giriş Komisyonu', girisKomisyonuDisplayValue,
                  textPrimary, textSecondary),
              const SizedBox(height: 8),
              _buildInfoRow('Çıkış Komisyonu', cikisKomisyonuDisplayValue,
                  textPrimary, textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (fundProfile['KAP Bilgi Adresi'] != null)
          FuturisticCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KAP Bilgi Adresi',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell( // Linki tıklanabilir yapalım
                  onTap: () {
                    //launchUrl(Uri.parse(fundProfile['KAP Bilgi Adresi'])); // url_launcher paketi lazım
                  },
                  child: Row(
                    children: [
                      Icon(Icons.link, color: accent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fundProfile['KAP Bilgi Adresi']?.toString() ??
                              'Bilgi yok',
                          style: TextStyle(
                            color: accent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDistributionTab(
      Color cardColor, Color textPrimary, Color textSecondary, Color accent) {
    // API'den gelen _fetchedFundDetails içindeki 'fund_distributions'ı kullan
    final fundDistributions =
        _fetchedFundDetails['fund_distributions'] as Map<String, dynamic>? ?? {};
    
    if (_isLoadingDetails) {
        return Center(child: CircularProgressIndicator(color: accent));
    }
     if (fundDistributions.isEmpty && _fetchedFundDetails.isNotEmpty && _fetchedFundDetails['kod'] == null) {
        return const Center(child: Text("Fon dağılım bilgisi bulunamadı."));
    }


    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        FuturisticCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fon Dağılımı',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: fundDistributions.isEmpty
                          ? Center(child: Text('Dağılım verisi yok', style: TextStyle(color: textSecondary)))
                          : Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: _getPieChartSections(fundDistributions), // Bu metod API verisine göre güncellenmeli
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              startDegreeOffset: -90,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Toplam',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '100%',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: fundDistributions.isEmpty
                          ? const SizedBox.shrink() // Zaten yukarıda mesaj gösteriliyor
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: fundDistributions.entries.map((entry) {
                                final index = fundDistributions.keys
                                    .toList()
                                    .indexOf(entry.key);
                                final color = _getAssetColor(index);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '%${entry.value.toString()}',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FuturisticCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yüzdesel Dağılım',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: fundDistributions.isEmpty
                    ? Center(
                        child: Text(
                          'Dağılım verisi bulunamadı',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          // ... (Bar chart ayarları aynı kalabilir, veri fundDistributions'dan gelecek)
                           alignment: BarChartAlignment.spaceAround,
                          maxY: 100, // Veya dağılımdaki max değere göre dinamik yap
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: cardColor.withOpacity(0.8),
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${fundDistributions.keys.elementAt(groupIndex)}\n',
                                  TextStyle(
                                    color: textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '%${rod.toY.toStringAsFixed(1)}',
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                  final index = value.toInt();
                                  if (index >= 0 &&
                                      index < fundDistributions.length) {
                                    final name =
                                        fundDistributions.keys.elementAt(index);
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        name.length > 8 // Daha kısa isimler için
                                            ? '${name.substring(0, 8)}...'
                                            : name,
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                                reservedSize: 28,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                interval: 20,
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      '%${value.toInt()}',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: false,
                          ),
                          barGroups: fundDistributions.entries.map((entry) {
                            final index = fundDistributions.keys
                                .toList()
                                .indexOf(entry.key);
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: double.tryParse(entry.value.toString()) ?? 0.0,
                                  color: _getAssetColor(index),
                                  width: 15,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                          gridData: FlGridData(
                            show: true,
                            checkToShowHorizontalLine: (value) =>
                                value % 20 == 0,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: textSecondary.withOpacity(0.2),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceTab(Color cardColor, Color textPrimary,
      Color textSecondary, Color accent, Color posColor, Color negColor) {
    // API'den gelen _riskMetricsData ve _monteCarloData'yı kullan
    // Dönemsel getiriler API'den gelmiyorsa, _historicalChartData'dan hesaplanabilir veya geçici olarak bırakılabilir.
    // Şimdilik dönemsel getirileri widget.fund veya _fetchedFundDetails üzerinden almaya çalışalım.
    final dailyReturn = _fetchedFundDetails['gunluk_getiri'] ?? widget.fund['gunluk_getiri'] ?? '0%';
    // Diğer periyotlar için API'nizden veri gelmiyorsa, burası statik kalabilir veya hesaplama gerektirir.
    // API'niz `getFundHistoricalData` ile yeterince data sağlıyorsa, bu getiriler hesaplanabilir.

    if (_isLoadingMetrics || _isLoadingMonteCarlo) {
        return Center(child: CircularProgressIndicator(color: accent));
    }


    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        FuturisticCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dönemsel Getiriler',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildReturnRow('Günlük', dailyReturn, posColor, negColor),
              const SizedBox(height: 8),
              // API'nizde bu veriler varsa:
              // _buildReturnRow('Haftalık', _fetchedFundDetails['returns']?['weekly'] ?? '%0.00', posColor, negColor),
              // _buildReturnRow('Aylık', _fetchedFundDetails['returns']?['monthly'] ?? '%0.00', posColor, negColor),
              // Şimdilik statik bırakalım veya API'ye göre güncelleyelim
              _buildReturnRow('Haftalık', _fetchedFundDetails['haftalik_getiri'] ?? '%2.47', posColor, negColor), // Örnek, API'nize göre güncelleyin
              const SizedBox(height: 8),
              _buildReturnRow('Aylık', _fetchedFundDetails['aylik_getiri'] ?? '%5.63', posColor, negColor),
              const SizedBox(height: 8),
              _buildReturnRow('3 Aylık', _fetchedFundDetails['uc_aylik_getiri'] ?? '%-1.23', posColor, negColor),
              const SizedBox(height: 8),
              _buildReturnRow('6 Aylık', _fetchedFundDetails['alti_aylik_getiri'] ?? '%8.92', posColor, negColor),
              const SizedBox(height: 8),
              _buildReturnRow('Yıllık', _fetchedFundDetails['yillik_getiri'] ?? '%14.76', posColor, negColor),
               const SizedBox(height: 8),
              _buildReturnRow('3 Yıllık', _fetchedFundDetails['uc_yillik_getiri'] ?? '%72.34', posColor, negColor),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FuturisticCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Risk ve Performans Metrikleri',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard('Sharpe Oranı',
                        (_riskMetricsData['sharpeRatio'] as num?)?.toDouble() ?? 0.0, textPrimary, accent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                        'Beta', (_riskMetricsData['beta'] as num?)?.toDouble() ?? 0.0, textPrimary, accent),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                        'Alfa', (_riskMetricsData['alpha'] as num?)?.toDouble() ?? 0.0, textPrimary, accent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                        'R²', (_riskMetricsData['rSquared'] as num?)?.toDouble() ?? 0.0, textPrimary, accent),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard('Max. Düşüş',
                        (_riskMetricsData['maxDrawdown'] as num?)?.toDouble() ?? 0.0, textPrimary, negColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                        'Std. Sapma', (_riskMetricsData['stdDev'] as num?)?.toDouble() ?? 0.0, textPrimary, accent),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FuturisticCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monte Carlo Simülasyonu (1 Yıl)', // API'den gelen periyoda göre dinamikleştirilebilir
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                // API'den gelen _monteCarloData'yı kullanarak LineChartData oluştur
                // _monteCarloData'nın yapısına göre spotları oluşturmanız gerekecek.
                // Örnek: _monteCarloData = {'optimistic': [FlSpot(...), ...], 'expected': ..., 'pessimistic': ...}
                child: _monteCarloData.isEmpty
                  ? Center(child: Text("Simülasyon verisi yok.", style: TextStyle(color: textSecondary)))
                  : LineChart(
                  LineChartData(
                    // ... (Grid, Titles, Border ayarları benzer kalabilir)
                     gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 10, // API verisine göre dinamik olabilir
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withOpacity(0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            // API'den gelen periyot sayısına göre etiketleri ayarla
                            final periods = (_monteCarloData['periods'] as int?) ?? 12; // Varsayılan 12
                            final months = List.generate( (periods ~/ 3) +1 , (i) => i == 0 ? 'Bugün' : '${i*3} Ay');
                             if (periods == 12) { // Özel durum 1 yıl için
                                months[months.length-1] = '1 Yıl';
                            }

                            final index = (value / 3).round().clamp(0, months.length -1);
                            if (index >= 0 && index < months.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  months[index],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 22,
                          interval: 3, // Her 3 periyotta bir etiket
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '%${value.toInt()}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                          reservedSize: 32,
                          interval: 10, // API verisine göre dinamik olabilir
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    minY: (_monteCarloData['min_return'] as num?)?.toDouble() ?? -20,
                    maxY: (_monteCarloData['max_return'] as num?)?.toDouble() ?? 40,
                    lineBarsData: [
                      if (_monteCarloData['optimistic_scenario'] != null)
                        LineChartBarData(
                          spots: (_monteCarloData['optimistic_scenario'] as List<dynamic>).asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value as num).toDouble())).toList(),
                          isCurved: true,
                          color: posColor,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: posColor.withOpacity(0.1)),
                        ),
                      if (_monteCarloData['expected_scenario'] != null)
                        LineChartBarData(
                          spots: (_monteCarloData['expected_scenario'] as List<dynamic>).asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value as num).toDouble())).toList(),
                          isCurved: true,
                          color: accent,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                        ),
                      if (_monteCarloData['pessimistic_scenario'] != null)
                        LineChartBarData(
                          spots: (_monteCarloData['pessimistic_scenario'] as List<dynamic>).asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value as num).toDouble())).toList(),
                          isCurved: true,
                          color: negColor,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: negColor.withOpacity(0.1)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Optimistik', posColor),
                  const SizedBox(width: 16),
                  _buildLegendItem('Beklenen', accent),
                  const SizedBox(width: 16),
                  _buildLegendItem('Pesimistik', negColor),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTab(
      Color cardColor,
      Color textPrimary,
      Color textSecondary,
      Color accent,
      Color posColor,
      Color negColor,
      Color cardColorLight) {
    // Kategori karşılaştırması için API'den veri çekilebilir veya statik kalabilir.
    // Benzer fonlar (_fetchedComparisonFunds) API'den gelen veriyi kullanacak.

    if (_isLoadingComparisonFunds) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    // Kategori karşılaştırması için örnek veri (API'nizden gelmeli)
    // Bu kısım için ayrı bir API çağrısı veya _fetchedFundDetails'den türetme gerekebilir.
    // Örneğin: _fetchedFundDetails['category_comparison_data']
    final categoryComparisonData = _fetchedFundDetails['category_comparison'] ?? {
        'this_fund': {'name': 'Bu Fon', 'value': 10.5, 'color_opacity': 1.0},
        'category_avg': {'name': 'Kat. Ort.', 'value': 8.2, 'color_opacity': 0.7},
        'bist_100': {'name': 'BIST 100', 'value': 6.7, 'color_opacity': 0.5},
        'inflation': {'name': 'Enflasyon', 'value': 4.2, 'color_opacity': 0.3},
    };
    final List<MapEntry<String, dynamic>> categoryEntries = categoryComparisonData.entries.toList();


    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        FuturisticCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori Karşılaştırması',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                // API'den gelen kategori karşılaştırma verisini kullan
                child: BarChart(
                  BarChartData(
                    // ... (Bar chart ayarları benzer kalabilir, veri API'den gelecek)
                     alignment: BarChartAlignment.spaceAround,
                    maxY: 20, // API verisine göre dinamik
                    minY: -10, // API verisine göre dinamik
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: cardColor.withOpacity(0.8),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          if (groupIndex < categoryEntries.length) {
                            final entry = categoryEntries[groupIndex];
                            return BarTooltipItem(
                              '${entry.value['name']}\n',
                              TextStyle(
                                color: textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: '%${(entry.value['value'] as num).toStringAsFixed(1)}',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < categoryEntries.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  categoryEntries[index].value['name'],
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: 5, // API verisine göre dinamik
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '%${value.toInt()}',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: categoryEntries.asMap().entries.map((entryMap) {
                        final index = entryMap.key;
                        final data = entryMap.value.value;
                        return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: (data['value'] as num).toDouble(),
                            color: accent.withOpacity((data['color_opacity'] as num).toDouble()),
                            width: 22,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    gridData: FlGridData(
                      show: true,
                      checkToShowHorizontalLine: (value) => value % 5 == 0,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: textSecondary.withOpacity(0.2),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FuturisticCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Benzer Fonlarla Karşılaştırma',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_fetchedComparisonFunds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(child: Text("Benzer fon bulunamadı.", style: TextStyle(color: textSecondary))),
                )
              else
                ..._fetchedComparisonFunds.asMap().entries.map((entry) {
                  final index = entry.key;
                  final fund = entry.value;
                  final isSelected = index == _selectedComparisonFund;
                  // API'den gelen 'return' değerini kullan
                  final returnValue = (fund['return'] as num?)?.toDouble() ?? (fund['gunluk_getiri'] != null ? _parseDailyReturn(fund['gunluk_getiri']) : 0.0);
                  final returnColor = returnValue >= 0 ? posColor : negColor;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedComparisonFund = isSelected ? -1 : index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? cardColorLight : cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? accent : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: accent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fund['kod']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fund['name']?.toString() ?? fund['fon_adi']?.toString() ?? 'İsim Yok',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            // API'den gelen return değerini formatla
                            returnValue >= 0 ? '+${returnValue.toStringAsFixed(2)}%' : '${returnValue.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: returnColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            returnValue >= 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: returnColor,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              const SizedBox(height: 8),
              if (_fetchedComparisonFunds.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedComparisonFund != -1 ? () {
                    // Seçili fonlarla karşılaştırma ekranına git
                    // final selectedFundCode = _fetchedComparisonFunds[_selectedComparisonFund]['kod'];
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => FundComparisonScreen(baseFund: widget.fund, compareWithFundCode: selectedFundCode)));
                  } : null, // Butonu disable et
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.sync_alt, size: 16),
                      SizedBox(width: 8),
                      Text('KARŞILAŞTIRMA EKRANINI AÇ'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // Utility methods (aynı kalabilir)
  Widget _buildInfoRow(
      String label, String value, Color textPrimary, Color textSecondary) {
    // ... aynı
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReturnRow(
      String period, String returnValue, Color posColor, Color negColor) {
    // ... aynı
     final returnPercentage = _parseDailyReturn(returnValue);
    final isPositive = returnPercentage >= 0;
    final returnColor = isPositive ? posColor : negColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(period, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)), // Temadan renk al
        Row(
          children: [
            Text(
              returnValue,
              style: TextStyle(
                color: returnColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: returnColor,
              size: 16,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, double value, Color textPrimary, Color valueColor) {
    // ... aynı
     return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2), // Temaya göre ayarlanabilir
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title == 'Max. Düşüş'
                ? '${value.toStringAsFixed(1)}%' // Max düşüş genellikle yüzde ile gösterilir
                : value.toStringAsFixed(2),
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    // ... aynı
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyLarge?.color // Temadan renk al
          ),
        ),
      ],
    );
  }

  double _parseDailyReturn(String returnStr) {
    try {
      if (returnStr.startsWith('%')) {
        returnStr = returnStr.substring(1);
      }
      returnStr = returnStr.replaceAll(',', '.');
      return double.parse(returnStr);
    } catch (_) {
      return 0.0;
    }
  }

  String _formatCurrency(dynamic value) {
    try {
      final numValue =
          value is String ? double.tryParse(value.replaceAll(',', '.')) ?? 0.0 : (value as num?)?.toDouble() ?? 0.0;
      if (numValue >= 1000000000) {
        return '${(numValue / 1000000000).toStringAsFixed(2)}B';
      } else if (numValue >= 1000000) {
        return '${(numValue / 1000000).toStringAsFixed(2)}M';
      } else if (numValue >= 1000) {
        return '${(numValue / 1000).toStringAsFixed(2)}K';
      } else {
        return numValue.toStringAsFixed(2);
      }
    } catch (_) {
      return '0.00';
    }
  }

  double _getMinY(List<FlSpot> spots) {
    if (spots.isEmpty || (spots.length == 1 && spots.first.y == 0)) return 0; // Veri yoksa veya sadece (0,0) ise
    double minY = spots[0].y;
    for (final spot in spots) {
      if (spot.y < minY) {
        minY = spot.y;
      }
    }
    return (minY * 0.98).floorToDouble(); // Biraz boşluk bırak ve tam sayıya yuvarla
  }

  double _getMaxY(List<FlSpot> spots) {
     if (spots.isEmpty || (spots.length == 1 && spots.first.y == 0)) return 1; // Veri yoksa veya sadece (0,0) ise
    double maxY = spots[0].y;
    for (final spot in spots) {
      if (spot.y > maxY) {
        maxY = spot.y;
      }
    }
    return (maxY * 1.02).ceilToDouble(); // Biraz boşluk bırak ve tam sayıya yuvarla
  }

  // ESKİ: _filterDataByTimeframe API'den filtrelenmiş veri geldiği için artık gerekmeyebilir.
  // Eğer API timeframe parametresi almıyorsa bu metod kullanılabilir.
  // List<dynamic> _filterDataByTimeframe(
  //     List<dynamic> historicalData, String timeframe) { ... }

  List<FlSpot> _getBenchmarkSpots(int length, double mainMinY, double mainMaxY) {
    // API'den benchmark verisi çekilmiyorsa, bu simülasyon kalabilir.
    // İdealde bu da API'den gelmeli: FundApiService.getBenchmarkHistoricalData('BIST100', _selectedTimeframe)
    final spots = <FlSpot>[];
    if (length == 0) return spots;

    final random = math.Random(42);
    double value = (mainMinY + mainMaxY) / 2 ; // Ana grafiğin ortasından başlasın
    final range = (mainMaxY - mainMinY).abs();
    final step = range / 20 / length; // Daha küçük adımlar

    for (int i = 0; i < length; i++) {
      final change = (random.nextDouble() - 0.48) * step * 5 ; // Biraz yukarı eğilim
      value += change;
      spots.add(FlSpot(i.toDouble(), value.clamp(mainMinY, mainMaxY))); // Ana grafik sınırları içinde kal
    }
    return spots;
  }

  List<PieChartSectionData> _getPieChartSections(
      Map<String, dynamic> distribution) {
    if (distribution.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 100,
          title: '', // 'Veri Yok'
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
      ];
    }

    final List<PieChartSectionData> sections = [];
    distribution.entries.toList().asMap().forEach((index, entry) {
      final value = double.tryParse(entry.value.toString()) ?? 0.0;
      final color = _getAssetColor(index);

      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '${value.toStringAsFixed(1)}%', // Yüzdeyi göster
          radius: 60, // Biraz daha büyük
          titleStyle: const TextStyle(
            fontSize: 10, // Daha küçük font
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)] // Okunurluk için gölge
          ),
           titlePositionPercentageOffset: 0.7, // Etiketi biraz dışarı taşı
        ),
      );
    });
    return sections;
  }
}

// _getAssetColor (aynı kalabilir)
Color _getAssetColor(int index) {
  final colors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFF97316), // Orange
    const Color(0xFF84CC16), // Lime
  ];
  return colors[index % colors.length];
}
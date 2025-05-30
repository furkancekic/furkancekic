import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/fund_widgets/fund_chart.dart';
import '../../widgets/fund_widgets/fund_distribution_chart.dart';
import '../../services/fund_api_service.dart';
import '../../utils/logger.dart';

class FundDetailScreen extends StatefulWidget {
  final Map<String, dynamic> fund;

  const FundDetailScreen({Key? key, required this.fund}) : super(key: key);

  @override
  State<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends State<FundDetailScreen>
    with TickerProviderStateMixin {
  final _logger = AppLogger('FundDetailScreen');
  final ScrollController _scrollController = ScrollController();

  // Data variables
  String _selectedTimeframe = '1M';
  List<Map<String, dynamic>> _historicalData = [];
  List<Map<String, dynamic>> _investorData = []; // Yatırımcı sayısı verileri
  Map<String, dynamic>? _riskMetrics;
  Map<String, dynamic>? _monteCarloResult;
  bool _isLoading = false;
  String _error = '';

  final List<String> _timeframes = ['1W', '1M', '3M', '6M', '1Y', 'All'];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadFundData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFundData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = ''; });

    try {
      final fundCode = widget.fund['kod']?.toString();
      if (fundCode == null || fundCode.isEmpty) {
        throw Exception('Fund code is missing');
      }
      _logger.info('Loading data for fund: $fundCode');

      final futures = await Future.wait([
        FundApiService.getFundHistorical(fundCode, timeframe: _selectedTimeframe)
            .catchError((e) {
          _logger.warning('Error loading historical data for $fundCode: $e');
          return <String, dynamic>{'status': 'error', 'historical': <Map<String, dynamic>>[]}; // Map tipi ekledik
        }),
        FundApiService.getFundRiskMetrics(fundCode)
            .catchError((e) {
          _logger.warning('Error loading risk metrics for $fundCode: $e');
          return <String, dynamic>{'status': 'error', 'metrics': FundApiService.getDefaultRiskMetrics()};
        }),
        FundApiService.getMonteCarlo(fundCode, periods: 12, simulations: 1000)
            .catchError((e) {
          _logger.warning('Error loading Monte Carlo for $fundCode: $e');
          return <String, dynamic>{'status': 'error', 'simulation': <String, dynamic>{}}; // Map tipi ekledik
        }),
        // Yatırımcı verilerini çekmek için getFundHistorical'a benzer bir fonksiyon eklenebilir
        // Şimdilik sadece mevcut historical verileri kullanarak demo göstereceğiz
        _getInvestorHistoricalData(fundCode)
            .catchError((e) {
          _logger.warning('Error loading investor data for $fundCode: $e');
          return <Map<String, dynamic>>[];
        }),
      ]);

      if (!mounted) return;

      setState(() {
        // Her bir API yanıtı için tür dönüşümü 
        final Map<String, dynamic> historicalResponse = futures[0] as Map<String, dynamic>;
        if (historicalResponse['status'] != 'error') {
          _historicalData = _parseAndSortHistoricalData(
              (historicalResponse['historical'] as List<dynamic>?) ?? []);
          _logger.info('Loaded ${_historicalData.length} historical data points for $fundCode');
        } else {
          _historicalData = [];
          _logger.warning('Historical data load failed for $fundCode, using empty list.');
        }
        
        final Map<String, dynamic> riskResponse = futures[1] as Map<String, dynamic>;
        if (riskResponse['status'] == 'success' && riskResponse['metrics'] != null) {
            _riskMetrics = riskResponse['metrics'] as Map<String, dynamic>?;
            _logger.info('Loaded risk metrics for $fundCode: $_riskMetrics');
        } else {
            _logger.warning('Risk metrics load failed or metrics missing for $fundCode. API response: $riskResponse. Using default metrics.');
            _riskMetrics = FundApiService.getDefaultRiskMetrics();
            _error += '\nRisk verileri yüklenemedi.';
        }

        final Map<String, dynamic> monteCarloResponse = futures[2] as Map<String, dynamic>;
        if (monteCarloResponse['status'] != 'error') {
            _monteCarloResult = monteCarloResponse['simulation'] as Map<String, dynamic>?;
        } else {
            _monteCarloResult = null;
            _logger.warning('Monte Carlo data load failed for $fundCode.');
        }
        
        // Yatırımcı verileri için 3. future - Tür belirtmesi
        _investorData = futures[3] as List<Map<String, dynamic>>;
        _logger.info('Loaded ${_investorData.length} investor data points for $fundCode');

        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _logger.severe('Error loading fund data for ${widget.fund['kod']}: $e', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Veri yüklenirken hata oluştu: ${e.toString()}';
        _riskMetrics = FundApiService.getDefaultRiskMetrics();
      });
    }
  }

  // Yatırımcı verilerini çekmek için yardımcı fonksiyon
  // Bu gerçek API'ye bağlı olmadığı için örnek veriler üretir
  Future<List<Map<String, dynamic>>> _getInvestorHistoricalData(String fundCode) async {
    // Bu fonksiyon normalde bir API çağrısı yapar, ancak şimdi demo veriler üretiyoruz
    // Gerçek uygulamada, bu verileri API'den almalısınız
    
    // Önce fon detaylarından son yatırımcı sayısını alalım
    final currentInvestorCount = widget.fund['yatirimci_sayisi'];
    int lastInvestorCount = 0;
    
    if (currentInvestorCount != null) {
      try {
        if (currentInvestorCount is int) {
          lastInvestorCount = currentInvestorCount;
        } else if (currentInvestorCount is String) {
          lastInvestorCount = int.parse(currentInvestorCount.replaceAll(',', ''));
        } else {
          lastInvestorCount = 1000; // Varsayılan
        }
      } catch (e) {
        lastInvestorCount = 1000; // Hata durumunda varsayılan
      }
    } else {
      lastInvestorCount = 1000; // Veri yoksa varsayılan
    }
    
    // Şimdi, historical verilerine dayalı olarak, yatırımcı sayısı verilerini oluşturalım
    // Bu, gerçek bir uygulamada API'den gelmesi gereken verinin bir simülasyonudur
    List<Map<String, dynamic>> investorData = [];
    
    // Historical veri yoksa, boş döndür
    if (_historicalData.isEmpty) {
      return [];
    }
    
    // Historical verilerin tarih aralığını kullanarak yatırımcı verileri oluştur
    // Bu örnek için, basit bir rasgele artış/azalış trendi kullanıyoruz
    for (int i = 0; i < _historicalData.length; i++) {
      try {
        final dateStr = _historicalData[i]['date'];
        if (dateStr != null) {
          // Gerçekçi bir trend oluştur - her zaman artan değil, dalgalanan
          double randomFactor = 0.95 + (0.1 * i / _historicalData.length);
          int investorCount = (lastInvestorCount * randomFactor * (1 + (i * 0.005))).round();
          
          investorData.add({
            'date': dateStr,
            'investor_count': investorCount,
          });
        }
      } catch (e) {
        _logger.warning('Error generating investor data for date: $e');
      }
    }
    
    return investorData;
  }

  List<Map<String, dynamic>> _parseAndSortHistoricalData(
      List<dynamic> rawData) {
    final List<Map<String, dynamic>> parsedData = [];

    for (final item in rawData) {
      if (item is Map<String, dynamic>) {
        try {
          final dateStr = item['date']?.toString();
          final priceStr = item['price']?.toString();

          if (dateStr != null && priceStr != null) {
            // Parse date with better handling
            DateTime? date;
            try {
              date = DateTime.parse(dateStr);

              // Check if date is in the future (likely a parsing error)
              if (date.isAfter(DateTime.now())) {
                _logger.warning('Future date detected: $dateStr, skipping');
                continue;
              }
            } catch (e) {
              _logger.warning('Error parsing date: $dateStr');
              continue;
            }

            // Parse price
            double? price;
            if (priceStr.isNotEmpty) {
              price = double.tryParse(priceStr);
            }

            if (date != null && price != null && price > 0) {
              parsedData.add({
                'date': date.toIso8601String(),
                'price': price,
              });
            }
          }
        } catch (e) {
          _logger.warning('Error parsing historical data point: $e');
          continue;
        }
      }
    }

    // Sort by date in ascending order
    parsedData.sort((a, b) {
      final dateA = DateTime.parse(a['date']);
      final dateB = DateTime.parse(b['date']);
      return dateA.compareTo(dateB);
    });

    return parsedData;
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(),
        ],
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Performance Chart Section
                _buildPerformanceSection(),
                const SizedBox(height: 24),
                
                // Yatırımcı Sayısı Grafiği Section - YENİ
                _buildInvestorCountSection(),
                const SizedBox(height: 24),

                // Fund Summary Section (Fon Özeti)
                _buildQuickStats(),
                const SizedBox(height: 24),

                // Distribution Section (Portföy Dağılımı)
                _buildDistributionSection(),
                const SizedBox(height: 24),

                // Risk Metrics Section
                _buildRiskSection(),
                const SizedBox(height: 24),

                // General Fund Information Section
                _buildGeneralInfoSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final positiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;

    final fundCode = widget.fund['kod'] ?? '';
    final fundName = widget.fund['fon_adi'] ?? '';
    final dailyReturn = widget.fund['gunluk_getiri'] ?? '0%';
    final category = widget.fund['kategori'] ?? '';

    // Parse daily return
    final returnStr =
        dailyReturn.toString().replaceAll('%', '').replaceAll(',', '.');
    double returnValue = 0.0;
    try {
      returnValue = double.parse(returnStr);
    } catch (e) {
      returnValue = 0.0;
    }

    final isPositive = returnValue >= 0;
    final returnColor = isPositive ? positiveColor : negativeColor;

    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: textPrimary,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: accentColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: accentColor),
          onPressed: () {
            // Share functionality
          },
        ),
        IconButton(
          icon: Icon(Icons.favorite_border, color: accentColor),
          onPressed: () {
            // Add to favorites
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: themeExtension?.gradientBackgroundColors ??
                  [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fundCode,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: returnColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: returnColor, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: returnColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dailyReturn,
                          style: TextStyle(
                            color: returnColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                fundName,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performans',
          style: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTimeframeSelector(),
        const SizedBox(height: 16),
        if (_isLoading)
          _buildLoadingChart()
        else if (_error.isNotEmpty)
          _buildErrorCard()
        else if (_historicalData.isEmpty)
          _buildNoDataCard()
        else
          _buildPerformanceChart(),
        const SizedBox(height: 24),
        _buildPerformanceMetrics(),
      ],
    );
  }

  // YENİ: Yatırımcı Sayısı Grafik Bölümü
  Widget _buildInvestorCountSection() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yatırımcı Sayısı',
          style: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          _buildLoadingChart()
        else if (_investorData.isEmpty)
          _buildNoDataCard(title: 'Yatırımcı verisi mevcut değil')
        else
          _buildInvestorCountChart(),
      ],
    );
  }

  // Yatırımcı sayısı grafiği
  Widget _buildInvestorCountChart() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;

    return FuturisticCard(
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yatırımcı Sayısı Grafiği',
                  style: TextStyle(
                    color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline, color: accentColor, size: 20),
                  onPressed: () {
                    // İnfo butonu için işlev
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateInvestorSpots(),
                      isCurved: true,
                      color: accentColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: accentColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minY: _getMinInvestorCount() * 0.9,
                  maxY: _getMaxInvestorCount() * 1.1,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (_investorData.length / 5).roundToDouble().clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _investorData.length) {
                            return const Text('');
                          }

                          final dateString = _investorData[index]['date'];
                          if (dateString == null) return const Text('');
                          final date = DateTime.tryParse(dateString.toString());
                          if (date == null) return const Text('');

                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              _formatInvestorCount(value.toInt()),
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: textSecondary.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: textSecondary.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: cardColor.withOpacity(0.95),
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots
                          .map((spot) {
                            final index = spot.x.toInt();
                            if (index < 0 || index >= _investorData.length) {
                              return null;
                            }

                            final dateString = _investorData[index]['date'];
                            if (dateString == null) return null;
                            final date = DateTime.tryParse(dateString.toString());
                            if (date == null) return null;

                            return LineTooltipItem(
                              '${date.day}/${date.month}/${date.year}\n${_formatInvestorCount(spot.y.toInt())} yatırımcı',
                              TextStyle(
                                color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          })
                          .where((item) => item != null)
                          .toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'İlk: ${_investorData.isNotEmpty ? _formatInvestorCount(_investorData.first['investor_count']) : 'N/A'}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Son: ${_investorData.isNotEmpty ? _formatInvestorCount(_investorData.last['investor_count']) : 'N/A'}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Değişim: ${_calculateInvestorChangePercentage()}',
                  style: TextStyle(
                    color: _calculateInvestorChange() >= 0 
                      ? themeExtension?.positiveColor ?? AppTheme.positiveColor
                      : themeExtension?.negativeColor ?? AppTheme.negativeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Yatırımcı grafiği için yardımcı fonksiyonlar
  List<FlSpot> _generateInvestorSpots() {
    List<FlSpot> spots = [];
    
    for (int i = 0; i < _investorData.length; i++) {
      final investorCount = _investorData[i]['investor_count'] ?? 0;
      spots.add(FlSpot(i.toDouble(), investorCount.toDouble()));
    }
    
    return spots;
  }
  
  double _getMinInvestorCount() {
    if (_investorData.isEmpty) return 0;
    
    double min = double.infinity;
    for (var data in _investorData) {
      final count = data['investor_count']?.toDouble() ?? 0;
      if (count < min) min = count;
    }
    
    return min == double.infinity ? 0 : min;
  }
  
  double _getMaxInvestorCount() {
    if (_investorData.isEmpty) return 1000;
    
    double max = 0;
    for (var data in _investorData) {
      final count = data['investor_count']?.toDouble() ?? 0;
      if (count > max) max = count;
    }
    
    return max;
  }
  
  String _formatInvestorCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
  
  int _calculateInvestorChange() {
    if (_investorData.isEmpty || _investorData.length < 2) return 0;
    
    final firstCount = _investorData.first['investor_count'] ?? 0;
    final lastCount = _investorData.last['investor_count'] ?? 0;
    
    return lastCount - firstCount;
  }
  
  String _calculateInvestorChangePercentage() {
    if (_investorData.isEmpty || _investorData.length < 2) return '0%';
    
    final firstCount = _investorData.first['investor_count'] ?? 0;
    final lastCount = _investorData.last['investor_count'] ?? 0;
    
    if (firstCount == 0) return '0%';
    
    final change = lastCount - firstCount;
    final percentage = (change / firstCount) * 100;
    
    return '${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(2)}%';
  }

  Widget _buildTimeframeSelector() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;

    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timeframes.length,
        itemBuilder: (context, index) {
          final timeframe = _timeframes[index];
          final isSelected = timeframe == _selectedTimeframe;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeframe = timeframe;
              });
              _loadFundData();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? accentColor : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  timeframe,
                  style: TextStyle(
                    color: isSelected ? Colors.white : textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return FuturisticCard(
      child: FundChart(
        data: _historicalData,
        timeframe: _selectedTimeframe,
        fundCode: widget.fund['kod'] ?? '',
        height: 350,
        showTitle: true,
        showTimeline: true,
      ),
    );
  }

  Widget _buildLoadingChart() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: accentColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Performans verileri yükleniyor...',
            style: TextStyle(
              color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final negativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;

    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: negativeColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _error,
            style: TextStyle(
              color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadFundData,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard({String title = 'Bu zaman aralığı için veri mevcut değil'}) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    if (_historicalData.isEmpty) return const SizedBox.shrink();

    // Calculate basic performance metrics
    final firstPrice = _historicalData.first['price']?.toDouble() ?? 0.0;
    final lastPrice = _historicalData.last['price']?.toDouble() ?? 0.0;
    final returnValue = lastPrice - firstPrice;
    final returnPercent =
        firstPrice != 0 ? (returnValue / firstPrice) * 100 : 0.0;

    // Calculate volatility and other metrics
    final returns = <double>[];
    for (int i = 1; i < _historicalData.length; i++) {
      final currentPrice = _historicalData[i]['price']?.toDouble() ?? 0.0;
      final previousPrice = _historicalData[i - 1]['price']?.toDouble() ?? 0.0;
      if (previousPrice != 0) {
        returns.add((currentPrice - previousPrice) / previousPrice);
      }
    }

    final volatility = returns.isNotEmpty
        ? returns.map((r) => r * r).reduce((a, b) => a + b) / returns.length
        : 0.0;

    final maxPrice = _historicalData
        .map((d) => d['price']?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
    final minPrice = _historicalData
        .map((d) => d['price']?.toDouble() ?? 0.0)
        .reduce((a, b) => a < b ? a : b);

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performans Metrikleri',
            style: TextStyle(
              color: Theme.of(context)
                      .extension<AppThemeExtension>()
                      ?.textPrimary ??
                  AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildMetricCard(
                  'Toplam Getiri',
                  '${returnPercent.toStringAsFixed(2)}%',
                  returnPercent >= 0 ? Icons.trending_up : Icons.trending_down),
              _buildMetricCard(
                  'En Yüksek', _formatPrice(maxPrice), Icons.arrow_upward),
              _buildMetricCard(
                  'En Düşük', _formatPrice(minPrice), Icons.arrow_downward),
              _buildMetricCard(
                  'Volatilite',
                  '${(volatility * 100).toStringAsFixed(2)}%',
                  Icons.show_chart),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final fund = widget.fund;
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final cardColorLight =
        themeExtension?.cardColorLight ?? AppTheme.cardColorLight;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    final totalValue = fund['fon_toplam_deger'] ?? 0.0;
    final investorCount = fund['yatirimci_sayisi'] ?? 0;
    final marketShare = fund['pazar_payi'] ?? '0%';
    final categoryRank = fund['kategori_drecece'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fon Özeti',
          style: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: cardColor,
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  cardColorLight.withOpacity(0.1),
                  cardColorLight.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Toplam Değer',
                        _formatCurrency(totalValue),
                        Icons.account_balance,
                        accentColor,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 80,
                      color: textSecondary.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Yatırımcı',
                        _formatNumber(investorCount),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: textSecondary.withOpacity(0.2),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Pazar Payı',
                        marketShare,
                        Icons.pie_chart,
                        Colors.orange,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 80,
                      color: textSecondary.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Kategori Sırası',
                        categoryRank.isNotEmpty ? categoryRank : 'N/A',
                        Icons.emoji_events,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionSection() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final distributions =
        widget.fund['fund_distributions'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portföy Dağılımı',
          style: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (distributions != null && distributions.isNotEmpty)
          FundDistributionChart(distributions: distributions)
        else
          _buildNoDistributionCard(),
      ],
    );
  }

  Widget _buildRiskSection() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;

      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Analizi',
          style: TextStyle(
            color: Theme.of(context).extension<AppThemeExtension>()?.textPrimary ?? AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading && _riskMetrics == null) // _riskMetrics null ise yükleniyor göster
          _buildLoadingRiskMetrics()
        else if (_riskMetrics == null || _riskMetrics!.entries.where((e) => e.value != null).isEmpty) // Tamamen boşsa veya null ise
          _buildNoRiskDataCard()
        else ...[
          _buildRiskMetricsGrid(), // Bu fonksiyonu yeni metriklere göre güncelleyeceğiz
          const SizedBox(height: 24),
          if (_monteCarloResult != null) _buildMonteCarloSection(),
        ],
      ],
    );
  }

  Widget _buildGeneralInfoSection() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genel Bilgiler',
          style: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFundProfile(),
        const SizedBox(height: 24),
        _buildTefasStatus(),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRiskMetricsGrid() {
    final metricsToShow = <Map<String, dynamic>>[
      {'title': 'Yıllık Volatilite', 'key': 'volatility', 'suffix': '%', 'color': Colors.teal},
      {'title': 'Max Düşüş', 'key': 'maxDrawdown', 'suffix': '%', 'color': Colors.red},
      {'title': 'Yıllık Ortalama Getiri', 'key': 'annualizedAverageReturn', 'suffix': '%', 'color': Colors.blue},
      {'title': 'Calmar Oranı', 'key': 'calmarRatio', 'suffix': '', 'color': Colors.orange},
      {'title': 'Pozitif Gün %', 'key': 'positiveDaysPercent', 'suffix': '%', 'color': Colors.green},
      {'title': 'Negatif Gün %', 'key': 'negativeDaysPercent', 'suffix': '%', 'color': Colors.pink},
      {'title': 'En İyi Günlük Getiri', 'key': 'bestDailyReturn', 'suffix': '%', 'color': Colors.lightGreen},
      {'title': 'En Kötü Günlük Getiri', 'key': 'worstDailyReturn', 'suffix': '%', 'color': Colors.deepOrange},
      {'title': 'Çarpıklık (Skewness)', 'key': 'skewness', 'suffix': '', 'color': Colors.purple},
      {'title': 'Basıklık (Kurtosis)', 'key': 'excessKurtosis', 'suffix': '', 'color': Colors.brown},
      {'title': 'VaR %95 (1 Gün)', 'key': 'historicalVaR95_1day', 'suffix': '%', 'color': Colors.cyan},
      {'title': 'Risk Seviyesi', 'key': 'riskLevel', 'suffix': '', 'color': Colors.grey},
    ];

    // API'den gelen _riskMetrics içinde değeri null olmayanları filtrele
    final availableMetrics = metricsToShow.where((metricConfig) {
      return _riskMetrics![metricConfig['key']] != null;
    }).toList();

    if (availableMetrics.isEmpty) {
      return _buildNoRiskDataCard(); // Gösterilecek uygun metrik yoksa
    }
    
    // İkişerli gruplar halinde göster
    int crossAxisCount = 2;
    double childAspectRatio = 1.3; // Kartların en-boy oranını ayarla

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: availableMetrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final metricConfig = availableMetrics[index];
        final value = _riskMetrics![metricConfig['key']];
        return _buildRiskMetricCard(
          metricConfig['title'] as String,
          value, // Değeri olduğu gibi gönder, _buildRiskMetricCard içinde formatlanacak
          metricConfig['suffix'] as String,
          metricConfig['color'] as Color,
        );
      },
    );
  }

  Widget _buildRiskMetricCard(String title, dynamic value, String suffix, Color color) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    String displayValue = 'N/A';
    if (value != null) {
      if (value is double) {
        displayValue = value.toStringAsFixed(2) + suffix;
      } else if (value is int) {
        displayValue = value.toString() + suffix;
      } else {
        displayValue = value.toString() + suffix; // String ise veya bilinmeyen tip
      }
    }
    
    // "null%" gibi bir çıktı olmaması için kontrol
    if (value == null && suffix.isNotEmpty) {
        displayValue = 'N/A';
    }

    return Container(
      padding: const EdgeInsets.all(12), // İçeriye biraz padding ekleyelim
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, // Ortalamak için
        children: [
          Icon(Icons.analytics_outlined, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: textSecondary,
              fontSize: 11, // Başlık fontunu biraz küçülttük
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Başlık iki satıra sığabilir
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            displayValue,
            style: TextStyle(
              color: color, // Değerin rengini dinamik yapalım
              fontSize: 18, // Değer fontunu biraz büyüttük
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accentColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingRiskMetrics() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: List.generate(
          6,
          (index) => ShimmerLoading(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 16,
              )),
    );
  }

  Widget _buildNoRiskDataCard() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Risk verileri henüz yüklenmedi',
            style: TextStyle(
              color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonteCarloSection() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final positiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    final scenarios = _monteCarloResult!['scenarios'];
    final periods = _monteCarloResult!['periods'];

    List<FlSpot> optimisticSpots = [];
    List<FlSpot> expectedSpots = [];
    List<FlSpot> pessimisticSpots = [];

    for (int i = 0; i < periods; i++) {
      optimisticSpots
          .add(FlSpot(i.toDouble(), scenarios['optimistic'][i].toDouble()));
      expectedSpots
          .add(FlSpot(i.toDouble(), scenarios['expected'][i].toDouble()));
      pessimisticSpots
          .add(FlSpot(i.toDouble(), scenarios['pessimistic'][i].toDouble()));
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monte Carlo Simülasyonu',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_monteCarloResult!['simulations']} simülasyon, $periods aylık projeksiyon',
            style: TextStyle(
              color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 5,
                  verticalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: themeExtension?.textSecondary?.withOpacity(0.1) ??
                          Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: themeExtension?.textSecondary?.withOpacity(0.1) ??
                          Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: themeExtension?.textSecondary ??
                                AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}M',
                          style: TextStyle(
                            color: themeExtension?.textSecondary ??
                                AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: optimisticSpots,
                    isCurved: true,
                    color: positiveColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: positiveColor.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: expectedSpots,
                    isCurved: true,
                    color: accentColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: pessimisticSpots,
                    isCurved: true,
                    color: negativeColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: negativeColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScenarioItem('İyimser', positiveColor),
              _buildScenarioItem('Beklenen', accentColor),
              _buildScenarioItem('Kötümser', negativeColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color:
                Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
                    AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFundProfile() {
    final fund = widget.fund;
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    final profile = fund['fund_profile'] as Map<String, dynamic>?;

    if (profile == null || profile.isEmpty) {
      return const SizedBox.shrink();
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fon Bilgileri',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...profile.entries
              .where((entry) =>
                  entry.value != null && entry.value.toString().isNotEmpty)
              .map((entry) =>
                  _buildProfileItem(entry.key, entry.value.toString())),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String key, String value) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    // Format key name
    String formattedKey = key;
    if (key.contains('Kodu')) formattedKey = 'Kod';
    if (key.contains('Risk')) formattedKey = 'Risk Seviyesi';
    if (key.contains('Platform')) formattedKey = 'Platform Durumu';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              formattedKey,
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTefasStatus() {
    final fund = widget.fund;
    final tefas = fund['tefas'];

    if (tefas == null) return const SizedBox.shrink();

    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final positiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;

    final isOnTefas = tefas.toString().contains('işlem görüyor');
    final statusColor = isOnTefas ? positiveColor : negativeColor;
    final statusIcon = isOnTefas ? Icons.check_circle : Icons.cancel;

    return FuturisticCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEFAS Durumu',
                  style: TextStyle(
                    color:
                        themeExtension?.textSecondary ?? AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tefas.toString(),
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDistributionCard() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart,
            color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Dağılım bilgisi mevcut değil',
            style: TextStyle(
              color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null || value == 0) return '0 ₺';

    double val = 0.0;
    if (value is String) {
      try {
        val = double.parse(value.replaceAll(',', '.'));
      } catch (e) {
        return '0 ₺';
      }
    } else {
      val = value.toDouble();
    }

    if (val >= 1e9) {
      return '${(val / 1e9).toStringAsFixed(1)}B ₺';
    } else if (val >= 1e6) {
      return '${(val / 1e6).toStringAsFixed(1)}M ₺';
    } else if (val >= 1e3) {
      return '${(val / 1e3).toStringAsFixed(1)}K ₺';
    } else {
      return '${val.toStringAsFixed(0)} ₺';
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null || value == 0) return '0';

    int val = 0;
    if (value is String) {
      try {
        val = int.parse(value);
      } catch (e) {
        return '0';
      }
    } else {
      val = value.toInt();
    }

    if (val >= 1e6) {
      return '${(val / 1e6).toStringAsFixed(1)}M';
    } else if (val >= 1e3) {
      return '${(val / 1e3).toStringAsFixed(1)}K';
    } else {
      return val.toString();
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}k';
    } else if (price >= 100) {
      return price.toStringAsFixed(0);
    } else if (price >= 10) {
      return price.toStringAsFixed(1);
    } else {
      return price.toStringAsFixed(3);
    }
  }
}


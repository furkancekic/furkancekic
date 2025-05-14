// lib/screens/fund_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/fund.dart';
import '../services/fund_api_service.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';

class FundDetailScreen extends StatefulWidget {
  final String fundCode;

  const FundDetailScreen({
    Key? key,
    required this.fundCode,
  }) : super(key: key);

  @override
  State<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends State<FundDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AppLogger _logger;
  
  Fund? _fund;
  FundRiskMetrics? _riskMetrics;
  MonteCarloSimulation? _simulation;
  List<FundHistoricalPoint> _historicalData = [];
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedTimeframe = '1M';
  
  final List<String> _timeframes = ['1G', '1H', '1A', '3A', '6A', '1Y', 'Tümü'];

  @override
  void initState() {
    super.initState();
    _logger = AppLogger('FundDetailScreen');
    _tabController = TabController(length: 5, vsync: this);
    _loadFundData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFundData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Fon detayını getir
      final fund = await FundApiService.getFundDetail(widget.fundCode);
      
      // Paralel olarak diğer verileri getir
      final results = await Future.wait([
        FundApiService.getFundHistoricalData(widget.fundCode, _selectedTimeframe),
        FundApiService.getFundRiskMetrics(widget.fundCode).catchError((_) => null),
        FundApiService.getMonteCarloSimulation(widget.fundCode).catchError((_) => null),
      ]);

      if (mounted) {
        setState(() {
          _fund = fund;
          _historicalData = results[0] as List<FundHistoricalPoint>;
          _riskMetrics = results[1] as FundRiskMetrics?;
          _simulation = results[2] as MonteCarloSimulation?;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error loading fund data', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadHistoricalData(String timeframe) async {
    try {
      final data = await FundApiService.getFundHistoricalData(
        widget.fundCode, 
        timeframe
      );
      if (mounted) {
        setState(() {
          _historicalData = data;
          _selectedTimeframe = timeframe;
        });
      }
    } catch (e) {
      _logger.severe('Error loading historical data', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final bgGradientColors = themeExtension?.gradientBackgroundColors ?? [
      theme.scaffoldBackgroundColor,
      theme.scaffoldBackgroundColor,
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingContent()
                    : _hasError
                        ? _buildErrorContent()
                        : _buildMainContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fund?.kod ?? widget.fundCode,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                if (_fund != null)
                  Text(
                    _fund!.fonAdi,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.extension<AppThemeExtension>()?.textSecondary ?? AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Favori ekleme işlemi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favorilere eklendi')),
              );
            },
            icon: Icon(Icons.favorite_border, color: accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    final theme = Theme.of(context);
    final accentColor = theme.extension<AppThemeExtension>()?.accentColor ?? AppTheme.accentColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: accentColor),
          const SizedBox(height: 16),
          Text('Fon verileri yükleniyor...'),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Hata Oluştu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFundData,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Fund summary card
        _buildFundSummary(),
        
        // Tab bar
        _buildTabBar(),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildPerformanceTab(),
              _buildRiskTab(),
              _buildDistributionTab(),
              _buildSimulationTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFundSummary() {
    if (_fund == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final positiveColor = themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor = themeExtension?.negativeColor ?? AppTheme.negativeColor;
    
    final isPositive = _fund!.gunlukGetiriDouble >= 0;
    final changeColor = isPositive ? positiveColor : negativeColor;

    return Container(
      margin: const EdgeInsets.all(16),
      child: FuturisticCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_fund!.sonFiyat} TL',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: changeColor,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _fund!.gunlukGetiri,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fund!.kategori,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _fund!.isTefasActive 
                        ? positiveColor.withOpacity(0.2)
                        : textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _fund!.isTefasActive ? 'TEFAS' : 'Özel',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _fund!.isTefasActive ? positiveColor : textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: accentColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: accentColor,
        unselectedLabelColor: theme.extension<AppThemeExtension>()?.textSecondary ?? AppTheme.textSecondary,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Genel'),
          Tab(text: 'Performans'),
          Tab(text: 'Risk'),
          Tab(text: 'Dağılım'),
          Tab(text: 'Simülasyon'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_fund == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Genel Bilgiler', [
            _buildInfoRow('Fon Toplam Değeri', '${_formatCurrency(_fund!.fonToplamDeger)} TL'),
            _buildInfoRow('Yatırımcı Sayısı', _formatNumber(_fund!.yatirimciSayisi)),
            _buildInfoRow('Pazar Payı', _fund!.pazarPayi),
            _buildInfoRow('Pay Sayısı', _formatNumber(_fund!.pay)),
            _buildInfoRow('Kayıt Tarihi', _formatDate(_fund!.kayitTarihi)),
          ]),
          
          const SizedBox(height: 16),
          
          if (_fund!.fundProfile != null)
            _buildInfoCard('Fon Profili', [
              if (_fund!.fundProfile!.isınKodu != null)
                _buildInfoRow('ISIN Kodu', _fund!.fundProfile!.isınKodu!),
              if (_fund!.fundProfile!.fonunRiskDegeri != null)
                _buildInfoRow('Risk Değeri', _fund!.fundProfile!.fonunRiskDegeri!),
              if (_fund!.fundProfile!.platformİslemDurumu != null)
                _buildInfoRow('İşlem Durumu', _fund!.fundProfile!.platformİslemDurumu!),
            ]),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeframe selector
          _buildTimeframeSelector(),
          
          const SizedBox(height: 16),
          
          // Performance chart
          _buildPerformanceChart(),
        ],
      ),
    );
  }

  Widget _buildRiskTab() {
    if (_riskMetrics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Theme.of(context).extension<AppThemeExtension>()?.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text('Risk verileri yüklenemedi'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRiskMetricCard('Sharpe Ratio', _riskMetrics!.sharpeRatio, 
              'Risk başına getiri oranı'),
          _buildRiskMetricCard('Beta', _riskMetrics!.beta, 
              'Piyasa ile korelasyon'),
          _buildRiskMetricCard('Alpha', _riskMetrics!.alpha, 
              'Piyasa üstü getiri'),
          _buildRiskMetricCard('Volatilite', _riskMetrics!.volatility, 
              'Fiyat dalgalanması', suffix: '%'),
          _buildRiskMetricCard('Max Drawdown', _riskMetrics!.maxDrawdown, 
              'Maksimum düşüş', suffix: '%'),
          _buildRiskMetricCard('Std Deviation', _riskMetrics!.stdDev, 
              'Standart sapma', suffix: '%'),
        ],
      ),
    );
  }

  Widget _buildDistributionTab() {
    if (_fund?.fundDistributions == null || _fund!.fundDistributions!.isEmpty) {
      return const Center(
        child: Text('Dağılım verileri bulunamadı'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDistributionChart(),
          const SizedBox(height: 16),
          _buildDistributionList(),
        ],
      ),
    );
  }

  Widget _buildSimulationTab() {
    if (_simulation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Theme.of(context).extension<AppThemeExtension>()?.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text('Monte Carlo simülasyonu yüklenemedi'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSimulationChart(),
          const SizedBox(height: 16),
          _buildSimulationScenarios(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final cardColorLight = themeExtension?.cardColorLight ?? AppTheme.cardColorLight;

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timeframes.length,
        itemBuilder: (context, index) {
          final timeframe = _timeframes[index];
          final isSelected = timeframe == _selectedTimeframe;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(timeframe),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _loadHistoricalData(timeframe);
                }
              },
              selectedColor: accentColor.withOpacity(0.2),
              backgroundColor: cardColorLight,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceChart() {
    if (_historicalData.isEmpty) {
      return Container(
        height: 300,
        child: const Center(
          child: Text('Performans verileri bulunamadı'),
        ),
      );
    }

    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;

    // Chart verilerini hazırla
    final spots = _historicalData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.price);
    }).toList();

    return Container(
      height: 300,
      child: FuturisticCard(
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: null,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: textSecondary.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(2),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: accentColor,
                barWidth: 3,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: accentColor.withOpacity(0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: theme.extension<AppThemeExtension>()?.cardColor ?? AppTheme.cardColor,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    if (index < _historicalData.length) {
                      final point = _historicalData[index];
                      return LineTooltipItem(
                        '${point.price.toStringAsFixed(4)} TL\n${_formatDate(point.date)}',
                        TextStyle(
                          color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskMetricCard(String title, double value, String description, {String suffix = ''}) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FuturisticCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${value.toStringAsFixed(2)}$suffix',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart() {
    if (_fund?.fundDistributions == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    // Pie chart için verileri hazırla
    final sections = _fund!.fundDistributions!.entries.map((entry) {
      final colors = [
        accentColor,
        themeExtension?.positiveColor ?? AppTheme.positiveColor,
        themeExtension?.warningColor ?? AppTheme.warningColor,
        themeExtension?.negativeColor ?? AppTheme.negativeColor,
        Colors.purple,
        Colors.orange,
      ];
      
      final index = _fund!.fundDistributions!.keys.toList().indexOf(entry.key);
      final color = colors[index % colors.length];

      return PieChartSectionData(
        value: entry.value,
        title: '${entry.value.toStringAsFixed(1)}%',
        color: color,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      height: 300,
      child: FuturisticCard(
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 40,
            sectionsSpace: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDistributionList() {
    if (_fund?.fundDistributions == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    final colors = [
      accentColor,
      themeExtension?.positiveColor ?? AppTheme.positiveColor,
      themeExtension?.warningColor ?? AppTheme.warningColor,
      themeExtension?.negativeColor ?? AppTheme.negativeColor,
      Colors.purple,
      Colors.orange,
    ];

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portföy Dağılımı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._fund!.fundDistributions!.entries.map((entry) {
            final index = _fund!.fundDistributions!.keys.toList().indexOf(entry.key);
            final color = colors[index % colors.length];
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(color: textPrimary),
                    ),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSimulationChart() {
    if (_simulation == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final positiveColor = themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor = themeExtension?.negativeColor ?? AppTheme.negativeColor;

    final scenarios = _simulation!.scenarios;
    final data = <LineChartBarData>[];

    // Her senaryo için çizgi oluştur
    scenarios.forEach((scenario, values) {
      Color color;
      switch (scenario) {
        case 'pessimistic':
          color = negativeColor;
          break;
        case 'expected':
          color = accentColor;
          break;
        case 'optimistic':
          color = positiveColor;
          break;
        default:
          color = textSecondary;
      }

      final spots = values.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value);
      }).toList();

      data.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: scenario == 'expected',
            color: color.withOpacity(0.1),
          ),
        ),
      );
    });

    return Container(
      height: 300,
      child: FuturisticCard(
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
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
                    return Text(
                      '${value.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: data,
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationScenarios() {
    if (_simulation == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final positiveColor = themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor = themeExtension?.negativeColor ?? AppTheme.negativeColor;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    final scenarios = [
      ('pessimistic', 'Kötümser', negativeColor),
      ('below_average', 'Ortalamanın Altı', Colors.orange),
      ('expected', 'Beklenen', accentColor),
      ('above_average', 'Ortalamanın Üstü', Colors.blue),
      ('optimistic', 'İyimser', positiveColor),
    ];

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monte Carlo Senaryoları',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...scenarios.map((scenario) {
            final key = scenario.$1;
            final name = scenario.$2;
            final color = scenario.$3;
            final values = _simulation!.scenarios[key];
            
            if (values == null || values.isEmpty) return const SizedBox.shrink();
            
            final finalValue = values.last;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(color: textPrimary),
                    ),
                  ),
                  Text(
                    '${finalValue >= 0 ? '+' : ''}${finalValue.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: finalValue >= 0 ? positiveColor : negativeColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Utility methods
  String _formatCurrency(double value) {
    if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)} Milyar';
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)} Milyon';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)} Bin';
    }
    return value.toStringAsFixed(0);
  }

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}B';
    }
    return value.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
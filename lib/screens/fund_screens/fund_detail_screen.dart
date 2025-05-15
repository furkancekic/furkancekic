// lib/screens/fund_screens/fund_detail_screen.dart - Single page version
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/fund_widgets/fund_performance_chart.dart';
import '../../widgets/fund_widgets/fund_distribution_chart.dart';
import '../../widgets/fund_widgets/fund_loading_shimmer.dart';
import '../../services/fund_api_service.dart';

class FundDetailScreen extends StatefulWidget {
  final Map<String, dynamic> fund;

  const FundDetailScreen({Key? key, required this.fund}) : super(key: key);

  @override
  State<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends State<FundDetailScreen> {
  String _selectedTimeframe = '1M';
  List<Map<String, dynamic>> _historicalData = [];
  Map<String, dynamic>? _riskMetrics;
  Map<String, dynamic>? _monteCarloResult;
  bool _isLoading = false;

  final List<String> _timeframes = ['1W', '1M', '3M', '6M', '1Y', 'All'];

  @override
  void initState() {
    super.initState();
    _loadFundData();
  }

  Future<void> _loadFundData() async {
    setState(() => _isLoading = true);

    try {
      final fundCode = widget.fund['kod'];

      // Load historical data
      final historical = await FundApiService.getFundHistorical(
        fundCode,
        timeframe: _selectedTimeframe,
      );

      // Load risk metrics
      final riskMetrics = await FundApiService.getFundRiskMetrics(fundCode);

      // Load Monte Carlo simulation (optional)
      final monteCarloResult = await FundApiService.getMonteCarlo(
        fundCode,
        periods: 12,
        simulations: 1000,
      );

      setState(() {
        _historicalData = historical['historical'] ?? [];
        _riskMetrics = riskMetrics['metrics'];
        _monteCarloResult = monteCarloResult['simulation'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri yüklenirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(),
        ],
        body: _isLoading
            ? const FundDetailShimmer()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Quick Stats (Genel bakıştaki metrikler en üstte)
                    _buildQuickStats(),
                    const SizedBox(height: 24),

                    // 2. Performance Section (Grafik)
                    _buildPerformanceSection(),
                    const SizedBox(height: 24),

                    // 3. Distribution Section (Dağılım)
                    _buildDistributionSection(),
                    const SizedBox(height: 24),

                    // 4. Risk Section (Risk)
                    _buildRiskSection(),
                    const SizedBox(height: 24),

                    // 5. Overview Section (Genel Bakış - en altta)
                    _buildOverviewSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final positiveColor = themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor = themeExtension?.negativeColor ?? AppTheme.negativeColor;

    final fundCode = widget.fund['kod'] ?? '';
    final fundName = widget.fund['fon_adi'] ?? '';
    final dailyReturn = widget.fund['gunluk_getiri'] ?? '0%';
    final category = widget.fund['kategori'] ?? '';

    // Parse daily return
    final returnStr = dailyReturn.toString().replaceAll('%', '').replaceAll(',', '.');
    double returnValue = 0.0;
    try {
      returnValue = double.parse(returnStr);
    } catch (e) {
      returnValue = 0.0;
    }

    final isPositive = returnValue >= 0;
    final returnColor = isPositive ? positiveColor : negativeColor;

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: textPrimary,
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: accentColor),
          onPressed: () {
            // Share functionality
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          fundCode,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: themeExtension?.gradientBackgroundColors ?? [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: returnColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: returnColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dailyReturn,
                          style: TextStyle(
                            color: returnColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                fundName,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
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

  // GÜNCELLEME: Quick Stats en üste çıktı
  Widget _buildQuickStats() {
    final fund = widget.fund;
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final cardColorLight = themeExtension?.cardColorLight ?? AppTheme.cardColorLight;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColorLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Toplam Değer',
                  _formatCurrency(totalValue),
                  Icons.account_balance,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: textSecondary.withOpacity(0.2),
              ),
              Expanded(
                child: _buildStatCard(
                  'Yatırımcı',
                  _formatNumber(investorCount),
                  Icons.people,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: textSecondary.withOpacity(0.2),
              ),
              Expanded(
                child: _buildStatCard(
                  'Pazar Payı',
                  marketShare,
                  Icons.pie_chart,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: textSecondary.withOpacity(0.2),
              ),
              Expanded(
                child: _buildStatCard(
                  'Sıralama',
                  categoryRank,
                  Icons.emoji_events,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Column(
      children: [
        Icon(icon, color: accentColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Timeframe Selector
        Container(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _timeframes.length,
            itemBuilder: (context, index) {
              final timeframe = _timeframes[index];
              final isSelected = timeframe == _selectedTimeframe;
              final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
              final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTimeframe = timeframe;
                  });
                  _loadFundData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? accentColor : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    timeframe,
                    style: TextStyle(
                      color: isSelected ? Colors.white : textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Performance Chart
        FuturisticCard(
          child: FundPerformanceChart(
            data: _historicalData,
            timeframe: _selectedTimeframe,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionSection() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final distributions = widget.fund['fund_distributions'] as Map<String, dynamic>?;

    if (distributions == null || distributions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portföy Dağılımı',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          FuturisticCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Dağılım bilgisi mevcut değil',
                  style: TextStyle(
                    color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portföy Dağılımı',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        FuturisticCard(
          child: FundDistributionChart(distributions: distributions),
        ),
      ],
    );
  }

  Widget _buildRiskSection() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Analizi',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_riskMetrics != null) ...[
          // Risk Metrics Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildRiskMetricCard('Sharpe Oranı', _riskMetrics!['sharpeRatio']),
              _buildRiskMetricCard('Beta', _riskMetrics!['beta']),
              _buildRiskMetricCard('Alpha', _riskMetrics!['alpha']),
              _buildRiskMetricCard('R²', _riskMetrics!['rSquared']),
              _buildRiskMetricCard('Max Düşüş', _riskMetrics!['maxDrawdown']),
              _buildRiskMetricCard('Volatilite', _riskMetrics!['volatility']),
            ],
          ),
          const SizedBox(height: 24),
          // Monte Carlo Simulation
          if (_monteCarloResult != null) ...[
            FuturisticCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monte Carlo Simülasyonu',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMonteCarloChart(),
                ],
              ),
            ),
          ],
        ] else ...[
          FuturisticCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Risk verileri yükleniyor...',
                  style: TextStyle(color: textSecondary),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRiskMetricCard(String title, dynamic value) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    String displayValue = value?.toString() ?? '0';
    if (value is double) {
      displayValue = value.toStringAsFixed(2);
    }

    return FuturisticCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            displayValue,
            style: TextStyle(
              color: accentColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
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

  Widget _buildMonteCarloChart() {
    final scenarios = _monteCarloResult!['scenarios'];
    final periods = _monteCarloResult!['periods'];
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final positiveColor = themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor = themeExtension?.negativeColor ?? AppTheme.negativeColor;

    List<FlSpot> optimisticSpots = [];
    List<FlSpot> expectedSpots = [];
    List<FlSpot> pessimisticSpots = [];

    for (int i = 0; i < periods; i++) {
      optimisticSpots.add(FlSpot(i.toDouble(), scenarios['optimistic'][i].toDouble()));
      expectedSpots.add(FlSpot(i.toDouble(), scenarios['expected'][i].toDouble()));
      pessimisticSpots.add(FlSpot(i.toDouble(), scenarios['pessimistic'][i].toDouble()));
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}M',
                    style: TextStyle(
                      color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: optimisticSpots,
              isCurved: true,
              color: positiveColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final fund = widget.fund;
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genel Bakış',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Fund Profile
        FuturisticCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fon Bilgileri',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (fund['fund_profile'] != null) ...[
                ...(fund['fund_profile'] as Map<String, dynamic>)
                    .entries
                    .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
                    .map((entry) => _buildProfileItem(entry.key, entry.value.toString())),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // TEFAS Status
        if (fund['tefas'] != null)
          FuturisticCard(
            child: Row(
              children: [
                Icon(
                  fund['tefas'].toString().contains('işlem görüyor')
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: fund['tefas'].toString().contains('işlem görüyor')
                      ? themeExtension?.positiveColor ?? AppTheme.positiveColor
                      : themeExtension?.negativeColor ?? AppTheme.negativeColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fund['tefas'],
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProfileItem(String key, String value) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;

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
                fontWeight: FontWeight.w500,
              ),
            ),
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
}
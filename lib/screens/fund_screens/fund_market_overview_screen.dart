import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/fund_api_service.dart';

class FundMarketOverviewScreen extends StatefulWidget {
  const FundMarketOverviewScreen({Key? key}) : super(key: key);

  @override
  State<FundMarketOverviewScreen> createState() =>
      _FundMarketOverviewScreenState();
}

class _FundMarketOverviewScreenState extends State<FundMarketOverviewScreen> {
  Map<String, dynamic>? _marketData;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadMarketOverview();
  }

  Future<void> _loadMarketOverview() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final marketData = await FundApiService.getMarketOverview();
      print('Market data received: $marketData'); // Debug log

      setState(() {
        _marketData = marketData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading market data: $e'); // Debug log
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pazar Genel Bakış',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error,
                          color: themeExtension?.negativeColor ??
                              AppTheme.negativeColor,
                          size: 64),
                      const SizedBox(height: 16),
                      Text('Hata: $_error',
                          style: TextStyle(color: textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMarketOverview,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMarketOverview,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Debug widget - data kontrolü için
                        if (_marketData != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Debug: Loaded ${_marketData!.keys.length} keys',
                              style:
                                  TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ),

                        // Temel Pazar İstatistikleri
                        _buildMarketStats(),
                        const SizedBox(height: 24),

                        // Kategori Dağılımı
                        _buildCategoryDistribution(),
                        const SizedBox(height: 24),

                        // Performans Analizi
                        _buildPerformanceAnalysis(),
                        const SizedBox(height: 24),

                        // Risk Dağılımı
                        _buildRiskDistribution(),
                        const SizedBox(height: 24),

                        // TEFAS ve Pazar Payı Analizi
                        _buildTefasAndMarketShare(),
                        const SizedBox(height: 24),

                        // Kategori Performans Sıralaması
                        _buildCategoryPerformanceRanking(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMarketStats() {
    if (_marketData == null) return const SizedBox.shrink();

    final totalFunds = _marketData!['total_funds'] ?? 0;
    final totalMarketValue = _marketData!['total_market_value'] ?? 0.0;
    final totalInvestors = _marketData!['total_investors'] ?? 0;
    final averageReturn = _marketData!['average_return'] ?? 0.0;

    print(
        'Building market stats: $totalFunds funds, $totalMarketValue value'); // Debug

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pazar İstatistikleri',
          style: TextStyle(
            color:
                Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
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
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildStatCard(
              'Toplam Fon Sayısı',
              totalFunds.toString(),
              Icons.account_balance,
              Theme.of(context).extension<AppThemeExtension>()?.accentColor ??
                  AppTheme.accentColor,
            ),
            _buildStatCard(
              'Toplam Pazar Değeri',
              _formatCurrency(totalMarketValue),
              Icons.attach_money,
              Theme.of(context).extension<AppThemeExtension>()?.positiveColor ??
                  AppTheme.positiveColor,
            ),
            _buildStatCard(
              'Toplam Yatırımcı',
              _formatNumber(totalInvestors),
              Icons.people,
              Theme.of(context).extension<AppThemeExtension>()?.warningColor ??
                  AppTheme.warningColor,
            ),
            _buildStatCard(
              'Ortalama Getiri',
              '${averageReturn >= 0 ? '+' : ''}${averageReturn.toStringAsFixed(2)}%',
              averageReturn >= 0 ? Icons.trending_up : Icons.trending_down,
              averageReturn >= 0
                  ? (Theme.of(context)
                          .extension<AppThemeExtension>()
                          ?.positiveColor ??
                      AppTheme.positiveColor)
                  : (Theme.of(context)
                          .extension<AppThemeExtension>()
                          ?.negativeColor ??
                      AppTheme.negativeColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return FuturisticCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context)
                      .extension<AppThemeExtension>()
                      ?.textPrimary ??
                  AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context)
                      .extension<AppThemeExtension>()
                      ?.textSecondary ??
                  AppTheme.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    if (_marketData == null || _marketData!['category_distribution'] == null) {
      print('Category distribution data is null'); // Debug
      return _buildEmptySection(
          'Kategori Dağılımı', 'Kategori verileri mevcut değil');
    }

    final categories =
        _marketData!['category_distribution'] as Map<String, dynamic>;
    print('Category distribution: $categories'); // Debug

    if (categories.isEmpty) {
      return _buildEmptySection('Kategori Dağılımı', 'Kategori verileri boş');
    }

    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Dağılımı',
            style: TextStyle(
              color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: categories.values
                        .map((v) => (v as num).toDouble())
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor:
                        themeExtension?.cardColor ?? AppTheme.cardColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final category = categories.keys.elementAt(groupIndex);
                      return BarTooltipItem(
                        '$category\n${rod.toY.toInt()} fon',
                        TextStyle(
                          color: themeExtension?.textPrimary ??
                              AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < categories.length) {
                          final categoryName = categories.keys.elementAt(index);
                          final shortName = _getShortCategoryName(categoryName);
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 16,
                            child: Text(
                              shortName,
                              style: TextStyle(
                                color: themeExtension?.textSecondary ??
                                    AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: themeExtension?.textSecondary ??
                                AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _createBarGroups(categories),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: themeExtension?.textSecondary?.withOpacity(0.1) ??
                          Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalysis() {
    if (_marketData == null || _marketData!['performance_metrics'] == null) {
      print('Performance metrics data is null'); // Debug
      return _buildEmptySection(
          'Performans Analizi', 'Performans verileri mevcut değil');
    }

    final metrics = _marketData!['performance_metrics'] as Map<String, dynamic>;
    print('Performance metrics: $metrics'); // Debug

    final positiveReturns = metrics['positive_returns'] ?? 0;
    final negativeReturns = metrics['negative_returns'] ?? 0;
    final neutralReturns = metrics['neutral_returns'] ?? 0;
    final bestReturn = metrics['best_return'] ?? 0.0;
    final worstReturn = metrics['worst_return'] ?? 0.0;

    final totalReturns = positiveReturns + negativeReturns + neutralReturns;

    if (totalReturns == 0) {
      return _buildEmptySection(
          'Performans Analizi', 'Performans verileri hesaplanamadı');
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performans Analizi',
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
          Row(
            children: [
              // Performans dağılım grafiği
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Theme.of(context)
                                  .extension<AppThemeExtension>()
                                  ?.positiveColor ??
                              AppTheme.positiveColor,
                          value: positiveReturns.toDouble(),
                          title: totalReturns > 0
                              ? '${(positiveReturns / totalReturns * 100).toStringAsFixed(1)}%'
                              : '0%',
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Theme.of(context)
                                  .extension<AppThemeExtension>()
                                  ?.negativeColor ??
                              AppTheme.negativeColor,
                          value: negativeReturns.toDouble(),
                          title: totalReturns > 0
                              ? '${(negativeReturns / totalReturns * 100).toStringAsFixed(1)}%'
                              : '0%',
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Colors.grey,
                          value: neutralReturns.toDouble(),
                          title: totalReturns > 0
                              ? '${(neutralReturns / totalReturns * 100).toStringAsFixed(1)}%'
                              : '0%',
                          radius: 50,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ),
              // Performans metrikleri
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildPerformanceMetric(
                        'Pozitif Getiri',
                        positiveReturns,
                        Icons.trending_up,
                        Theme.of(context)
                                .extension<AppThemeExtension>()
                                ?.positiveColor ??
                            AppTheme.positiveColor),
                    const SizedBox(height: 12),
                    _buildPerformanceMetric(
                        'Negatif Getiri',
                        negativeReturns,
                        Icons.trending_down,
                        Theme.of(context)
                                .extension<AppThemeExtension>()
                                ?.negativeColor ??
                            AppTheme.negativeColor),
                    const SizedBox(height: 12),
                    _buildPerformanceMetric('Nötr', neutralReturns,
                        Icons.trending_flat, Colors.grey),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('En İyi',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                              .extension<AppThemeExtension>()
                                              ?.textSecondary ??
                                          AppTheme.textSecondary,
                                      fontSize: 12)),
                              Text('${bestReturn.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                              .extension<AppThemeExtension>()
                                              ?.positiveColor ??
                                          AppTheme.positiveColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text('En Kötü',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                              .extension<AppThemeExtension>()
                                              ?.textSecondary ??
                                          AppTheme.textSecondary,
                                      fontSize: 12)),
                              Text('${worstReturn.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                              .extension<AppThemeExtension>()
                                              ?.negativeColor ??
                                          AppTheme.negativeColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(
      String label, int value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: Theme.of(context)
                        .extension<AppThemeExtension>()
                        ?.textPrimary ??
                    AppTheme.textPrimary)),
        const Spacer(),
        Text(value.toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRiskDistribution() {
    if (_marketData == null || _marketData!['risk_distribution'] == null) {
      print('Risk distribution data is null'); // Debug
      return _buildEmptySection(
          'Risk Seviyesi Dağılımı', 'Risk verileri mevcut değil');
    }

    final risks = _marketData!['risk_distribution'] as Map<String, dynamic>;
    print('Risk distribution: $risks'); // Debug

    if (risks.isEmpty) {
      return _buildEmptySection('Risk Seviyesi Dağılımı', 'Risk verileri boş');
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Seviyesi Dağılımı',
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
          ...risks.entries.map((entry) {
            final total =
                risks.values.fold(0, (sum, val) => sum + (val as int));
            final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
            Color riskColor = Colors.grey;

            if (entry.key.contains('Düşük')) {
              riskColor = Theme.of(context)
                      .extension<AppThemeExtension>()
                      ?.positiveColor ??
                  AppTheme.positiveColor;
            } else if (entry.key.contains('Orta')) {
              riskColor = Theme.of(context)
                      .extension<AppThemeExtension>()
                      ?.warningColor ??
                  AppTheme.warningColor;
            } else if (entry.key.contains('Yüksek')) {
              riskColor = Theme.of(context)
                      .extension<AppThemeExtension>()
                      ?.negativeColor ??
                  AppTheme.negativeColor;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration:
                        BoxDecoration(color: riskColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(entry.key,
                          style: TextStyle(
                              color: Theme.of(context)
                                      .extension<AppThemeExtension>()
                                      ?.textPrimary ??
                                  AppTheme.textPrimary))),
                  Text('${entry.value} (${percentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                          color: riskColor, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTefasAndMarketShare() {
    if (_marketData == null) return const SizedBox.shrink();

    final tefas =
        _marketData!['tefas_distribution'] as Map<String, dynamic>? ?? {};
    final marketShare =
        _marketData!['market_share_distribution'] as Map<String, dynamic>? ??
            {};

    print('TEFAS distribution: $tefas'); // Debug
    print('Market share distribution: $marketShare'); // Debug

    return Row(
      children: [
        // TEFAS dağılımı
        Expanded(
          child: FuturisticCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEFAS Dağılımı',
                  style: TextStyle(
                    color: Theme.of(context)
                            .extension<AppThemeExtension>()
                            ?.textPrimary ??
                        AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (tefas.isEmpty)
                  Text('TEFAS verileri mevcut değil',
                      style: TextStyle(
                          color: Theme.of(context)
                                  .extension<AppThemeExtension>()
                                  ?.textSecondary ??
                              AppTheme.textSecondary))
                else
                  ...tefas.entries.map((entry) {
                    final color = entry.key.contains('İşlem Gören')
                        ? (Theme.of(context)
                                .extension<AppThemeExtension>()
                                ?.positiveColor ??
                            AppTheme.positiveColor)
                        : (Theme.of(context)
                                .extension<AppThemeExtension>()
                                ?.textSecondary ??
                            AppTheme.textSecondary);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            entry.key.contains('İşlem Gören')
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: color,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(entry.key,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                              .extension<AppThemeExtension>()
                                              ?.textPrimary ??
                                          AppTheme.textPrimary,
                                      fontSize: 12))),
                          Text(entry.value.toString(),
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Pazar payı dağılımı
        Expanded(
          child: FuturisticCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pazar Payı Dağılımı',
                  style: TextStyle(
                    color: Theme.of(context)
                            .extension<AppThemeExtension>()
                            ?.textPrimary ??
                        AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (marketShare.isEmpty)
                  Text('Pazar payı verileri mevcut değil',
                      style: TextStyle(
                          color: Theme.of(context)
                                  .extension<AppThemeExtension>()
                                  ?.textSecondary ??
                              AppTheme.textSecondary))
                else
                  ...marketShare.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(entry.key,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                              .extension<AppThemeExtension>()
                                              ?.textPrimary ??
                                          AppTheme.textPrimary,
                                      fontSize: 12))),
                          Text(entry.value.toString(),
                              style: TextStyle(
                                  color: Theme.of(context)
                                          .extension<AppThemeExtension>()
                                          ?.accentColor ??
                                      AppTheme.accentColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPerformanceRanking() {
    if (_marketData == null || _marketData!['category_performance'] == null) {
      print('Category performance data is null'); // Debug
      return _buildEmptySection('Kategori Performans Sıralaması',
          'Kategori performans verileri mevcut değil');
    }

    final categoryPerformance =
        _marketData!['category_performance'] as Map<String, dynamic>;
    final topCategories =
        _marketData!['top_performing_categories'] as List<dynamic>? ?? [];
    final bottomCategories =
        _marketData!['bottom_performing_categories'] as List<dynamic>? ?? [];

    print('Category performance: $categoryPerformance'); // Debug
    print('Top categories: $topCategories'); // Debug
    print('Bottom categories: $bottomCategories'); // Debug

    if (topCategories.isEmpty && bottomCategories.isEmpty) {
      return _buildEmptySection('Kategori Performans Sıralaması',
          'Performans sıralaması hesaplanamadı');
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Performans Sıralaması',
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
          if (topCategories.isNotEmpty) ...[
            Text(
              'En İyi Performans',
              style: TextStyle(
                color: Theme.of(context)
                        .extension<AppThemeExtension>()
                        ?.positiveColor ??
                    AppTheme.positiveColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...topCategories.take(3).map((cat) {
              final categoryName = cat[0];
              final performance = cat[1];
              final averageReturn = performance['average_return'];
              final fundCount = performance['fund_count'];

              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                          .extension<AppThemeExtension>()
                          ?.positiveColor
                          ?.withOpacity(0.1) ??
                      AppTheme.positiveColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up,
                        color: Theme.of(context)
                                .extension<AppThemeExtension>()
                                ?.positiveColor ??
                            AppTheme.positiveColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(categoryName,
                              style: TextStyle(
                                  color: Theme.of(context)
                                          .extension<AppThemeExtension>()
                                          ?.textPrimary ??
                                      AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600)),
                          Text('$fundCount fon',
                              style: TextStyle(
                                  color: Theme.of(context)
                                          .extension<AppThemeExtension>()
                                          ?.textSecondary ??
                                      AppTheme.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      '${averageReturn >= 0 ? '+' : ''}${averageReturn.toStringAsFixed(2)}%',
                      style: TextStyle(
                          color: Theme.of(context)
                                  .extension<AppThemeExtension>()
                                  ?.positiveColor ??
                              AppTheme.positiveColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
          if (bottomCategories.isNotEmpty) ...[
            Text(
              'En Kötü Performans',
              style: TextStyle(
                color: Theme.of(context)
                        .extension<AppThemeExtension>()
                        ?.negativeColor ??
                    AppTheme.negativeColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...bottomCategories.take(3).map((cat) {
              final categoryName = cat[0];
              final performance = cat[1];
              final averageReturn = performance['average_return'];
              final fundCount = performance['fund_count'];

              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                          .extension<AppThemeExtension>()
                          ?.negativeColor
                          ?.withOpacity(0.1) ??
                      AppTheme.negativeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_down,
                        color: Theme.of(context)
                                .extension<AppThemeExtension>()
                                ?.negativeColor ??
                            AppTheme.negativeColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(categoryName,
                              style: TextStyle(
                                  color: Theme.of(context)
                                          .extension<AppThemeExtension>()
                                          ?.textPrimary ??
                                      AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600)),
                          Text('$fundCount fon',
                              style: TextStyle(
                                  color: Theme.of(context)
                                          .extension<AppThemeExtension>()
                                          ?.textSecondary ??
                                      AppTheme.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      '${averageReturn >= 0 ? '+' : ''}${averageReturn.toStringAsFixed(2)}%',
                      style: TextStyle(
                          color: Theme.of(context)
                                  .extension<AppThemeExtension>()
                                  ?.negativeColor ??
                              AppTheme.negativeColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptySection(String title, String message) {
    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
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
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context)
                          .extension<AppThemeExtension>()
                          ?.textSecondary ??
                      AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups(Map<String, dynamic> categories) {
    final colors = [
      Theme.of(context).extension<AppThemeExtension>()?.accentColor ??
          AppTheme.accentColor,
      Theme.of(context).extension<AppThemeExtension>()?.positiveColor ??
          AppTheme.positiveColor,
      Theme.of(context).extension<AppThemeExtension>()?.warningColor ??
          AppTheme.warningColor,
      Theme.of(context).extension<AppThemeExtension>()?.primaryColor ??
          AppTheme.primaryColor,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
    ];

    return categories.entries.map((entry) {
      final index = categories.keys.toList().indexOf(entry.key);
      final color = colors[index % colors.length];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (entry.value as num).toDouble(),
            color: color,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();
  }

  String _getShortCategoryName(String category) {
    final mappings = {
      'Hisse Senedi Fonu': 'Hisse',
      'Serbest Fon': 'Serbest',
      'BES Emeklilik Fonu': 'BES',
      'Para Piyasası Fonu': 'Para P.',
      'Karma Fon': 'Karma',
      'Tahvil Fonu': 'Tahvil',
      'Altın Fonu': 'Altın',
      'Endeks Fonu': 'Endeks',
      'Yabancı Menkul Kıymet Fonu': 'Yabancı',
    };

    return mappings[category] ?? category.split(' ').first;
  }

  String _formatCurrency(double value) {
    if (value >= 1e12) {
      return '${(value / 1e12).toStringAsFixed(1)}T ₺';
    } else if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}B ₺';
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M ₺';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K ₺';
    } else {
      return '${value.toStringAsFixed(0)} ₺';
    }
  }

  String _formatNumber(int value) {
    if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      return value.toString();
    }
  }
}

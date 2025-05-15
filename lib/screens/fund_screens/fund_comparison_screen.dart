// lib/screens/fund_screens/fund_comparison_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/fund_api_service.dart';
import '../../models/fund.dart';

class FundComparisonScreen extends StatefulWidget {
  final List<String> fundCodes;

  const FundComparisonScreen({
    Key? key,
    required this.fundCodes,
  }) : super(key: key);

  @override
  State<FundComparisonScreen> createState() => _FundComparisonScreenState();
}

class _FundComparisonScreenState extends State<FundComparisonScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _comparisonData;
  Map<String, List<Map<String, dynamic>>> _historicalData = {};
  bool _isLoading = true;
  String _selectedTimeframe = '1Y';

  final List<String> _timeframes = ['1M', '3M', '6M', '1Y', 'All'];
  final List<String> _tabLabels = ['Performans', 'Metrikler', 'Dağılım'];

  // Comparison colors for different funds
  final List<Color> _comparisonColors = [
    const Color(0xFF6366F1), // Purple
    const Color(0xFF10B981), // Green
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Violet
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadComparisonData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadComparisonData() async {
    setState(() => _isLoading = true);

    try {
      // Load comparison data from API
      final comparisonData =
          await FundApiService.compareFunds(widget.fundCodes);

      // Load historical data for each fund
      final Map<String, List<Map<String, dynamic>>> historicalData = {};

      for (final fundCode in widget.fundCodes) {
        final historical = await FundApiService.getFundHistorical(
          fundCode,
          timeframe: _selectedTimeframe,
        );
        historicalData[fundCode] = historical['historical'] ?? [];
      }

      setState(() {
        _comparisonData = comparisonData;
        _historicalData = historicalData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Karşılaştırma verileri yüklenirken hata: $e')),
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
      appBar: AppBar(
        title: Text(
          'Fon Karşılaştırması',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFundList(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPerformanceTab(),
                      _buildMetricsTab(),
                      _buildDistributionTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFundList() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    final funds = _comparisonData?['funds'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Karşılaştırılan Fonlar',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.fundCodes.length,
              itemBuilder: (context, index) {
                final fundCode = widget.fundCodes[index];
                final color =
                    _comparisonColors[index % _comparisonColors.length];

                // Find fund details from comparison data
                Map<String, dynamic>? fundDetails;
                if (funds.isNotEmpty && index < funds.length) {
                  fundDetails = funds[index];
                }

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        fundCode,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (fundDetails != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          fundDetails['gunluk_getiri'] ?? '0%',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: accentColor,
        labelColor: accentColor,
        unselectedLabelColor: textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return Column(
      children: [
        // Timeframe Selector
        Container(
          height: 60,
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _timeframes.length,
            itemBuilder: (context, index) {
              final timeframe = _timeframes[index];
              final isSelected = timeframe == _selectedTimeframe;
              final themeExtension =
                  Theme.of(context).extension<AppThemeExtension>();
              final accentColor =
                  themeExtension?.accentColor ?? AppTheme.accentColor;
              final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
              final textPrimary =
                  themeExtension?.textPrimary ?? AppTheme.textPrimary;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTimeframe = timeframe;
                  });
                  _loadComparisonData();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Performance Chart
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FuturisticCard(
              child: _buildPerformanceChart(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceChart() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    if (_historicalData.isEmpty) {
      return Center(
        child: Text(
          'Performans verisi mevcut değil',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    // Create line chart data for each fund
    final List<LineChartBarData> lines = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < widget.fundCodes.length; i++) {
      final fundCode = widget.fundCodes[i];
      final color = _comparisonColors[i % _comparisonColors.length];
      final data = _historicalData[fundCode] ?? [];

      if (data.isEmpty) continue;

      final spots = <FlSpot>[];
      for (int j = 0; j < data.length; j++) {
        final price = data[j]['price']?.toDouble() ?? 0.0;
        spots.add(FlSpot(j.toDouble(), price));

        if (price < minY) minY = price;
        if (price > maxY) maxY = price;
      }

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    // Add padding to min/max values
    final range = maxY - minY;
    final padding = range * 0.1;
    minY = (minY - padding).clamp(0, double.infinity);
    maxY = maxY + padding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performans Karşılaştırması',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              lineBarsData: lines,
              minY: minY,
              maxY: maxY,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      // Use first fund's data for date labels
                      final firstFundData =
                          _historicalData[widget.fundCodes.first] ?? [];
                      final index = value.toInt();

                      if (index < 0 || index >= firstFundData.length) {
                        return const Text('');
                      }

                      final dateString = firstFundData[index]['date'];
                      if (dateString == null) return const Text('');
                      final date = DateTime.tryParse(dateString.toString());
                      if (date == null) return const Text('');

                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '${date.month}/${date.year.toString().substring(2)}',
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
                          _formatPrice(value),
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
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
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPerformanceLegend(),
      ],
    );
  }

  Widget _buildPerformanceLegend() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: widget.fundCodes.asMap().entries.map((entry) {
        final index = entry.key;
        final fundCode = entry.value;
        final color = _comparisonColors[index % _comparisonColors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              fundCode,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMetricsTab() {
    if (_comparisonData == null) {
      return const Center(child: Text('Metrik verisi mevcut değil'));
    }

    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    final metrics = _comparisonData!['metrics'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Daily Returns Comparison
          _buildMetricComparisonCard(
            'Günlük Getiriler',
            metrics['daily_returns'],
            Icons.trending_up,
            (value) => value['value'],
          ),
          const SizedBox(height: 16),

          // Market Share Comparison
          _buildMetricComparisonCard(
            'Pazar Payları',
            metrics['market_shares'],
            Icons.pie_chart,
            (value) => value['value'],
          ),
          const SizedBox(height: 16),

          // Total Value Comparison
          _buildMetricComparisonCard(
            'Toplam Değerler',
            metrics['total_values'],
            Icons.account_balance,
            (value) => _formatCurrency(value['value']),
          ),
          const SizedBox(height: 16),

          // Risk Levels Comparison
          _buildMetricComparisonCard(
            'Risk Seviyeleri',
            metrics['risk_levels'],
            Icons.warning,
            (value) => 'Seviye ${value['value']}',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricComparisonCard(
    String title,
    List<dynamic>? data,
    IconData icon,
    String Function(dynamic) formatter,
  ) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    if (data == null || data.isEmpty) {
      return Container();
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: themeExtension?.accentColor ?? AppTheme.accentColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final color = _comparisonColors[index % _comparisonColors.length];
            final fundCode = item['fund_code'];
            final value = formatter(item);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    fundCode,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
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

  Widget _buildDistributionTab() {
    final funds = _comparisonData?['funds'] as List<dynamic>? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: funds.length,
      itemBuilder: (context, index) {
        final fund = funds[index];
        final fundCode = fund['kod'];
        final color = _comparisonColors[index % _comparisonColors.length];
        final distributions =
            fund['fund_distributions'] as Map<String, dynamic>? ?? {};

        if (distributions.isEmpty) {
          return Container();
        }

        return Column(
          children: [
            FuturisticCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$fundCode Portföy Dağılımı',
                        style: TextStyle(
                          color: Theme.of(context)
                                  .extension<AppThemeExtension>()
                                  ?.textPrimary ??
                              AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...distributions.entries.map((entry) {
                    final assetName = entry.key;
                    final percentage = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              assetName,
                              style: TextStyle(
                                color: Theme.of(context)
                                        .extension<AppThemeExtension>()
                                        ?.textSecondary ??
                                    AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: color,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
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
}

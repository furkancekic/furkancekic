import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/fund_api_service.dart';
import '../../models/fund.dart';
import '../../widgets/fund_widgets/fund_card.dart';

class FundMarketOverviewScreen extends StatefulWidget {
  const FundMarketOverviewScreen({Key? key}) : super(key: key);

  @override
  State<FundMarketOverviewScreen> createState() => _FundMarketOverviewScreenState();
}

class _FundMarketOverviewScreenState extends State<FundMarketOverviewScreen> {
  Map<String, dynamic>? _marketData;
  List<Fund> _topFunds = [];
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
      final topFunds = await FundApiService.getTopPerformingFunds(limit: 10);

      setState(() {
        _marketData = marketData;
        _topFunds = topFunds;
        _isLoading = false;
      });
    } catch (e) {
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
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
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
                      Icon(Icons.error, color: themeExtension?.negativeColor ?? AppTheme.negativeColor, size: 64),
                      const SizedBox(height: 16),
                      Text(_error, style: TextStyle(color: textSecondary)),
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
                        // Market Statistics
                        _buildMarketStats(),
                        const SizedBox(height: 24),

                        // Category Distribution Chart
                        _buildCategoryChart(),
                        const SizedBox(height: 24),

                        // Top Performing Funds
                        _buildTopFunds(),
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
    final averageReturn = _marketData!['average_return'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pazar İstatistikleri',
          style: TextStyle(
            color: Theme.of(context).extension<AppThemeExtension>()?.textPrimary ?? AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Fon Sayısı',
                totalFunds.toString(),
                Icons.account_balance,
                Theme.of(context).extension<AppThemeExtension>()?.accentColor ?? AppTheme.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Toplam Pazar Değeri',
                _formatCurrency(totalMarketValue),
                Icons.attach_money,
                Theme.of(context).extension<AppThemeExtension>()?.positiveColor ?? AppTheme.positiveColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ortalama Getiri',
                '${averageReturn >= 0 ? '+' : ''}${averageReturn.toStringAsFixed(2)}%',
                averageReturn >= 0 ? Icons.trending_up : Icons.trending_down,
                averageReturn >= 0 
                    ? (Theme.of(context).extension<AppThemeExtension>()?.positiveColor ?? AppTheme.positiveColor)
                    : (Theme.of(context).extension<AppThemeExtension>()?.negativeColor ?? AppTheme.negativeColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Aktif Kategoriler',
                (_marketData!['categories'] as Map<String, dynamic>?)?.length.toString() ?? '0',
                Icons.category,
                Theme.of(context).extension<AppThemeExtension>()?.warningColor ?? AppTheme.warningColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return FuturisticCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).extension<AppThemeExtension>()?.textPrimary ?? AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).extension<AppThemeExtension>()?.textSecondary ?? AppTheme.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (_marketData == null || _marketData!['categories'] == null) {
      return const SizedBox.shrink();
    }

    final categories = _marketData!['categories'] as Map<String, dynamic>;
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
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: categories.values.map((v) => (v as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: themeExtension?.cardColor ?? AppTheme.cardColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final category = categories.keys.elementAt(groupIndex);
                      return BarTooltipItem(
                        '$category\n${rod.toY.toInt()} fon',
                        TextStyle(
                          color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                                color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
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
                            color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
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
                      color: themeExtension?.textSecondary?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
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

  List<BarChartGroupData> _createBarGroups(Map<String, dynamic> categories) {
    final colors = [
      Theme.of(context).extension<AppThemeExtension>()?.accentColor ?? AppTheme.accentColor,
      Theme.of(context).extension<AppThemeExtension>()?.positiveColor ?? AppTheme.positiveColor,
      Theme.of(context).extension<AppThemeExtension>()?.warningColor ?? AppTheme.warningColor,
      Theme.of(context).extension<AppThemeExtension>()?.primaryColor ?? AppTheme.primaryColor,
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

  Widget _buildTopFunds() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'En İyi Performans Gösteren Fonlar',
          style: TextStyle(
            color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _topFunds.length,
          itemBuilder: (context, index) {
            final fund = _topFunds[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FundCard(
                fund: fund.toJson(),
                onTap: () {
                  // Navigate to fund detail
                  Navigator.pushNamed(
                    context, 
                    '/fund_detail',
                    arguments: fund.toJson(),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
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
}
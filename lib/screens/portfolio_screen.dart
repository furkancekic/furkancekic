// Updated portfolio_screen.dart without pie charts, with benchmark comparison feature
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/portfolio.dart';
import '../services/portfolio_service.dart';
import 'portfolio_detail_screen.dart';
import 'add_portfolio_screen.dart';
import '../widgets/mini_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/logger.dart';
import 'benchmark_comparison_screen.dart'; // Import the new screen

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  bool _isLoading = true;
  List<Portfolio> _portfolios = [];
  String _selectedTimeframe = '1M'; // Default to 1 month view
  final List<String> _timeframes = ['1W', '1M', '3M', '6M', '1Y', 'All'];
  final _logger = AppLogger('PortfolioScreen');
  // Chart related fields
  List<PerformancePoint> _totalPerformanceData = [];
  List<PerformancePoint> _selectedPortfolioPerformanceData = [];
  String? _selectedPortfolioId; // null means showing total portfolio
  bool _isLoadingChart = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolios();
  }

  Future<void> _loadPortfolios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final portfolios = await PortfolioService.getPortfolios();
      setState(() {
        _portfolios = portfolios;
        _isLoading = false;
      });

      // Load performance data after portfolios
      _loadPerformanceData();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load portfolios: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  Future<void> _loadPerformanceData() async {
    setState(() {
      _isLoadingChart = true;
    });

    try {
      if (_selectedPortfolioId == null) {
        // Load total portfolio performance
        final totalPerformance = await _calculateTotalPortfolioPerformance();
        setState(() {
          _totalPerformanceData = totalPerformance;
          _selectedPortfolioPerformanceData = totalPerformance;
          _isLoadingChart = false;
        });
      } else {
        // Load specific portfolio performance
        final portfolioPerformance =
            await PortfolioService.getPortfolioPerformance(
          _selectedPortfolioId!,
          _selectedTimeframe,
        );
        setState(() {
          _selectedPortfolioPerformanceData = portfolioPerformance.data;
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingChart = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load performance data: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  Future<List<PerformancePoint>> _calculateTotalPortfolioPerformance() async {
    try {
      final performance = await PortfolioService.getTotalPortfoliosPerformance(
          _selectedTimeframe);
      return performance.data;
    } catch (e) {
      _logger.severe('Error calculating total portfolio performance: $e');

      // Fallback to local calculation if API fails
      final allPerformances = <DateTime, double>{};

      for (var portfolio in _portfolios) {
        if (portfolio.id != null) {
          final performance = await PortfolioService.getPortfolioPerformance(
            portfolio.id!,
            _selectedTimeframe,
          );

          for (var point in performance.data) {
            allPerformances.update(
              point.date,
              (value) => value + point.value,
              ifAbsent: () => point.value,
            );
          }
        }
      }

      // Convert to sorted list
      final totalPerformance = allPerformances.entries
          .map((e) => PerformancePoint(date: e.key, value: e.value))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return totalPerformance;
    }
  }

  void _navigateToAddPortfolio() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPortfolioScreen()),
    );

    if (result == true) {
      _loadPortfolios(); // Refresh portfolios
    }
  }

  void _navigateToPortfolioDetail(Portfolio portfolio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PortfolioDetailScreen(portfolio: portfolio),
      ),
    ).then((_) {
      _loadPortfolios(); // Refresh when returning
    });
  }
  
  void _navigateToBenchmarkComparison([Portfolio? portfolio]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BenchmarkComparisonScreen(portfolio: portfolio),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final accent = ext?.accentColor ?? AppTheme.accentColor;
    final cardColor = ext?.cardColor ?? AppTheme.cardColor;
    final textPrimary = ext?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = ext?.textSecondary ?? AppTheme.textSecondary;
    final positiveColor = ext?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor = ext?.negativeColor ?? AppTheme.negativeColor;

    if (_isLoadingChart) {
      return FuturisticCard(
        child: SizedBox(
          height: 300,
          child: Center(
            child: CircularProgressIndicator(color: accent),
          ),
        ),
      );
    }

    if (_selectedPortfolioPerformanceData.isEmpty) {
      return FuturisticCard(
        child: SizedBox(
          height: 300,
          child: Center(
            child: Text(
              'No performance data available',
              style: TextStyle(color: textSecondary),
            ),
          ),
        ),
      );
    }

    // Calculate performance metrics
    final firstValue = _selectedPortfolioPerformanceData.first.value;
    final lastValue = _selectedPortfolioPerformanceData.last.value;
    final change = lastValue - firstValue;
    final changePercent = firstValue > 0 ? (change / firstValue) * 100 : 0;
    final isPositive = change >= 0;

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Portfolio Performance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    // Benchmark Comparison Button
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to benchmark comparison with current selection
                        if (_selectedPortfolioId != null) {
                          final selectedPortfolio = _portfolios.firstWhere(
                            (p) => p.id == _selectedPortfolioId,
                            orElse: () => _portfolios.first,
                          );
                          _navigateToBenchmarkComparison(selectedPortfolio);
                        } else {
                          _navigateToBenchmarkComparison();
                        }
                      },
                      icon: Icon(Icons.compare_arrows, color: accent, size: 18),
                      label: Text(
                        'Compare to Benchmark',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Portfolio dropdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedPortfolioId,
                      isExpanded: true,
                      dropdownColor: cardColor,
                      icon: Icon(Icons.arrow_drop_down, color: accent),
                      style: TextStyle(color: textPrimary),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All Portfolios',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: _selectedPortfolioId == null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        ..._portfolios.map((portfolio) {
                          return DropdownMenuItem<String?>(
                            value: portfolio.id,
                            child: Text(
                              portfolio.name,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: _selectedPortfolioId == portfolio.id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedPortfolioId = value;
                        });
                        _loadPerformanceData();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Performance metrics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Value',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    Text(
                      '\$${lastValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Return ($_selectedTimeframe)',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isPositive ? positiveColor : negativeColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (lastValue - firstValue).abs() / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: textSecondary.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: _selectedPortfolioPerformanceData.length / 5,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >=
                                  _selectedPortfolioPerformanceData.length) {
                            return const SizedBox.shrink();
                          }

                          final date =
                              _selectedPortfolioPerformanceData[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _getDateLabel(date),
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
                        reservedSize: 60,
                        interval: (lastValue - firstValue).abs() / 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildChartSpots(),
                      isCurved: true,
                      color: isPositive ? positiveColor : negativeColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            (isPositive ? positiveColor : negativeColor)
                                .withOpacity(0.3),
                            (isPositive ? positiveColor : negativeColor)
                                .withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: cardColor.withOpacity(0.8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final date =
                              _selectedPortfolioPerformanceData[index].date;
                          final value = spot.y;

                          return LineTooltipItem(
                            '${_formatDate(date)}\n\$${value.toStringAsFixed(2)}',
                            const TextStyle(color: AppTheme.textPrimary),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<FlSpot> _buildChartSpots() {
    return _selectedPortfolioPerformanceData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  String _getDateLabel(DateTime date) {
    switch (_selectedTimeframe) {
      case '1W':
        return '${date.day}';
      case '1M':
      case '3M':
        return '${date.day}/${date.month}';
      case '6M':
      case '1Y':
        return '${date.month}/${date.year}';
      case 'All':
        return '${date.year}';
      default:
        return '${date.day}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // New widget to replace the asset allocation pie chart
  Widget _buildBenchmarkComparisonCard() {
    if (_portfolios.isEmpty) return const SizedBox.shrink();
    
    final accent = Theme.of(context).extension<AppThemeExtension>()?.accentColor ?? AppTheme.accentColor;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: FuturisticCard(
        onTap: () => _navigateToBenchmarkComparison(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Benchmark Comparison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Compare your portfolio performance against market indices',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Sample benchmark options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBenchmarkChip('S&P 500', accent),
                _buildBenchmarkChip('NASDAQ', Colors.purple),
                _buildBenchmarkChip('Bitcoin', Colors.orange),
                _buildBenchmarkChip('Gold', Colors.amber),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToBenchmarkComparison(),
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Compare Performance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBenchmarkChip(String name, Color color) {
    return Chip(
      label: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPortfolioSummary() {
    if (_portfolios.isEmpty) return const SizedBox.shrink();

    // Calculate total portfolio value
    double totalValue = 0;
    double totalGainLoss = 0;
    double totalInitialValue = 0;

    for (var portfolio in _portfolios) {
      if (portfolio.totalValue != null) {
        totalValue += portfolio.totalValue!;
      }
      if (portfolio.totalGainLoss != null) {
        totalGainLoss += portfolio.totalGainLoss!;
        totalInitialValue += portfolio.totalValue! - portfolio.totalGainLoss!;
      }
    }

    double totalGainLossPercent =
        totalInitialValue > 0 ? (totalGainLoss / totalInitialValue) * 100 : 0;

    final isPositive = totalGainLoss >= 0;
    final color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: FuturisticCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Portfolio Value',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${totalValue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}\$${totalGainLoss.toStringAsFixed(2)} (${isPositive ? '+' : ''}${totalGainLossPercent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'All time',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioCard(Portfolio portfolio) {
    final isPositive = portfolio.totalGainLossPercent != null &&
        portfolio.totalGainLossPercent! >= 0;
    final color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FuturisticCard(
        onTap: () => _navigateToPortfolioDetail(portfolio),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portfolio name and value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        portfolio.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (portfolio.description.isNotEmpty)
                        Text(
                          portfolio.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${portfolio.totalValue?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (portfolio.totalGainLossPercent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${portfolio.totalGainLossPercent!.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Portfolio mini chart (if available)
            if (portfolio.positions.any((p) =>
                p.performanceData != null && p.performanceData!.isNotEmpty))
              SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    // Draw charts for each position
                    ...portfolio.positions
                        .where((p) =>
                            p.performanceData != null &&
                            p.performanceData!.isNotEmpty)
                        .map((position) {
                      final isPositive = position.gainLossPercent != null &&
                          position.gainLossPercent! >= 0;
                      return Opacity(
                        opacity: 0.5, // Make semi-transparent for layering
                        child: MiniChart(
                          data: position.performanceData!,
                          isPositive: isPositive,
                          height: 60,
                          width: double.infinity,
                          showGradient: false, // Disable gradient for layering
                        ),
                      );
                    }),

                    // Position labels on the right
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        color: AppTheme.cardColor.withOpacity(0.8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${portfolio.positions.length} positions',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Button to compare with benchmarks
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _navigateToBenchmarkComparison(portfolio),
                  icon: Icon(
                    Icons.compare_arrows,
                    size: 16,
                    color: Theme.of(context).extension<AppThemeExtension>()?.accentColor ?? AppTheme.accentColor,
                  ),
                  label: Text(
                    'Compare to Benchmark',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).extension<AppThemeExtension>()?.accentColor ?? AppTheme.accentColor,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),

            // Last updated date
            Text(
              'Last updated: ${_formatUpdateDate(portfolio.updatedAt)}',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No portfolios found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to create your first portfolio',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddPortfolio,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Portfolio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatUpdateDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} mins ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final textPrim = ext?.textPrimary ?? AppTheme.textPrimary;
    final accent = ext?.accentColor ?? AppTheme.accentColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Portfolios',
          style: TextStyle(
            color: textPrim,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: accent),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: accent),
            onPressed: _navigateToAddPortfolio,
            tooltip: 'Add New Portfolio',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: accent),
            onPressed: _loadPortfolios,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFF192138),
            ],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: accent))
            : RefreshIndicator(
                onRefresh: _loadPortfolios,
                backgroundColor: ext?.cardColor ?? AppTheme.cardColor,
                color: accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeframe selector
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _timeframes.length,
                          itemBuilder: (context, index) {
                            final timeframe = _timeframes[index];
                            final isSelected = timeframe == _selectedTimeframe;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(timeframe),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedTimeframe = timeframe;
                                    });
                                    _loadPerformanceData(); // Reload chart data
                                  }
                                },
                                backgroundColor: ext?.cardColor ?? AppTheme.cardColor,
                                selectedColor: accent,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.black : textPrim,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                
                    // Main content - scrollable
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Portfolio Performance Chart
                          const SizedBox(height: 8),
                          _buildPerformanceChart(),
                          const SizedBox(height: 24),

                          // Portfolio Summary
                          if (!_isLoading && _portfolios.isNotEmpty)
                            _buildPortfolioSummary(),
                            
                          // Benchmark Comparison Card (replaces pie chart)
                          if (!_isLoading && _portfolios.isNotEmpty)
                            _buildBenchmarkComparisonCard(),

                          // Portfolios List
                          if (_isLoading)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: CircularProgressIndicator(color: accent),
                              ),
                            )
                          else if (_portfolios.isEmpty)
                            _buildEmptyState()
                          else
                            ..._portfolios
                                .map((portfolio) => _buildPortfolioCard(portfolio))
                                .toList(),

                          // Add some bottom padding
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
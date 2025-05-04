import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/portfolio_service.dart';
import '../utils/logger.dart';

class BenchmarkComparisonChart extends StatefulWidget {
  final List<PerformancePoint> portfolioData;
  final String timeframe;
  final String? selectedPortfolioId;
  final double portfolioStartValue;
  final double portfolioEndValue;

  const BenchmarkComparisonChart({
    Key? key,
    required this.portfolioData,
    required this.timeframe,
    this.selectedPortfolioId,
    required this.portfolioStartValue,
    required this.portfolioEndValue,
  }) : super(key: key);

  @override
  State<BenchmarkComparisonChart> createState() => _BenchmarkComparisonChartState();
}

class _BenchmarkComparisonChartState extends State<BenchmarkComparisonChart> {
  final _logger = AppLogger('BenchmarkComparisonChart');
  bool _isLoading = true;
  BenchmarkPerformanceData? _benchmarkData;
  String _selectedBenchmark = '^GSPC'; // Default to S&P 500
  final List<Map<String, String>> _availableBenchmarks = [
    {'ticker': '^GSPC', 'name': 'S&P 500'},
    {'ticker': '^IXIC', 'name': 'NASDAQ'},
    {'ticker': '^DJI', 'name': 'Dow Jones'},
    {'ticker': '^RUT', 'name': 'Russell 2000'},
    {'ticker': '^XU100', 'name': 'BIST 100'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBenchmarkData();
  }

  @override
  void didUpdateWidget(BenchmarkComparisonChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeframe != widget.timeframe || 
        oldWidget.selectedPortfolioId != widget.selectedPortfolioId) {
      _loadBenchmarkData();
    }
  }

  Future<void> _loadBenchmarkData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final benchmarkData = await PortfolioService.getBenchmarkPerformance(
        _selectedBenchmark,
        widget.timeframe,
      );

      setState(() {
        _benchmarkData = benchmarkData;
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading benchmark data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changeBenchmark(String ticker) {
    setState(() {
      _selectedBenchmark = ticker;
    });
    _loadBenchmarkData();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final accent = ext?.accentColor ?? AppTheme.accentColor;
    final cardColor = ext?.cardColor ?? AppTheme.cardColor;
    final textPrimary = ext?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = ext?.textSecondary ?? AppTheme.textSecondary;

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Benchmark Comparison',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    // Benchmark dropdown selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBenchmark,
                          isDense: true,
                          dropdownColor: cardColor,
                          icon: Icon(Icons.arrow_drop_down, color: accent, size: 16),
                          style: TextStyle(color: textPrimary, fontSize: 12),
                          items: _availableBenchmarks.map((benchmark) {
                            return DropdownMenuItem<String>(
                              value: benchmark['ticker'],
                              child: Text(
                                benchmark['name']!,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: _selectedBenchmark == benchmark['ticker']
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              _changeBenchmark(value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Performance comparison metrics
                if (_benchmarkData != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPerformanceComparisonMetric(
                        'Portfolio',
                        widget.portfolioEndValue,
                        _calculatePercentChange(
                          widget.portfolioStartValue,
                          widget.portfolioEndValue,
                        ),
                        accent,
                      ),
                      _buildPerformanceComparisonMetric(
                        _benchmarkData!.name,
                        _benchmarkData!.endValue,
                        _benchmarkData!.percentChange,
                        Colors.orange,
                      ),
                      _buildPerformanceComparisonMetric(
                        'Difference',
                        0, // Not applicable
                        _calculatePercentChange(
                              widget.portfolioStartValue,
                              widget.portfolioEndValue,
                            ) -
                            _benchmarkData!.percentChange,
                        null, // Will determine color based on value
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Chart showing portfolio vs benchmark
          if (_isLoading)
            SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: accent),
              ),
            )
          else if (_benchmarkData != null)
            SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildComparisonChart(
                  context,
                  widget.portfolioData,
                  _benchmarkData!.data,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Legend
          if (_benchmarkData != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(
                    'Portfolio',
                    accent,
                  ),
                  const SizedBox(width: 24),
                  _buildLegendItem(
                    _benchmarkData!.name,
                    Colors.orange,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
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
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceComparisonMetric(
    String label,
    double value,
    double percentChange,
    Color? color,
  ) {
    // Determine color based on value if not provided
    final displayColor = color ?? (percentChange >= 0
        ? AppTheme.positiveColor
        : AppTheme.negativeColor);
    
    final isPositive = percentChange >= 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        if (label != 'Difference')
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: displayColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
            style: TextStyle(
              color: displayColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper to calculate percent change
  double _calculatePercentChange(double startValue, double endValue) {
    if (startValue <= 0) return 0;
    return ((endValue - startValue) / startValue) * 100;
  }

  // Build the comparison chart
  Widget _buildComparisonChart(
    BuildContext context,
    List<PerformancePoint> portfolioData,
    List<PerformancePoint> benchmarkData,
  ) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final accent = ext?.accentColor ?? AppTheme.accentColor;
    final textSecondary = ext?.textSecondary ?? AppTheme.textSecondary;

    // Normalize the data to show percentage change rather than absolute value
    final normalizedPortfolioData = _normalizeData(portfolioData);
    final normalizedBenchmarkData = _normalizeData(benchmarkData);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5, // 5% intervals
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: textSecondary.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: normalizedPortfolioData.length / 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= portfolioData.length) {
                  return const SizedBox.shrink();
                }

                final date = portfolioData[index].date;
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
              reservedSize: 40,
              interval: 5, // 5% intervals
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)}%',
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
          // Portfolio line
          LineChartBarData(
            spots: _buildNormalizedSpots(normalizedPortfolioData),
            isCurved: true,
            color: accent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(0.3),
                  accent.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Benchmark line
          LineChartBarData(
            spots: _buildNormalizedSpots(normalizedBenchmarkData),
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.2),
                  Colors.orange.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppTheme.cardColor.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final isPortfolio = spot.barIndex == 0;
                final date = isPortfolio
                    ? portfolioData[index].date
                    : benchmarkData[index].date;
                final performance = spot.y;
                final dataSource = isPortfolio ? 'Portfolio' : _benchmarkData!.name;

                return LineTooltipItem(
                  '$dataSource\n${_formatDate(date)}\n${performance.toStringAsFixed(2)}%',
                  TextStyle(
                    color: isPortfolio ? accent : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // Helper to normalize data to percentage changes
  List<double> _normalizeData(List<PerformancePoint> data) {
    if (data.isEmpty) return [];
    
    final baseValue = data.first.value;
    return data.map((point) {
      if (baseValue <= 0) return 0.0;
      return ((point.value - baseValue) / baseValue) * 100;
    }).toList();
  }

  // Build chart spots from normalized data
  List<FlSpot> _buildNormalizedSpots(List<double> normalizedData) {
    return normalizedData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  String _getDateLabel(DateTime date) {
    switch (widget.timeframe) {
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
}
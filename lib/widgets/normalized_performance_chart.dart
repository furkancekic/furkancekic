// widgets/normalized_performance_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/portfolio_service.dart';

class NormalizedPerformanceChart extends StatefulWidget {
  final String? portfolioId; // null means show total performance
  final String timeframe;
  final double height;

  const NormalizedPerformanceChart({
    Key? key,
    this.portfolioId,
    required this.timeframe,
    this.height = 200,
  }) : super(key: key);

  @override
  State<NormalizedPerformanceChart> createState() => _NormalizedPerformanceChartState();
}

class _NormalizedPerformanceChartState extends State<NormalizedPerformanceChart> {
  bool _isLoading = true;
  List<PerformancePoint> _performanceData = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  @override
  void didUpdateWidget(NormalizedPerformanceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeframe != widget.timeframe || 
        oldWidget.portfolioId != widget.portfolioId) {
      _loadPerformanceData();
    }
  }

  Future<void> _loadPerformanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      PerformanceData performanceData;
      
      if (widget.portfolioId != null) {
        // Load individual portfolio normalized performance
        performanceData = await PortfolioService.getNormalizedPortfolioPerformance(
          widget.portfolioId!,
          widget.timeframe,
        );
      } else {
        // Load total normalized performance
        performanceData = await PortfolioService.getNormalizedTotalPortfoliosPerformance(
          widget.timeframe,
        );
      }

      if (mounted) {
        setState(() {
          _performanceData = performanceData.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load performance data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.negativeColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading chart',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_performanceData.isEmpty) {
      return Container(
        height: widget.height,
        child: Center(
          child: Text(
            'No performance data available',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with performance info
          _buildPerformanceHeader(),
          const SizedBox(height: 16),
          
          // Chart
          Expanded(child: _buildChart()),
          
          const SizedBox(height: 8),
          
          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildPerformanceHeader() {
    if (_performanceData.isEmpty) return const SizedBox.shrink();
    
    final firstValue = _performanceData.first.value;
    final lastValue = _performanceData.last.value;
    final totalReturn = lastValue - firstValue;
    final totalReturnPercent = totalReturn;
    
    final isPositive = totalReturn >= 0;
    final color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;
    final sign = isPositive ? '+' : '';

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Normalized Performance',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cash flow adjusted returns',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${lastValue.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$sign${totalReturnPercent.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart() {
    final spots = _performanceData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    final isPositive = spots.isNotEmpty && spots.last.y >= 100;
    final lineColor = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range > 10 ? range / 4 : 2.5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.textSecondary.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (spots.length / 4).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _performanceData.length) {
                  final date = _performanceData[index].date;
                  final month = date.month.toString().padLeft(2, '0');
                  final day = date.day.toString().padLeft(2, '0');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '$month/$day',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: range > 10 ? range / 4 : 2.5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3, // Changed from 2 to 3
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              // color: lineColor.withOpacity(0.1), // Old
              gradient: LinearGradient( // New gradient approach
                colors: [
                  lineColor.withOpacity(0.3),
                  lineColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData( // Added for tooltips
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppTheme.cardColor.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= _performanceData.length) {
                  return null;
                }
                final dataPoint = _performanceData[index];
                // Format date similar to PortfolioScreen's _formatDate if available, or use a simple one
                final String formattedDate = '${dataPoint.date.day}/${dataPoint.date.month}/${dataPoint.date.year}';
                return LineTooltipItem(
                  '$formattedDate\n${dataPoint.value.toStringAsFixed(1)}%',
                  const TextStyle(color: AppTheme.textPrimary, fontSize: 11), // Use AppTheme.textPrimary
                );
              }).toList();
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            // Add baseline at 100%
            HorizontalLine(
              y: 100,
              color: AppTheme.textSecondary.withOpacity(0.3),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 2,
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '100% = Break Even',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 12,
          height: 2,
          decoration: BoxDecoration(
            color: _performanceData.isNotEmpty && _performanceData.last.value >= 100
                ? AppTheme.positiveColor
                : AppTheme.negativeColor,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Portfolio Return',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
// widgets/switchable_performance_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/portfolio_service.dart';

class SwitchablePerformanceChart extends StatefulWidget {
  final String? portfolioId; // null means show total performance
  final String timeframe;
  final double height;

  const SwitchablePerformanceChart({
    Key? key,
    this.portfolioId,
    required this.timeframe,
    this.height = 300,
  }) : super(key: key);

  @override
  State<SwitchablePerformanceChart> createState() => _SwitchablePerformanceChartState();
}

class _SwitchablePerformanceChartState extends State<SwitchablePerformanceChart> with TickerProviderStateMixin {
  bool _isNormalizedView = false; // false = dollar view, true = normalized view
  bool _isLoading = true;
  
  // Data for both views
  List<PerformancePoint> _dollarPerformanceData = [];
  List<PerformancePoint> _normalizedPerformanceData = [];
  String _errorMessage = '';
  
  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadPerformanceData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SwitchablePerformanceChart oldWidget) {
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
      // Load both dollar and normalized performance data in parallel
      final futures = await Future.wait([
        _loadDollarPerformance(),
        _loadNormalizedPerformance(),
      ]);

      if (mounted) {
        setState(() {
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

  Future<PerformanceData> _loadDollarPerformance() async {
    PerformanceData performanceData;
    
    if (widget.portfolioId != null) {
      performanceData = await PortfolioService.getPortfolioPerformance(
        widget.portfolioId!,
        widget.timeframe,
      );
    } else {
      performanceData = await PortfolioService.getTotalPortfoliosPerformance(
        widget.timeframe,
      );
    }
    
    _dollarPerformanceData = performanceData.data;
    return performanceData;
  }

  Future<PerformanceData> _loadNormalizedPerformance() async {
    PerformanceData performanceData;
    
    if (widget.portfolioId != null) {
      performanceData = await PortfolioService.getNormalizedPortfolioPerformance(
        widget.portfolioId!,
        widget.timeframe,
      );
    } else {
      performanceData = await PortfolioService.getNormalizedTotalPortfoliosPerformance(
        widget.timeframe,
      );
    }
    
    _normalizedPerformanceData = performanceData.data;
    return performanceData;
  }

  void _toggleView() {
    setState(() {
      _isNormalizedView = !_isNormalizedView;
    });
    
    if (_isNormalizedView) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  List<PerformancePoint> get _currentData => 
      _isNormalizedView ? _normalizedPerformanceData : _dollarPerformanceData;

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

    return Container(
      height: widget.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with performance info and toggle
          _buildHeader(),
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

  Widget _buildHeader() {
    final currentData = _currentData;
    if (currentData.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: [
        Expanded(
          child: _buildPerformanceInfo(),
        ),
        _buildViewToggle(),
      ],
    );
  }

  Widget _buildPerformanceInfo() {
    final currentData = _currentData;
    if (currentData.isEmpty) return const SizedBox.shrink();
    
    final firstValue = currentData.first.value;
    final lastValue = currentData.last.value;
    
    if (_isNormalizedView) {
      // Normalized view - show percentage (convert from 100 baseline to 0 baseline)
      final totalReturn = lastValue - 100; // Convert 117% to 17%
      final isPositive = totalReturn >= 0;
      final color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;
      final sign = isPositive ? '+' : '';

      return Column(
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
          Row(
            children: [
              Text(
                '$sign${totalReturn.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${lastValue.toStringAsFixed(1)}% total)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            'Cash flow adjusted returns',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      );
    } else {
      // Dollar view - show dollar amounts
      final totalReturn = lastValue - firstValue;
      final isPositive = totalReturn >= 0;
      final color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;
      final sign = isPositive ? '+' : '';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Value',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '\$${_formatCurrency(lastValue)}',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($sign\$${_formatCurrency(totalReturn.abs())})',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            'Total portfolio value over time',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: '\$',
            isActive: !_isNormalizedView,
            tooltip: 'Dollar Value View',
            onTap: () {
              if (_isNormalizedView) _toggleView();
            },
          ),
          _buildToggleButton(
            label: '%',
            isActive: _isNormalizedView,
            tooltip: 'Normalized Performance View',
            onTap: () {
              if (!_isNormalizedView) _toggleView();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : AppTheme.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    final currentData = _currentData;
    if (currentData.isEmpty) {
      return Center(
        child: Text(
          'No performance data available',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    final spots = currentData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    // Determine line color based on performance
    Color lineColor;
    if (_isNormalizedView) {
      lineColor = spots.isNotEmpty && spots.last.y >= 100 
          ? AppTheme.positiveColor 
          : AppTheme.negativeColor;
    } else {
      lineColor = spots.length > 1 && spots.last.y >= spots.first.y
          ? AppTheme.positiveColor 
          : AppTheme.negativeColor;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _calculateHorizontalInterval(range),
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
                    if (index >= 0 && index < currentData.length) {
                      final date = currentData[index].date;
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
                  reservedSize: 50,
                  interval: _calculateHorizontalInterval(range),
                  getTitlesWidget: (value, meta) {
                    if (_isNormalizedView) {
                      // Convert from 100 baseline to 0 baseline for display
                      final displayValue = value - 100;
                      return Text(
                        '${displayValue >= 0 ? '+' : ''}${displayValue.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    } else {
                      return Text(
                        '\$${_formatCurrencyCompact(value)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    }
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
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: lineColor.withOpacity(0.1),
                ),
              ),
            ],
            extraLinesData: _isNormalizedView ? ExtraLinesData(
              horizontalLines: [
                // Add baseline at 100% for normalized view
                HorizontalLine(
                  y: 100,
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ],
            ) : null,
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    if (_isNormalizedView) {
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
            '0% = Break Even',
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
              color: _currentData.isNotEmpty && _currentData.last.value >= 100
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
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 2,
            decoration: BoxDecoration(
              color: _currentData.length > 1 && _currentData.last.value >= _currentData.first.value
                  ? AppTheme.positiveColor
                  : AppTheme.negativeColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Portfolio Value Over Time',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      );
    }
  }

  double _calculateHorizontalInterval(double range) {
    if (range > 100) return range / 4;
    if (range > 50) return range / 5;
    if (range > 20) return range / 4;
    if (range > 10) return range / 5;
    return range / 4;
  }

  String _formatCurrency(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  String _formatCurrencyCompact(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}
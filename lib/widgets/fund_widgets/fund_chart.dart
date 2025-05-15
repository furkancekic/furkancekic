import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
// Import math library at the top of the file
import 'dart:math' as math;
class FundChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String timeframe;
  final String fundCode;
  final double? height;
  final bool showTitle;
  final bool showTimeline;

  const FundChart({
    Key? key,
    required this.data,
    required this.timeframe,
    required this.fundCode,
    this.height,
    this.showTitle = true,
    this.showTimeline = true,
  }) : super(key: key);

  @override
  State<FundChart> createState() => _FundChartState();
}

class _FundChartState extends State<FundChart> {
  int touchedIndex = -1;
  bool showAvg = false;

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final positiveColor = themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor = themeExtension?.negativeColor ?? AppTheme.negativeColor;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    if (widget.data.isEmpty) {
      return Container(
        height: widget.height ?? 250,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Veri mevcut değil',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Convert data to chart spots
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < widget.data.length; i++) {
      final price = widget.data[i]['price']?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), price));

      if (price < minY) minY = price;
      if (price > maxY) maxY = price;
    }

    // Determine line color based on performance
    Color lineColor = accentColor;
    if (spots.isNotEmpty && spots.length > 1) {
      final firstPrice = spots.first.y;
      final lastPrice = spots.last.y;
      lineColor = lastPrice >= firstPrice ? positiveColor : negativeColor;
    }

    // Add padding to min/max values
    final range = maxY - minY;
    final padding = range * 0.1;
    minY = (minY - padding).clamp(0, double.infinity);
    maxY = maxY + padding;

    // Calculate average if needed
    double averageY = 0;
    if (showAvg && spots.isNotEmpty) {
      averageY = spots.map((spot) => spot.y).reduce((a, b) => a + b) / spots.length;
    }

    return Container(
      height: widget.height ?? 350,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and controls
          if (widget.showTitle) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.fundCode} - ${_getChartTitle()}',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Average line toggle
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          showAvg = !showAvg;
                        });
                      },
                      icon: Icon(
                        showAvg ? Icons.remove : Icons.add,
                        size: 16,
                        color: accentColor,
                      ),
                      label: Text(
                        'Ortalama',
                        style: TextStyle(
                          color: showAvg ? accentColor : textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  // Main price line
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        lineColor,
                        lineColor.withOpacity(0.5),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          lineColor.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Average line
                  if (showAvg)
                    LineChartBarData(
                      spots: [
                        FlSpot(0, averageY),
                        FlSpot(spots.length - 1.0, averageY),
                      ],
                      isCurved: false,
                      color: accentColor.withOpacity(0.8),
                      barWidth: 2,
                      isDashed: true,
                      dotData: FlDotData(show: false),
                    ),
                ],
                minY: minY,
                maxY: maxY,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: widget.showTimeline,
                      reservedSize: 30,
                      interval: _getBottomInterval(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.data.length) {
                          return const Text('');
                        }

                        final date = DateTime.parse(widget.data[index]['date']);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            _formatDate(date),
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
                      interval: (maxY - minY) / 5,
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
                  horizontalInterval: (maxY - minY) / 5,
                  verticalInterval: widget.data.length / 5,
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
                  enabled: true,
                  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          touchResponse == null ||
                          touchResponse.lineBarSpots == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = touchResponse.lineBarSpots!.first.spotIndex;
                    });
                  },
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: cardColor.withOpacity(0.95),
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= widget.data.length) {
                          return null;
                        }

                        final date = DateTime.parse(widget.data[index]['date']);
                        final price = spot.y;

                        return LineTooltipItem(
                          '${_formatDate(date)}\n${_formatPrice(price)}',
                          TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: lineColor.withOpacity(0.8),
                          strokeWidth: 2,
                          dashArray: [3, 3],
                        ),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                            radius: 6,
                            color: lineColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: showAvg
                      ? [
                          HorizontalLine(
                            y: averageY,
                            color: accentColor.withOpacity(0.6),
                            strokeWidth: 2,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              labelResolver: (line) => 'Ort: ${_formatPrice(line.y)}',
                            ),
                          ),
                        ]
                      : [],
                ),
              ),
            ),
          ),

          // Performance summary
          const SizedBox(height: 16),
          _buildPerformanceStats(spots, lineColor, textPrimary, textSecondary),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats(List<FlSpot> spots, Color lineColor, Color textPrimary, Color textSecondary) {
    if (spots.isEmpty) return const SizedBox.shrink();

    final firstPrice = spots.first.y;
    final lastPrice = spots.last.y;
    final returnValue = lastPrice - firstPrice;
    final returnPercent = (returnValue / firstPrice) * 100;
    final isPositive = returnValue >= 0;

    // Calculate additional metrics
    final maxPrice = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final minPrice = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final volatility = _calculateVolatility(spots);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppThemeExtension>()?.cardColorLight ?? AppTheme.cardColorLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Başlangıç',
                _formatPrice(firstPrice),
                textSecondary,
                textPrimary,
              ),
              _buildStatItem(
                'Güncel',
                _formatPrice(lastPrice),
                textSecondary,
                textPrimary,
              ),
              _buildStatItem(
                'Değişim',
                '${isPositive ? '+' : ''}${returnPercent.toStringAsFixed(2)}%',
                textSecondary,
                lineColor,
                icon: isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'En Yüksek',
                _formatPrice(maxPrice),
                textSecondary,
                textPrimary,
              ),
              _buildStatItem(
                'En Düşük',
                _formatPrice(minPrice),
                textSecondary,
                textPrimary,
              ),
              _buildStatItem(
                'Volatilite',
                '${volatility.toStringAsFixed(2)}%',
                textSecondary,
                textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color labelColor, Color valueColor, {IconData? icon}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: valueColor, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateVolatility(List<FlSpot> spots) {
    if (spots.length < 2) return 0.0;

    final returns = <double>[];
    for (int i = 1; i < spots.length; i++) {
      final dailyReturn = (spots[i].y - spots[i - 1].y) / spots[i - 1].y;
      returns.add(dailyReturn);
    }

    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) / returns.length;
    final stdDev = variance < 0 ? 0 : variance.sqrt();

    return stdDev * 100; // Convert to percentage
  }

  String _getChartTitle() {
    switch (widget.timeframe) {
      case '1W':
        return 'Son 1 Hafta';
      case '1M':
        return 'Son 1 Ay';
      case '3M':
        return 'Son 3 Ay';
      case '6M':
        return 'Son 6 Ay';
      case '1Y':
        return 'Son 1 Yıl';
      case 'All':
        return 'Tüm Zaman';
      default:
        return 'Performans';
    }
  }

  double _getBottomInterval() {
    if (widget.data.length <= 7) return 1;
    if (widget.data.length <= 30) return 7;
    if (widget.data.length <= 90) return 15;
    return 30;
  }

  String _formatDate(DateTime date) {
    switch (widget.timeframe) {
      case '1W':
      case '1M':
        return '${date.day}/${date.month}';
      case '3M':
      case '6M':
        return '${date.day}/${date.month}';
      case '1Y':
      case 'All':
        return '${date.month}/${date.year.toString().substring(2)}';
      default:
        return '${date.day}/${date.month}';
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

  extension MathExt on double {
    double sqrt() => math.sqrt(this);
  }
}


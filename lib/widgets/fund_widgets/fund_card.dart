// lib/widgets/fund_widgets/fund_chart.dart - Geliştirilmiş versiyon
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../common_widgets.dart';
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

class _FundChartState extends State<FundChart>
    with SingleTickerProviderStateMixin {
  int? touchedIndex;
  bool showAvg = false;
  late AnimationController _animationController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final positiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final cardColorLight =
        themeExtension?.cardColorLight ?? AppTheme.cardColorLight;

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
    final padding = range == 0 ? (maxY * 0.1).abs() : (range * 0.1).abs();
    minY = (minY - padding).clamp(0.0, double.infinity);
    maxY = maxY + padding;

    if (minY == maxY) {
      maxY = minY + (minY * 0.2).abs() + 1.0;
      if (minY == 0 && maxY == 1.0) {
        minY = 0;
        maxY = 1.0;
      } else if (minY == 0 && maxY == 0) {
        maxY = 1.0;
      }
    }

    // Calculate average if needed
    double averageY = 0;
    if (showAvg && spots.isNotEmpty) {
      averageY =
          spots.map((spot) => spot.y).reduce((a, b) => a + b) / spots.length;
    }

    return Container(
      height: widget.height ?? 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            cardColor,
            cardColorLight.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and controls
            if (widget.showTitle) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.fundCode} - ${_getChartTitle()}',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.data.length} veri noktası',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Average line toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            showAvg = !showAvg;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: showAvg ? accentColor : cardColorLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.show_chart,
                                size: 16,
                                color: showAvg ? Colors.white : textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ortalama',
                                style: TextStyle(
                                  color: showAvg ? Colors.white : textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
              child: AnimatedBuilder(
                animation: _chartAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _chartAnimation.value,
                    child: Opacity(
                      opacity: _chartAnimation.value,
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
                                  lineColor.withOpacity(0.7),
                                ],
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: touchedIndex != null,
                                getDotPainter:
                                    (spot, percent, barData, index) =>
                                        FlDotCirclePainter(
                                  radius: touchedIndex == index ? 6 : 3,
                                  color: lineColor,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    lineColor.withOpacity(0.15),
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
                                  FlSpot(
                                      spots.length > 0
                                          ? spots.length - 1.0
                                          : 0.0,
                                      averageY),
                                ],
                                isCurved: false,
                                color: accentColor.withOpacity(0.8),
                                barWidth: 2,
                                dashArray: [5, 3],
                                dotData: FlDotData(show: false),
                              ),
                          ],
                          minY: minY,
                          maxY: maxY,
                          backgroundColor: Colors.transparent,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: widget.showTimeline,
                                reservedSize: 30,
                                interval: _getBottomInterval(),
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= widget.data.length) {
                                    return const Text('');
                                  }

                                  final dateString = widget.data[index]['date'];
                                  if (dateString == null) return const Text('');

                                  try {
                                    final date =
                                        DateTime.parse(dateString.toString());
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        _formatDate(date),
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    return const Text('');
                                  }
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                interval:
                                    (maxY - minY) > 0 ? (maxY - minY) / 5 : 1,
                                getTitlesWidget: (value, meta) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      _formatPrice(value),
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
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
                            horizontalInterval:
                                (maxY - minY) > 0 ? (maxY - minY) / 5 : 1,
                            verticalInterval: widget.data.isNotEmpty
                                ? widget.data.length / 5
                                : 1,
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
                            touchCallback: (FlTouchEvent event,
                                LineTouchResponse? touchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    touchResponse == null ||
                                    touchResponse.lineBarSpots == null ||
                                    touchResponse.lineBarSpots!.isEmpty) {
                                  touchedIndex = null;
                                  return;
                                }
                                touchedIndex =
                                    touchResponse.lineBarSpots!.first.spotIndex;
                              });
                            },
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: cardColor.withOpacity(0.95),
                              tooltipRoundedRadius: 8,
                              tooltipPadding: const EdgeInsets.all(12),
                              tooltipMargin: 8,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots
                                    .map((spot) {
                                      final index = spot.x.toInt();
                                      if (index < 0 ||
                                          index >= widget.data.length) {
                                        return null;
                                      }

                                      final dateString =
                                          widget.data[index]['date'];
                                      if (dateString == null) return null;

                                      try {
                                        final date = DateTime.parse(
                                            dateString.toString());
                                        final price = spot.y;

                                        return LineTooltipItem(
                                          '${_formatTooltipDate(date)}\n${_formatTooltipPrice(price)}',
                                          TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        );
                                      } catch (e) {
                                        return null;
                                      }
                                    })
                                    .where((item) => item != null)
                                    .toList();
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
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
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
                                        labelResolver: (line) =>
                                            'Ort: ${_formatPrice(line.y)}',
                                      ),
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Performance summary
            if (spots.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPerformanceStats(
                  spots, lineColor, textPrimary, textSecondary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStats(List<FlSpot> spots, Color lineColor,
      Color textPrimary, Color textSecondary) {
    if (spots.isEmpty) return const SizedBox.shrink();

    final firstPrice = spots.first.y;
    final lastPrice = spots.last.y;
    final returnValue = lastPrice - firstPrice;
    final returnPercent =
        (firstPrice != 0) ? (returnValue / firstPrice) * 100 : 0.0;
    final isPositive = returnValue >= 0;

    // Calculate additional metrics
    final maxPrice =
        spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final minPrice =
        spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final volatility = _calculateVolatility(spots);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
                .extension<AppThemeExtension>()
                ?.cardColorLight
                ?.withOpacity(0.3) ??
            AppTheme.cardColorLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lineColor.withOpacity(0.3),
          width: 1,
        ),
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

  Widget _buildStatItem(
      String label, String value, Color labelColor, Color valueColor,
      {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
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
      if (spots[i - 1].y == 0) continue;
      final dailyReturn = (spots[i].y - spots[i - 1].y) / spots[i - 1].y;
      returns.add(dailyReturn);
    }

    if (returns.isEmpty) return 0.0;

    final mean = returns.reduce((a, b) => a + b) / returns.length;
    if (returns.length == 1 && mean.isNaN) return 0.0;

    final variance =
        returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
            returns.length;

    final nonNegativeVariance = variance < 0 ? 0.0 : variance;
    final stdDev = math.sqrt(nonNegativeVariance);

    return stdDev * 100;
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
        return 'Tüm Zamanlar';
      default:
        return 'Performans';
    }
  }

  double _getBottomInterval() {
    if (widget.data.isEmpty) return 1;
    int length = widget.data.length;
    if (length <= 1) return 1;
    if (length <= 7) return 1;
    if (length <= 30) return (length / 4).roundToDouble().clamp(1, 7);
    if (length <= 90) return (length / 6).roundToDouble().clamp(1, 15);
    if (length <= 180) return (length / 6).roundToDouble().clamp(1, 30);
    if (length <= 365) return (length / 6).roundToDouble().clamp(1, 60);
    return (length / 6).roundToDouble().clamp(1, (length / 2).floorToDouble());
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

  String _formatTooltipDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatPrice(double price) {
    if (price.isNaN || price.isInfinite) return "N/A";
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}k';
    } else if (price >= 100) {
      return price.toStringAsFixed(0);
    } else if (price >= 10) {
      return price.toStringAsFixed(1);
    } else if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(3);
    }
  }

  String _formatTooltipPrice(double price) {
    return '${price.toStringAsFixed(4)} ₺';
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';

class FundPerformanceChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String timeframe;
  final double? height;

  const FundPerformanceChart({
    Key? key,
    required this.data,
    required this.timeframe,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final positiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    if (data.isEmpty) {
      return Container(
        height: height ?? 300,
        child: Center(
          child: Text(
            'Veri mevcut değil',
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }

    // Convert data to chart spots
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < data.length; i++) {
      final price = data[i]['price']?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), price));

      if (price < minY) minY = price;
      if (price > maxY) maxY = price;
    }

    // Determine line color based on performance
    final Color lineColor;
    if (spots.isNotEmpty && spots.length > 1) {
      final firstPrice = spots.first.y;
      final lastPrice = spots.last.y;
      lineColor = lastPrice >= firstPrice ? positiveColor : negativeColor;
    } else {
      lineColor = accentColor;
    }

    // Add padding to min/max values
    final range = maxY - minY;
    final padding = range * 0.1;
    minY = (minY - padding).clamp(0, double.infinity);
    maxY = maxY + padding;

    return Container(
      height: height ?? 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getChartTitle(),
            style: TextStyle(
              color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
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
                    dotData: FlDotData(
                      show: spots.length <=
                          20, // Show dots only for small datasets
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: lineColor,
                        strokeWidth: 0,
                      ),
                    ),
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
                ],
                minY: minY,
                maxY: maxY,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _getBottomInterval(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const Text('');
                        }

                        final date = DateTime.parse(data[index]['date']);
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
                      reservedSize: 45,
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
                borderData: FlBorderData(
                  show: false,
                ),
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
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: cardColor,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= data.length) {
                          return null;
                        }

                        final date = DateTime.parse(data[index]['date']);
                        final price = spot.y;

                        return LineTooltipItem(
                          '${_formatDate(date)}\n${_formatPrice(price)}',
                          TextStyle(
                            color: themeExtension?.textPrimary ??
                                AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
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
                          color: lineColor,
                          strokeWidth: 2,
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
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPerformanceStats(spots),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats(List<FlSpot> spots) {
    if (spots.isEmpty) return const SizedBox.shrink();

    final firstPrice = spots.first.y;
    final lastPrice = spots.last.y;
    final returnValue = lastPrice - firstPrice;
    final returnPercent = (returnValue / firstPrice) * 100;
    final isPositive = returnValue >= 0;

    return Builder(
      builder: (context) {
        final themeExtension = Theme.of(context).extension<AppThemeExtension>();
        final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
        final positiveColor =
            themeExtension?.positiveColor ?? AppTheme.positiveColor;
        final negativeColor =
            themeExtension?.negativeColor ?? AppTheme.negativeColor;
        final returnColor = isPositive ? positiveColor : negativeColor;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Başlangıç',
              _formatPrice(firstPrice),
              textPrimary,
            ),
            _buildStatItem(
              'Güncel',
              _formatPrice(lastPrice),
              textPrimary,
            ),
            _buildStatItem(
              'Değişim',
              '${isPositive ? '+' : ''}${returnPercent.toStringAsFixed(2)}%',
              returnColor,
              icon: isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor,
      {IconData? icon}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: valueColor, size: 16),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getChartTitle() {
    switch (timeframe) {
      case '1W':
        return 'Son 1 Hafta Performans';
      case '1M':
        return 'Son 1 Ay Performans';
      case '3M':
        return 'Son 3 Ay Performans';
      case '6M':
        return 'Son 6 Ay Performans';
      case '1Y':
        return 'Son 1 Yıl Performans';
      case 'All':
        return 'Tüm Zamanlarda Performans';
      default:
        return 'Performans Grafiği';
    }
  }

  double _getBottomInterval() {
    if (data.length <= 7) return 1;
    if (data.length <= 30) return 7;
    if (data.length <= 90) return 15;
    return 30;
  }

  String _formatDate(DateTime date) {
    switch (timeframe) {
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
}

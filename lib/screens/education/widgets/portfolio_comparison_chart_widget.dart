// screens/education/widgets/portfolio_comparison_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart'; // DateTime formatlama için
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';
import '../models/education_models.dart'; // PortfolioComparisonChartContent ve PortfolioScenario için

class PortfolioComparisonChartWidget extends StatefulWidget {
  final PortfolioComparisonChartContent content;
  final Function(Map<String, dynamic>)? onInteraction; // Opsiyonel

  const PortfolioComparisonChartWidget({
    Key? key,
    required this.content,
    this.onInteraction,
  }) : super(key: key);

  @override
  State<PortfolioComparisonChartWidget> createState() =>
      _PortfolioComparisonChartWidgetState();
}

class _PortfolioDataPoint {
  final int year;
  final double value;

  _PortfolioDataPoint(this.year, this.value);
}

class _PortfolioComparisonChartWidgetState
    extends State<PortfolioComparisonChartWidget> {
  List<List<_PortfolioDataPoint>> _allPortfolioData = [];
  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
    );
    _generatePortfolioData();
  }

  void _generatePortfolioData() {
    _allPortfolioData.clear();
    final random = math.Random();

    for (var portfolioScenario in widget.content.portfolios) {
      List<_PortfolioDataPoint> singlePortfolioData = [];
      double currentValue = portfolioScenario.initialValue;
      singlePortfolioData
          .add(_PortfolioDataPoint(0, currentValue)); // Başlangıç yılı

      for (int year = 1; year <= widget.content.durationYears; year++) {
        // Basit bir geometrik Brownian hareket benzeri simülasyon
        double drift = portfolioScenario.averageReturn;
        double diffusion =
            portfolioScenario.volatility * _generateGaussianNoise(random);
        double percentageChange = math.exp(drift -
            (math.pow(portfolioScenario.volatility, 2) / 2) +
            diffusion);
        currentValue *= percentageChange;
        currentValue = math.max(0, currentValue); // Negatif olmasını engelle
        singlePortfolioData.add(_PortfolioDataPoint(year, currentValue));
      }
      _allPortfolioData.add(singlePortfolioData);
    }
    // Etkileşim raporlama (opsiyonel)
    widget.onInteraction?.call({'action': 'portfolio_data_generated'});
  }

  double _generateGaussianNoise(math.Random random) {
    double u1 = random.nextDouble();
    while (u1 == 0) u1 = random.nextDouble(); // u1 sıfır olamaz
    double u2 = random.nextDouble();
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey; // Hata durumunda varsayılan renk
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;

    if (_allPortfolioData.isEmpty) {
      return AdaptiveCard(
        child: Center(
          child: Text('Portföy verileri yükleniyor...',
              style: TextStyle(color: themeExtension.textSecondary)),
        ),
      );
    }

    return Column(
      children: [
        // Başlık ve açıklama LessonDetailScreen'de zaten var, burada tekrar etmeyebiliriz
        // Veya widget'ın kendi içinde bir başlık kısmı olabilir.
        AdaptiveCard(
          child: SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(
                title: AxisTitle(
                    text: 'Yıl',
                    textStyle: TextStyle(
                        color: themeExtension.textSecondary, fontSize: 12)),
                majorGridLines: MajorGridLines(
                    width: 0.5,
                    color: themeExtension.textSecondary.withOpacity(0.2)),
                labelStyle: TextStyle(
                    color: themeExtension.textSecondary, fontSize: 10),
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(
                    text: 'Portföy Değeri',
                    textStyle: TextStyle(
                        color: themeExtension.textSecondary, fontSize: 12)),
                numberFormat:
                    NumberFormat.compactSimpleCurrency(locale: 'tr_TR'),
                majorGridLines: MajorGridLines(
                    width: 0.5,
                    color: themeExtension.textSecondary.withOpacity(0.2)),
                labelStyle: TextStyle(
                    color: themeExtension.textSecondary, fontSize: 10),
              ),
              legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  textStyle: TextStyle(
                      color: themeExtension.textPrimary, fontSize: 11)),
              tooltipBehavior: TooltipBehavior(enable: true),
              zoomPanBehavior: _zoomPanBehavior,
              series: _buildPortfolioSeries(themeExtension),
            ),
          ),
        ),
        if (widget.content.annotations.isNotEmpty) ...[
          const SizedBox(height: 12),
          AdaptiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notlar:',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: themeExtension.textPrimary)),
                const SizedBox(height: 8),
                ...widget.content.annotations
                    .map((note) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text('• $note',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: themeExtension.textSecondary)),
                        ))
                    .toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<LineSeries<_PortfolioDataPoint, int>> _buildPortfolioSeries(
      AppThemeExtension themeExtension) {
    List<LineSeries<_PortfolioDataPoint, int>> seriesList = [];
    for (int i = 0; i < _allPortfolioData.length; i++) {
      final scenario = widget.content.portfolios[i];
      seriesList.add(
        LineSeries<_PortfolioDataPoint, int>(
          dataSource: _allPortfolioData[i],
          xValueMapper: (_PortfolioDataPoint data, _) => data.year,
          yValueMapper: (_PortfolioDataPoint data, _) => data.value,
          name: scenario.name,
          color: _hexToColor(scenario.colorHex),
          width: 2,
          markerSettings: MarkerSettings(
              isVisible: widget.content.durationYears <=
                  15), // Az veri noktasında marker göster
        ),
      );
    }
    return seriesList;
  }
}

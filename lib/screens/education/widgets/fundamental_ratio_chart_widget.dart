// screens/education/widgets/fundamental_ratio_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';
import '../models/education_models.dart'; // FundamentalRatioComparisonChartContent ve CompanyRatioData için

class FundamentalRatioChartWidget extends StatefulWidget {
  final FundamentalRatioComparisonChartContent content;
  final Function(Map<String, dynamic>)? onInteraction; // Opsiyonel

  const FundamentalRatioChartWidget({
    Key? key,
    required this.content,
    this.onInteraction,
  }) : super(key: key);

  @override
  State<FundamentalRatioChartWidget> createState() =>
      _FundamentalRatioChartWidgetState();
}

class _FundamentalRatioChartWidgetState
    extends State<FundamentalRatioChartWidget> {
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
    // Etkileşim raporlama (opsiyonel)
    widget.onInteraction?.call({'action': 'ratio_chart_displayed'});
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;

    if (widget.content.companies.isEmpty) {
      return AdaptiveCard(
        child: Center(
          child: Text(
            'Karşılaştırma için şirket verisi bulunmuyor.',
            style: TextStyle(color: themeExtension.textSecondary),
          ),
        ),
      );
    }

    String yAxisTitle = widget.content.ratioType;
    if (widget.content.ratioType.toUpperCase() == "FK") {
      yAxisTitle = "F/K Oranı";
    } else if (widget.content.ratioType.toUpperCase() == "PDD") {
      yAxisTitle = "PD/DD Oranı";
    }
    // Diğer oran türleri için başlıklar eklenebilir

    return Column(
      children: [
        AdaptiveCard(
          child: SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: TextStyle(
                  color: themeExtension.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                labelRotation: -45, // Şirket isimleri uzunsa
                labelIntersectAction: AxisLabelIntersectAction.rotate45,
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(
                  text: yAxisTitle,
                  textStyle: TextStyle(
                    color: themeExtension.textSecondary,
                    fontSize: 12,
                  ),
                ),
                majorGridLines: MajorGridLines(
                  width: 0.5,
                  color: themeExtension.textSecondary.withOpacity(0.2),
                ),
                labelStyle: TextStyle(
                  color: themeExtension.textSecondary,
                  fontSize: 10,
                ),
                numberFormat: NumberFormat("0.0#"), // Oranlar için uygun format
              ),
              tooltipBehavior: _tooltipBehavior,
              // Burada ChartSeries yerine CartesianSeries kullandık:
              series: <CartesianSeries<CompanyRatioData, String>>[
                ColumnSeries<CompanyRatioData, String>(
                  dataSource: widget.content.companies,
                  xValueMapper: (CompanyRatioData data, _) => data.name,
                  yValueMapper: (CompanyRatioData data, _) => data.value,
                  name: widget.content.ratioType,
                  color: themeExtension.accentColor,
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(
                      fontSize: 10,
                      color: themeExtension.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.content.averageRatio != null)
                  LineSeries<CompanyRatioData, String>(
                    // Ortalama için çizgi
                    dataSource: widget.content.companies
                        .map((c) => CompanyRatioData(
                              name: c.name,
                              value: widget.content.averageRatio!,
                            ))
                        .toList(),
                    xValueMapper: (CompanyRatioData data, _) => data.name,
                    yValueMapper: (CompanyRatioData data, _) => data.value,
                    name: 'Ortalama ${widget.content.ratioType}',
                    color: themeExtension.warningColor,
                    width: 2,
                    dashArray: const <double>[5, 5], // Kesik çizgi
                  ),
              ],
              // PlotBands ile de ortalama gösterilebilirdi.
            ),
          ),
        ),
        if (widget.content.learningPoints.isNotEmpty) ...[
          const SizedBox(height: 12),
          AdaptiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Öğrenme Noktaları:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: themeExtension.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.content.learningPoints
                    .map(
                      (point) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '• $point',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeExtension.textSecondary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

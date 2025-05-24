// screens/education/widgets/interactive_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../theme/app_theme.dart'; // AppTheme dosyanız
import '../../../widgets/common_widgets.dart'; // Assuming AdaptiveCard is defined here
import '../../../models/candle_data.dart'; // Assuming CandleData is defined here
import '../models/education_models.dart'; // Assuming InteractiveChartContent and ChartType are defined here
import 'dart:math' as Math; // For Math.max/min

class InteractiveChartWidget extends StatefulWidget {
  final InteractiveChartContent content;
  final Function(Map<String, dynamic>) onInteraction;

  const InteractiveChartWidget({
    Key? key,
    required this.content,
    required this.onInteraction,
  }) : super(key: key);

  @override
  State<InteractiveChartWidget> createState() => _InteractiveChartWidgetState();
}

class _InteractiveChartWidgetState extends State<InteractiveChartWidget> {
  List<CandleData> _chartData = [];
  bool _isLoading = true;
  String _selectedDataPoint = '';
  late ZoomPanBehavior _zoomPanBehavior;
  late TrackballBehavior _trackballBehavior;
  Set<String> _enabledIndicators = {};

  // GRAFİK İÇİN SABİT RENKLER (AppTheme'deki static const değerlerden)
  // Bu değerler, chart widget'ı içinde const olarak kullanılacak.
  // Eğer temanız dinamikse ve bu renkler ThemeExtension'dan geliyorsa,
  // chart widget'ındaki 'const'ları kaldırmanız gerekir.
  // Ancak, AppTheme'nizde doğrudan static const renkler olduğu için bunları kullanabiliriz.
  static const Color _chartGridLinesColor = AppTheme
      .textSecondary; // VEYA AppTheme._darkTextSecondary gibi spesifik bir renk
  static const Color _chartAxisLabelColor = AppTheme.textSecondary;
  static const Color _chartTooltipBackgroundColor = AppTheme.cardColor;
  static const Color _chartTooltipTextColor = AppTheme.textPrimary;

  @override
  void initState() {
    super.initState();
    _initializeChart();
    _loadChartData();
  }

  void _initializeChart() {
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      enableMouseWheelZooming: true,
      enableSelectionZooming: true,
    );

    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      lineType: TrackballLineType.vertical,
      tooltipSettings: const InteractiveTooltip(
        // const KULLANIMI İÇİN RENKLERİN const OLMASI GEREKİR
        enable: true,
        color:
            _chartTooltipBackgroundColor, // AppTheme.cardColor'ı kullanıyoruz (static const)
        textStyle: TextStyle(
            color:
                _chartTooltipTextColor), // AppTheme.textPrimary'yi kullanıyoruz (static const)
      ),
    );

    for (var indicator in widget.content.indicators) {
      if (indicator.isVisible) {
        _enabledIndicators.add(indicator.type);
      }
    }
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final data = await _generateEducationalData();
      if (!mounted) return;
      setState(() {
        _chartData = data;
        _isLoading = false;
      });
      widget.onInteraction({
        'action': 'data_loaded',
        'symbol': widget.content.symbol,
        'dataPoints': data.length,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // print("Error loading chart data: $e");
    }
  }

  Future<List<CandleData>> _generateEducationalData() async {
    final List<CandleData> data = [];
    final now = DateTime.now();
    final randomSeed = DateTime.now().millisecondsSinceEpoch % 1000;

    double basePrice = 100.0;

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: 30 - i));
      double trend = 0.0;
      if (widget.content.chartType == ChartType.line) {
        trend = i * 0.5;
      } else if (widget.content.symbol.toUpperCase() == 'EDUCATIONAL_PATTERN') {
        if (i < 10)
          trend = i * 0.3;
        else if (i < 20)
          trend = 3 - (i - 10) * 0.2;
        else
          trend = 1 + (i - 20) * 0.1;
      }
      final noise = (randomSeed + i * 17) % 100 / 100.0 - 0.5;
      final price = basePrice + trend + noise;
      final open = price + (noise * 0.5);
      final close = price - (noise * 0.3);
      final high = [open, close, price + 1].reduce(Math.max);
      final low = [open, close, price - 1].reduce(Math.min);
      data.add(CandleData(
          date: date,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: 1000000 + (i * 50000)));
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    // Dinamik tema renklerini ThemeExtension'dan alabilirsiniz,
    // ANCAK chart widget'ının içindeki 'const' tanımlamalar için bu kullanılmaz.
    // final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    // final currentAccentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    // final currentTextPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    // final currentTextSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    // final currentCardColorLight = themeExtension?.cardColorLight ?? AppTheme.cardColorLight;
    // final currentPositiveColor = themeExtension?.positiveColor ?? AppTheme.positiveColor;
    // final currentNegativeColor = themeExtension?.negativeColor ?? AppTheme.negativeColor;
    // final currentWarningColor = themeExtension?.warningColor ?? AppTheme.warningColor;

    return Column(
      children: [
        _buildChartControls(), // Bu widget içindeki Text stilleri için AppTheme.textPrimary kullanılabilir (eğer const ise)
        const SizedBox(height: 12),
        AdaptiveCard(
          child: SizedBox(
            height: 300,
            child: _isLoading ? _buildLoadingChart() : _buildChart(),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.content.indicators.isNotEmpty) _buildIndicatorControls(),
        if (_selectedDataPoint.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSelectedDataInfo(),
        ],
      ],
    );
  }

  Widget _buildChartControls() {
    return AdaptiveCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${widget.content.symbol} - ${widget.content.timeframe}',
              style: const TextStyle(
                // const olması için AppTheme.textPrimary'nin static const olması gerekir
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme
                    .textPrimary, // AppTheme'deki static const textPrimary
              ),
            ),
          ),
          _buildChartTypeButton(ChartType.candlestick, Icons.candlestick_chart),
          const SizedBox(width: 8),
          _buildChartTypeButton(ChartType.line, Icons.show_chart),
          const SizedBox(width: 8),
          _buildChartTypeButton(ChartType.area, Icons.area_chart),
        ],
      ),
    );
  }

  Widget _buildChartTypeButton(ChartType type, IconData icon) {
    final isSelected = widget.content.chartType == type;
    // Dinamik renkler için ThemeExtension kullanılabilir, ancak butonun kendisi const olamaz.
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final currentAccentColor =
        themeExtension?.accentColor ?? AppTheme.accentColor;
    final currentTextSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          widget.onInteraction(
              {'action': 'chart_type_changed', 'new_type': type.name});
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? currentAccentColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? currentAccentColor
                : currentTextSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(icon,
            color: isSelected ? currentAccentColor : currentTextSecondary,
            size: 20),
      ),
    );
  }

  Widget _buildLoadingChart() {
    // Dinamik renkler için ThemeExtension
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final currentAccentColor =
        themeExtension?.accentColor ?? AppTheme.accentColor;
    final currentTextSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    return Center(
      // Bu widget'ın const olması için renklerin const olması gerekir.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: currentAccentColor),
          const SizedBox(height: 12),
          Text('Grafik yükleniyor...',
              style: TextStyle(color: currentTextSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChart() {
    switch (widget.content.chartType) {
      case ChartType.candlestick:
        return _buildCandlestickChart();
      case ChartType.line:
        return _buildLineChart();
      case ChartType.area:
        return _buildAreaChart();
      case ChartType.indicator:
        return _buildIndicatorChart();
      default:
        return _buildCandlestickChart();
    }
  }

  DateTimeAxis _primaryXAxis() => DateTimeAxis(
        majorGridLines:
            const MajorGridLines(width: 0.5, color: _chartGridLinesColor),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: _chartAxisLabelColor, fontSize: 10),
      );

  NumericAxis _primaryYAxis({String labelFormat = '\${value}'}) => NumericAxis(
        opposedPosition: true,
        labelFormat: labelFormat,
        majorGridLines:
            const MajorGridLines(width: 0.5, color: _chartGridLinesColor),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: _chartAxisLabelColor, fontSize: 10),
      );

  Widget _buildCandlestickChart() {
    // Dinamik renkler için ThemeExtension
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final currentPositiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final currentNegativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: _primaryXAxis(),
      primaryYAxis: _primaryYAxis(),
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      series: <CartesianSeries<CandleData, DateTime>>[
        CandleSeries<CandleData, DateTime>(
          dataSource: _chartData,
          xValueMapper: (CandleData data, _) => data.date,
          lowValueMapper: (CandleData data, _) => data.low,
          highValueMapper: (CandleData data, _) => data.high,
          openValueMapper: (CandleData data, _) => data.open,
          closeValueMapper: (CandleData data, _) => data.close,
          bullColor: currentPositiveColor,
          bearColor: currentNegativeColor,
          enableSolidCandles: true,
          onPointTap: _onDataPointTapped,
          name: 'Candlestick',
        ),
      ],
      indicators: _buildTechnicalIndicators(),
    );
  }

  Widget _buildLineChart() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final currentAccentColor =
        themeExtension?.accentColor ?? AppTheme.accentColor;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: _primaryXAxis(),
      primaryYAxis: _primaryYAxis(),
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      series: <CartesianSeries<CandleData, DateTime>>[
        LineSeries<CandleData, DateTime>(
          dataSource: _chartData,
          xValueMapper: (CandleData data, _) => data.date,
          yValueMapper: (CandleData data, _) => data.close,
          color: currentAccentColor,
          width: 2,
          onPointTap: _onDataPointTapped,
          name: 'Line',
        ),
      ],
    );
  }

  Widget _buildAreaChart() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final currentAccentColor =
        themeExtension?.accentColor ?? AppTheme.accentColor;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: _primaryXAxis(),
      primaryYAxis: _primaryYAxis(),
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      series: <CartesianSeries<CandleData, DateTime>>[
        AreaSeries<CandleData, DateTime>(
          dataSource: _chartData,
          xValueMapper: (CandleData data, _) => data.date,
          yValueMapper: (CandleData data, _) => data.close,
          color: currentAccentColor.withOpacity(0.3),
          borderColor: currentAccentColor,
          borderWidth: 2,
          onPointTap: _onDataPointTapped,
          name: 'Area',
        ),
      ],
    );
  }

  Widget _buildIndicatorChart() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final currentWarningColor =
        themeExtension?.warningColor ?? AppTheme.warningColor;
    final currentPositiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final currentNegativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: _primaryXAxis(),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        labelFormat: '{value}',
        majorGridLines:
            const MajorGridLines(width: 0.5, color: _chartGridLinesColor),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: _chartAxisLabelColor, fontSize: 10),
        minimum: 0,
        maximum: 100,
        plotBands: [
          PlotBand(
            start: 70,
            end: 100,
            color: currentNegativeColor.withOpacity(0.1), // Dinamik renk
            text: 'Aşırı Alım',
            textStyle: const TextStyle(
                color: _chartAxisLabelColor, fontSize: 10), // Sabit const renk
          ),
          PlotBand(
            start: 0,
            end: 30,
            color: currentPositiveColor.withOpacity(0.1), // Dinamik renk
            text: 'Aşırı Satım',
            textStyle: const TextStyle(
                color: _chartAxisLabelColor, fontSize: 10), // Sabit const renk
          ),
        ],
      ),
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      series: <CartesianSeries<CandleData, DateTime>>[
        LineSeries<CandleData, DateTime>(
          dataSource: _chartData,
          xValueMapper: (CandleData data, _) => data.date,
          yValueMapper: (CandleData data, _) => _calculateRSI(data),
          color: currentWarningColor, // Dinamik renk
          width: 2,
          name: 'RSI',
          onPointTap: _onDataPointTapped,
        ),
      ],
    );
  }

  List<TechnicalIndicator<dynamic, dynamic>> _buildTechnicalIndicators(
      {String seriesName = 'Candlestick'}) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final currentAccentColor =
        themeExtension?.accentColor ?? AppTheme.accentColor;
    final currentPositiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final currentNegativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;

    final List<TechnicalIndicator<dynamic, dynamic>> indicators = [];
    if (widget.content.chartType != ChartType.candlestick &&
        seriesName == 'Candlestick') {
      return indicators;
    }

    for (var indicatorConfig in widget.content.indicators) {
      if (!_enabledIndicators.contains(indicatorConfig.type)) continue;

      final period =
          (indicatorConfig.parameters['period'] as num?)?.toInt() ?? 20;
      final color = _parseColor(indicatorConfig.parameters['color']) ??
          currentAccentColor; // Dinamik renk

      switch (indicatorConfig.type) {
        case 'SMA':
          indicators.add(SmaIndicator<CandleData, DateTime>(
            seriesName: seriesName,
            valueField: 'close',
            period: period,
            signalLineWidth: 2,
            signalLineColor: color,
          ));
          break;
        case 'EMA':
          indicators.add(EmaIndicator<CandleData, DateTime>(
            seriesName: seriesName,
            valueField: 'close',
            period: period,
            signalLineWidth: 2,
            signalLineColor: color,
          ));
          break;
        case 'BOLLINGER':
          indicators.add(BollingerBandIndicator<CandleData, DateTime>(
            seriesName: seriesName,
            period: period,
            standardDeviation:
                (indicatorConfig.parameters['standardDeviation'] as num?)
                        ?.toInt() ??
                    2,
            upperLineColor:
                currentNegativeColor.withOpacity(0.7), // Dinamik renk
            lowerLineColor:
                currentPositiveColor.withOpacity(0.7), // Dinamik renk
            bandColor: currentAccentColor.withOpacity(0.1), // Dinamik renk
            upperLineWidth: 1.5,
            lowerLineWidth: 1.5,
          ));
          break;
      }
    }
    return indicators;
  }

  Color? _parseColor(dynamic colorValue) {
    if (colorValue is String) {
      switch (colorValue.toLowerCase()) {
        case 'blue':
          return Colors
              .blue; // Bunlar sabit kalabilir veya AppTheme'den alınabilir
        case 'orange':
          return Colors.orange;
        case 'red':
          return Colors.red;
        case 'green':
          return Colors.green;
        case 'purple':
          return Colors.purple;
      }
    }
    return null;
  }

  double _calculateRSI(CandleData data) {
    final index = _chartData.indexOf(data);
    const int period = 14;
    if (index < period - 1) return 50.0;

    double gains = 0.0;
    double losses = 0.0;

    for (int i = index - (period - 1); i <= index; i++) {
      if (i <= 0) continue;
      final change = _chartData[i].close - _chartData[i - 1].close;
      if (change > 0)
        gains += change;
      else
        losses += change.abs();
    }

    if (period == 0) return 50.0;
    final avgGain = gains / period;
    final avgLoss = losses / period;

    if (avgLoss == 0) return 100.0;
    final rs = avgGain / avgLoss;
    return (100 - (100 / (1 + rs))).clamp(0.0, 100.0);
  }

  Widget _buildIndicatorControls() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final currentAccentColor =
        themeExtension?.accentColor ?? AppTheme.accentColor;
    final currentTextPrimary =
        themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final currentTextSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final currentCardColorLight =
        themeExtension?.cardColorLight ?? AppTheme.cardColorLight;

    return AdaptiveCard(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Teknik Göstergeler',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: currentTextPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.content.indicators.map((indicator) {
              final isEnabled = _enabledIndicators.contains(indicator.type);
              return FilterChip(
                label: Text(indicator.type),
                selected: isEnabled,
                onSelected: (selected) {
                  setState(() {
                    if (selected)
                      _enabledIndicators.add(indicator.type);
                    else
                      _enabledIndicators.remove(indicator.type);
                  });
                  widget.onInteraction({
                    'action': 'indicator_toggled',
                    'indicator': indicator.type,
                    'enabled': selected
                  });
                },
                backgroundColor: currentCardColorLight,
                selectedColor: currentAccentColor.withOpacity(0.2),
                checkmarkColor: currentAccentColor,
                labelStyle: TextStyle(
                    color: isEnabled ? currentAccentColor : currentTextPrimary,
                    fontSize: 12),
                shape: StadiumBorder(
                    side: BorderSide(
                        color: isEnabled
                            ? currentAccentColor
                            : currentTextSecondary.withOpacity(0.3))),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDataInfo() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final currentTextPrimary =
        themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final currentTextSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    return AdaptiveCard(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seçili Veri Noktası',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: currentTextPrimary)),
          const SizedBox(height: 8),
          Text(_selectedDataPoint,
              style: TextStyle(fontSize: 12, color: currentTextSecondary)),
        ],
      ),
    );
  }

  void _onDataPointTapped(ChartPointDetails details) {
    if (details.pointIndex != null && details.pointIndex! < _chartData.length) {
      final data = _chartData[details.pointIndex!];
      setState(() {
        _selectedDataPoint =
            'Tarih: ${data.date.day}/${data.date.month}/${data.date.year}\n'
            'Açılış: \$${data.open.toStringAsFixed(2)}\n'
            'Kapanış: \$${data.close.toStringAsFixed(2)}\n'
            'Yüksek: \$${data.high.toStringAsFixed(2)}\n'
            'Düşük: \$${data.low.toStringAsFixed(2)}';
      });
      widget.onInteraction({
        'action': 'data_point_selected',
        'data': {
          'date': data.date.toIso8601String(),
          'open': data.open,
          'close': data.close,
          'high': data.high,
          'low': data.low
        },
      });
    }
  }
}

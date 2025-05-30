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

  // Bu statik const renkler artık kullanılmayacak, tema eklentisinden alınacak.
  // static const Color _chartGridLinesColor = AppTheme.textSecondary;
  // static const Color _chartAxisLabelColor = AppTheme.textSecondary;
  // static const Color _chartTooltipBackgroundColor = AppTheme.cardColor;
  // static const Color _chartTooltipTextColor = AppTheme.textPrimary;

  @override
  void initState() {
    super.initState();
    // _initializeChart behaviors now depend on context, so move to didChangeDependencies or build
    _loadChartData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize behaviors here as they might depend on Theme
    _initializeChartBehaviors();
    _initializeEnabledIndicators();
  }

  void _initializeChartBehaviors() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final tooltipBackgroundColor =
        themeExtension?.cardColor ?? AppTheme.cardColor;
    final tooltipTextColor =
        themeExtension?.textPrimary ?? AppTheme.textPrimary;

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
      tooltipSettings: InteractiveTooltip(
        // const kaldırıldı
        enable: true,
        color: tooltipBackgroundColor,
        textStyle: TextStyle(color: tooltipTextColor),
      ),
    );
  }

  void _initializeEnabledIndicators() {
    _enabledIndicators.clear(); // Clear before re-initializing
    for (var indicator in widget.content.indicators) {
      if (indicator.isVisible) {
        _enabledIndicators.add(indicator.type);
      }
    }
  }

  Future<void> _loadChartData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      // Simulating a network call or data generation
      await Future.delayed(const Duration(milliseconds: 300));
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
    final random = Math.Random(DateTime.now().millisecondsSinceEpoch);

    double basePrice =
        100.0 + random.nextDouble() * 50; // Add some randomness to base price

    for (int i = 0; i < 60; i++) {
      // Generate more data points for better zooming/panning
      final date = now.subtract(Duration(days: 60 - i));
      double trend = 0.0;

      // Apply pattern for "EDUCATIONAL_PATTERN"
      if (widget.content.symbol.toUpperCase() == 'EDUCATIONAL_PATTERN') {
        // Simple Head and Shoulders like pattern
        if (i < 10)
          trend =
              i * 0.1 * (random.nextDouble() * 0.4 + 0.8); // Left shoulder up
        else if (i < 20)
          trend = (1 - (i - 10) * 0.05) *
              (random.nextDouble() * 0.4 + 0.8); // Left shoulder down
        else if (i < 30)
          trend = (0.5 + (i - 20) * 0.15) *
              (random.nextDouble() * 0.4 + 0.8); // Head up
        else if (i < 40)
          trend = (2 - (i - 30) * 0.1) *
              (random.nextDouble() * 0.4 + 0.8); // Head down
        else if (i < 50)
          trend = (1 + (i - 40) * 0.08) *
              (random.nextDouble() * 0.4 + 0.8); // Right shoulder up
        else
          trend = (1.8 - (i - 50) * 0.07) *
              (random.nextDouble() * 0.4 + 0.8); // Right shoulder down
      } else if (widget.content.chartType == ChartType.line ||
          widget.content.chartType == ChartType.area) {
        trend =
            Math.sin(i * 0.2) * 5 + i * 0.1; // Sinusoidal trend for line/area
      } else {
        trend = (random.nextDouble() - 0.45) *
            2; // General random walk for candlestick
      }

      final noise = (random.nextDouble() - 0.5) * 2; // More volatile noise
      double open, close, high, low;

      if (i > 0 && _chartData.isNotEmpty && i <= _chartData.length) {
        // Ensure _chartData[i-1] is safe
        open = _chartData[i - 1].close + (random.nextDouble() - 0.5) * 0.5;
      } else {
        open = basePrice + trend + noise * 0.5;
      }

      close = open +
          trend +
          noise * 0.8 +
          (random.nextDouble() - 0.5) * 1.5; // More movement in close

      high = Math.max(open, close) + random.nextDouble() * 2;
      low = Math.min(open, close) - random.nextDouble() * 2;

      // Ensure OHLC logic
      if (low > open) low = open - random.nextDouble();
      if (low > close) low = close - random.nextDouble();
      if (high < open) high = open + random.nextDouble();
      if (high < close) high = close + random.nextDouble();
      if (open < low)
        open = low + random.nextDouble() * 0.1; // ensure open > low
      if (close < low)
        close = low + random.nextDouble() * 0.1; // ensure close > low

      basePrice = close; // Next candle starts relative to current close

      data.add(CandleData(
          date: date,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: 1000000 + random.nextInt(500000) + (i * 10000)));
    }
    _chartData = data; // Update _chartData for RSI calculation
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;
    // _initializeChartBehaviors(); // Called in didChangeDependencies

    return Column(
      children: [
        _buildChartControls(themeExtension),
        const SizedBox(height: 12),
        AdaptiveCard(
          child: SizedBox(
            height: 300,
            child: _isLoading
                ? _buildLoadingChart(themeExtension)
                : _buildChart(themeExtension),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.content.indicators.isNotEmpty)
          _buildIndicatorControls(themeExtension),
        if (_selectedDataPoint.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSelectedDataInfo(themeExtension),
        ],
      ],
    );
  }

  Widget _buildChartControls(AppThemeExtension themeExtension) {
    return AdaptiveCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${widget.content.symbol} - ${widget.content.timeframe}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: themeExtension.textPrimary,
              ),
            ),
          ),
          _buildChartTypeButton(
              ChartType.candlestick, Icons.candlestick_chart, themeExtension),
          const SizedBox(width: 8),
          _buildChartTypeButton(
              ChartType.line, Icons.show_chart, themeExtension),
          const SizedBox(width: 8),
          _buildChartTypeButton(
              ChartType.area, Icons.area_chart, themeExtension),
        ],
      ),
    );
  }

  Widget _buildChartTypeButton(
      ChartType type, IconData icon, AppThemeExtension themeExtension) {
    final isSelected = widget.content.chartType == type;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          widget.onInteraction(
              {'action': 'chart_type_changed', 'new_type': type.name});
          // Note: The parent widget (LessonDetailScreen) should handle the state change
          // for widget.content.chartType for this button to reflect the change.
          // This widget itself does not directly modify widget.content.
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? themeExtension.accentColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? themeExtension.accentColor
                : themeExtension.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(icon,
            color: isSelected
                ? themeExtension.accentColor
                : themeExtension.textSecondary,
            size: 20),
      ),
    );
  }

  Widget _buildLoadingChart(AppThemeExtension themeExtension) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: themeExtension.accentColor),
          const SizedBox(height: 12),
          Text('Grafik yükleniyor...',
              style:
                  TextStyle(color: themeExtension.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChart(AppThemeExtension themeExtension) {
    switch (widget.content.chartType) {
      case ChartType.candlestick:
        return _buildCandlestickChart(themeExtension);
      case ChartType.line:
        return _buildLineChart(themeExtension);
      case ChartType.area:
        return _buildAreaChart(themeExtension);
      case ChartType.indicator:
        return _buildIndicatorChart(themeExtension);
      default:
        return _buildCandlestickChart(themeExtension);
    }
  }

  DateTimeAxis _primaryXAxis(AppThemeExtension themeExtension) => DateTimeAxis(
        majorGridLines: MajorGridLines(
            width: 0.5, color: themeExtension.textSecondary.withOpacity(0.5)),
        axisLine: const AxisLine(width: 0),
        labelStyle:
            TextStyle(color: themeExtension.textSecondary, fontSize: 10),
      );

  NumericAxis _primaryYAxis(AppThemeExtension themeExtension,
          {String labelFormat = '\${value}'}) =>
      NumericAxis(
        opposedPosition: true,
        labelFormat: labelFormat,
        majorGridLines: MajorGridLines(
            width: 0.5, color: themeExtension.textSecondary.withOpacity(0.5)),
        axisLine: const AxisLine(width: 0),
        labelStyle:
            TextStyle(color: themeExtension.textSecondary, fontSize: 10),
      );

  Widget _buildCandlestickChart(AppThemeExtension themeExtension) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: _primaryXAxis(themeExtension),
      primaryYAxis: _primaryYAxis(themeExtension),
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
          bullColor: themeExtension.positiveColor,
          bearColor: themeExtension.negativeColor,
          enableSolidCandles: true,
          onPointTap: _onDataPointTapped,
          name: 'Candlestick',
        ),
      ],
      indicators:
          _buildTechnicalIndicators(themeExtension, seriesName: 'Candlestick'),
    );
  }

  Widget _buildLineChart(AppThemeExtension themeExtension) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: _primaryXAxis(themeExtension),
      primaryYAxis: _primaryYAxis(themeExtension),
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      series: <CartesianSeries<CandleData, DateTime>>[
        LineSeries<CandleData, DateTime>(
          dataSource: _chartData,
          xValueMapper: (CandleData data, _) => data.date,
          yValueMapper: (CandleData data, _) => data.close,
          color: themeExtension.accentColor,
          width: 2,
          onPointTap: _onDataPointTapped,
          name: 'Line',
        ),
      ],
      indicators: _buildTechnicalIndicators(themeExtension, seriesName: 'Line'),
    );
  }

  Widget _buildAreaChart(AppThemeExtension themeExtension) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: _primaryXAxis(themeExtension),
      primaryYAxis: _primaryYAxis(themeExtension),
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      series: <CartesianSeries<CandleData, DateTime>>[
        AreaSeries<CandleData, DateTime>(
          dataSource: _chartData,
          xValueMapper: (CandleData data, _) => data.date,
          yValueMapper: (CandleData data, _) => data.close,
          color: themeExtension.accentColor.withOpacity(0.3),
          borderColor: themeExtension.accentColor,
          borderWidth: 2,
          onPointTap: _onDataPointTapped,
          name: 'Area',
        ),
      ],
      indicators: _buildTechnicalIndicators(themeExtension, seriesName: 'Area'),
    );
  }

  Widget _buildIndicatorChart(AppThemeExtension themeExtension) {
    final chartAxisLabelColor = themeExtension.textSecondary;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: _primaryXAxis(themeExtension),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        labelFormat: '{value}',
        majorGridLines: MajorGridLines(
            width: 0.5, color: themeExtension.textSecondary.withOpacity(0.5)),
        axisLine: const AxisLine(width: 0),
        labelStyle: TextStyle(color: chartAxisLabelColor, fontSize: 10),
        minimum: 0,
        maximum: 100,
        plotBands: [
          PlotBand(
            start: 70,
            end: 100,
            color: themeExtension.negativeColor.withOpacity(0.1),
            text: 'Aşırı Alım',
            textStyle: TextStyle(color: chartAxisLabelColor, fontSize: 10),
          ),
          PlotBand(
            start: 0,
            end: 30,
            color: themeExtension.positiveColor.withOpacity(0.1),
            text: 'Aşırı Satım',
            textStyle: TextStyle(color: chartAxisLabelColor, fontSize: 10),
          ),
        ],
      ),
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      series: <CartesianSeries<CandleData, DateTime>>[
        LineSeries<CandleData, DateTime>(
          dataSource: _chartData,
          xValueMapper: (CandleData data, _) => data.date,
          yValueMapper: (CandleData data, _) =>
              _calculateRSI(data), // Use the local _chartData for calculation
          color: themeExtension.warningColor,
          width: 2,
          name: 'RSI', // This is the seriesName for this specific chart
          onPointTap: _onDataPointTapped,
        ),
      ],
      // For IndicatorChart, technical indicators might be less common, or you might want to add
      // other series that are indicators themselves (e.g. MACD lines directly)
      // indicators: _buildTechnicalIndicators(themeExtension, seriesName: 'RSI'),
    );
  }

  List<TechnicalIndicator<dynamic, dynamic>> _buildTechnicalIndicators(
      AppThemeExtension themeExtension,
      {required String seriesName}) {
    final List<TechnicalIndicator<dynamic, dynamic>> indicators = [];

    // Only add indicators if the chart type itself is not 'indicator'
    // and the seriesName matches the primary series of that chart type.
    bool canAddIndicators = widget.content.chartType != ChartType.indicator;

    if (!canAddIndicators) return indicators;

    // Ensure indicators are added only to the relevant series type
    if (widget.content.chartType == ChartType.candlestick &&
        seriesName != 'Candlestick') return indicators;
    if (widget.content.chartType == ChartType.line && seriesName != 'Line')
      return indicators;
    if (widget.content.chartType == ChartType.area && seriesName != 'Area')
      return indicators;

    for (var indicatorConfig in widget.content.indicators) {
      if (!_enabledIndicators.contains(indicatorConfig.type)) continue;

      final period =
          (indicatorConfig.parameters['period'] as num?)?.toInt() ?? 20;
      final color = _parseColor(indicatorConfig.parameters['color']) ??
          themeExtension.accentColor;

      switch (indicatorConfig.type) {
        case 'SMA':
          indicators.add(SmaIndicator<CandleData, DateTime>(
            seriesName: seriesName,
            // For SMA, we need to specify the data source and mappings
            dataSource: _chartData,
            xValueMapper: (CandleData data, _) => data.date,
            // SMA uses the close value by default
            period: period,
            signalLineWidth: 2,
            signalLineColor: color,
          ));
          break;
        case 'EMA':
          indicators.add(EmaIndicator<CandleData, DateTime>(
            seriesName: seriesName,
            dataSource: _chartData,
            xValueMapper: (CandleData data, _) => data.date,
            period: period,
            signalLineWidth: 2,
            signalLineColor: color,
          ));
          break;
        case 'BOLLINGER':
          // Convert double to int for standardDeviation
          final stdDev =
              (indicatorConfig.parameters['standardDeviation'] as num?)
                      ?.toInt() ??
                  2;

          indicators.add(BollingerBandIndicator<CandleData, DateTime>(
            seriesName: seriesName,
            dataSource: _chartData,
            xValueMapper: (CandleData data, _) => data.date,
            period: period,
            standardDeviation: stdDev, // Now it's an int
            upperLineColor: themeExtension.negativeColor.withOpacity(0.7),
            lowerLineColor: themeExtension.positiveColor.withOpacity(0.7),
            bandColor: themeExtension.accentColor.withOpacity(0.1),
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
          return Colors.blue;
        case 'orange':
          return Colors.orange;
        case 'red':
          return Colors.red;
        case 'green':
          return Colors.green;
        case 'purple':
          return Colors.purple;
        case 'yellow':
          return Colors.yellow;
        // Add more named colors if needed
      }
    }
    // Potentially handle hex colors like '#FF0000' later if needed
    return null;
  }

  double _calculateRSI(CandleData currentDataPoint) {
    // Ensure _chartData is not empty and contains the currentDataPoint
    if (_chartData.isEmpty) return 50.0;

    final index = _chartData.indexWhere((d) => d.date == currentDataPoint.date);
    if (index == -1) return 50.0; // Data point not found

    const int period = 14;
    if (index < period)
      return 50.0; // Not enough data for full period calculation for earlier points

    double gains = 0.0;
    double losses = 0.0;
    int actualPeriodsForAvg = 0;

    // Calculate initial average gain and loss for the first period
    for (int i = index - period + 1; i <= index; i++) {
      if (i <= 0) continue; // Skip if previous data point doesn't exist
      final change = _chartData[i].close - _chartData[i - 1].close;
      if (change > 0) {
        gains += change;
      } else {
        losses += change.abs();
      }
      actualPeriodsForAvg++;
    }

    if (actualPeriodsForAvg == 0)
      return 50.0; // Should not happen if index >= period

    double avgGain = gains / actualPeriodsForAvg;
    double avgLoss = losses / actualPeriodsForAvg;

    // For subsequent points, use Wilder's smoothing method (optional, simple average is also common)
    // This example uses a simple moving average for gains/losses over the period for each point.

    if (avgLoss == 0) return 100.0; // Avoid division by zero; max RSI

    final rs = avgGain / avgLoss;
    return (100 - (100 / (1 + rs))).clamp(0.0, 100.0);
  }

  Widget _buildIndicatorControls(AppThemeExtension themeExtension) {
    return AdaptiveCard(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Teknik Göstergeler',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeExtension.textPrimary)),
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
                    if (selected) {
                      _enabledIndicators.add(indicator.type);
                    } else {
                      _enabledIndicators.remove(indicator.type);
                    }
                  });
                  widget.onInteraction({
                    'action': 'indicator_toggled',
                    'indicator': indicator.type,
                    'enabled': selected
                  });
                },
                backgroundColor: themeExtension.cardColorLight,
                selectedColor: themeExtension.accentColor.withOpacity(0.2),
                checkmarkColor: themeExtension.accentColor,
                labelStyle: TextStyle(
                    color: isEnabled
                        ? themeExtension.accentColor
                        : themeExtension.textPrimary,
                    fontSize: 12),
                shape: StadiumBorder(
                    side: BorderSide(
                        color: isEnabled
                            ? themeExtension.accentColor
                            : themeExtension.textSecondary.withOpacity(0.3))),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDataInfo(AppThemeExtension themeExtension) {
    return AdaptiveCard(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seçili Veri Noktası',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeExtension.textPrimary)),
          const SizedBox(height: 8),
          Text(_selectedDataPoint,
              style:
                  TextStyle(fontSize: 12, color: themeExtension.textSecondary)),
        ],
      ),
    );
  }

  void _onDataPointTapped(ChartPointDetails details) {
    if (details.pointIndex != null &&
        _chartData.isNotEmpty &&
        details.pointIndex! < _chartData.length) {
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

// screens/education/widgets/interactive_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';

// education_models.dart içindeki CandleData’yı gizliyoruz. 
// Böylece tek “CandleData” tanımımız '../../../models/candle_data.dart' içinden gelecek.
import '../models/education_models.dart' hide CandleData;
import '../../../models/candle_data.dart';

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

class _InteractiveChartWidgetState extends State<InteractiveChartWidget>
    with TickerProviderStateMixin {
  List<CandleData> _priceData = [];
  List<IndicatorDataPoint> _indicatorData = [];
  bool _isLoading = true;
  bool _showVolume = false;
  bool _showGrid = true;
  late AnimationController _animationController;

  // Chart interaction tracking
  int _totalInteractions = 0;
  bool _hasZoomed = false;
  bool _hasPanned = false;
  bool _hasUsedTrackball = false;

  /// The ZoomPanBehavior instance used by the chart.
  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      enableMouseWheelZooming: true,
    );
    _loadChartData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));

    _priceData = _generateRealisticPriceData();
    _indicatorData = _calculateIndicators();

    setState(() => _isLoading = false);

    // Start animation
    _animationController.forward();

    // Report data load interaction
    _reportInteraction('data_loaded');
  }

  List<CandleData> _generateRealisticPriceData() {
    final List<CandleData> data = [];
    final now = DateTime.now();
    final random = math.Random(42); // Fixed seed for consistent data

    // Determine base price based on symbol
    double basePrice = _getBasePriceForSymbol(widget.content.symbol);

    // Generate data points based on timeframe
    final dataPoints = _getDataPointsForTimeframe(widget.content.timeframe);
    final timeInterval = _getTimeInterval(widget.content.timeframe);

    double currentPrice = basePrice;
    double momentum = 0.0;
    List<double> recentChanges = [];

    for (int i = 0; i < dataPoints; i++) {
      final date = now.subtract(Duration(
        milliseconds: (dataPoints - i) * timeInterval,
      ));

      // Create realistic price movements
      final marketHour = date.hour;
      double volatilityMultiplier = _getVolatilityForHour(marketHour);

      // Calculate momentum from recent changes
      if (recentChanges.length >= 3) {
        momentum = recentChanges.take(3).reduce((a, b) => a + b) / 3;
        momentum *= 0.7; // Momentum decay
      }

      // Generate price change
      double baseVolatility = currentPrice * 0.002; // 0.2% base volatility
      double priceChange = _generateGaussianNoise(random) *
          baseVolatility *
          volatilityMultiplier;

      // Add momentum and mean reversion
      priceChange += momentum * 0.3;
      priceChange += (basePrice - currentPrice) * 0.001; // Mean reversion

      // Create OHLC values
      final open = currentPrice;
      final close = math.max(
          open + priceChange, basePrice * 0.5); // Prevent negative prices

      final bodySize = (close - open).abs();
      final minBodySize = currentPrice * 0.001;
      final effectiveBodySize = math.max(bodySize, minBodySize);

      // Calculate high and low with realistic wicks
      final wickSize = effectiveBodySize * (0.5 + random.nextDouble() * 1.5);

      double high, low;
      if (close >= open) {
        // Bullish candle
        high = close + wickSize * (0.3 + random.nextDouble() * 0.4);
        low = open - wickSize * (0.2 + random.nextDouble() * 0.3);
      } else {
        // Bearish candle
        high = open + wickSize * (0.2 + random.nextDouble() * 0.3);
        low = close - wickSize * (0.3 + random.nextDouble() * 0.4);
      }

      // Ensure logical constraints
      low = math.max(low, basePrice * 0.3);
      high = math.max(high, math.max(open, close));

      // Generate volume
      final volumeBase = _getVolumeBase(widget.content.symbol);
      final volumeMultiplier = 0.7 + random.nextDouble() * 0.6;
      final priceImpact = effectiveBodySize / currentPrice * 5;
      final volume =
          (volumeBase * volumeMultiplier * (1 + priceImpact)).round();

      data.add(CandleData(
        date: date,
        open: double.parse(open.toStringAsFixed(2)),
        high: double.parse(high.toStringAsFixed(2)),
        low: double.parse(low.toStringAsFixed(2)),
        close: double.parse(close.toStringAsFixed(2)),
        volume: volume,
      ));

      // Update for next iteration
      recentChanges.insert(0, priceChange);
      if (recentChanges.length > 10) recentChanges.removeLast();
      currentPrice = close;
    }

    return data;
  }

  List<IndicatorDataPoint> _calculateIndicators() {
    final List<IndicatorDataPoint> indicators = [];

    // Process enabled indicators from content
    for (final indicatorConfig in widget.content.indicators) {
      if (indicatorConfig.isVisible) {
        switch (indicatorConfig.type.toUpperCase()) {
          case 'SMA':
            indicators.addAll(_calculateSMA(indicatorConfig.parameters));
            break;
          case 'EMA':
            indicators.addAll(_calculateEMA(indicatorConfig.parameters));
            break;
          case 'RSI':
            indicators.addAll(_calculateRSI(indicatorConfig.parameters));
            break;
          case 'MACD':
            indicators.addAll(_calculateMACD(indicatorConfig.parameters));
            break;
          default:
            // Belirtilen tip tanınmıyorsa atla
            break;
        }
      }
    }

    return indicators;
  }

  List<IndicatorDataPoint> _calculateSMA(Map<String, dynamic> params) {
    final period = params['period'] as int? ?? 20;
    final List<IndicatorDataPoint> smaData = [];

    if (_priceData.length < period) return smaData;

    for (int i = period - 1; i < _priceData.length; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += _priceData[j].close;
      }
      final sma = sum / period;

      smaData.add(IndicatorDataPoint(
        date: _priceData[i].date,
        value: sma,
        type: 'SMA',
        additionalValues: {'period': period.toDouble()},
      ));
    }

    return smaData;
  }

  List<IndicatorDataPoint> _calculateEMA(Map<String, dynamic> params) {
    final period = params['period'] as int? ?? 20;
    final List<IndicatorDataPoint> emaData = [];

    if (_priceData.length < period) return emaData;

    // Calculate initial SMA for first EMA value
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += _priceData[i].close;
    }
    double ema = sum / period;

    emaData.add(IndicatorDataPoint(
      date: _priceData[period - 1].date,
      value: ema,
      type: 'EMA',
      additionalValues: {'period': period.toDouble()},
    ));

    // Calculate EMA for remaining data
    final multiplier = 2.0 / (period + 1);
    for (int i = period; i < _priceData.length; i++) {
      ema = (_priceData[i].close * multiplier) + (ema * (1 - multiplier));

      emaData.add(IndicatorDataPoint(
        date: _priceData[i].date,
        value: ema,
        type: 'EMA',
        additionalValues: {'period': period.toDouble()},
      ));
    }

    return emaData;
  }

  List<IndicatorDataPoint> _calculateRSI(Map<String, dynamic> params) {
    final period = params['period'] as int? ?? 14;
    final List<IndicatorDataPoint> rsiData = [];

    if (_priceData.length < period + 1) return rsiData;

    // Calculate initial average gain and loss
    double avgGain = 0;
    double avgLoss = 0;

    for (int i = 1; i <= period; i++) {
      final change = _priceData[i].close - _priceData[i - 1].close;
      if (change > 0) {
        avgGain += change;
      } else {
        avgLoss += change.abs();
      }
    }

    avgGain /= period;
    avgLoss /= period;

    // Calculate RSI
    for (int i = period; i < _priceData.length; i++) {
      if (i > period) {
        final change = _priceData[i].close - _priceData[i - 1].close;
        final smoothingFactor = 1.0 / period;

        if (change > 0) {
          avgGain = avgGain * (1 - smoothingFactor) + change * smoothingFactor;
          avgLoss = avgLoss * (1 - smoothingFactor);
        } else {
          avgGain = avgGain * (1 - smoothingFactor);
          avgLoss =
              avgLoss * (1 - smoothingFactor) + change.abs() * smoothingFactor;
        }
      }

      final rs =
          avgLoss == 0 ? 100 : avgGain / avgLoss; // Avoid division by zero
      final rsi = 100 - (100 / (1 + rs));

      rsiData.add(IndicatorDataPoint(
        date: _priceData[i].date,
        value: rsi.clamp(0.0, 100.0),
        type: 'RSI',
        additionalValues: {'period': period.toDouble()},
      ));
    }

    return rsiData;
  }

  List<IndicatorDataPoint> _calculateMACD(Map<String, dynamic> params) {
    final fastPeriod = params['fast'] as int? ?? 12;
    final slowPeriod = params['slow'] as int? ?? 26;

    final fastEMA = _calculateEMA({'period': fastPeriod});
    final slowEMA = _calculateEMA({'period': slowPeriod});

    if (fastEMA.isEmpty || slowEMA.isEmpty) return [];

    final List<IndicatorDataPoint> macdData = [];

    for (int i = 0; i < slowEMA.length; i++) {
      final fastIndex = i + (slowPeriod - fastPeriod);
      if (fastIndex >= 0 && fastIndex < fastEMA.length) {
        final macdValue = fastEMA[fastIndex].value - slowEMA[i].value;

        macdData.add(IndicatorDataPoint(
          date: slowEMA[i].date,
          value: macdValue,
          type: 'MACD',
          additionalValues: {
            'fast': fastPeriod.toDouble(),
            'slow': slowPeriod.toDouble(),
          },
        ));
      }
    }

    return macdData;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildChartControls(),
        const SizedBox(height: 12),
        _buildMainChart(),
        if (_indicatorData.any((i) => i.type == 'RSI' || i.type == 'MACD'))
          ...[
            const SizedBox(height: 12),
            _buildIndicatorChart(),
          ],
        const SizedBox(height: 12),
        _buildInteractionStats(),
      ],
    );
  }

  Widget _buildChartControls() {
    return AdaptiveCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.content.symbol,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.content.timeframe} • ${widget.content.chartType.name.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Row(
                  children: [
                    IconButton(
                      onPressed: _refreshData,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Veriyi Yenile',
                    ),
                    IconButton(
                      onPressed: _resetZoom,
                      icon: const Icon(Icons.zoom_out_map),
                      tooltip: 'Yakınlaştırmayı Sıfırla',
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildToggleButton(
                'Hacim',
                _showVolume,
                Icons.bar_chart,
                (value) => setState(() => _showVolume = value),
              ),
              const SizedBox(width: 8),
              _buildToggleButton(
                'Izgara',
                _showGrid,
                Icons.grid_on,
                (value) => setState(() => _showGrid = value),
              ),
              const Spacer(),
              Text(
                '${_priceData.length} veri noktası',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
        _reportInteraction(
            'toggle_${label.toLowerCase().replaceAll('ı', 'i')}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value
              ? AppTheme.accentColor.withOpacity(0.2)
              : AppTheme.cardColorLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? AppTheme.accentColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: value ? AppTheme.accentColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: value ? AppTheme.accentColor : AppTheme.textSecondary,
                fontWeight: value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainChart() {
    if (_isLoading) {
      return AdaptiveCard(
        child: SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Grafik verileri yükleniyor...',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AdaptiveCard(
      child: SizedBox(
        height: 300,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: DateTimeAxis(
                majorGridLines: MajorGridLines(
                  width: _showGrid ? 0.5 : 0,
                  color: AppTheme.textSecondary.withOpacity(0.3),
                ),
                axisLine: const AxisLine(width: 0),
                labelStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
              primaryYAxis: NumericAxis(
                opposedPosition: true,
                majorGridLines: MajorGridLines(
                  width: _showGrid ? 0.5 : 0,
                  color: AppTheme.textSecondary.withOpacity(0.3),
                ),
                axisLine: const AxisLine(width: 0),
                labelStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
                numberFormat: _getNumberFormat(),
              ),
              zoomPanBehavior: _zoomPanBehavior,

              /// Called whenever zooming or panning is in progress.
              onZooming: (ZoomPanArgs args) {
                final prevFactor = args.previousZoomFactor;
                final currFactor = args.currentZoomFactor;

                // Detect zooming if both factors are non-null and changed.
                if (prevFactor != null &&
                    currFactor != null &&
                    (prevFactor - currFactor).abs() > 1e-6) {
                  if (!_hasZoomed) {
                    _hasZoomed = true;
                    _reportInteraction('chart_zoomed');
                  }
                }
                // If factors are equal or null, check for panning via position.
                else {
                  final prevPos = args.previousZoomPosition;
                  final currPos = args.currentZoomPosition;
                  if (prevPos != null &&
                      currPos != null &&
                      prevPos != currPos) {
                    if (!_hasPanned) {
                      _hasPanned = true;
                      _reportInteraction('chart_panned');
                    }
                  }
                }
              },

              /// Called when zoom/pan is reset programmatically veya grafiğin kendi reset butonuyla.
              onZoomReset: (ZoomPanArgs args) {
                _reportInteraction('zoom_reset');
              },
              trackballBehavior: TrackballBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                tooltipSettings: const InteractiveTooltip(
                  enable: true,
                  color: AppTheme.cardColor,
                  textStyle: TextStyle(color: AppTheme.textPrimary),
                ),
              ),
              onTrackballPositionChanging: (TrackballArgs args) {
                if (!_hasUsedTrackball) {
                  _hasUsedTrackball = true;
                  _reportInteraction('trackball_used');
                }
              },
              series: _buildChartSeries(),
            );
          },
        ),
      ),
    );
  }

  NumericAxis _buildIndicatorYAxis() {
    final rsiData = _indicatorData.where((i) => i.type == 'RSI').toList();

    if (rsiData.isNotEmpty) {
      return NumericAxis(
        opposedPosition: true,
        minimum: 0,
        maximum: 100,
        majorGridLines: MajorGridLines(
          width: _showGrid ? 0.5 : 0,
          color: AppTheme.textSecondary.withOpacity(0.3),
        ),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
        ),
        plotBands: <PlotBand>[
          PlotBand(
            start: 70,
            end: 100,
            color: AppTheme.negativeColor.withOpacity(0.1),
          ),
          PlotBand(
            start: 0,
            end: 30,
            color: AppTheme.positiveColor.withOpacity(0.1),
          ),
        ],
      );
    }

    return NumericAxis(
      opposedPosition: true,
      majorGridLines: MajorGridLines(
        width: _showGrid ? 0.5 : 0,
        color: AppTheme.textSecondary.withOpacity(0.3),
      ),
      axisLine: const AxisLine(width: 0),
      labelStyle: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 10,
      ),
    );
  }

  Widget _buildIndicatorChart() {
    final rsiData = _indicatorData.where((i) => i.type == 'RSI').toList();
    final macdData = _indicatorData.where((i) => i.type == 'MACD').toList();

    if (rsiData.isEmpty && macdData.isEmpty) return const SizedBox.shrink();

    return AdaptiveCard(
      child: SizedBox(
        height: 150,
        child: SfCartesianChart(
          plotAreaBorderWidth: 0,
          primaryXAxis: DateTimeAxis(
            majorGridLines: MajorGridLines(
              width: _showGrid ? 0.5 : 0,
              color: AppTheme.textSecondary.withOpacity(0.3),
            ),
            axisLine: const AxisLine(width: 0),
            labelStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
          primaryYAxis: _buildIndicatorYAxis(),
          series: _buildIndicatorSeries(),
          trackballBehavior: TrackballBehavior(
            enable: true,
            activationMode: ActivationMode.singleTap,
            tooltipSettings: const InteractiveTooltip(
              enable: true,
              color: AppTheme.cardColor,
              textStyle: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionStats() {
    return AdaptiveCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics,
                size: 16,
                color: AppTheme.accentColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Etkileşim İstatistikleri',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip('Toplam Etkileşim', _totalInteractions.toString()),
              _buildStatChip('Yakınlaştırma', _hasZoomed ? '✓' : '✗'),
              _buildStatChip('Kaydırma', _hasPanned ? '✓' : '✗'),
              _buildStatChip('Trackball', _hasUsedTrackball ? '✓' : '✗'),
            ],
          ),
          if (_totalInteractions >= 5) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.positiveColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppTheme.positiveColor,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Harika! Grafikle yeterince etkileşim kurdunuz.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.positiveColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardColorLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  List<CartesianSeries> _buildChartSeries() {
    final List<CartesianSeries> series = [];

    switch (widget.content.chartType) {
      case ChartType.candlestick:
        series.add(CandleSeries<CandleData, DateTime>(
          dataSource: _priceData,
          xValueMapper: (CandleData data, _) => data.date,
          lowValueMapper: (CandleData data, _) => data.low,
          highValueMapper: (CandleData data, _) => data.high,
          openValueMapper: (CandleData data, _) => data.open,
          closeValueMapper: (CandleData data, _) => data.close,
          bullColor: AppTheme.positiveColor,
          bearColor: AppTheme.negativeColor,
          enableSolidCandles: true,
          name: 'Fiyat',
          animationDuration: _animationController.isAnimating ? 1500 : 0,
        ));
        break;
      case ChartType.line:
        series.add(LineSeries<CandleData, DateTime>(
          dataSource: _priceData,
          xValueMapper: (CandleData data, _) => data.date,
          yValueMapper: (CandleData data, _) => data.close,
          color: AppTheme.accentColor,
          width: 2,
          name: 'Kapanış',
          animationDuration: _animationController.isAnimating ? 1500 : 0,
        ));
        break;
      case ChartType.area:
        series.add(AreaSeries<CandleData, DateTime>(
          dataSource: _priceData,
          xValueMapper: (CandleData data, _) => data.date,
          yValueMapper: (CandleData data, _) => data.close,
          color: AppTheme.accentColor.withOpacity(0.3),
          borderColor: AppTheme.accentColor,
          borderWidth: 2,
          name: 'Kapanış',
          animationDuration: _animationController.isAnimating ? 1500 : 0,
        ));
        break;
      case ChartType.indicator:
        // Bu durumda sadece indikatör serileri çizilecek, fiyat serisi eklenmiyor.
        break;
    }

    final smaData = _indicatorData.where((i) => i.type == 'SMA').toList();
    final emaData = _indicatorData.where((i) => i.type == 'EMA').toList();

    if (smaData.isNotEmpty) {
      series.add(LineSeries<IndicatorDataPoint, DateTime>(
        dataSource: smaData,
        xValueMapper: (IndicatorDataPoint data, _) => data.date,
        yValueMapper: (IndicatorDataPoint data, _) => data.value,
        color: Colors.blue,
        width: 2,
        name: 'SMA(${smaData.first.additionalValues['period']?.toInt()})',
        dashArray: const [5, 5],
        animationDuration: _animationController.isAnimating ? 1500 : 0,
      ));
    }

    if (emaData.isNotEmpty) {
      series.add(LineSeries<IndicatorDataPoint, DateTime>(
        dataSource: emaData,
        xValueMapper: (IndicatorDataPoint data, _) => data.date,
        yValueMapper: (IndicatorDataPoint data, _) => data.value,
        color: Colors.orange,
        width: 2,
        name: 'EMA(${emaData.first.additionalValues['period']?.toInt()})',
        animationDuration: _animationController.isAnimating ? 1500 : 0,
      ));
    }

    if (_showVolume && widget.content.chartType == ChartType.candlestick) {
      series.add(ColumnSeries<CandleData, DateTime>(
        dataSource: _priceData,
        xValueMapper: (CandleData data, _) => data.date,
        yValueMapper: (CandleData data, _) => data.volume.toDouble(),
        name: 'Hacim',
        color: AppTheme.textSecondary.withOpacity(0.4),
        width: 0.8,
        animationDuration: _animationController.isAnimating ? 1500 : 0,
      ));
    }

    return series;
  }

  List<CartesianSeries> _buildIndicatorSeries() {
    final List<CartesianSeries> series = [];

    final rsiData = _indicatorData.where((i) => i.type == 'RSI').toList();
    final macdData = _indicatorData.where((i) => i.type == 'MACD').toList();

    if (rsiData.isNotEmpty) {
      series.add(LineSeries<IndicatorDataPoint, DateTime>(
        dataSource: rsiData,
        xValueMapper: (IndicatorDataPoint data, _) => data.date,
        yValueMapper: (IndicatorDataPoint data, _) => data.value,
        color: AppTheme.warningColor,
        width: 2,
        name: 'RSI(${rsiData.first.additionalValues['period']?.toInt()})',
        animationDuration: _animationController.isAnimating ? 1500 : 0,
      ));
    }

    if (macdData.isNotEmpty) {
      series.add(LineSeries<IndicatorDataPoint, DateTime>(
        dataSource: macdData,
        xValueMapper: (IndicatorDataPoint data, _) => data.date,
        yValueMapper: (IndicatorDataPoint data, _) => data.value,
        color: AppTheme.accentColor,
        width: 2,
        name: 'MACD',
        animationDuration: _animationController.isAnimating ? 1500 : 0,
      ));
    }

    return series;
  }

  void _refreshData() {
    _animationController.reset();
    _loadChartData();
    _reportInteraction('data_refresh');
  }

  void _resetZoom() {
    _zoomPanBehavior.reset(); // Reset zoom/pan on the chart
    _reportInteraction('zoom_reset_manual');
  }

  void _reportInteraction(String type) {
    _totalInteractions++;
    widget.onInteraction({
      'action': type,
      'total_interactions': _totalInteractions,
      'has_zoomed': _hasZoomed,
      'has_panned': _hasPanned,
      'has_used_trackball': _hasUsedTrackball,
      'chart_type': widget.content.chartType.name,
      'symbol': widget.content.symbol,
    });
    if (mounted) setState(() {});
  }

  // Helper methods
  double _getBasePriceForSymbol(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'BTC/USD':
      case 'BTCUSD':
        return 45000;
      case 'ETH/USD':
      case 'ETHUSD':
        return 3000;
      case 'AAPL':
        return 180;
      case 'TSLA':
        return 250;
      default:
        return 100;
    }
  }

  int _getVolumeBase(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'BTC/USD':
      case 'BTCUSD':
        return 1000000;
      case 'ETH/USD':
      case 'ETHUSD':
        return 5000000;
      default:
        return 2000000;
    }
  }

  int _getDataPointsForTimeframe(String timeframe) {
    switch (timeframe.toLowerCase()) {
      case 'dakikalık':
      case '1m':
        return 200;
      case 'saatlik':
      case '1h':
        return 168; // 1 week
      case 'günlük':
      case '1d':
        return 100; // ~3 months
      case 'haftalık':
      case '1w':
        return 52; // 1 year
      default:
        return 100;
    }
  }

  int _getTimeInterval(String timeframe) {
    switch (timeframe.toLowerCase()) {
      case 'dakikalık':
      case '1m':
        return 60 * 1000; // 1 minute in milliseconds
      case 'saatlik':
      case '1h':
        return 60 * 60 * 1000; // 1 hour
      case 'günlük':
      case '1d':
        return 24 * 60 * 60 * 1000; // 1 day
      case 'haftalık':
      case '1w':
        return 7 * 24 * 60 * 60 * 1000; // 1 week
      default:
        return 24 * 60 * 60 * 1000;
    }
  }

  double _getVolatilityForHour(int hour) {
    if (hour >= 9 && hour <= 16) {
      return 1.2;
    } else if (hour >= 17 && hour <= 20) {
      return 0.8;
    } else {
      return 0.4;
    }
  }

  double _generateGaussianNoise(math.Random random) {
    double u1 = random.nextDouble();
    while (u1 == 0) {
      u1 = random.nextDouble();
    }
    final u2 = random.nextDouble();
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
  }

  NumberFormat _getNumberFormat() {
    final basePrice = _getBasePriceForSymbol(widget.content.symbol);
    if (basePrice > 1000) {
      return NumberFormat('#,##0');
    } else if (basePrice > 1) {
      return NumberFormat('#,##0.00');
    } else {
      return NumberFormat('#,##0.0000');
    }
  }
}

class IndicatorDataPoint {
  final DateTime date;
  final double value;
  final String type;
  final Map<String, double> additionalValues;

  IndicatorDataPoint({
    required this.date,
    required this.value,
    required this.type,
    this.additionalValues = const {},
  });
}

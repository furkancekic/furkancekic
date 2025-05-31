// screens/education/widgets/interactive_education_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';
import '../../../models/candle_data.dart';

class InteractiveEducationChartWidget extends StatefulWidget {
  final String
      indicatorType; // 'rsi', 'macd', 'stochastic', 'bollingerBands', 'fibonacci'
  final String title;
  final String description;
  final List<String> learningPoints;
  final Function(Map<String, dynamic>) onLearningProgress;

  const InteractiveEducationChartWidget({
    Key? key,
    required this.indicatorType,
    required this.title,
    required this.description,
    required this.learningPoints,
    required this.onLearningProgress,
  }) : super(key: key);

  @override
  State<InteractiveEducationChartWidget> createState() =>
      _InteractiveEducationChartWidgetState();
}

class PricePattern {
  final String name;
  final List<double> multipliers;
  final double volatility;
  final double trendStrength;

  PricePattern({
    required this.name,
    required this.multipliers,
    required this.volatility,
    required this.trendStrength,
  });
}

class _InteractiveEducationChartWidgetState
    extends State<InteractiveEducationChartWidget>
    with TickerProviderStateMixin {
  List<CandleData> _priceData = [];
  List<IndicatorDataPoint> _indicatorData = [];
  bool _isLoading = true;
  int _currentScenario = 0;
  bool _showExplanations = true;
  bool _isPlaying = false;
  int _currentDataIndex = 0;
  double? _gaussianSpare;

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Interactive controls
  Map<String, double> _parameters = {};
  List<String> _completedLearningPoints = [];

  // Scenario management
  late List<EducationScenario> _scenarios;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeScenarios();
    _initializeParameters();
    _loadData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _initializeScenarios() {
    switch (widget.indicatorType) {
      case 'rsi':
        _scenarios = _createRSIScenarios();
        break;
      case 'macd':
        _scenarios = _createMACDScenarios();
        break;
      case 'stochastic':
        _scenarios = _createStochasticScenarios();
        break;
      case 'bollingerBands':
        _scenarios = _createBollingerScenarios();
        break;
      default:
        _scenarios = _createRSIScenarios();
    }
  }

  void _initializeParameters() {
    switch (widget.indicatorType) {
      case 'rsi':
        _parameters = {'period': 14.0, 'overbought': 70.0, 'oversold': 30.0};
        break;
      case 'macd':
        _parameters = {'fast': 12.0, 'slow': 26.0, 'signal': 9.0};
        break;
      case 'stochastic':
        _parameters = {
          'kPeriod': 14.0,
          'dPeriod': 3.0,
          'overbought': 80.0,
          'oversold': 20.0
        };
        break;
      case 'bollingerBands':
        _parameters = {'period': 20.0, 'standardDeviation': 2.0};
        break;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;

    return Column(
      children: [
        _buildHeader(themeExtension),
        const SizedBox(height: 12),
        _buildScenarioSelector(themeExtension),
        const SizedBox(height: 12),
        _buildMainChart(themeExtension),
        const SizedBox(height: 12),
        _buildIndicatorChart(themeExtension),
        const SizedBox(height: 12),
        _buildControlPanel(themeExtension),
        const SizedBox(height: 12),
        _buildLearningPanel(themeExtension),
      ],
    );
  }

  Widget _buildHeader(AppThemeExtension themeExtension) {
    return AdaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeExtension.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIndicatorIcon(),
                  color: themeExtension.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeExtension.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeExtension.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: IconButton(
                      onPressed: _toggleExplanations,
                      icon: Icon(
                        _showExplanations
                            ? Icons.lightbulb
                            : Icons.lightbulb_outline,
                        color: themeExtension.warningColor,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (_showExplanations) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeExtension.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: themeExtension.warningColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                _getCurrentScenarioExplanation(),
                style: TextStyle(
                  fontSize: 13,
                  color: themeExtension.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScenarioSelector(AppThemeExtension themeExtension) {
    return AdaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Eğitim Senaryoları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeExtension.textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _isPlaying ? _pauseAnimation : _playAnimation,
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: themeExtension.accentColor,
                    ),
                  ),
                  IconButton(
                    onPressed: _resetAnimation,
                    icon: Icon(
                      Icons.refresh,
                      color: themeExtension.accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _scenarios.length,
              itemBuilder: (context, index) {
                final scenario = _scenarios[index];
                final isSelected = index == _currentScenario;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _selectScenario(index),
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeExtension.accentColor.withOpacity(0.2)
                            : themeExtension.cardColorLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? themeExtension.accentColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scenario.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? themeExtension.accentColor
                                  : themeExtension.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scenario.description,
                            style: TextStyle(
                              fontSize: 10,
                              color: themeExtension.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart(AppThemeExtension themeExtension) {
    if (_isLoading) {
      return AdaptiveCard(
        child: SizedBox(
          height: 250,
          child: Center(
            child: CircularProgressIndicator(
              color: themeExtension.accentColor,
            ),
          ),
        ),
      );
    }

    return AdaptiveCard(
      child: SizedBox(
        height: 250,
        child: SfCartesianChart(
          plotAreaBorderWidth: 0,
          primaryXAxis: DateTimeAxis(
            majorGridLines: MajorGridLines(
              width: 0.5,
              color: themeExtension.textSecondary.withOpacity(0.3),
            ),
            axisLine: const AxisLine(width: 0),
            labelStyle: TextStyle(
              color: themeExtension.textSecondary,
              fontSize: 10,
            ),
          ),
          primaryYAxis: NumericAxis(
            opposedPosition: true,
            majorGridLines: MajorGridLines(
              width: 0.5,
              color: themeExtension.textSecondary.withOpacity(0.3),
            ),
            axisLine: const AxisLine(width: 0),
            labelStyle: TextStyle(
              color: themeExtension.textSecondary,
              fontSize: 10,
            ),
          ),
          zoomPanBehavior: ZoomPanBehavior(
            enablePinching: true,
            enablePanning: true,
            enableDoubleTapZooming: true,
          ),
          trackballBehavior: TrackballBehavior(
            enable: true,
            activationMode: ActivationMode.singleTap,
            tooltipSettings: InteractiveTooltip(
              enable: true,
              color: themeExtension.cardColor,
              textStyle: TextStyle(color: themeExtension.textPrimary),
            ),
          ),
          series: _buildPriceSeries(themeExtension),
        ),
      ),
    );
  }

  Widget _buildIndicatorChart(AppThemeExtension themeExtension) {
    if (_isLoading || _indicatorData.isEmpty) {
      return const SizedBox.shrink();
    }

    return AdaptiveCard(
      child: SizedBox(
        height: 200,
        child: SfCartesianChart(
          plotAreaBorderWidth: 0,
          primaryXAxis: DateTimeAxis(
            majorGridLines: MajorGridLines(
              width: 0.5,
              color: themeExtension.textSecondary.withOpacity(0.3),
            ),
            axisLine: const AxisLine(width: 0),
            labelStyle: TextStyle(
              color: themeExtension.textSecondary,
              fontSize: 10,
            ),
          ),
          primaryYAxis: _buildIndicatorYAxis(themeExtension),
          series: _buildIndicatorSeries(themeExtension),
        ),
      ),
    );
  }

  Widget _buildControlPanel(AppThemeExtension themeExtension) {
    return AdaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parametre Ayarları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeExtension.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._parameters.entries.map((entry) => _buildParameterSlider(
                entry.key,
                entry.value,
                themeExtension,
              )),
        ],
      ),
    );
  }

  Widget _buildParameterSlider(
      String paramName, double value, AppThemeExtension themeExtension) {
    final ranges = _getParameterRanges(paramName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getParameterDisplayName(paramName),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: themeExtension.textPrimary,
                ),
              ),
              Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeExtension.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: themeExtension.accentColor,
              inactiveTrackColor: themeExtension.textSecondary.withOpacity(0.3),
              thumbColor: themeExtension.accentColor,
              overlayColor: themeExtension.accentColor.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: ranges['min']!,
              max: ranges['max']!,
              divisions: (ranges['max']! - ranges['min']!).toInt(),
              onChanged: (newValue) {
                setState(() {
                  _parameters[paramName] = newValue;
                });
                _recalculateIndicator();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPanel(AppThemeExtension themeExtension) {
    return AdaptiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: themeExtension.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Öğrenme Noktaları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeExtension.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_completedLearningPoints.length}/${widget.learningPoints.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: themeExtension.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: widget.learningPoints.isEmpty
                ? 0.0
                : _completedLearningPoints.length /
                    widget.learningPoints.length,
            backgroundColor: themeExtension.textSecondary.withOpacity(0.2),
            valueColor:
                AlwaysStoppedAnimation<Color>(themeExtension.accentColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 16),
          ...widget.learningPoints.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            final isCompleted = _completedLearningPoints.contains(point);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? themeExtension.positiveColor
                          : themeExtension.textSecondary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: themeExtension.textPrimary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _markLearningPointCompleted(point),
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: 13,
                          color: isCompleted
                              ? themeExtension.textSecondary
                              : themeExtension.textPrimary,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_completedLearningPoints.length ==
              widget.learningPoints.length) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeExtension.positiveColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: themeExtension.positiveColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration,
                    color: themeExtension.positiveColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tebrikler! Tüm öğrenme noktalarını tamamladınız.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: themeExtension.positiveColor,
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

  // Data generation methods
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    _priceData = _generatePriceData();
    _indicatorData = _calculateIndicatorData();

    setState(() {
      _isLoading = false;
    });

    widget.onLearningProgress({
      'action': 'data_loaded',
      'indicator': widget.indicatorType,
      'scenario': _currentScenario,
    });
  }

  List<CandleData> _generatePriceData() {
    final scenario = _scenarios[_currentScenario];
    final List<CandleData> data = [];
    final now = DateTime.now();
    final random = math.Random();

    double price = 100.0;
    final dataCount =
        50; // Veri sayısını azalttık - daha az mum, daha net görünüm

    // Momentum ve trend takibi için
    double momentum = 0.0;
    double trendDirection = 0.0;
    List<double> recentChanges = [];

    for (int i = 0; i < dataCount; i++) {
      final date = now.subtract(
          Duration(days: dataCount - i)); // Günlük veri (saatlik yerine)

      // Senaryo etkisini kademeli olarak uygula
      double scenarioEffect =
          scenario.pattern(i, dataCount) * 0.4; // Etkiyi artırdık

      // Momentum hesapla (önceki hareketlerin etkisi)
      if (recentChanges.length >= 3) {
        momentum = recentChanges.take(3).reduce((a, b) => a + b) / 3;
        momentum *= 0.6; // Momentum azalması
      }

      // Trend yönü hesapla
      if (recentChanges.length >= 5) {
        final recentAvg = recentChanges.take(5).reduce((a, b) => a + b) / 5;
        trendDirection = recentAvg.clamp(-0.8, 0.8);
      }

      // Mean reversion etkisi (fiyatın ortalamaya dönme eğilimi)
      final priceDeviation = price - 100.0;
      double meanReversionForce = -priceDeviation * 0.015;

      // Volatilite hesaplama (daha belirgin)
      double baseVolatility = 1.2;
      if (recentChanges.length >= 3) {
        final recentVolatility =
            recentChanges.take(3).map((e) => e.abs()).reduce((a, b) => a + b) /
                3;
        baseVolatility = (baseVolatility + recentVolatility).clamp(0.8, 2.5);
      }

      // Gaussian gürültü (daha belirgin)
      double noise = _generateGaussianNoise(random) * baseVolatility * 0.5;

      // Support/resistance seviyeleri
      double supportResistanceEffect = _calculateSmoothSupportResistance(price);

      // Toplam değişim (daha dengeli)
      double totalChange = (scenarioEffect * 0.35) + // Senaryo etkisi
          (momentum * 0.25) + // Momentum etkisi
          (trendDirection * 0.20) + // Trend etkisi
          (meanReversionForce * 0.10) + // Mean reversion
          (supportResistanceEffect * 0.10); // Support/resistance

      // Volatilite ile değişimi güçlendir
      totalChange += noise;

      // Değişimi sınırla (daha geniş aralık)
      totalChange =
          totalChange.clamp(-baseVolatility * 2.0, baseVolatility * 2.0);

      // Anti-bubble mechanism
      if (price > 140) totalChange = math.min(totalChange, -0.5);
      if (price < 60) totalChange = math.max(totalChange, 0.5);

      final open = price;
      double close = price + totalChange;

      // Minimum fiyat koruması
      close = math.max(close, 10.0);

      // Daha belirgin High/Low hesaplama (mumların daha büyük görünmesi için)
      final bodySize = (close - open).abs();
      final minBodySize = price * 0.008; // Minimum gövde boyutu (%0.8)
      final effectiveBodySize = math.max(bodySize, minBodySize);

      // Wick boyutları (daha belirgin)
      final wickMultiplier = 0.8 + random.nextDouble() * 1.2;
      final wickSize = effectiveBodySize * wickMultiplier;

      double high, low;
      if (close >= open) {
        // Yükseliş mumu (yeşil)
        high = close + wickSize * (0.4 + random.nextDouble() * 0.6);
        low = open - wickSize * (0.3 + random.nextDouble() * 0.4);
      } else {
        // Düşüş mumu (kırmızı)
        high = open + wickSize * (0.3 + random.nextDouble() * 0.4);
        low = close - wickSize * (0.4 + random.nextDouble() * 0.6);
      }

      // Sınırları kontrol et
      low = math.max(low, 10.0);
      high = math.max(high, math.max(open, close));
      if (high < low) high = low + 0.1;

      // Eğer mum çok küçükse, biraz büyüt
      if ((high - low) < price * 0.01) {
        final expansion = price * 0.005;
        high += expansion;
        low -= expansion;
        low = math.max(low, 10.0);
      }

      // Hacim hesapla (volatiliteye bağlı)
      final volumeBase = 500000;
      final priceChangeImpact = effectiveBodySize / price * 8;
      final volumeMultiplier =
          1 + priceChangeImpact + (random.nextDouble() * 0.8);
      final volume = (volumeBase * volumeMultiplier).round();

      data.add(CandleData(
        date: date,
        open: double.parse(open.toStringAsFixed(2)),
        high: double.parse(high.toStringAsFixed(2)),
        low: double.parse(low.toStringAsFixed(2)),
        close: double.parse(close.toStringAsFixed(2)),
        volume: volume,
      ));

      // Geçmiş değişimleri takip et
      recentChanges.insert(0, totalChange);
      if (recentChanges.length > 10) {
        recentChanges.removeLast();
      }

      price = close;
    }

    return data;
  }

  double _calculateSmoothSupportResistance(double currentPrice) {
    // Daha yumuşak support/resistance seviyeleri
    final levels = [80.0, 90.0, 100.0, 110.0, 120.0];
    double effect = 0.0;

    for (final level in levels) {
      final distance = (currentPrice - level).abs();
      if (distance < 5.0) {
        final strength = (5.0 - distance) / 5.0;
        final direction = currentPrice > level ? -1.0 : 1.0;
        effect += direction * strength * 0.1;
      }
    }

    return effect;
  }

  List<PricePattern> _getMarketPatterns() {
    return [
      // Trending Bull Market
      PricePattern(
        name: 'Bull Trend',
        multipliers: [1.0, 1.2, 1.1, 1.3, 1.0, 1.4, 1.2, 1.1],
        volatility: 1.2,
        trendStrength: 0.8,
      ),

      // Ranging Market
      PricePattern(
        name: 'Sideways',
        multipliers: [1.0, 0.9, 1.1, 0.95, 1.05, 0.98, 1.02, 1.0],
        volatility: 0.8,
        trendStrength: 0.1,
      ),

      // Volatile Market
      PricePattern(
        name: 'High Volatility',
        multipliers: [1.0, 1.5, 0.7, 1.3, 0.8, 1.4, 0.9, 1.2],
        volatility: 2.5,
        trendStrength: 0.3,
      ),

      // Bear Trend
      PricePattern(
        name: 'Bear Trend',
        multipliers: [1.0, 0.8, 0.9, 0.7, 1.0, 0.6, 0.8, 0.9],
        volatility: 1.5,
        trendStrength: -0.8,
      ),

      // Accumulation Phase
      PricePattern(
        name: 'Accumulation',
        multipliers: [1.0, 0.98, 1.01, 0.99, 1.005, 0.995, 1.002, 1.0],
        volatility: 0.5,
        trendStrength: 0.2,
      ),
    ];
  }

  double _calculatePatternEffect(PricePattern pattern, double progress) {
    final index = (progress * (pattern.multipliers.length - 1)).floor();
    final nextIndex = math.min(index + 1, pattern.multipliers.length - 1);
    final fraction = (progress * (pattern.multipliers.length - 1)) - index;

    final current = pattern.multipliers[index];
    final next = pattern.multipliers[nextIndex];

    // Linear interpolation
    final multiplier = current + (next - current) * fraction;

    return (multiplier - 1.0) * pattern.volatility;
  }

  double _calculateTimeBasedVolatility(DateTime date) {
    final hour = date.hour;

    // Piyasa açılışı ve kapanışında daha yüksek volatilite
    if (hour >= 9 && hour <= 11) return 1.5; // Açılış
    if (hour >= 15 && hour <= 17) return 1.3; // Kapanış
    if (hour >= 12 && hour <= 14) return 0.8; // Öğle arası
    return 1.0; // Normal saatler
  }

// Sınıf seviyesinde spare değişkenini tanımlayın

  double _generateGaussianNoise(math.Random random) {
    // Box-Muller dönüşümü ile Gaussian gürültü
    if (_gaussianSpare != null) {
      final result = _gaussianSpare!;
      _gaussianSpare = null;
      return result;
    }

    final u = random.nextDouble();
    final v = random.nextDouble();
    final mag = math.sqrt(-2.0 * math.log(u));
    _gaussianSpare = mag * math.cos(2.0 * math.pi * v);
    return mag * math.sin(2.0 * math.pi * v);
  }

  double _calculateTrendEffect(List<CandleData> data, double trendStrength) {
    if (data.length < 10) return 0.0;

    // Son 10 mumun trend yönünü hesapla
    final recentData = data.skip(math.max(0, data.length - 10)).toList();
    double trendSum = 0.0;

    for (int i = 1; i < recentData.length; i++) {
      final change = recentData[i].close - recentData[i - 1].close;
      trendSum += change;
    }

    final avgTrend = trendSum / (recentData.length - 1);
    return avgTrend * trendStrength * 0.1;
  }

  double _calculateSupportResistanceEffect(double currentPrice, int index) {
    // Basit destek/direnç seviyeleri
    final supportLevels = [95.0, 100.0, 105.0, 110.0, 115.0];

    for (final level in supportLevels) {
      final distance = (currentPrice - level).abs();
      if (distance < 2.0) {
        // Seviyeye yakınsa, seviyeden uzaklaşma eğilimi
        final direction = currentPrice > level ? -1.0 : 1.0;
        final strength = (2.0 - distance) / 2.0;
        return direction * strength * 0.5;
      }
    }

    return 0.0;
  }

  List<IndicatorDataPoint> _calculateIndicatorData() {
    switch (widget.indicatorType) {
      case 'rsi':
        return _calculateRSI();
      case 'macd':
        return _calculateMACD();
      case 'stochastic':
        return _calculateStochastic();
      case 'bollingerBands':
        return _calculateBollingerBands();
      default:
        return [];
    }
  }

  // RSI hesaplama metodunu da iyileştirin
  List<IndicatorDataPoint> _calculateRSI() {
    final List<IndicatorDataPoint> rsiData = [];
    final period = _parameters['period']!.toInt();

    if (_priceData.length < period + 1) return rsiData;

    // İlk RSI değeri için basit hesaplama
    double avgGain = 0;
    double avgLoss = 0;

    // İlk periyot için ortalama kazanç/kayıp hesapla
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

    // Sıfır bölme koruması
    if (avgLoss == 0) avgLoss = 0.000001;
    if (avgGain == 0) avgGain = 0.000001;

    // İlk RSI değeri
    double rs = avgGain / avgLoss;
    double rsi = 100 - (100 / (1 + rs));

    rsiData.add(IndicatorDataPoint(
      date: _priceData[period].date,
      value: rsi.clamp(0.0, 100.0), // RSI sınırlarını kontrol et
      additionalValues: {},
    ));

    // Wilder's smoothing method ile devam et (daha yumuşak RSI)
    for (int i = period + 1; i < _priceData.length; i++) {
      final change = _priceData[i].close - _priceData[i - 1].close;

      // Wilder's smoothing - exponential moving average benzeri
      final smoothingFactor = 1.0 / period;

      if (change > 0) {
        avgGain = avgGain * (1 - smoothingFactor) + change * smoothingFactor;
        avgLoss = avgLoss * (1 - smoothingFactor);
      } else {
        avgGain = avgGain * (1 - smoothingFactor);
        avgLoss =
            avgLoss * (1 - smoothingFactor) + change.abs() * smoothingFactor;
      }

      // Sıfır bölme koruması
      if (avgLoss < 0.000001) avgLoss = 0.000001;
      if (avgGain < 0.000001) avgGain = 0.000001;

      rs = avgGain / avgLoss;
      rsi = 100 - (100 / (1 + rs));

      // RSI değerini sınırla ve yumuşak geçişler için
      rsi = rsi.clamp(0.0, 100.0);

      // Eğer önceki değerle çok farklıysa, geçişi yumuşat
      if (rsiData.isNotEmpty) {
        final previousRSI = rsiData.last.value;
        final maxChange = 15.0; // Maksimum RSI değişimi

        if ((rsi - previousRSI).abs() > maxChange) {
          if (rsi > previousRSI) {
            rsi = previousRSI + maxChange;
          } else {
            rsi = previousRSI - maxChange;
          }
        }
      }

      rsiData.add(IndicatorDataPoint(
        date: _priceData[i].date,
        value: rsi,
        additionalValues: {},
      ));
    }

    return rsiData;
  }

// MACD hesaplama metodunu da iyileştirin
  List<IndicatorDataPoint> _calculateMACD() {
    final List<IndicatorDataPoint> macdData = [];
    final fastPeriod = _parameters['fast']!.toInt();
    final slowPeriod = _parameters['slow']!.toInt();
    final signalPeriod = _parameters['signal']!.toInt();

    if (_priceData.length < slowPeriod) return macdData;

    // EMA hesaplama fonksiyonu
    List<double> calculateEMA(List<double> prices, int period) {
      final List<double> ema = [];
      final multiplier = 2.0 / (period + 1);

      // İlk değer SMA
      double sum = 0;
      for (int i = 0; i < period; i++) {
        sum += prices[i];
      }
      ema.add(sum / period);

      // EMA hesapla
      for (int i = period; i < prices.length; i++) {
        final newEma = (prices[i] * multiplier) + (ema.last * (1 - multiplier));
        ema.add(newEma);
      }

      return ema;
    }

    // Kapanış fiyatlarını al
    final closePrices = _priceData.map((e) => e.close).toList();

    // Fast ve Slow EMA hesapla
    final fastEMA = calculateEMA(
        closePrices.skip(slowPeriod - fastPeriod).toList(), fastPeriod);
    final slowEMA = calculateEMA(closePrices, slowPeriod);

    // MACD çizgisini hesapla
    final macdLine = <double>[];
    for (int i = 0; i < slowEMA.length; i++) {
      macdLine.add(fastEMA[i] - slowEMA[i]);
    }

    // Signal çizgisini hesapla (MACD'nin EMA'sı)
    final signalLine = calculateEMA(macdLine, signalPeriod);

    // MACD verilerini oluştur
    final startIndex = slowPeriod - 1 + signalPeriod - 1;
    for (int i = 0; i < signalLine.length; i++) {
      final dataIndex = startIndex + i;
      if (dataIndex < _priceData.length) {
        final histogram = macdLine[signalPeriod - 1 + i] - signalLine[i];

        macdData.add(IndicatorDataPoint(
          date: _priceData[dataIndex].date,
          value: macdLine[signalPeriod - 1 + i],
          additionalValues: {
            'signal': signalLine[i],
            'histogram': histogram,
          },
        ));
      }
    }

    return macdData;
  }

  List<IndicatorDataPoint> _calculateStochastic() {
    // Simplified Stochastic calculation
    final List<IndicatorDataPoint> stochData = [];
    final period = _parameters['kPeriod']!.toInt();

    if (_priceData.length < period) return stochData;

    for (int i = period - 1; i < _priceData.length; i++) {
      double highest = _priceData[i - period + 1].high;
      double lowest = _priceData[i - period + 1].low;

      for (int j = i - period + 1; j <= i; j++) {
        highest = math.max(highest, _priceData[j].high);
        lowest = math.min(lowest, _priceData[j].low);
      }

      final currentClose = _priceData[i].close;
      final k = ((currentClose - lowest) / (highest - lowest)) * 100;

      stochData.add(IndicatorDataPoint(
        date: _priceData[i].date,
        value: k,
        additionalValues: {'d': k * 0.9}, // Simplified %D
      ));
    }

    return stochData;
  }

  List<IndicatorDataPoint> _calculateBollingerBands() {
    // Simplified Bollinger Bands calculation
    final List<IndicatorDataPoint> bbData = [];
    final period = _parameters['period']!.toInt();
    final stdDev = _parameters['standardDeviation']!;

    if (_priceData.length < period) return bbData;

    for (int i = period - 1; i < _priceData.length; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += _priceData[j].close;
      }
      final sma = sum / period;

      double variance = 0;
      for (int j = i - period + 1; j <= i; j++) {
        variance += math.pow(_priceData[j].close - sma, 2);
      }
      final standardDeviation = math.sqrt(variance / period);

      final upperBand = sma + (stdDev * standardDeviation);
      final lowerBand = sma - (stdDev * standardDeviation);

      bbData.add(IndicatorDataPoint(
        date: _priceData[i].date,
        value: sma,
        additionalValues: {
          'upper': upperBand,
          'lower': lowerBand,
        },
      ));
    }

    return bbData;
  }

  // Animation methods
  void _playAnimation() {
    setState(() {
      _isPlaying = true;
    });

    _animationController.forward().then((_) {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  void _pauseAnimation() {
    setState(() {
      _isPlaying = false;
    });
    _animationController.stop();
  }

  void _resetAnimation() {
    _animationController.reset();
    setState(() {
      _isPlaying = false;
      _currentDataIndex = 0;
    });
  }

  void _selectScenario(int index) {
    setState(() {
      _currentScenario = index;
      _currentDataIndex = 0;
    });
    _loadData();
  }

  void _toggleExplanations() {
    setState(() {
      _showExplanations = !_showExplanations;
    });
  }

  void _recalculateIndicator() {
    _indicatorData = _calculateIndicatorData();
    setState(() {});
  }

  void _markLearningPointCompleted(String point) {
    if (!_completedLearningPoints.contains(point)) {
      setState(() {
        _completedLearningPoints.add(point);
      });

      widget.onLearningProgress({
        'action': 'learning_point_completed',
        'point': point,
        'total_completed': _completedLearningPoints.length,
        'total_points': widget.learningPoints.length,
      });

      if (_completedLearningPoints.length == widget.learningPoints.length) {
        widget.onLearningProgress({
          'action': 'all_learning_points_completed',
          'indicator': widget.indicatorType,
        });
      }
    }
  }

  // Chart building methods
  List<CartesianSeries<CandleData, DateTime>> _buildPriceSeries(
      AppThemeExtension themeExtension) {
    return [
      CandleSeries<CandleData, DateTime>(
        dataSource: _priceData,
        xValueMapper: (CandleData data, _) => data.date,
        lowValueMapper: (CandleData data, _) => data.low,
        highValueMapper: (CandleData data, _) => data.high,
        openValueMapper: (CandleData data, _) => data.open,
        closeValueMapper: (CandleData data, _) => data.close,
        bullColor: themeExtension.positiveColor,
        bearColor: themeExtension.negativeColor,
        enableSolidCandles: true,
        name: 'Price',
      ),
    ];
  }

  List<CartesianSeries<IndicatorDataPoint, DateTime>> _buildIndicatorSeries(
      AppThemeExtension themeExtension) {
    switch (widget.indicatorType) {
      case 'rsi':
        return [
          LineSeries<IndicatorDataPoint, DateTime>(
            dataSource: _indicatorData,
            xValueMapper: (IndicatorDataPoint data, _) => data.date,
            yValueMapper: (IndicatorDataPoint data, _) => data.value,
            color: themeExtension.accentColor,
            width: 2,
            name: 'RSI',
          ),
        ];
      case 'macd':
        return [
          LineSeries<IndicatorDataPoint, DateTime>(
            dataSource: _indicatorData,
            xValueMapper: (IndicatorDataPoint data, _) => data.date,
            yValueMapper: (IndicatorDataPoint data, _) => data.value,
            color: themeExtension.accentColor,
            width: 2,
            name: 'MACD',
          ),
          LineSeries<IndicatorDataPoint, DateTime>(
            dataSource: _indicatorData,
            xValueMapper: (IndicatorDataPoint data, _) => data.date,
            yValueMapper: (IndicatorDataPoint data, _) =>
                data.additionalValues['signal'] ?? 0,
            color: themeExtension.warningColor,
            width: 2,
            name: 'Signal',
          ),
        ];
      case 'stochastic':
        return [
          LineSeries<IndicatorDataPoint, DateTime>(
            dataSource: _indicatorData,
            xValueMapper: (IndicatorDataPoint data, _) => data.date,
            yValueMapper: (IndicatorDataPoint data, _) => data.value,
            color: themeExtension.accentColor,
            width: 2,
            name: '%K',
          ),
          LineSeries<IndicatorDataPoint, DateTime>(
            dataSource: _indicatorData,
            xValueMapper: (IndicatorDataPoint data, _) => data.date,
            yValueMapper: (IndicatorDataPoint data, _) =>
                data.additionalValues['d'] ?? 0,
            color: themeExtension.warningColor,
            width: 2,
            name: '%D',
          ),
        ];
      default:
        return [];
    }
  }

  NumericAxis _buildIndicatorYAxis(AppThemeExtension themeExtension) {
    switch (widget.indicatorType) {
      case 'rsi':
      case 'stochastic':
        return NumericAxis(
          opposedPosition: true,
          minimum: 0,
          maximum: 100,
          interval: 20,
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: themeExtension.textSecondary.withOpacity(0.3),
          ),
          axisLine: const AxisLine(width: 0),
          labelStyle: TextStyle(
            color: themeExtension.textSecondary,
            fontSize: 10,
          ),
          plotBands: [
            PlotBand(
              start: widget.indicatorType == 'rsi' ? 70 : 80,
              end: 100,
              color: themeExtension.negativeColor.withOpacity(0.1),
              text: 'Aşırı Alım',
              textStyle: TextStyle(
                color: themeExtension.textSecondary,
                fontSize: 9,
              ),
            ),
            PlotBand(
              start: 0,
              end: widget.indicatorType == 'rsi' ? 30 : 20,
              color: themeExtension.positiveColor.withOpacity(0.1),
              text: 'Aşırı Satım',
              textStyle: TextStyle(
                color: themeExtension.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        );
      default:
        return NumericAxis(
          opposedPosition: true,
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: themeExtension.textSecondary.withOpacity(0.3),
          ),
          axisLine: const AxisLine(width: 0),
          labelStyle: TextStyle(
            color: themeExtension.textSecondary,
            fontSize: 10,
          ),
        );
    }
  }

  // Scenario creation methods
  List<EducationScenario> _createRSIScenarios() {
    return [
      EducationScenario(
        title: 'Aşırı Alım Sinyali',
        description: 'RSI 70 üzerinde, satış fırsatı',
        pattern: (index, total) {
          if (index < total * 0.3) return math.sin(index * 0.1) * 2;
          if (index < total * 0.7) return 3 + math.sin(index * 0.05) * 1;
          return -2 + math.sin(index * 0.1) * 1;
        },
        explanation:
            'Bu senaryoda RSI 70 seviyesini aştığında güçlü satış sinyali oluşur.',
      ),
      EducationScenario(
        title: 'Aşırı Satım Sinyali',
        description: 'RSI 30 altında, alış fırsatı',
        pattern: (index, total) {
          if (index < total * 0.3) return -math.sin(index * 0.1) * 2;
          if (index < total * 0.7) return -3 + math.sin(index * 0.05) * 1;
          return 2 + math.sin(index * 0.1) * 1;
        },
        explanation:
            'RSI 30 seviyesinin altına indiğinde güçlü alış fırsatı doğar.',
      ),
      EducationScenario(
        title: 'Divergence Sinyali',
        description: 'Fiyat ve RSI arasında uyumsuzluk',
        pattern: (index, total) {
          if (index < total * 0.5) return math.sin(index * 0.05) * 3;
          return math.sin(index * 0.03) * 2 + (index - total * 0.5) * 0.02;
        },
        explanation:
            'Fiyat yeni yüksek yaparken RSI düşük yapıyorsa bearish divergence oluşur.',
      ),
    ];
  }

  List<EducationScenario> _createMACDScenarios() {
    return [
      EducationScenario(
        title: 'Bullish Crossover',
        description: 'MACD sinyal çizgisini yukarı kesiyor',
        pattern: (index, total) => index < total * 0.5 ? -1 : 2,
        explanation:
            'MACD çizgisi sinyal çizgisini yukarı kestiğinde alım sinyali oluşur.',
      ),
      EducationScenario(
        title: 'Bearish Crossover',
        description: 'MACD sinyal çizgisini aşağı kesiyor',
        pattern: (index, total) => index < total * 0.5 ? 2 : -1,
        explanation:
            'MACD çizgisi sinyal çizgisini aşağı kestiğinde satım sinyali oluşur.',
      ),
    ];
  }

  List<EducationScenario> _createStochasticScenarios() {
    return [
      EducationScenario(
        title: 'Oversold Bounce',
        description: '%K ve %D 20 altında crossover',
        pattern: (index, total) {
          if (index < total * 0.3) return -2;
          if (index < total * 0.8) return 1;
          return 0;
        },
        explanation:
            'Stochastic 20 altında %K, %D\'yi yukarı keserse güçlü alım sinyali.',
      ),
    ];
  }

  List<EducationScenario> _createBollingerScenarios() {
    return [
      EducationScenario(
        title: 'Bollinger Squeeze',
        description: 'Bantlar daraldı, volatilite patlaması bekleniyor',
        pattern: (index, total) {
          if (index < total * 0.4) return math.sin(index * 0.3) * 0.5;
          if (index < total * 0.6) return math.sin(index * 0.3) * 0.2;
          return math.sin(index * 0.1) * 3;
        },
        explanation:
            'Bantlar daraldığında büyük bir fiyat hareketi yaklaşıyor demektir.',
      ),
    ];
  }

  // Utility methods
  IconData _getIndicatorIcon() {
    switch (widget.indicatorType) {
      case 'rsi':
        return Icons.trending_up;
      case 'macd':
        return Icons.stacked_line_chart;
      case 'stochastic':
        return Icons.show_chart;
      case 'bollingerBands':
        return Icons.area_chart;
      default:
        return Icons.analytics;
    }
  }

  String _getCurrentScenarioExplanation() {
    if (_currentScenario < _scenarios.length) {
      return _scenarios[_currentScenario].explanation;
    }
    return '';
  }

  Map<String, double> _getParameterRanges(String paramName) {
    switch (paramName) {
      case 'period':
        return {'min': 5.0, 'max': 50.0};
      case 'overbought':
        return {'min': 60.0, 'max': 90.0};
      case 'oversold':
        return {'min': 10.0, 'max': 40.0};
      case 'fast':
        return {'min': 5.0, 'max': 20.0};
      case 'slow':
        return {'min': 20.0, 'max': 50.0};
      case 'signal':
        return {'min': 5.0, 'max': 15.0};
      case 'kPeriod':
        return {'min': 5.0, 'max': 25.0};
      case 'dPeriod':
        return {'min': 1.0, 'max': 10.0};
      case 'standardDeviation':
        return {'min': 1.0, 'max': 4.0};
      default:
        return {'min': 1.0, 'max': 100.0};
    }
  }

  String _getParameterDisplayName(String paramName) {
    switch (paramName) {
      case 'period':
        return 'Periyot';
      case 'overbought':
        return 'Aşırı Alım';
      case 'oversold':
        return 'Aşırı Satım';
      case 'fast':
        return 'Hızlı EMA';
      case 'slow':
        return 'Yavaş EMA';
      case 'signal':
        return 'Sinyal Çizgisi';
      case 'kPeriod':
        return '%K Periyodu';
      case 'dPeriod':
        return '%D Periyodu';
      case 'standardDeviation':
        return 'Standart Sapma';
      default:
        return paramName;
    }
  }
}

// Data classes
class IndicatorDataPoint {
  final DateTime date;
  final double value;
  final Map<String, double> additionalValues;

  IndicatorDataPoint({
    required this.date,
    required this.value,
    required this.additionalValues,
  });
}

class EducationScenario {
  final String title;
  final String description;
  final double Function(int index, int total) pattern;
  final String explanation;

  EducationScenario({
    required this.title,
    required this.description,
    required this.pattern,
    required this.explanation,
  });
}

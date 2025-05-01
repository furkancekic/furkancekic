import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/chart_service.dart';
import '../models/candle_data.dart';
import '../models/indicator.dart' as model;

class ChartScreen extends StatefulWidget {
  const ChartScreen({Key? key}) : super(key: key);

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final TextEditingController _tickerController =
      TextEditingController(text: 'AAPL');
  String _currentTimeframe = '1M';
  final List<String> _timeframes = ['1D', '1W', '1M', '3M', '1Y', '5Y'];
  bool _isLoading = true;
  List<CandleData> _candleData = [];
  final ZoomPanBehavior _zoomPanBehavior = ZoomPanBehavior(
    enablePinching: true,
    enablePanning: true,
    enableDoubleTapZooming: true,
    enableMouseWheelZooming: true,
    enableSelectionZooming: true,
  );
  final TrackballBehavior _trackballBehavior = TrackballBehavior(
    enable: true,
    activationMode: ActivationMode.singleTap,
    tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
    lineType: TrackballLineType.vertical,
  );

  // Selected indicators
  List<model.TechnicalIndicator> _selectedIndicators = [];

  // Moving average periods
  List<int> _maPeriods = [];

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ticker = _tickerController.text.toUpperCase();
      final data = await ChartService.getHistoricalData(
        ticker,
        _currentTimeframe,
        _selectedIndicators.map((i) => i.type).toList(),
        _maPeriods,
      );

      setState(() {
        _candleData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veri yüklenirken hata oluştu: $e'),
          backgroundColor: AppTheme.negativeColor,
        ),
      );
    }
  }

  void _showIndicatorSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => IndicatorSelectorSheet(
        selectedIndicators: _selectedIndicators,
        maPeriods: _maPeriods,
        onApply: (indicators, maPeriods) {
          setState(() {
            _selectedIndicators = indicators;
            _maPeriods = maPeriods;
          });
          _loadChartData();
        },
      ),
    );
  }

  List<TechnicalIndicator<CandleData, DateTime>> _buildIndicators() {
    final List<TechnicalIndicator<CandleData, DateTime>> indicators = [];

    for (var indicator in _selectedIndicators) {
      switch (indicator.type) {
        // ---- SMA -----------------------------------------------------------
        case 'SMA':
          for (var p in _maPeriods) {
            indicators.add(
              SmaIndicator<CandleData, DateTime>(
                seriesName: 'Mum Çubuğu',
                period: p,
                // valueField varsayılanı zaten 'close'; isterseniz yazmayın
                signalLineWidth: indicator.width,
                signalLineColor: indicator.color,
                dashArray: indicator.dashArray,
              ),
            );
          }
          break;

        // ---- EMA -----------------------------------------------------------
        case 'EMA':
          for (var p in _maPeriods) {
            indicators.add(
              EmaIndicator<CandleData, DateTime>(
                seriesName: 'Mum Çubuğu',
                period: p,
                signalLineWidth: indicator.width,
                signalLineColor: indicator.color,
                dashArray: indicator.dashArray,
              ),
            );
          }
          break;

        // ---- Bollinger Band -----------------------------------------------
        case 'BOLLINGER':
          indicators.add(
            BollingerBandIndicator<CandleData, DateTime>(
              seriesName: 'Mum Çubuğu',
              period: 20,
              standardDeviation: 2,
              upperLineColor: Colors.red,
              lowerLineColor: Colors.green,
              upperLineWidth: 2,
              lowerLineWidth: 2,
              bandColor: Colors.grey.withOpacity(0.2),
            ),
          );
          break;

        // ---- RSI -----------------------------------------------------------
        case 'RSI':
          indicators.add(
            RsiIndicator<CandleData, DateTime>(
              seriesName: 'Mum Çubuğu',
              period: 14,
              overbought: 70,
              oversold: 30,
              showZones: true,
              signalLineColor: indicator.color,
              upperLineColor: AppTheme.negativeColor.withOpacity(0.5),
              lowerLineColor: AppTheme.positiveColor.withOpacity(0.5),
              signalLineWidth: indicator.width,
            ),
          );
          break;

        // ---- MACD ----------------------------------------------------------
        case 'MACD':
          indicators.add(
            MacdIndicator<CandleData, DateTime>(
              seriesName: 'Mum Çubuğu',
              shortPeriod: 12,
              longPeriod: 26,
              period: 9, // ← signalPeriod yerine
              macdLineColor: Colors.blue,
              macdLineWidth: 2,
              signalLineColor: Colors.red,
              signalLineWidth: 2,
              histogramPositiveColor: AppTheme.positiveColor,
              histogramNegativeColor: AppTheme.negativeColor,
              dashArray: indicator.dashArray, // artık non‑nullable
            ),
          );
          break;
      }
    }
    return indicators;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundColor,
            Color(0xFF192138),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page title
              const Text(
                'Gelişmiş Grafik',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Search and filter row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _tickerController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Sembol ara...',
                          prefixIcon:
                              Icon(Icons.search, color: AppTheme.accentColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _loadChartData(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.cardColor,
                    child: IconButton(
                      icon: const Icon(Icons.bar_chart,
                          color: AppTheme.accentColor),
                      onPressed: _showIndicatorSelector,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.cardColor,
                    child: IconButton(
                      icon: const Icon(Icons.refresh,
                          color: AppTheme.accentColor),
                      onPressed: _loadChartData,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Timeframe selector
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _timeframes.length,
                  itemBuilder: (context, index) {
                    final timeframe = _timeframes[index];
                    final isSelected = timeframe == _currentTimeframe;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(timeframe),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _currentTimeframe = timeframe;
                            });
                            _loadChartData();
                          }
                        },
                        backgroundColor: AppTheme.cardColor,
                        selectedColor: AppTheme.accentColor,
                        labelStyle: TextStyle(
                          color:
                              isSelected ? Colors.black : AppTheme.textPrimary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Chart
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentColor,
                        ),
                      )
                    : _candleData.isEmpty
                        ? const Center(
                            child: Text(
                              'Veri bulunamadı',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : FuturisticCard(
                            child: SfCartesianChart(
                              title: ChartTitle(
                                text:
                                    '${_tickerController.text.toUpperCase()} - $_currentTimeframe',
                                textStyle: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              primaryXAxis: DateTimeAxis(
                                dateFormat: _currentTimeframe == '1D' ||
                                        _currentTimeframe == '1W'
                                    ? DateFormat.Hm()
                                    : DateFormat.MMMd(),
                                intervalType: _currentTimeframe == '1D' ||
                                        _currentTimeframe == '1W'
                                    ? DateTimeIntervalType.hours
                                    : DateTimeIntervalType.days,
                                majorGridLines: const MajorGridLines(
                                    width: 0.5, color: Colors.grey),
                                labelStyle: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                              primaryYAxis: NumericAxis(
                                opposedPosition: true,
                                labelFormat: '\${value}',
                                labelStyle: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                                majorGridLines: const MajorGridLines(
                                    width: 0.5, color: Colors.grey),
                              ),
                              zoomPanBehavior: _zoomPanBehavior,
                              trackballBehavior: _trackballBehavior,
                              legend: Legend(
                                isVisible: true,
                                position: LegendPosition.bottom,
                                textStyle: const TextStyle(
                                    color: AppTheme.textPrimary),
                              ),
                              tooltipBehavior: TooltipBehavior(enable: true),
                              plotAreaBackgroundColor: AppTheme.cardColor,
                              enableAxisAnimation: true,
                              series: <CartesianSeries>[
                                CandleSeries<CandleData, DateTime>(
                                  name: 'Mum Çubuğu',
                                  dataSource: _candleData,
                                  xValueMapper: (CandleData data, _) =>
                                      data.date,
                                  lowValueMapper: (CandleData data, _) =>
                                      data.low,
                                  highValueMapper: (CandleData data, _) =>
                                      data.high,
                                  openValueMapper: (CandleData data, _) =>
                                      data.open,
                                  closeValueMapper: (CandleData data, _) =>
                                      data.close,
                                  bullColor: AppTheme.positiveColor,
                                  bearColor: AppTheme.negativeColor,
                                  enableSolidCandles: true,
                                  animationDuration: 1000,
                                )
                              ],
                              indicators: _buildIndicators(),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IndicatorSelectorSheet extends StatefulWidget {
  final List<model.TechnicalIndicator> selectedIndicators;
  final List<int> maPeriods;
  final Function(List<model.TechnicalIndicator>, List<int>) onApply;

  const IndicatorSelectorSheet({
    Key? key,
    required this.selectedIndicators,
    required this.maPeriods,
    required this.onApply,
  }) : super(key: key);

  @override
  State<IndicatorSelectorSheet> createState() => _IndicatorSelectorSheetState();
}

class _IndicatorSelectorSheetState extends State<IndicatorSelectorSheet> {
  late List<model.TechnicalIndicator> _indicators;
  late List<int> _periods;
  final TextEditingController _periodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _indicators = List.from(widget.selectedIndicators);
    _periods = List.from(widget.maPeriods);
  }

  @override
  void dispose() {
    _periodController.dispose();
    super.dispose();
  }

  void _toggleIndicator(model.TechnicalIndicator indicator) {
    if (_indicators.any((i) => i.type == indicator.type)) {
      _indicators.removeWhere((i) => i.type == indicator.type);
    } else {
      _indicators.add(indicator);
    }
    setState(() {});
  }

  void _addPeriod() {
    final period = int.tryParse(_periodController.text);
    if (period != null && period > 0 && !_periods.contains(period)) {
      setState(() {
        _periods.add(period);
        _periods.sort();
        _periodController.clear();
      });
    }
  }

  void _removePeriod(int period) {
    setState(() {
      _periods.remove(period);
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableIndicators = [
      model.TechnicalIndicator(
        type: 'SMA',
        name: 'Basit Hareketli Ortalama (SMA)',
        color: Colors.blue,
        width: 2,
      ),
      model.TechnicalIndicator(
        type: 'EMA',
        name: 'Üssel Hareketli Ortalama (EMA)',
        color: Colors.purple,
        width: 2,
      ),
      model.TechnicalIndicator(
        type: 'BOLLINGER',
        name: 'Bollinger Bantları',
        color: Colors.orange,
        width: 2,
      ),
      model.TechnicalIndicator(
        type: 'RSI',
        name: 'Göreceli Güç Endeksi (RSI)',
        color: Colors.yellow,
        width: 2,
      ),
      model.TechnicalIndicator(
        type: 'MACD',
        name: 'MACD',
        color: Colors.green,
        width: 2,
      ),
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Teknik Göstergeler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicators list
                  const Text(
                    'Göstergeler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Available indicators
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableIndicators.map((indicator) {
                      final isSelected =
                          _indicators.any((i) => i.type == indicator.type);
                      return FilterChip(
                        label: Text(indicator.name),
                        selected: isSelected,
                        onSelected: (_) => _toggleIndicator(indicator),
                        backgroundColor: AppTheme.cardColor,
                        selectedColor: AppTheme.accentColor,
                        checkmarkColor: Colors.black,
                        labelStyle: TextStyle(
                          color:
                              isSelected ? Colors.black : AppTheme.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // MA Periods
                  if (_indicators
                      .any((i) => i.type == 'SMA' || i.type == 'EMA'))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hareketli Ortalama Periyotları',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Period input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _periodController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Yeni periyot',
                                  filled: true,
                                  fillColor: AppTheme.cardColor,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addPeriod,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              child: const Text('Ekle'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Selected periods
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _periods.map((period) {
                            return Chip(
                              label: Text('$period gün'),
                              backgroundColor: AppTheme.cardColorLight,
                              deleteIconColor: AppTheme.negativeColor,
                              onDeleted: () => _removePeriod(period),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.textSecondary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_indicators, _periods);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Uygula'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

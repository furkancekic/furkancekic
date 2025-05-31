import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/portfolio.dart';
// Corrected imports for service layer classes that define their own data structures for now
import '../services/portfolio_service.dart' as portfolio_service_ns;
import '../services/portfolio_benchmark_service.dart' as benchmark_service_ns;
// Common model
import '../models/performance_point.dart';
import '../utils/chart_utils.dart';

class BenchmarkComparisonScreen extends StatefulWidget {
  final Portfolio? portfolio;

  const BenchmarkComparisonScreen({
    Key? key,
    this.portfolio,
  }) : super(key: key);

  @override
  State<BenchmarkComparisonScreen> createState() =>
      _BenchmarkComparisonScreenState();
}

// Define BenchmarkData at this level if it's used across services after conversion
// Or ensure services return data that can be easily converted to a common screen-level model.
// For now, let's assume BenchmarkData is a type used within this screen,
// and data from services will be mapped to it.
class BenchmarkData {
  final String id;
  final String name;
  final String symbol;
  final String timeframe;
  final List<PerformancePoint> data; // Uses common PerformancePoint
  final double returnPercent;

  BenchmarkData({
    required this.id,
    required this.name,
    required this.symbol,
    required this.timeframe,
    required this.data,
    this.returnPercent = 0.0,
  });
}


class _BenchmarkComparisonScreenState extends State<BenchmarkComparisonScreen> {
  bool _isLoading = true;
  List<benchmark_service_ns.BenchmarkInfo> _availableBenchmarks = [];
  List<String> _selectedBenchmarkIds = [];
  String _selectedTimeframe = '1M';
  final List<String> _timeframes = ['1W', '1M', '3M', '6M', '1Y', 'All'];

  bool _isNormalizedView = false;

  List<BenchmarkData> _absoluteBenchmarkData = [];
  List<BenchmarkData> _normalizedBenchmarkData = [];

  final TextEditingController _customTickerController = TextEditingController();
  bool _isCustomTickerValid = false;
  bool _isValidatingTicker = false;

  List<BenchmarkData> _benchmarkData = []; // This will use the screen-level BenchmarkData
  PortfolioBenchmarkMetrics? _comparisonMetrics; // This comes from benchmark_service_ns

  List<PerformancePoint> _portfolioPerformanceData = []; // Common PerformancePoint
  List<PerformancePoint> _normalizedPortfolioData = []; // Common PerformancePoint
  double _portfolioReturn = 0.0;

  DateTime? _startDate;
  DateTime? _endDate;

  final Color _portfolioColor = Colors.blue;
  final List<Color> _benchmarkColors = [
      Colors.red.shade400, Colors.green.shade600, Colors.orange.shade500,
      Colors.purple.shade400, Colors.teal.shade500, Colors.yellow.shade800,
      Colors.pink.shade300, Colors.indigo.shade400, Colors.lightGreen.shade600,
      Colors.deepOrange.shade400, Colors.cyan.shade500, Colors.blueGrey.shade400,
      Colors.lime.shade600, Colors.brown.shade400, Colors.amber.shade700
  ];

  final List<Color> _customTickerSpecificColors = [
      Colors.pinkAccent.shade200, Colors.lightBlueAccent.shade200, Colors.amberAccent.shade400,
      Colors.deepPurpleAccent.shade100, Colors.tealAccent.shade400,
      Colors.redAccent.shade100, Colors.greenAccent.shade700,
      Colors.orangeAccent.shade200, Colors.cyanAccent.shade400, Colors.indigoAccent.shade100
  ];

  final Map<String, Color> _assignedBenchmarkColors = {};
  int _nextBenchmarkColorIndex = 0;
  int _nextCustomColorIndex = 0;

  final int _maxSelectableBenchmarks = 4;

  final Map<String, String> _metricExplanations = {
    'Alpha': 'Alpha measures the investment\'s performance relative to a benchmark index. A positive Alpha indicates the investment outperformed the benchmark after adjusting for risk. For example, an Alpha of 2% means the investment returned 2% more than the benchmark, considering its risk.',
    'Beta': 'Beta measures an investment\'s volatility or systematic risk in comparison to the market as a whole (usually the benchmark). A Beta greater than 1 indicates the investment is more volatile than the benchmark, while a Beta less than 1 means it\'s less volatile.',
    'Correlation': 'Correlation (specifically, the Correlation Coefficient) measures how two investments move in relation to each other. It ranges from -1 to +1. +1 means they move perfectly in sync, -1 means they move perfectly opposite, and 0 means no linear relationship.',
    'R-Squared': 'R-Squared indicates the percentage of an investment\'s movements that can be explained by movements in its benchmark index. It ranges from 0% to 100%. A high R-Squared (e.g., 85%) suggests the benchmark is a good fit for comparing performance.',
    'Sharpe Ratio': 'The Sharpe Ratio measures an investment\'s risk-adjusted return. It\'s calculated by subtracting the risk-free rate from the investment\'s return and dividing by its standard deviation (volatility). A higher Sharpe Ratio generally indicates better performance for the amount of risk taken.',
    'Information Ratio': 'The Information Ratio measures a portfolio manager\'s ability to generate excess returns relative to a benchmark, adjusted for the volatility of those excess returns (tracking error). A higher Information Ratio suggests better and more consistent active management.'
  };

  @override
  void initState() {
    super.initState();
    _loadBenchmarks();

    if (widget.portfolio?.name.contains('Tech') ?? false) {
      _selectedBenchmarkIds = ['NASDAQ', 'SP500'];
    } else if (widget.portfolio?.name.contains('Dividend') ?? false) {
      _selectedBenchmarkIds = ['SP500', 'DOW'];
    } else {
      _selectedBenchmarkIds = ['SP500'];
    }
  }

  @override
  void dispose() {
    _customTickerController.dispose();
    super.dispose();
  }

  Future<void> _loadBenchmarks() async {
    setState(() => _isLoading = true);
    try {
      _availableBenchmarks = await benchmark_service_ns.PortfolioBenchmarkService.getAvailableBenchmarks();
      await _loadPortfolioData();
      await _loadBenchmarkData();
      if (widget.portfolio != null && _selectedBenchmarkIds.isNotEmpty) {
        final firstBenchmarkId = _selectedBenchmarkIds.firstWhere((id) => !_isCustomBenchmarkId(id), orElse: () => '');
        if (firstBenchmarkId.isNotEmpty) {
          // Assuming compareToBenchmark returns a type that can be assigned to _comparisonMetrics
          _comparisonMetrics = await benchmark_service_ns.PortfolioBenchmarkService.compareToBenchmark(widget.portfolio!.id!, firstBenchmarkId, _selectedTimeframe);
        } else {
          _comparisonMetrics = null;
        }
      } else {
        _comparisonMetrics = null;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load benchmark data: $e'), backgroundColor: AppTheme.negativeColor));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _validateTicker(String ticker) async {
    if (ticker.isEmpty) return false;
    setState(() => _isValidatingTicker = true);
    try {
      final stockInfo = await StockApiService.getStockInfo(ticker);
      final isValid = stockInfo.price > 0;
      if (mounted) setState(() => _isCustomTickerValid = isValid);
      return isValid;
    } catch (e) {
      if (mounted) setState(() => _isCustomTickerValid = false);
      return false;
    } finally {
      if (mounted) setState(() => _isValidatingTicker = false);
    }
  }

  Future<void> _addCustomTicker() async {
    if (_selectedBenchmarkIds.length >= _maxSelectableBenchmarks) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You can select a maximum of $_maxSelectableBenchmarks benchmarks/tickers.'), backgroundColor: AppTheme.warningColor));
      return;
    }
    final ticker = _customTickerController.text.trim().toUpperCase();
    if (ticker.isEmpty) return;
    final isValid = await _validateTicker(ticker);
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid ticker symbol. Please enter a valid ticker.'), backgroundColor: AppTheme.negativeColor));
      return;
    }
    final customId = 'CUSTOM_$ticker';
    if (_selectedBenchmarkIds.contains(customId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$ticker is already added.'), backgroundColor: Colors.orange));
      return;
    }
    setState(() {
      _selectedBenchmarkIds.add(customId);
      _customTickerController.clear();
      _isCustomTickerValid = false;
      _resetColorAssignments();
    });
    await _loadBenchmarkData();
  }

  void _determineTimeframeDateRange() {
    final now = DateTime.now();
    _endDate = now;
    switch (_selectedTimeframe) {
      case '1W': _startDate = now.subtract(const Duration(days: 7)); break;
      case '1M': _startDate = now.subtract(const Duration(days: 30)); break;
      case '3M': _startDate = now.subtract(const Duration(days: 90)); break;
      case '6M': _startDate = now.subtract(const Duration(days: 180)); break;
      case '1Y': _startDate = now.subtract(const Duration(days: 365)); break;
      case 'All': _startDate = now.subtract(const Duration(days: 3 * 365)); break;
      default: _startDate = now.subtract(const Duration(days: 30));
    }
  }

  Future<void> _loadPortfolioData() async {
    try {
      _determineTimeframeDateRange();
      List<portfolio_service_ns.PerformancePoint> spPerformancePoints;
      List<portfolio_service_ns.PerformancePoint> spNormalizedPerformancePoints = [];

      if (widget.portfolio != null) {
        final performanceResult = await portfolio_service_ns.PortfolioService.getPortfolioPerformance(widget.portfolio!.id!, _selectedTimeframe);
        spPerformancePoints = performanceResult.data;
        try {
          final normalizedResult = await portfolio_service_ns.PortfolioService.getNormalizedPortfolioPerformance(widget.portfolio!.id!, _selectedTimeframe);
          spNormalizedPerformancePoints = normalizedResult.data;
        } catch (e) {
          print('Normalized portfolio data not available: $e');
          if (spPerformancePoints.isNotEmpty) {
            final baseValue = spPerformancePoints.first.value;
            if (baseValue > 0) {
              spNormalizedPerformancePoints = spPerformancePoints.map((p) => portfolio_service_ns.PerformancePoint(date: p.date, value: (p.value / baseValue) * 100)).toList();
            } else {
               spNormalizedPerformancePoints = List.from(spPerformancePoints);
            }
          }
        }
      } else {
        final performanceResult = await portfolio_service_ns.PortfolioService.getTotalPortfoliosPerformance(_selectedTimeframe);
        spPerformancePoints = performanceResult.data;
         try {
          final normalizedResult = await portfolio_service_ns.PortfolioService.getNormalizedTotalPortfoliosPerformance(_selectedTimeframe);
          spNormalizedPerformancePoints = normalizedResult.data;
        } catch (e) {
          print('Normalized total portfolio data not available: $e');
          if (spPerformancePoints.isNotEmpty) {
            final baseValue = spPerformancePoints.first.value;
             if (baseValue > 0) {
              spNormalizedPerformancePoints = spPerformancePoints.map((p) => portfolio_service_ns.PerformancePoint(date: p.date, value: (p.value / baseValue) * 100)).toList();
            } else {
              spNormalizedPerformancePoints = List.from(spPerformancePoints);
            }
          }
        }
      }

      final convertedData = _convertSpPerformancePoints(spPerformancePoints);
      final convertedNormalizedData = _convertSpPerformancePoints(spNormalizedPerformancePoints);

      if(mounted) setState(() {
        _portfolioPerformanceData = convertedData;
        _normalizedPortfolioData = convertedNormalizedData;
        if (_portfolioPerformanceData.isNotEmpty) {
          final firstValue = _portfolioPerformanceData.first.value;
          final lastValue = _portfolioPerformanceData.last.value;
          _portfolioReturn = firstValue > 0 ? ((lastValue / firstValue) - 1) * 100 : 0.0;
        } else {
          _portfolioReturn = 0.0;
        }
      });
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load portfolio data: $e'), backgroundColor: AppTheme.negativeColor));
    }
  }

  List<PerformancePoint> _convertSpPerformancePoints(List<portfolio_service_ns.PerformancePoint> points) {
    return points.map((p) => PerformancePoint(date: p.date, value: p.value)).toList();
  }

  List<PerformancePoint> _convertBenchmarkPerformancePoints(List<benchmark_service_ns.PerformancePoint> points) {
    return points.map((p) => PerformancePoint(date: p.date, value: p.value)).toList();
  }

  Future<void> _loadBenchmarkData() async {
    try {
      await Future.wait([_loadAbsoluteBenchmarkData(), _loadNormalizedBenchmarkData()]);
      if(mounted) setState(() => _benchmarkData = _isNormalizedView ? _normalizedBenchmarkData : _absoluteBenchmarkData);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load benchmark data: $e'), backgroundColor: AppTheme.negativeColor));
    }
  }

  Future<void> _loadAbsoluteBenchmarkData() async {
    try {
      List<BenchmarkData> newBenchmarkData = [];
      for (String id in _selectedBenchmarkIds) {
        if (_isCustomBenchmarkId(id)) {
          final ticker = id.substring('CUSTOM_'.length);
          try {
            final stockData = await StockApiService.getStockData(ticker, _selectedTimeframe, startDate: _startDate?.toIso8601String(), endDate: _endDate?.toIso8601String(), interval: _getApiIntervalForTimeframe(_selectedTimeframe));
            if (stockData.isNotEmpty) {
              List<PerformancePoint> dataPoints = stockData.map((p) => PerformancePoint(date: DateTime.parse(p['date'].toString()), value: double.parse(p['close'].toString()))).toList()..sort((a,b) => a.date.compareTo(b.date));
              double returnPercent = dataPoints.isNotEmpty && dataPoints.first.value > 0 ? ((dataPoints.last.value / dataPoints.first.value) - 1) * 100 : 0.0;
              newBenchmarkData.add(BenchmarkData(id: id, name: ticker, symbol: ticker, timeframe: _selectedTimeframe, data: _normalizeDataPointsToMatchTimeframe(dataPoints), returnPercent: returnPercent));
            }
          } catch (e) { print('Error loading custom ticker data ($ticker): $e'); }
        }
      }
      List<String> standardBenchmarkIdsToLoad = _selectedBenchmarkIds.where((id) => !_isCustomBenchmarkId(id)).toList();
      if (standardBenchmarkIdsToLoad.isNotEmpty) {
        List<benchmark_service_ns.BenchmarkData> standardServiceData = await benchmark_service_ns.PortfolioBenchmarkService.getBenchmarkPerformance(_selectedTimeframe, standardBenchmarkIdsToLoad);
        newBenchmarkData.addAll(standardServiceData.map((bsd) => BenchmarkData(id: bsd.id, name: bsd.name, symbol: bsd.symbol, timeframe: bsd.timeframe, data: _convertBenchmarkPerformancePoints(bsd.data), returnPercent: bsd.returnPercent)));
      }
      if(mounted) setState(() {
        _absoluteBenchmarkData = newBenchmarkData;
        if (!_isNormalizedView) _benchmarkData = _absoluteBenchmarkData;
      });
    } catch (e) { print('Error loading absolute benchmark data: $e'); }
  }

  Future<void> _loadNormalizedBenchmarkData() async {
    try {
      List<BenchmarkData> newNormalizedData = [];
      for (String id in _selectedBenchmarkIds) {
        if (_isCustomBenchmarkId(id)) {
          final absoluteDataForCustom = _absoluteBenchmarkData.firstWhere((data) => data.id == id, orElse: () => BenchmarkData(id: id, name: id.substring('CUSTOM_'.length), symbol: id.substring('CUSTOM_'.length), timeframe: _selectedTimeframe, data: [], returnPercent: 0.0));
          if (absoluteDataForCustom.data.isNotEmpty) {
            final List<PerformancePoint> commonPerformancePoints = absoluteDataForCustom.data.map((p) => PerformancePoint(date: p.date, value: p.value)).toList();
            final normalizedDataPoints = normalizePerformanceDataToHundred(commonPerformancePoints); // Uses util
            final returnPercent = normalizedDataPoints.isNotEmpty ? normalizedDataPoints.last.value - 100 : 0.0;
            newNormalizedData.add(BenchmarkData(id: id, name: absoluteDataForCustom.name, symbol: absoluteDataForCustom.symbol, timeframe: _selectedTimeframe, data: normalizedDataPoints, returnPercent: returnPercent));
          }
        }
      }
      List<String> standardBenchmarkIdsToLoad = _selectedBenchmarkIds.where((id) => !_isCustomBenchmarkId(id)).toList();
      if (standardBenchmarkIdsToLoad.isNotEmpty) {
        try {
          List<benchmark_service_ns.BenchmarkData> standardNormalizedServiceData = await benchmark_service_ns.PortfolioBenchmarkService.getNormalizedBenchmarkPerformance(_selectedTimeframe, standardBenchmarkIdsToLoad);
           newNormalizedData.addAll(standardNormalizedServiceData.map((bsd) => BenchmarkData(id: bsd.id, name: bsd.name, symbol: bsd.symbol, timeframe: bsd.timeframe, data: _convertBenchmarkPerformancePoints(bsd.data), returnPercent: bsd.returnPercent)));
        } catch (e) {
          print('Normalized benchmark service not available, using fallback: $e');
          for (String id in standardBenchmarkIdsToLoad) {
            final absoluteDataForStandard = _absoluteBenchmarkData.firstWhere((data) => data.id == 'benchmark_$id' || data.id == id, orElse: () => BenchmarkData(id: id, name: id, symbol: id, timeframe: _selectedTimeframe, data: [], returnPercent: 0.0));
            if (absoluteDataForStandard.data.isNotEmpty) {
              final List<PerformancePoint> commonPerformancePoints = absoluteDataForStandard.data.map((p) => PerformancePoint(date: p.date, value: p.value)).toList();
              final normalizedDataPoints = normalizePerformanceDataToHundred(commonPerformancePoints); // Uses util
              final returnPercent = normalizedDataPoints.isNotEmpty ? normalizedDataPoints.last.value - 100 : 0.0;
              newNormalizedData.add(BenchmarkData(id: absoluteDataForStandard.id, name: absoluteDataForStandard.name, symbol: absoluteDataForStandard.symbol, timeframe: _selectedTimeframe, data: normalizedDataPoints, returnPercent: returnPercent));
            }
          }
        }
      }
      if(mounted) setState(() {
        _normalizedBenchmarkData = newNormalizedData;
        if (_isNormalizedView) _benchmarkData = _normalizedBenchmarkData;
      });
    } catch (e) { print('Error loading normalized benchmark data: $e'); }
  }

  void _toggleView() {
    if(mounted) setState(() {
      _isNormalizedView = !_isNormalizedView;
      _benchmarkData = _isNormalizedView ? _normalizedBenchmarkData : _absoluteBenchmarkData;
    });
  }

  String _getApiIntervalForTimeframe(String timeframe) {
    switch (timeframe) {
      case '1W': case '1M': case '3M': case '6M': return '1d';
      case '1Y': return '1wk';
      case 'All': return '1mo';
      default: return '1d';
    }
  }

  List<PerformancePoint> _normalizeDataPointsToMatchTimeframe(List<PerformancePoint> points) {
    if (points.isEmpty) return [];
    final expectedPoints = _getExpectedDataPointsForTimeframe(_selectedTimeframe);
    if (points.length == expectedPoints || points.length < 2) return points;
    if (points.length > expectedPoints) {
      final sampledPoints = <PerformancePoint>[];
      final step = (points.length - 1) / (expectedPoints - 1);
      for (int i = 0; i < expectedPoints; i++) {
        final index = (i * step).round();
        if (index < points.length) sampledPoints.add(points[index]);
      }
      if (sampledPoints.isEmpty || (sampledPoints.isNotEmpty && sampledPoints.last.date != points.last.date)) {
        if (sampledPoints.isNotEmpty && sampledPoints.length >= expectedPoints) sampledPoints.removeLast();
        if (points.isNotEmpty) sampledPoints.add(points.last);
      }
      return sampledPoints.take(expectedPoints).toList();
    }
    return points;
  }

  int _getExpectedDataPointsForTimeframe(String timeframe) {
    switch (timeframe) {
      case '1W': return 7;
      case '1M': case '3M': case '6M': return 15;
      case '1Y': return 12;
      case 'All': return 20;
      default: return 15;
    }
  }

  void _updateSelectedBenchmarks(String benchmarkId, bool isSelected) {
    if (isSelected && _selectedBenchmarkIds.length >= _maxSelectableBenchmarks && !_selectedBenchmarkIds.contains(benchmarkId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You can select a maximum of $_maxSelectableBenchmarks benchmarks/tickers.'), backgroundColor: AppTheme.warningColor));
      return;
    }
    _resetColorAssignments();
    setState(() {
      if (isSelected) {
        if (!_selectedBenchmarkIds.contains(benchmarkId)) _selectedBenchmarkIds.add(benchmarkId);
      } else {
        _selectedBenchmarkIds.remove(benchmarkId);
      }
    });
    _loadBenchmarkData();
    if (widget.portfolio != null && _selectedBenchmarkIds.isNotEmpty) {
      final firstStandardBenchmarkId = _selectedBenchmarkIds.firstWhere((id) => !_isCustomBenchmarkId(id), orElse: () => '');
      if (firstStandardBenchmarkId.isNotEmpty) {
        benchmark_service_ns.PortfolioBenchmarkService.compareToBenchmark(widget.portfolio!.id!, firstStandardBenchmarkId, _selectedTimeframe)
            .then((metrics) { if (mounted) setState(() => _comparisonMetrics = metrics); });
      } else {
        if (mounted) setState(() => _comparisonMetrics = null);
      }
    } else {
      if (mounted) setState(() => _comparisonMetrics = null);
    }
  }

  bool _isCustomBenchmarkId(String id) => id.startsWith('CUSTOM_');

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>() ??
                AppThemeExtension(
                  primaryColor: AppTheme.primaryColor, accentColor: AppTheme.accentColor,
                  positiveColor: AppTheme.positiveColor, negativeColor: AppTheme.negativeColor,
                  warningColor: AppTheme.warningColor, cardColor: AppTheme.cardColor,
                  cardColorLight: AppTheme.cardColorLight, textPrimary: AppTheme.textPrimary,
                  textSecondary: AppTheme.textSecondary, gradientColors: AppTheme.primaryGradient,
                  isDark: WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark, // Or your app's default
                  themeStyle: ThemeStyle.modern, // Or your app's default
                  gradientBackgroundColors: [AppTheme.backgroundColor, const Color(0xFF192138)]
                );
    final textPrim = ext.textPrimary;
    final accent = ext.accentColor;
    final String screenTitle = widget.portfolio != null ? 'Compare: ${widget.portfolio!.name}' : 'Benchmark Comparison';

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle, style: TextStyle(color: textPrim, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: accent), onPressed: () => Navigator.of(context).pop()),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: ext.gradientBackgroundColors)),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: accent))
            : RefreshIndicator(
                onRefresh: _loadBenchmarks,
                backgroundColor: ext.cardColor,
                color: accent,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTimeframeSelector(),
                    const SizedBox(height: 16),
                    _buildCustomTickerInput(),
                    const SizedBox(height: 16),
                    _buildBenchmarkSelector(),
                    const SizedBox(height: 24),
                    _buildPerformanceChart(),
                    const SizedBox(height: 24),
                    if (widget.portfolio != null && _comparisonMetrics != null) _buildMetricsComparison(),
                    const SizedBox(height: 24),
                    _buildReturnStatistics(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCustomTickerInput() {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final cardColor = ext.cardColor;
    final accent = ext.accentColor;
    final textPrim = ext.textPrimary;
    List<String> customTickersAdded = _selectedBenchmarkIds.where((id) => _isCustomBenchmarkId(id)).map((id) => id.substring('CUSTOM_'.length)).toList();

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Custom Ticker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Compare with up to $_maxSelectableBenchmarks benchmarks/tickers.', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customTickerController,
                  style: TextStyle(color: textPrim),
                  decoration: InputDecoration(
                    filled: true, fillColor: cardColor.withOpacity(0.5),
                    hintText: 'Enter ticker (e.g. AAPL)', hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: _isValidatingTicker ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : _isCustomTickerValid ? Icon(Icons.check_circle, color: AppTheme.positiveColor) : null,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    if (value != value.toUpperCase()) _customTickerController.value = TextEditingValue(text: value.toUpperCase(), selection: _customTickerController.selection);
                    if (mounted) setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _customTickerController.text.trim().isEmpty || _isValidatingTicker || _selectedBenchmarkIds.length >= _maxSelectableBenchmarks ? null : _addCustomTicker,
                style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Add'),
              ),
            ],
          ),
          if (customTickersAdded.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0, runSpacing: 4.0,
              children: customTickersAdded.map((ticker) => Chip(
                label: Text(ticker), backgroundColor: _getBenchmarkColor('CUSTOM_$ticker').withOpacity(0.7),
                labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                onDeleted: () {
                  setState(() => _selectedBenchmarkIds.remove('CUSTOM_$ticker'));
                  _resetColorAssignments();
                  _loadBenchmarkData();
                },
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, itemCount: _timeframes.length,
        itemBuilder: (context, index) {
          final timeframe = _timeframes[index];
          final isSelected = timeframe == _selectedTimeframe;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(timeframe), selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTimeframe = timeframe);
                  _determineTimeframeDateRange();
                  _loadPortfolioData().then((_) => _loadBenchmarkData());
                  if (widget.portfolio != null && _selectedBenchmarkIds.isNotEmpty) {
                    final firstStandardBenchmarkId = _selectedBenchmarkIds.firstWhere((id) => !_isCustomBenchmarkId(id), orElse: () => '');
                    if (firstStandardBenchmarkId.isNotEmpty) {
                      benchmark_service_ns.PortfolioBenchmarkService.compareToBenchmark(widget.portfolio!.id!, firstStandardBenchmarkId, _selectedTimeframe)
                          .then((metrics) { if (mounted) setState(() => _comparisonMetrics = metrics); });
                    } else {
                      if (mounted) setState(() => _comparisonMetrics = null);
                    }
                  }
                }
              },
              backgroundColor: ext.cardColor,
              selectedColor: ext.accentColor,
              labelStyle: TextStyle(color: isSelected ? Colors.black : ext.textPrimary),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenchmarkSelector() {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final cardColor = ext.cardColor;
    final textPrim = ext.textPrimary;

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Benchmarks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              if (_selectedBenchmarkIds.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 18), label: const Text('Clear All'),
                  onPressed: () {
                    setState(() { _selectedBenchmarkIds.clear(); _resetColorAssignments(); });
                    _loadBenchmarkData();
                    if (mounted) setState(() => _comparisonMetrics = null);
                  },
                  style: TextButton.styleFrom(foregroundColor: ext.accentColor, padding: EdgeInsets.zero),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...['Equity', 'Currency', 'Commodity', 'Crypto', 'Volatility'].map((category) {
            final benchmarksInCategory = _availableBenchmarks.where((b) => b.category == category).toList();
            if (benchmarksInCategory.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrim.withOpacity(0.7))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: benchmarksInCategory.map((benchmark) {
                    final isSelected = _selectedBenchmarkIds.contains(benchmark.id);
                    return FilterChip(
                      label: Text(benchmark.name), selected: isSelected,
                      onSelected: (selected) => _updateSelectedBenchmarks(benchmark.id, selected),
                      backgroundColor: cardColor, selectedColor: _getBenchmarkColor(benchmark.id),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : textPrim, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      showCheckmark: false, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Chart Building Helper Methods
  FlGridData _buildBenchmarkChartGridData(AppThemeExtension themeExt) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (value) => FlLine(
        color: themeExt.textSecondary.withOpacity(0.1),
        strokeWidth: 1,
      ),
    );
  }

  FlTitlesData _buildBenchmarkChartTitlesData(
    AppThemeExtension themeExt,
    int expectedPoints,
    Map<String, List<FlSpot>> normalizedDataSets, // Using FlSpot here as it's chart specific
    List<PerformancePoint> currentPortfolioPerformanceData, // Common model
    List<BenchmarkData> currentBenchmarkData // Screen specific model
  ) {
    final textSecondary = themeExt.textSecondary;
    return FlTitlesData(
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: expectedPoints > 5 ? (expectedPoints / 5).floorToDouble() : 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            List<DateTime> dateSeries = [];

            if (normalizedDataSets['Portfolio'] != null && currentPortfolioPerformanceData.length >= expectedPoints) {
               final portfolioDataForLabels = currentPortfolioPerformanceData.length == expectedPoints ? currentPortfolioPerformanceData : _normalizeDataPointsToMatchTimeframe(currentPortfolioPerformanceData);
              dateSeries = portfolioDataForLabels.map((p) => p.date).toList();
            } else if (currentBenchmarkData.isNotEmpty && currentBenchmarkData.first.data.length >= expectedPoints) {
              final benchmarkDataForLabels = currentBenchmarkData.first.data.length == expectedPoints ? currentBenchmarkData.first.data : _normalizeDataPointsToMatchTimeframe(currentBenchmarkData.first.data);
              dateSeries = benchmarkDataForLabels.map((p) => p.date).toList();
            } else if (currentPortfolioPerformanceData.isNotEmpty) {
                 dateSeries = currentPortfolioPerformanceData.map((p) => p.date).toList();
            }

            if (dateSeries.isEmpty || index < 0 || index >= dateSeries.length) {
              return const SizedBox.shrink();
            }
            final date = dateSeries[index];
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(getChartDateLabel(date, _selectedTimeframe), style: TextStyle(color: textSecondary, fontSize: 10)),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          getTitlesWidget: (value, meta) {
            if (_isNormalizedView) return Text('${value.toInt()}%', style: TextStyle(color: textSecondary, fontSize: 10));
            final displayValue = value - 100;
            return Text('${displayValue >= 0 ? '+' : ''}${displayValue.toInt()}%', style: TextStyle(color: textSecondary, fontSize: 10));
          },
        ),
      ),
    );
  }

  LineTouchData _buildBenchmarkChartTouchData(AppThemeExtension themeExt, Map<String, List<FlSpot>> normalizedDataSets, Color tooltipBackgroundColor) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: tooltipBackgroundColor,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final datasetName = _getDatasetNameForLineId(spot.barIndex, normalizedDataSets.keys.toList());
            final displayValue = _isNormalizedView ? spot.y : spot.y - 100;
            final suffix = _isNormalizedView ? '' : '%';
            final prefix = _isNormalizedView ? '' : (displayValue >= 0 ? '+' : '');
            return LineTooltipItem(
              '$datasetName: $prefix${displayValue.toStringAsFixed(2)}$suffix',
              TextStyle(color: _getColorForLineId(spot.barIndex, normalizedDataSets.keys.toList()), fontWeight: FontWeight.bold),
            );
          }).toList();
        },
      ),
    );
  }

  ExtraLinesData _buildBenchmarkChartExtraLinesData(AppThemeExtension themeExt) {
    return ExtraLinesData(
      horizontalLines: _isNormalizedView
          ? []
          : [
              HorizontalLine(
                y: 100,
                color: themeExt.textSecondary.withOpacity(0.3),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ],
    );
  }

  Widget _buildPerformanceChart() {
    final ext = Theme.of(context).extension<AppThemeExtension>() ??
                AppThemeExtension(
                  primaryColor: AppTheme.primaryColor, accentColor: AppTheme.accentColor,
                  positiveColor: AppTheme.positiveColor, negativeColor: AppTheme.negativeColor,
                  warningColor: AppTheme.warningColor, cardColor: AppTheme.cardColor,
                  cardColorLight: AppTheme.cardColorLight, textPrimary: AppTheme.textPrimary,
                  textSecondary: AppTheme.textSecondary, gradientColors: AppTheme.primaryGradient,
                  isDark: WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
                  themeStyle: ThemeStyle.modern,
                  gradientBackgroundColors: [AppTheme.backgroundColor, const Color(0xFF192138)]
                );
    final cardColor = ext.cardColor;
    final textSecondary = ext.textSecondary;

    Map<String, List<FlSpot>> chartDataSets = {}; // Changed name from normalizedDataSets for clarity
    int expectedPoints = _getExpectedDataPointsForTimeframe(_selectedTimeframe);
    final currentPortfolioDisplayData = _isNormalizedView ? _normalizedPortfolioData : _portfolioPerformanceData;

    if (currentPortfolioDisplayData.isNotEmpty) {
      final List<FlSpot> portfolioSpots = [];
      List<PerformancePoint> pointsToMap = currentPortfolioDisplayData.length == expectedPoints ? currentPortfolioDisplayData : _normalizeDataPointsToMatchTimeframe(currentPortfolioDisplayData);

      double baseValueForDisplayNormalization = !_isNormalizedView && pointsToMap.isNotEmpty ? pointsToMap.first.value : 1.0;
      if(baseValueForDisplayNormalization <=0) baseValueForDisplayNormalization = 1.0; // Avoid division by zero/negative

      for (int i = 0; i < pointsToMap.length; i++) {
          double yValue = _isNormalizedView ? pointsToMap[i].value : (pointsToMap[i].value / baseValueForDisplayNormalization) * 100;
          portfolioSpots.add(FlSpot(i.toDouble(), yValue));
      }
      if (portfolioSpots.isNotEmpty) chartDataSets['Portfolio'] = portfolioSpots;
    }

    for (var benchmark in _benchmarkData) { // _benchmarkData is already switched based on _isNormalizedView
      final List<FlSpot> spots = [];
      if (benchmark.data.isNotEmpty) {
        List<PerformancePoint> pointsToMap = benchmark.data.length == expectedPoints ? benchmark.data : _normalizeDataPointsToMatchTimeframe(benchmark.data);

        double baseValueForDisplayNormalization = !_isNormalizedView && pointsToMap.isNotEmpty ? pointsToMap.first.value : 1.0;
         if(baseValueForDisplayNormalization <=0) baseValueForDisplayNormalization = 1.0;

        for (int i = 0; i < pointsToMap.length; i++) {
          double yValue = _isNormalizedView ? pointsToMap[i].value : (pointsToMap[i].value / baseValueForDisplayNormalization) * 100;
          spots.add(FlSpot(i.toDouble(), yValue));
        }
        if (spots.isNotEmpty) chartDataSets[benchmark.name] = spots;
      }
    }

    if (chartDataSets.isEmpty) {
      return FuturisticCard(child: SizedBox(height: 300, child: Center(child: Text('No data available for comparison', style: TextStyle(color: textSecondary)))));
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isNormalizedView ? 'Normalized Performance Comparison' : 'Performance Comparison', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text(_isNormalizedView ? 'All assets start at 100%' : 'Performance relative to start (100%)', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              _buildViewToggle(),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: _buildBenchmarkChartGridData(ext),
                titlesData: _buildBenchmarkChartTitlesData(ext, expectedPoints, chartDataSets, currentPortfolioDisplayData, _benchmarkData),
                borderData: FlBorderData(show: false),
                lineBarsData: _createLineData(chartDataSets),
                lineTouchData: _buildBenchmarkChartTouchData(ext, chartDataSets, cardColor.withOpacity(0.8)),
                extraLinesData: _buildBenchmarkChartExtraLinesData(ext),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16, runSpacing: 12,
            children: chartDataSets.keys.map((name) { // Use chartDataSets keys for legend
              final id = _getBenchmarkIdForName(name);
              final color = (name == 'Portfolio') ? _portfolioColor : _getBenchmarkColor(id);
              final isCustom = _isCustomBenchmarkId(id);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4, spreadRadius: 1, offset: const Offset(0, 2))], border: isCustom ? Border.all(color: Colors.white.withOpacity(0.7), width: 1.5) : null)),
                  const SizedBox(width: 6),
                  Text(name, style: TextStyle(color: ext.textPrimary, fontSize: 12, fontWeight: isCustom ? FontWeight.bold : FontWeight.w500)),
                  if (isCustom) Container(margin: const EdgeInsets.only(left: 4), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text('Custom', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold))),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    final accent = Theme.of(context).extension<AppThemeExtension>()?.accentColor ?? AppTheme.accentColor;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withOpacity(0.3), width: 1)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(label: '\$', isActive: !_isNormalizedView, tooltip: 'Show absolute values (chart normalized to start at 100 for comparison)', onTap: () { if (_isNormalizedView) _toggleView(); }),
          _buildToggleButton(label: '%', isActive: _isNormalizedView, tooltip: 'Show normalized performance (all start at 100%)', onTap: () { if (!_isNormalizedView) _toggleView(); }),
        ],
      ),
    );
  }

  Widget _buildToggleButton({ required String label, required bool isActive, required String tooltip, required VoidCallback onTap}) {
    final accent = Theme.of(context).extension<AppThemeExtension>()?.accentColor ?? AppTheme.accentColor;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: isActive ? accent : Colors.transparent, borderRadius: BorderRadius.circular(16)),
          child: Text(label, style: TextStyle(color: isActive ? Colors.black : AppTheme.textSecondary, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        ),
      ),
    );
  }

  List<LineChartBarData> _createLineData(Map<String, List<FlSpot>> dataSets) {
    final List<LineChartBarData> lineBarsData = [];
    List<String> sortedKeys = dataSets.keys.toList();
    if (sortedKeys.contains('Portfolio')) { sortedKeys.remove('Portfolio'); sortedKeys.insert(0, 'Portfolio'); }
    for (String name in sortedKeys) {
      final spots = dataSets[name]!;
      final id = (name == 'Portfolio') ? 'Portfolio' : _getBenchmarkIdForName(name);
      final color = (name == 'Portfolio') ? _portfolioColor : _getBenchmarkColor(id);
      final isCustom = _isCustomBenchmarkId(id);
      lineBarsData.add(LineChartBarData(
        spots: spots, isCurved: true, color: color, barWidth: (name == 'Portfolio') ? 3.5 : (isCustom ? 3.0 : 2.5),
        isStrokeCapRound: true, dotData: FlDotData(show: false), dashArray: isCustom ? [4, 4] : null,
        belowBarData: BarAreaData(show: name == 'Portfolio', gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      ));
    }
    return lineBarsData;
  }

  Widget _buildMetricsComparison() {
    if (_comparisonMetrics == null || _selectedBenchmarkIds.isEmpty) return const SizedBox.shrink();
    final metrics = _comparisonMetrics!;
    final firstStandardBenchmarkId = _selectedBenchmarkIds.firstWhere((id) => !_isCustomBenchmarkId(id), orElse: () => '');
    if (firstStandardBenchmarkId.isEmpty) return const SizedBox.shrink();
    final benchmarkName = _getBenchmarkName(firstStandardBenchmarkId);
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final textPrim = ext.textPrimary;
    final positiveColor = ext.positiveColor;
    final negativeColor = ext.negativeColor;
    Color getMetricColor(double value, bool higherIsBetter) {
      if (value > 0 && higherIsBetter) return positiveColor;
      if (value < 0 && !higherIsBetter) return positiveColor;
      if (value < 0 && higherIsBetter) return negativeColor;
      if (value > 0 && !higherIsBetter) return negativeColor;
      return textPrim;
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comparison with $benchmarkName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildMetricCard('Alpha', 'Alpha', '${metrics.alpha.toStringAsFixed(2)}%', 'Excess return vs market risk', metrics.alpha > 0 ? Icons.trending_up : Icons.trending_down, getMetricColor(metrics.alpha, true))),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricCard('Beta', 'Beta', metrics.beta.toStringAsFixed(2), 'Volatility vs benchmark', metrics.beta < 1 ? Icons.shield_outlined : Icons.waves, metrics.beta > 1.5 ? negativeColor : (metrics.beta < 0.8 ? positiveColor : textPrim))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _buildMetricCard('Correlation', 'Correlation', '${(metrics.correlation * 100).toStringAsFixed(0)}%', 'How returns move together', metrics.correlation > 0.7 ? Icons.link : Icons.link_off, textPrim)),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricCard('R-Squared', 'R-Squared', '${(metrics.rSquared * 100).toStringAsFixed(0)}%', '% returns explained by benchmark', null, textPrim)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _buildMetricCard('Sharpe Ratio', 'Sharpe Ratio', metrics.sharpeRatio.toStringAsFixed(2), 'Return per unit of total risk', null, metrics.sharpeRatio > 1 ? positiveColor : (metrics.sharpeRatio < 0 ? negativeColor : textPrim))),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricCard('Information Ratio', 'Information Ratio', metrics.informationRatio.toStringAsFixed(2), 'Excess return per unit of tracking risk', null, metrics.informationRatio > 0.5 ? positiveColor : (metrics.informationRatio < -0.5 ? negativeColor : textPrim))),
          ]),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String metricKey, String titleDisplay, String value, String description, IconData? icon, Color color) {
    final cardColor = Theme.of(context).extension<AppThemeExtension>()?.cardColor ?? AppTheme.cardColor;
    final explanation = _metricExplanations[metricKey];
    final textSecondaryColor = Theme.of(context).extension<AppThemeExtension>()?.textSecondary ?? AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(titleDisplay, style: TextStyle(fontSize: 12, color: textSecondaryColor)),
                    if (explanation != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: IconButton(
                          icon: Icon(Icons.info_outline, color: textSecondaryColor.withOpacity(0.7), size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          splashRadius: 16,
                          onPressed: () => _showExplanationDialog(titleDisplay, explanation),
                        ),
                      ),
                  ],
                ),
              ),
              if (icon != null) Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _showExplanationDialog(String title, String explanation) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>()!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeExtension.cardColor,
          title: Text(title, style: TextStyle(color: themeExtension.textPrimary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(explanation, style: TextStyle(color: themeExtension.textPrimary.withOpacity(0.85), height: 1.5)),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: themeExtension.accentColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      },
    );
  }

  Widget _buildReturnStatistics() {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final textPrim = ext.textPrimary;
    final textSecondary = ext.textSecondary;
    final positiveColor = ext.positiveColor;
    final negativeColor = ext.negativeColor;

    if (_benchmarkData.isEmpty && _portfolioPerformanceData.isEmpty) return const SizedBox.shrink();

    final List<TableRow> rows = [];
    rows.add(TableRow(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: textSecondary.withOpacity(0.3), width: 1))),
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Asset', style: TextStyle(fontWeight: FontWeight.bold, color: textPrim))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Return (${_selectedTimeframe})', style: TextStyle(fontWeight: FontWeight.bold, color: textPrim), textAlign: TextAlign.right)),
      ],
    ));

    if (_portfolioPerformanceData.isNotEmpty) {
      final portfolioName = widget.portfolio?.name ?? 'All Portfolios';
      double displayReturn = _isNormalizedView && _normalizedPortfolioData.isNotEmpty ? _normalizedPortfolioData.last.value - 100 : _portfolioReturn;
      rows.add(TableRow(
        decoration: BoxDecoration(color: _portfolioColor.withOpacity(0.1), border: Border(bottom: BorderSide(color: textSecondary.withOpacity(0.1), width: 1))),
        children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: _portfolioColor, shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(portfolioName, style: TextStyle(fontWeight: FontWeight.bold, color: textPrim), overflow: TextOverflow.ellipsis))])),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${displayReturn >= 0 ? '+' : ''}${displayReturn.toStringAsFixed(2)}%', style: TextStyle(fontWeight: FontWeight.bold, color: displayReturn >= 0 ? positiveColor : negativeColor), textAlign: TextAlign.right)),
        ],
      ));
    }

    List<BenchmarkData> sortedBenchmarkData = [];
    for (String id in _selectedBenchmarkIds) {
      var found = _benchmarkData.where((b) => b.id == id);
      if (found.isNotEmpty) sortedBenchmarkData.add(found.first);
    }

    for (final benchmark in sortedBenchmarkData) {
      final benchmarkId = benchmark.id;
      final color = _getBenchmarkColor(benchmarkId);
      final isCustom = _isCustomBenchmarkId(benchmarkId);
      double displayReturn = benchmark.returnPercent;
      rows.add(TableRow(
        decoration: BoxDecoration(color: isCustom ? color.withOpacity(0.05) : null, border: Border(bottom: BorderSide(color: textSecondary.withOpacity(0.1), width: 1))),
        children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: isCustom ? Border.all(color: Colors.white.withOpacity(0.5), width: 1) : null)), const SizedBox(width: 8), Expanded(child: Text(benchmark.name, style: TextStyle(color: textPrim, fontWeight: isCustom ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis)), if (isCustom) Icon(Icons.star_border, color: color.withOpacity(0.7), size: 14)])),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${displayReturn >= 0 ? '+' : ''}${displayReturn.toStringAsFixed(2)}%', style: TextStyle(color: displayReturn >= 0 ? positiveColor : negativeColor, fontWeight: isCustom ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.right)),
        ],
      ));
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isNormalizedView ? 'Normalized Return Comparison' : 'Return Comparison', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Table(columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)}, defaultVerticalAlignment: TableCellVerticalAlignment.middle, children: rows),
        ],
      ),
    );
  }

  Color _getBenchmarkColor(String benchmarkId) {
    if (_assignedBenchmarkColors.containsKey(benchmarkId)) return _assignedBenchmarkColors[benchmarkId]!;
    Color color;
    if (_isCustomBenchmarkId(benchmarkId)) {
      color = _customTickerSpecificColors.isNotEmpty ? _customTickerSpecificColors[_nextCustomColorIndex++ % _customTickerSpecificColors.length] : Colors.grey.shade700;
    } else {
      color = _benchmarkColors.isNotEmpty ? _benchmarkColors[_nextBenchmarkColorIndex++ % _benchmarkColors.length] : Colors.grey.shade500;
    }
    _assignedBenchmarkColors[benchmarkId] = color;
    return color;
  }

  void _resetColorAssignments() {
    _assignedBenchmarkColors.clear();
    _nextBenchmarkColorIndex = 0;
    _nextCustomColorIndex = 0;
  }

  String _getBenchmarkName(String benchmarkId) {
    if (_isCustomBenchmarkId(benchmarkId)) return benchmarkId.substring('CUSTOM_'.length);
    final benchmark = _availableBenchmarks.firstWhere((b) => b.id == benchmarkId, orElse: () => benchmark_service_ns.BenchmarkInfo(id: benchmarkId, name: benchmarkId, symbol: benchmarkId, description: '', category: '', region: ''));
    return benchmark.name;
  }

  String _getBenchmarkIdForName(String name) {
    for (final data in _benchmarkData) if (data.name == name) return data.id;
    final availableInfo = _availableBenchmarks.firstWhere((b) => b.name == name, orElse: () {
      bool mightBeCustom = !_availableBenchmarks.any((bInfo) => bInfo.name == name);
      return benchmark_service_ns.BenchmarkInfo(id: mightBeCustom ? 'CUSTOM_$name' : name, name: name, symbol: name, category: '', description: '', region: '');
    });
    return availableInfo.id;
  }

  String _getDatasetNameForLineId(int lineId, List<String> datasetKeys) {
    return (lineId >= 0 && lineId < datasetKeys.length) ? datasetKeys[lineId] : 'Unknown';
  }

  Color _getColorForLineId(int lineId, List<String> datasetKeys) {
    if (lineId < 0 || lineId >= datasetKeys.length) return Colors.grey;
    final name = datasetKeys[lineId];
    if (name == 'Portfolio') return _portfolioColor;
    final id = _getBenchmarkIdForName(name);
    return _getBenchmarkColor(id);
  }
}

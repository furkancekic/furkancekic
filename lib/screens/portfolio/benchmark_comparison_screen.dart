import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/portfolio.dart';
import '../../services/portfolio_service.dart' as portfolio_service;
import '../../services/portfolio_benchmark_service.dart';
import '../../services/stock_api_service.dart';

class BenchmarkComparisonScreen extends StatefulWidget {
  final Portfolio?
      portfolio; // Optional: if null, compares all portfolios combined

  const BenchmarkComparisonScreen({
    Key? key,
    this.portfolio,
  }) : super(key: key);

  @override
  State<BenchmarkComparisonScreen> createState() =>
      _BenchmarkComparisonScreenState();
}

class _BenchmarkComparisonScreenState extends State<BenchmarkComparisonScreen> {
  bool _isLoading = true;
  List<BenchmarkInfo> _availableBenchmarks = [];
  List<String> _selectedBenchmarkIds = [];
  String _selectedTimeframe = '1M'; // Default to 1 month view
  final List<String> _timeframes = ['1W', '1M', '3M', '6M', '1Y', 'All'];

  // NEW: Toggle for normalized view
  bool _isNormalizedView =
      false; // false = absolute values, true = normalized (100% start)

  // NEW: Separate data storage for both views
  List<BenchmarkData> _absoluteBenchmarkData = [];
  List<BenchmarkData> _normalizedBenchmarkData = [];

  // Custom ticker controller and state variables
  final TextEditingController _customTickerController = TextEditingController();
  String? _customTicker;
  bool _isCustomTickerValid = false;
  bool _isValidatingTicker = false;

  List<BenchmarkData> _benchmarkData = [];
  PortfolioBenchmarkMetrics? _comparisonMetrics;

  // Portfolio data
  List<PerformancePoint> _portfolioPerformanceData = [];
  List<PerformancePoint> _normalizedPortfolioData = [];
  double _portfolioReturn = 0.0;

  // Date range for normalization
  DateTime? _startDate;
  DateTime? _endDate;

  // Colors for different benchmarks and portfolio
  final Color _portfolioColor = Colors.blue;
  final List<Color> _benchmarkColors = [
    Colors.red.shade400,
    Colors.green.shade600,
    Colors.orange.shade500,
    Colors.purple.shade400,
    Colors.teal.shade500,
    Colors.yellow.shade700,
    Colors.pink.shade300,
    Colors.indigo.shade400,
    Colors.lightGreen.shade500,
    Colors.deepOrange.shade400,
    Colors.cyan.shade500,
    Colors.blueGrey.shade400,
  ];

  // Özel tickerlar için kullanılacak renkler
  final List<Color> _customTickerSpecificColors = [
    Colors.pinkAccent.shade200,
    Colors.lightBlueAccent.shade200,
    Colors.amberAccent.shade200,
    Colors.deepPurpleAccent.shade100,
    Colors.tealAccent.shade200,
    Colors.redAccent.shade100,
    Colors.greenAccent.shade400,
    Colors.orangeAccent.shade200,
  ];

  @override
  void initState() {
    super.initState();
    _loadBenchmarks();

    // Default selections based on portfolio type or user region
    if (widget.portfolio?.name.contains('Tech') ?? false) {
      _selectedBenchmarkIds = ['NASDAQ', 'SP500'];
    } else if (widget.portfolio?.name.contains('Dividend') ?? false) {
      _selectedBenchmarkIds = ['SP500', 'DOW'];
    } else {
      _selectedBenchmarkIds = ['SP500']; // Default benchmark
    }
  }

  @override
  void dispose() {
    _customTickerController.dispose();
    super.dispose();
  }

  Future<void> _loadBenchmarks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load available benchmarks
      _availableBenchmarks =
          await PortfolioBenchmarkService.getAvailableBenchmarks();

      // Load portfolio data first
      await _loadPortfolioData();

      // Then load benchmark data for selected benchmarks
      await _loadBenchmarkData();

      // Load comparison metrics if a specific portfolio is selected
      if (widget.portfolio != null && _selectedBenchmarkIds.isNotEmpty) {
        final firstBenchmarkId = _selectedBenchmarkIds.firstWhere(
          (id) => !_isCustomBenchmarkId(id),
          orElse: () => _selectedBenchmarkIds.isNotEmpty
              ? _selectedBenchmarkIds.first
              : '',
        );
        if (firstBenchmarkId.isNotEmpty) {
          _comparisonMetrics =
              await PortfolioBenchmarkService.compareToBenchmark(
            widget.portfolio!.id!,
            firstBenchmarkId,
            _selectedTimeframe,
          );
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load benchmark data: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  // Validate ticker
  Future<bool> _validateTicker(String ticker) async {
    if (ticker.isEmpty) return false;

    setState(() {
      _isValidatingTicker = true;
    });

    try {
      final stockInfo = await StockApiService.getStockInfo(ticker);
      final isValid = stockInfo.price > 0;

      setState(() {
        _isValidatingTicker = false;
        _isCustomTickerValid = isValid;
      });

      return isValid;
    } catch (e) {
      setState(() {
        _isValidatingTicker = false;
        _isCustomTickerValid = false;
      });
      return false;
    }
  }

  // Add custom ticker to benchmarks
  Future<void> _addCustomTicker() async {
    final ticker = _customTickerController.text.trim().toUpperCase();
    if (ticker.isEmpty) return;

    // Validate ticker
    final isValid = await _validateTicker(ticker);
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid ticker symbol. Please enter a valid ticker.'),
          backgroundColor: AppTheme.negativeColor,
        ),
      );
      return;
    }

    // Create custom ID (e.g., 'CUSTOM_AAPL')
    final customId = 'CUSTOM_$ticker';

    // If already selected, don't add again
    if (_selectedBenchmarkIds.contains(customId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$ticker is already added.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedBenchmarkIds.add(customId);
      _customTickerController.clear();
      _isCustomTickerValid = false;
    });

    // Reload benchmark data
    await _loadBenchmarkData();
  }

  // Determine date range based on timeframe
  void _determineTimeframeDateRange() {
    final now = DateTime.now();
    _endDate = now;

    switch (_selectedTimeframe) {
      case '1W':
        _startDate = now.subtract(const Duration(days: 7));
        break;
      case '1M':
        _startDate = now.subtract(const Duration(days: 30));
        break;
      case '3M':
        _startDate = now.subtract(const Duration(days: 90));
        break;
      case '6M':
        _startDate = now.subtract(const Duration(days: 180));
        break;
      case '1Y':
        _startDate = now.subtract(const Duration(days: 365));
        break;
      case 'All':
        _startDate = now.subtract(const Duration(days: 3 * 365));
        break;
      default:
        _startDate = now.subtract(const Duration(days: 30));
    }
  }

  Future<void> _loadPortfolioData() async {
    try {
      _determineTimeframeDateRange();

      if (widget.portfolio != null) {
        // Load both regular and normalized portfolio data
        final performance =
            await portfolio_service.PortfolioService.getPortfolioPerformance(
          widget.portfolio!.id!,
          _selectedTimeframe,
        );

        // Try to load normalized performance
        List<portfolio_service.PerformancePoint> normalizedPerformance = [];
        try {
          final normalizedResult = await portfolio_service.PortfolioService
              .getNormalizedPortfolioPerformance(
            widget.portfolio!.id!,
            _selectedTimeframe,
          );
          normalizedPerformance = normalizedResult.data;
        } catch (e) {
          print('Normalized portfolio data not available: $e');
          // Fallback: create normalized data from regular data
          if (performance.data.isNotEmpty) {
            final baseValue = performance.data.first.value;
            normalizedPerformance = performance.data
                .map((point) => portfolio_service.PerformancePoint(
                      date: point.date,
                      value: (point.value / baseValue) * 100,
                    ))
                .toList();
          }
        }

        final convertedData = _convertPerformancePoints(performance.data);
        final convertedNormalizedData =
            _convertPerformancePoints(normalizedPerformance);

        setState(() {
          _portfolioPerformanceData = convertedData;
          _normalizedPortfolioData = convertedNormalizedData;

          if (_portfolioPerformanceData.isNotEmpty) {
            final firstValue = _portfolioPerformanceData.first.value;
            final lastValue = _portfolioPerformanceData.last.value;
            if (firstValue > 0) {
              _portfolioReturn = ((lastValue / firstValue) - 1) * 100;
            } else {
              _portfolioReturn = 0.0;
            }
          } else {
            _portfolioReturn = 0.0;
          }
        });
      } else {
        // Load total portfolio performance
        final performance = await portfolio_service.PortfolioService
            .getTotalPortfoliosPerformance(_selectedTimeframe);

        List<portfolio_service.PerformancePoint> normalizedPerformance = [];
        try {
          final normalizedResult = await portfolio_service.PortfolioService
              .getNormalizedTotalPortfoliosPerformance(_selectedTimeframe);
          normalizedPerformance = normalizedResult.data;
        } catch (e) {
          print('Normalized total portfolio data not available: $e');
          // Fallback: create normalized data from regular data
          if (performance.data.isNotEmpty) {
            final baseValue = performance.data.first.value;
            normalizedPerformance = performance.data
                .map((point) => portfolio_service.PerformancePoint(
                      date: point.date,
                      value: (point.value / baseValue) * 100,
                    ))
                .toList();
          }
        }

        final convertedData = _convertPerformancePoints(performance.data);
        final convertedNormalizedData =
            _convertPerformancePoints(normalizedPerformance);

        setState(() {
          _portfolioPerformanceData = convertedData;
          _normalizedPortfolioData = convertedNormalizedData;

          if (_portfolioPerformanceData.isNotEmpty) {
            final firstValue = _portfolioPerformanceData.first.value;
            final lastValue = _portfolioPerformanceData.last.value;
            if (firstValue > 0) {
              _portfolioReturn = ((lastValue / firstValue) - 1) * 100;
            } else {
              _portfolioReturn = 0.0;
            }
          } else {
            _portfolioReturn = 0.0;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load portfolio data: $e'),
          backgroundColor: AppTheme.negativeColor,
        ),
      );
    }
  }

  List<PerformancePoint> _convertPerformancePoints(
      List<portfolio_service.PerformancePoint> points) {
    return points
        .map((p) => PerformancePoint(date: p.date, value: p.value))
        .toList();
  }

  // NEW: Updated to load both absolute and normalized data
  Future<void> _loadBenchmarkData() async {
    try {
      // Load both absolute and normalized data in parallel
      await Future.wait([
        _loadAbsoluteBenchmarkData(),
        _loadNormalizedBenchmarkData(),
      ]);

      // Update the main _benchmarkData based on current view
      setState(() {
        _benchmarkData = _isNormalizedView
            ? _normalizedBenchmarkData
            : _absoluteBenchmarkData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load benchmark data: $e'),
          backgroundColor: AppTheme.negativeColor,
        ),
      );
    }
  }

  Future<void> _loadAbsoluteBenchmarkData() async {
    try {
      List<BenchmarkData> newBenchmarkData = [];

      for (String id in _selectedBenchmarkIds) {
        if (_isCustomBenchmarkId(id)) {
          // Custom Ticker
          final ticker = id.substring('CUSTOM_'.length);
          try {
            final String interval =
                _getApiIntervalForTimeframe(_selectedTimeframe);
            final stockData = await StockApiService.getStockData(
                ticker, _selectedTimeframe,
                startDate: _startDate?.toIso8601String(),
                endDate: _endDate?.toIso8601String(),
                interval: interval);

            if (stockData.isNotEmpty) {
              List<PerformancePoint> dataPoints = [];
              for (var point in stockData) {
                if (point.containsKey('date') && point.containsKey('close')) {
                  dataPoints.add(PerformancePoint(
                    date: DateTime.parse(point['date'].toString()),
                    value: double.parse(point['close'].toString()),
                  ));
                }
              }
              dataPoints.sort((a, b) => a.date.compareTo(b.date));

              double returnPercent = 0;
              if (dataPoints.isNotEmpty && dataPoints.first.value > 0) {
                returnPercent =
                    ((dataPoints.last.value / dataPoints.first.value) - 1) *
                        100;
              }

              final normalizedPoints =
                  _normalizeDataPointsToMatchTimeframe(dataPoints);
              newBenchmarkData.add(BenchmarkData(
                id: id,
                name: ticker,
                symbol: ticker,
                timeframe: _selectedTimeframe,
                data: normalizedPoints,
                returnPercent: returnPercent,
              ));
            }
          } catch (e) {
            print('Error loading custom ticker data ($ticker): $e');
          }
        }
      }

      // Load standard benchmarks
      List<String> standardBenchmarkIdsToLoad = _selectedBenchmarkIds
          .where((id) => !_isCustomBenchmarkId(id))
          .toList();
      if (standardBenchmarkIdsToLoad.isNotEmpty) {
        List<BenchmarkData> standardData =
            await PortfolioBenchmarkService.getBenchmarkPerformance(
          _selectedTimeframe,
          standardBenchmarkIdsToLoad,
        );
        newBenchmarkData.addAll(standardData);
      }

      setState(() {
        _absoluteBenchmarkData = newBenchmarkData;
        if (!_isNormalizedView) {
          _benchmarkData = _absoluteBenchmarkData;
        }
      });
    } catch (e) {
      print('Error loading absolute benchmark data: $e');
    }
  }

  Future<void> _loadNormalizedBenchmarkData() async {
    try {
      List<BenchmarkData> newNormalizedData = [];

      // For custom tickers, normalize the absolute data
      for (String id in _selectedBenchmarkIds) {
        if (_isCustomBenchmarkId(id)) {
          final absoluteData = _absoluteBenchmarkData.firstWhere(
            (data) => data.id == id,
            orElse: () => BenchmarkData(
              id: id,
              name: id.substring('CUSTOM_'.length),
              symbol: id.substring('CUSTOM_'.length),
              timeframe: _selectedTimeframe,
              data: [],
              returnPercent: 0.0,
            ),
          );

          if (absoluteData.data.isNotEmpty) {
            final normalizedData =
                _normalizeToHundredPercent(absoluteData.data);
            final returnPercent = normalizedData.isNotEmpty
                ? normalizedData.last.value - 100
                : 0.0;

            newNormalizedData.add(BenchmarkData(
              id: id,
              name: absoluteData.name,
              symbol: absoluteData.symbol,
              timeframe: _selectedTimeframe,
              data: normalizedData,
              returnPercent: returnPercent,
            ));
          }
        }
      }

      // Load normalized standard benchmarks
      List<String> standardBenchmarkIdsToLoad = _selectedBenchmarkIds
          .where((id) => !_isCustomBenchmarkId(id))
          .toList();
      if (standardBenchmarkIdsToLoad.isNotEmpty) {
        try {
          List<BenchmarkData> standardNormalizedData =
              await PortfolioBenchmarkService.getNormalizedBenchmarkPerformance(
            _selectedTimeframe,
            standardBenchmarkIdsToLoad,
          );
          newNormalizedData.addAll(standardNormalizedData);
        } catch (e) {
          print(
              'Normalized benchmark service not available, using fallback: $e');
          // Fallback: normalize the absolute data
          for (String id in standardBenchmarkIdsToLoad) {
            final absoluteData = _absoluteBenchmarkData.firstWhere(
              (data) => data.id == 'benchmark_$id' || data.id == id,
              orElse: () => BenchmarkData(
                  id: id,
                  name: id,
                  symbol: id,
                  timeframe: _selectedTimeframe,
                  data: [],
                  returnPercent: 0.0),
            );

            if (absoluteData.data.isNotEmpty) {
              final normalizedData =
                  _normalizeToHundredPercent(absoluteData.data);
              final returnPercent = normalizedData.isNotEmpty
                  ? normalizedData.last.value - 100
                  : 0.0;

              newNormalizedData.add(BenchmarkData(
                id: absoluteData.id,
                name: absoluteData.name,
                symbol: absoluteData.symbol,
                timeframe: _selectedTimeframe,
                data: normalizedData,
                returnPercent: returnPercent,
              ));
            }
          }
        }
      }

      setState(() {
        _normalizedBenchmarkData = newNormalizedData;
        if (_isNormalizedView) {
          _benchmarkData = _normalizedBenchmarkData;
        }
      });
    } catch (e) {
      print('Error loading normalized benchmark data: $e');
    }
  }

  // NEW: Helper method to normalize data to 100% start
  List<PerformancePoint> _normalizeToHundredPercent(
      List<PerformancePoint> data) {
    if (data.isEmpty) return [];

    final baseValue = data.first.value;
    if (baseValue <= 0) return data;

    return data
        .map((point) => PerformancePoint(
              date: point.date,
              value: (point.value / baseValue) * 100,
            ))
        .toList();
  }

  // NEW: Toggle between views
  void _toggleView() {
    setState(() {
      _isNormalizedView = !_isNormalizedView;
      // Switch the data source
      _benchmarkData =
          _isNormalizedView ? _normalizedBenchmarkData : _absoluteBenchmarkData;
    });
  }

  String _getApiIntervalForTimeframe(String timeframe) {
    switch (timeframe) {
      case '1W':
        return '1d';
      case '1M':
        return '1d';
      case '3M':
        return '1d';
      case '6M':
        return '1d';
      case '1Y':
        return '1wk';
      case 'All':
        return '1mo';
      default:
        return '1d';
    }
  }

  List<PerformancePoint> _normalizeDataPointsToMatchTimeframe(
      List<PerformancePoint> points) {
    if (points.isEmpty) return [];

    final expectedPoints =
        _getExpectedDataPointsForTimeframe(_selectedTimeframe);
    if (points.length == expectedPoints || points.length < 2) {
      return points;
    }

    if (points.length > expectedPoints) {
      final sampledPoints = <PerformancePoint>[];
      final step = (points.length - 1) / (expectedPoints - 1);

      for (int i = 0; i < expectedPoints; i++) {
        final index = (i * step).round();
        if (index < points.length) {
          sampledPoints.add(points[index]);
        }
      }

      if (sampledPoints.isEmpty ||
          sampledPoints.last.date != points.last.date) {
        if (sampledPoints.isNotEmpty && sampledPoints.length >= expectedPoints)
          sampledPoints.removeLast();
        sampledPoints.add(points.last);
      }
      return sampledPoints.take(expectedPoints).toList();
    }
    return points;
  }

  int _getExpectedDataPointsForTimeframe(String timeframe) {
    switch (timeframe) {
      case '1W':
        return 7;
      case '1M':
        return 15;
      case '3M':
        return 15;
      case '6M':
        return 15;
      case '1Y':
        return 12;
      case 'All':
        return 20;
      default:
        return 15;
    }
  }

  void _updateSelectedBenchmarks(String benchmarkId, bool isSelected) {
    setState(() {
      if (isSelected) {
        if (!_selectedBenchmarkIds.contains(benchmarkId)) {
          _selectedBenchmarkIds.add(benchmarkId);
        }
      } else {
        _selectedBenchmarkIds.remove(benchmarkId);
      }
    });

    _loadBenchmarkData();

    if (widget.portfolio != null && _selectedBenchmarkIds.isNotEmpty) {
      final firstStandardBenchmarkId = _selectedBenchmarkIds.firstWhere(
        (id) => !_isCustomBenchmarkId(id),
        orElse: () => '',
      );
      if (firstStandardBenchmarkId.isNotEmpty) {
        PortfolioBenchmarkService.compareToBenchmark(
          widget.portfolio!.id!,
          firstStandardBenchmarkId,
          _selectedTimeframe,
        ).then((metrics) {
          if (mounted) setState(() => _comparisonMetrics = metrics);
        });
      } else {
        if (mounted) setState(() => _comparisonMetrics = null);
      }
    } else {
      if (mounted) setState(() => _comparisonMetrics = null);
    }
  }

  bool _isCustomBenchmarkId(String id) {
    return id.startsWith('CUSTOM_');
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final textPrim = ext?.textPrimary ?? AppTheme.textPrimary;
    final accent = ext?.accentColor ?? AppTheme.accentColor;

    final String screenTitle = widget.portfolio != null
        ? 'Compare: ${widget.portfolio!.name}'
        : 'Benchmark Comparison';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          screenTitle,
          style: TextStyle(color: textPrim, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFF192138),
            ],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: accent))
            : RefreshIndicator(
                onRefresh: _loadBenchmarks,
                backgroundColor: ext?.cardColor ?? AppTheme.cardColor,
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
                    if (widget.portfolio != null && _comparisonMetrics != null)
                      _buildMetricsComparison(),
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
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = ext?.cardColor ?? AppTheme.cardColor;
    final accent = ext?.accentColor ?? AppTheme.accentColor;
    final textPrim = ext?.textPrimary ?? AppTheme.textPrimary;

    List<String> customTickersAdded = _selectedBenchmarkIds
        .where((id) => _isCustomBenchmarkId(id))
        .map((id) => id.substring('CUSTOM_'.length))
        .toList();

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Custom Ticker',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Add any stock ticker to compare (max 3 total selections)',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customTickerController,
                  style: TextStyle(color: textPrim),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cardColor.withOpacity(0.5),
                    hintText: 'Enter ticker (e.g. AAPL)',
                    hintStyle: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.5)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    suffixIcon: _isValidatingTicker
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)))
                        : _isCustomTickerValid
                            ? Icon(Icons.check_circle,
                                color: AppTheme.positiveColor)
                            : null,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    if (value != value.toUpperCase()) {
                      _customTickerController.value = TextEditingValue(
                        text: value.toUpperCase(),
                        selection: _customTickerController.selection,
                      );
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _customTickerController.text.trim().isEmpty ||
                        _isValidatingTicker
                    ? null
                    : _addCustomTicker,
                style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: const Text('Add'),
              ),
            ],
          ),
          if (customTickersAdded.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: customTickersAdded.map((ticker) {
                return Chip(
                  label: Text(ticker),
                  backgroundColor:
                      _getBenchmarkColor('CUSTOM_$ticker').withOpacity(0.7),
                  labelStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  deleteIcon:
                      const Icon(Icons.close, size: 16, color: Colors.white70),
                  onDeleted: () {
                    setState(() {
                      _selectedBenchmarkIds.remove('CUSTOM_$ticker');
                    });
                    _loadBenchmarkData();
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timeframes.length,
        itemBuilder: (context, index) {
          final timeframe = _timeframes[index];
          final isSelected = timeframe == _selectedTimeframe;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(timeframe),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTimeframe = timeframe);
                  _determineTimeframeDateRange();
                  _loadPortfolioData().then((_) => _loadBenchmarkData());
                  if (widget.portfolio != null &&
                      _selectedBenchmarkIds.isNotEmpty) {
                    final firstStandardBenchmarkId =
                        _selectedBenchmarkIds.firstWhere(
                      (id) => !_isCustomBenchmarkId(id),
                      orElse: () => '',
                    );
                    if (firstStandardBenchmarkId.isNotEmpty) {
                      PortfolioBenchmarkService.compareToBenchmark(
                        widget.portfolio!.id!,
                        firstStandardBenchmarkId,
                        _selectedTimeframe,
                      ).then((metrics) {
                        if (mounted)
                          setState(() => _comparisonMetrics = metrics);
                      });
                    } else {
                      if (mounted) setState(() => _comparisonMetrics = null);
                    }
                  }
                }
              },
              backgroundColor:
                  Theme.of(context).extension<AppThemeExtension>()?.cardColor ??
                      AppTheme.cardColor,
              selectedColor: Theme.of(context)
                      .extension<AppThemeExtension>()
                      ?.accentColor ??
                  AppTheme.accentColor,
              labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.black
                      : Theme.of(context)
                              .extension<AppThemeExtension>()
                              ?.textPrimary ??
                          AppTheme.textPrimary),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenchmarkSelector() {
    final cardColor =
        Theme.of(context).extension<AppThemeExtension>()?.cardColor ??
            AppTheme.cardColor;
    final textPrim =
        Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
            AppTheme.textPrimary;

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Benchmarks',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          ...['Equity', 'Currency', 'Commodity', 'Crypto', 'Volatility']
              .map((category) {
            final benchmarksInCategory = _availableBenchmarks
                .where((b) => b.category == category)
                .toList();
            if (benchmarksInCategory.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrim.withOpacity(0.7))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: benchmarksInCategory.map((benchmark) {
                    final isSelected =
                        _selectedBenchmarkIds.contains(benchmark.id);
                    return FilterChip(
                      label: Text(benchmark.name),
                      selected: isSelected,
                      onSelected: (selected) =>
                          _updateSelectedBenchmarks(benchmark.id, selected),
                      backgroundColor: cardColor,
                      selectedColor: _getBenchmarkColor(benchmark.id),
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textPrim,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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

  // UPDATED: Performance chart with toggle
  Widget _buildPerformanceChart() {
    final cardColor =
        Theme.of(context).extension<AppThemeExtension>()?.cardColor ??
            AppTheme.cardColor;
    final textPrim =
        Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
            AppTheme.textPrimary;
    final textSecondary =
        Theme.of(context).extension<AppThemeExtension>()?.textSecondary ??
            AppTheme.textSecondary;

    Map<String, List<FlSpot>> normalizedDataSets = {};
    int expectedPoints = _getExpectedDataPointsForTimeframe(_selectedTimeframe);

    // Use the appropriate portfolio data based on view
    final currentPortfolioData = _isNormalizedView
        ? _normalizedPortfolioData
        : _portfolioPerformanceData;

    if (currentPortfolioData.isNotEmpty) {
      final List<FlSpot> portfolioSpots = [];

      if (_isNormalizedView) {
        // For normalized view, data is already normalized to 100%
        List<PerformancePoint> pointsToNormalize =
            currentPortfolioData.length == expectedPoints
                ? currentPortfolioData
                : _normalizeDataPointsToMatchTimeframe(currentPortfolioData);

        for (int i = 0; i < pointsToNormalize.length; i++) {
          portfolioSpots.add(FlSpot(i.toDouble(), pointsToNormalize[i].value));
        }
      } else {
        // For absolute view, normalize to start at 100 for chart display
        double baseValue = currentPortfolioData.first.value;
        if (baseValue > 0) {
          List<PerformancePoint> pointsToNormalize =
              currentPortfolioData.length == expectedPoints
                  ? currentPortfolioData
                  : _normalizeDataPointsToMatchTimeframe(currentPortfolioData);

          for (int i = 0; i < pointsToNormalize.length; i++) {
            double normalizedValue =
                (pointsToNormalize[i].value / baseValue) * 100;
            portfolioSpots.add(FlSpot(i.toDouble(), normalizedValue));
          }
        }
      }

      if (portfolioSpots.isNotEmpty) {
        normalizedDataSets['Portfolio'] = portfolioSpots;
      }
    }

    for (var benchmark in _benchmarkData) {
      final List<FlSpot> spots = [];
      if (benchmark.data.isNotEmpty) {
        if (_isNormalizedView) {
          // For normalized view, data is already normalized to 100%
          List<PerformancePoint> pointsToNormalize =
              benchmark.data.length == expectedPoints
                  ? benchmark.data
                  : _normalizeDataPointsToMatchTimeframe(benchmark.data);

          for (int i = 0; i < pointsToNormalize.length; i++) {
            spots.add(FlSpot(i.toDouble(), pointsToNormalize[i].value));
          }
        } else {
          // For absolute view, normalize to start at 100 for chart display
          double baseValue = benchmark.data.first.value;
          if (baseValue > 0) {
            List<PerformancePoint> pointsToNormalize =
                benchmark.data.length == expectedPoints
                    ? benchmark.data
                    : _normalizeDataPointsToMatchTimeframe(benchmark.data);

            for (int i = 0; i < pointsToNormalize.length; i++) {
              double normalizedValue =
                  (pointsToNormalize[i].value / baseValue) * 100;
              spots.add(FlSpot(i.toDouble(), normalizedValue));
            }
          }
        }

        if (spots.isNotEmpty) {
          normalizedDataSets[benchmark.name] = spots;
        }
      }
    }

    if (normalizedDataSets.isEmpty) {
      return FuturisticCard(
        child: SizedBox(
            height: 300,
            child: Center(
                child: Text('No data available for comparison',
                    style: TextStyle(color: textSecondary)))),
      );
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UPDATED: Header with toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isNormalizedView
                          ? 'Normalized Performance Comparison'
                          : 'Performance Comparison',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _isNormalizedView
                          ? 'All assets start at 100% - shows relative performance'
                          : 'Assets normalized to 100% at start for comparison',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // NEW: Toggle button
              _buildViewToggle(),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                        color: textSecondary.withOpacity(0.1), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: expectedPoints > 5
                          ? (expectedPoints / 5).floorToDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        List<DateTime> dateSeries = [];

                        if (normalizedDataSets['Portfolio'] != null &&
                            currentPortfolioData.length >= expectedPoints) {
                          dateSeries = _normalizeDataPointsToMatchTimeframe(
                                  currentPortfolioData)
                              .map((p) => p.date)
                              .toList();
                        } else if (_benchmarkData.isNotEmpty &&
                            _benchmarkData.first.data.length >=
                                expectedPoints) {
                          dateSeries = _normalizeDataPointsToMatchTimeframe(
                                  _benchmarkData.first.data)
                              .map((p) => p.date)
                              .toList();
                        } else if (currentPortfolioData.isNotEmpty) {
                          dateSeries =
                              currentPortfolioData.map((p) => p.date).toList();
                        }

                        if (dateSeries.isEmpty ||
                            index < 0 ||
                            index >= dateSeries.length) {
                          return const SizedBox.shrink();
                        }
                        final date = dateSeries[index];
                        return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(_getDateLabel(date),
                                style: TextStyle(
                                    color: textSecondary, fontSize: 10)));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (_isNormalizedView) {
                            // For normalized view, show actual percentage values
                            return Text('${value.toInt()}%',
                                style: TextStyle(
                                    color: textSecondary, fontSize: 10));
                          } else {
                            // For absolute view, show as relative percentage
                            final displayValue = value - 100;
                            return Text(
                                '${displayValue >= 0 ? '+' : ''}${displayValue.toInt()}%',
                                style: TextStyle(
                                    color: textSecondary, fontSize: 10));
                          }
                        }),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: _createLineData(normalizedDataSets),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: cardColor.withOpacity(0.8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final datasetName = _getDatasetNameForLineId(
                            spot.barIndex, normalizedDataSets.keys.toList());
                        final displayValue =
                            _isNormalizedView ? spot.y : spot.y - 100;
                        final suffix = _isNormalizedView ? '' : '%';
                        final prefix = _isNormalizedView
                            ? ''
                            : (displayValue >= 0 ? '+' : '');
                        return LineTooltipItem(
                          '$datasetName: $prefix${displayValue.toStringAsFixed(2)}$suffix',
                          TextStyle(
                              color: _getColorForLineId(spot.barIndex,
                                  normalizedDataSets.keys.toList()),
                              fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                // Add baseline at 100% if normalized view
                extraLinesData: _isNormalizedView
                    ? null
                    : ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: 100,
                            color: textSecondary.withOpacity(0.3),
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: normalizedDataSets.keys.map((name) {
              final id = _getBenchmarkIdForName(name);
              final color = (name == 'Portfolio')
                  ? _portfolioColor
                  : _getBenchmarkColor(id);
              final isCustom = _isCustomBenchmarkId(id);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(0, 2))
                      ],
                      border: isCustom
                          ? Border.all(
                              color: Colors.white.withOpacity(0.7), width: 1.5)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(name,
                      style: TextStyle(
                          color: textPrim,
                          fontSize: 12,
                          fontWeight:
                              isCustom ? FontWeight.bold : FontWeight.w500)),
                  if (isCustom)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('Özel',
                          style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // NEW: Build toggle button widget
  Widget _buildViewToggle() {
    final accent =
        Theme.of(context).extension<AppThemeExtension>()?.accentColor ??
            AppTheme.accentColor;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: '\$',
            isActive: !_isNormalizedView,
            tooltip: 'Absolute Values',
            onTap: () {
              if (_isNormalizedView) _toggleView();
            },
          ),
          _buildToggleButton(
            label: '%',
            isActive: _isNormalizedView,
            tooltip: 'Normalized View (100% start)',
            onTap: () {
              if (!_isNormalizedView) _toggleView();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final accent =
        Theme.of(context).extension<AppThemeExtension>()?.accentColor ??
            AppTheme.accentColor;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : AppTheme.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> _createLineData(Map<String, List<FlSpot>> dataSets) {
    final List<LineChartBarData> lineBarsData = [];
    List<String> sortedKeys = dataSets.keys.toList();
    // Portfolio'yu başa al
    if (sortedKeys.contains('Portfolio')) {
      sortedKeys.remove('Portfolio');
      sortedKeys.insert(0, 'Portfolio');
    }

    for (String name in sortedKeys) {
      final spots = dataSets[name]!;
      final id =
          (name == 'Portfolio') ? 'Portfolio' : _getBenchmarkIdForName(name);
      final color =
          (name == 'Portfolio') ? _portfolioColor : _getBenchmarkColor(id);
      final isCustom = _isCustomBenchmarkId(id);

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: (name == 'Portfolio') ? 3.5 : (isCustom ? 2.5 : 2.0),
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          dashArray: isCustom ? [4, 4] : null,
          belowBarData: BarAreaData(
            show: name == 'Portfolio',
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }
    return lineBarsData;
  }

  Widget _buildMetricsComparison() {
    if (_comparisonMetrics == null || _selectedBenchmarkIds.isEmpty)
      return const SizedBox.shrink();

    final metrics = _comparisonMetrics!;
    final firstStandardBenchmarkId = _selectedBenchmarkIds.firstWhere(
      (id) => !_isCustomBenchmarkId(id),
      orElse: () => '',
    );
    if (firstStandardBenchmarkId.isEmpty) return const SizedBox.shrink();

    final benchmarkName = _getBenchmarkName(firstStandardBenchmarkId);
    final textPrim =
        Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
            AppTheme.textPrimary;
    final positiveColor =
        Theme.of(context).extension<AppThemeExtension>()?.positiveColor ??
            AppTheme.positiveColor;
    final negativeColor =
        Theme.of(context).extension<AppThemeExtension>()?.negativeColor ??
            AppTheme.negativeColor;

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
          Text('Comparison with $benchmarkName',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _buildMetricCard(
                    'Alpha',
                    '${metrics.alpha.toStringAsFixed(2)}%',
                    'Excess return vs market risk',
                    metrics.alpha > 0 ? Icons.trending_up : Icons.trending_down,
                    getMetricColor(metrics.alpha, true))),
            const SizedBox(width: 8),
            Expanded(
                child: _buildMetricCard(
                    'Beta',
                    metrics.beta.toStringAsFixed(2),
                    'Volatility vs benchmark',
                    metrics.beta < 1 ? Icons.shield_outlined : Icons.waves,
                    metrics.beta > 1.5
                        ? negativeColor
                        : (metrics.beta < 0.8 ? positiveColor : textPrim))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: _buildMetricCard(
                    'Correlation',
                    '${(metrics.correlation * 100).toStringAsFixed(0)}%',
                    'How returns move together',
                    metrics.correlation > 0.7 ? Icons.link : Icons.link_off,
                    textPrim)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildMetricCard(
                    'R-Squared',
                    '${(metrics.rSquared * 100).toStringAsFixed(0)}%',
                    '% returns explained by benchmark',
                    null,
                    textPrim)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: _buildMetricCard(
                    'Sharpe Ratio',
                    metrics.sharpeRatio.toStringAsFixed(2),
                    'Return per unit of total risk',
                    null,
                    metrics.sharpeRatio > 1
                        ? positiveColor
                        : (metrics.sharpeRatio < 0
                            ? negativeColor
                            : textPrim))),
            const SizedBox(width: 8),
            Expanded(
                child: _buildMetricCard(
                    'Information Ratio',
                    metrics.informationRatio.toStringAsFixed(2),
                    'Excess return per unit of tracking risk',
                    null,
                    metrics.informationRatio > 0.5
                        ? positiveColor
                        : (metrics.informationRatio < -0.5
                            ? negativeColor
                            : textPrim))),
          ]),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String description,
      IconData? icon, Color color) {
    final cardColor =
        Theme.of(context).extension<AppThemeExtension>()?.cardColor ??
            AppTheme.cardColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            if (icon != null) Icon(icon, color: color, size: 16),
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(description,
              style:
                  const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // UPDATED: Return statistics with normalized view support
  Widget _buildReturnStatistics() {
    final textPrim =
        Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
            AppTheme.textPrimary;
    final textSecondary =
        Theme.of(context).extension<AppThemeExtension>()?.textSecondary ??
            AppTheme.textSecondary;
    final positiveColor =
        Theme.of(context).extension<AppThemeExtension>()?.positiveColor ??
            AppTheme.positiveColor;
    final negativeColor =
        Theme.of(context).extension<AppThemeExtension>()?.negativeColor ??
            AppTheme.negativeColor;

    if (_benchmarkData.isEmpty && _portfolioPerformanceData.isEmpty)
      return const SizedBox.shrink();

    final List<TableRow> rows = [];
    rows.add(TableRow(
      decoration: BoxDecoration(
          border: Border(
              bottom:
                  BorderSide(color: textSecondary.withOpacity(0.3), width: 1))),
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Asset',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: textPrim))),
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Return (${_selectedTimeframe})',
                style: TextStyle(fontWeight: FontWeight.bold, color: textPrim),
                textAlign: TextAlign.right)),
      ],
    ));

    if (_portfolioPerformanceData.isNotEmpty) {
      final portfolioName = widget.portfolio?.name ?? 'All Portfolios';

      // Calculate display return based on view
      double displayReturn;
      if (_isNormalizedView && _normalizedPortfolioData.isNotEmpty) {
        displayReturn = _normalizedPortfolioData.last.value -
            100; // Convert from 115% to +15%
      } else {
        displayReturn = _portfolioReturn; // Traditional percentage return
      }

      rows.add(TableRow(
        decoration: BoxDecoration(
            color: _portfolioColor.withOpacity(0.1),
            border: Border(
                bottom: BorderSide(
                    color: textSecondary.withOpacity(0.1), width: 1))),
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: _portfolioColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(portfolioName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: textPrim),
                        overflow: TextOverflow.ellipsis)),
              ])),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                  '${displayReturn >= 0 ? '+' : ''}${displayReturn.toStringAsFixed(2)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          displayReturn >= 0 ? positiveColor : negativeColor),
                  textAlign: TextAlign.right)),
        ],
      ));
    }

    // Sort benchmarks consistently
    List<BenchmarkData> sortedBenchmarkData = [];
    for (String id in _selectedBenchmarkIds) {
      var found = _benchmarkData.where((b) => b.id == id);
      if (found.isNotEmpty) {
        sortedBenchmarkData.add(found.first);
      }
    }

    for (final benchmark in sortedBenchmarkData) {
      final benchmarkId = benchmark.id;
      final color = _getBenchmarkColor(benchmarkId);
      final isCustom = _isCustomBenchmarkId(benchmarkId);

      // Use the return from the appropriate data based on view
      double displayReturn = benchmark.returnPercent;

      rows.add(TableRow(
        decoration: BoxDecoration(
            color: isCustom ? color.withOpacity(0.05) : null,
            border: Border(
                bottom: BorderSide(
                    color: textSecondary.withOpacity(0.1), width: 1))),
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isCustom
                            ? Border.all(
                                color: Colors.white.withOpacity(0.5), width: 1)
                            : null)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(benchmark.name,
                        style: TextStyle(
                            color: textPrim,
                            fontWeight:
                                isCustom ? FontWeight.bold : FontWeight.normal),
                        overflow: TextOverflow.ellipsis)),
                if (isCustom)
                  Icon(Icons.star_border,
                      color: color.withOpacity(0.7), size: 14),
              ])),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                  '${displayReturn >= 0 ? '+' : ''}${displayReturn.toStringAsFixed(2)}%',
                  style: TextStyle(
                      color: displayReturn >= 0 ? positiveColor : negativeColor,
                      fontWeight:
                          isCustom ? FontWeight.bold : FontWeight.normal),
                  textAlign: TextAlign.right)),
        ],
      ));
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              _isNormalizedView
                  ? 'Normalized Return Comparison'
                  : 'Return Comparison',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1)
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: rows),
        ],
      ),
    );
  }

  // Utility functions
  String _getDateLabel(DateTime date) {
    switch (_selectedTimeframe) {
      case '1W':
        return '${date.day}';
      case '1M':
      case '3M':
        return '${date.day}/${date.month}';
      case '6M':
      case '1Y':
        return '${date.month}/${date.year.toString().substring(2)}';
      case 'All':
        return '${date.year}';
      default:
        return '${date.day}';
    }
  }

  Color _getBenchmarkColor(String benchmarkId) {
    if (_isCustomBenchmarkId(benchmarkId)) {
      String ticker = benchmarkId.substring('CUSTOM_'.length);
      int hashCode = ticker.hashCode.abs();
      if (_customTickerSpecificColors.isNotEmpty) {
        return _customTickerSpecificColors[
            hashCode % _customTickerSpecificColors.length];
      }
      return Colors.grey.shade700;
    } else {
      int idHash = benchmarkId.hashCode.abs();
      if (_benchmarkColors.isNotEmpty) {
        return _benchmarkColors[idHash % _benchmarkColors.length];
      }
      return Colors.grey.shade500;
    }
  }

  String _getBenchmarkName(String benchmarkId) {
    if (_isCustomBenchmarkId(benchmarkId)) {
      return benchmarkId.substring('CUSTOM_'.length);
    }
    final benchmark = _availableBenchmarks.firstWhere(
      (b) => b.id == benchmarkId,
      orElse: () => BenchmarkInfo(
          id: benchmarkId,
          name: benchmarkId,
          symbol: benchmarkId,
          description: '',
          category: '',
          region: ''),
    );
    return benchmark.name;
  }

  String _getBenchmarkIdForName(String name) {
    // First try to find from _benchmarkData
    for (final data in _benchmarkData) {
      if (data.name == name) {
        return data.id;
      }
    }

    // Then try from _availableBenchmarks
    final availableInfo =
        _availableBenchmarks.firstWhere((b) => b.name == name, orElse: () {
      bool mightBeCustom = true;
      for (var bInfo in _availableBenchmarks) {
        if (bInfo.name == name) {
          mightBeCustom = false;
          break;
        }
      }
      if (mightBeCustom)
        return BenchmarkInfo(
            id: 'CUSTOM_$name',
            name: name,
            symbol: name,
            category: '',
            description: '',
            region: '');

      return BenchmarkInfo(
          id: name,
          name: name,
          symbol: name,
          description: '',
          category: '',
          region: '');
    });
    return availableInfo.id;
  }

  String _getDatasetNameForLineId(int lineId, List<String> datasetKeys) {
    if (lineId >= 0 && lineId < datasetKeys.length) {
      return datasetKeys[lineId];
    }
    return 'Unknown';
  }

  Color _getColorForLineId(int lineId, List<String> datasetKeys) {
    if (lineId < 0 || lineId >= datasetKeys.length) return Colors.grey;

    final name = datasetKeys[lineId];
    if (name == 'Portfolio') return _portfolioColor;

    final id = _getBenchmarkIdForName(name);
    return _getBenchmarkColor(id);
  }
}

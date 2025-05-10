import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/portfolio.dart';
import '../services/portfolio_service.dart' as portfolio_service;
import '../services/portfolio_benchmark_service.dart';
import '../services/stock_api_service.dart';

// Varsayılan olarak bu sınıfların var olduğunu kabul ediyorum
// class BenchmarkInfo {
//   final String id;
//   final String name;
//   final String symbol;
//   final String description;
//   final String category;
//   final String region;

//   BenchmarkInfo({
//     required this.id,
//     required this.name,
//     required this.symbol,
//     required this.description,
//     required this.category,
//     required this.region,
//   });
// }

// class BenchmarkData {
//   final String id;
//   final String name;
//   final String symbol;
//   final String timeframe;
//   final List<PerformancePoint> data;
//   final double returnPercent;

//   BenchmarkData({
//     required this.id,
//     required this.name,
//     required this.symbol,
//     required this.timeframe,
//     required this.data,
//     required this.returnPercent,
//   });
// }

// class PerformancePoint {
//   final DateTime date;
//   final double value;

//   PerformancePoint({
//     required this.date,
//     required this.value,
//   });
// }

// class PortfolioBenchmarkMetrics {
//   final double alpha;
//   final double beta;
//   final double rSquared;
//   final double sharpeRatio;
//   final double correlation;
//   final double informationRatio; // Treynor yerine Information Ratio kullanıldığı varsayılıyor

//   PortfolioBenchmarkMetrics({
//     required this.alpha,
//     required this.beta,
//     required this.rSquared,
//     required this.sharpeRatio,
//     required this.correlation,
//     required this.informationRatio,
//   });
// }

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

  // Custom ticker controller and state variables
  final TextEditingController _customTickerController = TextEditingController();
  String? _customTicker; // Bu değişken son eklenen özel ticker'ı tutuyordu,
  // artık birden fazla özel ticker olabileceği için
  // _selectedBenchmarkIds listesindeki 'CUSTOM_' prefix'li ID'lere bakacağız.
  // Ancak _customTicker'ı chip göstermek için hala kullanabiliriz.
  bool _isCustomTickerValid = false;
  bool _isValidatingTicker = false;

  List<BenchmarkData> _benchmarkData = [];
  PortfolioBenchmarkMetrics? _comparisonMetrics;

  // Portfolio data
  List<PerformancePoint> _portfolioPerformanceData = [];
  double _portfolioReturn = 0.0;

  // Date range for normalization
  DateTime? _startDate;
  DateTime? _endDate;

  // Colors for different benchmarks and portfolio
  final Color _portfolioColor = Colors.blue;
  final List<Color> _benchmarkColors = [
    // Standart benchmarklar için ana renk paleti
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
          (id) => !_isCustomBenchmarkId(
              id), // Metrikler için standart bir benchmark seç
          orElse: () => _selectedBenchmarkIds.isNotEmpty
              ? _selectedBenchmarkIds.first
              : '', // Fallback
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
      // Use StockApiService to check if ticker is valid
      final stockInfo = await StockApiService.getStockInfo(ticker);

      // If price is 0, it's probably an invalid ticker
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
      // _customTicker'ı son eklenen ticker için güncellemek yerine,
      // _selectedBenchmarkIds'e eklemek yeterli. Chip gösterimi için _customTickerController.text kullanılabilir.
      _selectedBenchmarkIds.add(customId);
      _customTickerController.clear(); // Input'u temizle
      _isCustomTickerValid = false; // Bir sonraki giriş için sıfırla
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
        final performance =
            await portfolio_service.PortfolioService.getPortfolioPerformance(
          widget.portfolio!.id!,
          _selectedTimeframe,
        );
        final convertedData = _convertPerformancePoints(performance.data);
        setState(() {
          _portfolioPerformanceData = convertedData;
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
        final performance = await portfolio_service.PortfolioService
            .getTotalPortfoliosPerformance(
          _selectedTimeframe,
        );
        final convertedData = _convertPerformancePoints(performance.data);
        setState(() {
          _portfolioPerformanceData = convertedData;
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
        .map((p) => PerformancePoint(
              date: p.date,
              value: p.value,
            ))
        .toList();
  }

  Future<void> _loadBenchmarkData() async {
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
            // Optionally, remove the failed ticker from _selectedBenchmarkIds or show a specific error
          }
        } else {
          // Standard Benchmark
          // Assuming PortfolioBenchmarkService.getBenchmarkPerformance can take a single ID
          // If not, you might need to batch these or call it for each standard benchmark.
          // For simplicity, let's assume it works for a list (even if it's a list of one).
        }
      }

      // Load standard benchmarks in a single call if possible
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
        _benchmarkData = newBenchmarkData;
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

  String _getApiIntervalForTimeframe(String timeframe) {
    switch (timeframe) {
      case '1W':
        return '1d';
      case '1M':
        return '1d';
      case '3M':
        return '1d';
      case '6M':
        return '1d'; // For 6M, daily might be too much, weekly could be an option
      case '1Y':
        return '1wk';
      case 'All':
        return '1mo'; // For 'All' (e.g., 3 years), monthly is good
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
      // If too few points, no need to sample
      return points;
    }

    if (points.length > expectedPoints) {
      final sampledPoints = <PerformancePoint>[];
      final step = (points.length - 1) /
          (expectedPoints - 1); // Ensure first and last points are included

      for (int i = 0; i < expectedPoints; i++) {
        final index = (i * step).round();
        if (index < points.length) {
          sampledPoints.add(points[index]);
        }
      }
      // Ensure the last point is always included if not already by rounding
      if (sampledPoints.isEmpty ||
          sampledPoints.last.date != points.last.date) {
        if (sampledPoints.isNotEmpty && sampledPoints.length >= expectedPoints)
          sampledPoints.removeLast();
        sampledPoints.add(points.last);
      }
      return sampledPoints
          .take(expectedPoints)
          .toList(); // Ensure we don't exceed expected points
    }
    // If we have fewer points than expected (but more than 1), just return them.
    // Or you could implement interpolation if needed, but for now, this is simpler.
    return points;
  }

  int _getExpectedDataPointsForTimeframe(String timeframe) {
    switch (timeframe) {
      case '1W':
        return 7; // Daily for a week
      case '1M':
        return 15; // ~Every other day for a month
      case '3M':
        return 15; // ~Weekly for 3 months
      case '6M':
        return 15; // ~Bi-weekly for 6 months
      case '1Y':
        return 12; // Monthly for a year
      case 'All':
        return 20; // More points for longer "All" views
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
                      // Widget'ın hala ağaçta olduğundan emin ol
                      setState(() {});
                    }
                    // Optionally, trigger validation as user types after a delay
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _customTickerController.text
                            .trim()
                            .isEmpty || // YENİ EKLENEN KONTROLssss
                        _isValidatingTicker
                    ? null // Koşullardan biri true ise buton devre dışı
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
                    _loadBenchmarkData(); // Reload data after removing a custom ticker
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

    if (_portfolioPerformanceData.isNotEmpty) {
      final List<FlSpot> portfolioSpots = [];
      double baseValue = _portfolioPerformanceData.first.value;
      if (baseValue > 0) {
        // Portföy verisini de normalize et (eğer beklenen nokta sayısından farklıysa)
        List<PerformancePoint> pointsToNormalize = _portfolioPerformanceData
                    .length ==
                expectedPoints
            ? _portfolioPerformanceData
            : _normalizeDataPointsToMatchTimeframe(_portfolioPerformanceData);

        for (int i = 0; i < pointsToNormalize.length; i++) {
          double normalizedValue =
              (pointsToNormalize[i].value / baseValue) * 100;
          portfolioSpots.add(FlSpot(i.toDouble(), normalizedValue));
        }
        if (portfolioSpots.isNotEmpty) {
          // Sadece doluysa ekle
          normalizedDataSets['Portfolio'] = portfolioSpots;
        }
      }
    }

    for (var benchmark in _benchmarkData) {
      final List<FlSpot> spots = [];
      if (benchmark.data.isNotEmpty) {
        double baseValue = benchmark.data.first.value;
        if (baseValue > 0) {
          // Benchmark verisini de normalize et (eğer beklenen nokta sayısından farklıysa)
          List<PerformancePoint> pointsToNormalize =
              benchmark.data.length == expectedPoints
                  ? benchmark.data
                  : _normalizeDataPointsToMatchTimeframe(benchmark.data);

          for (int i = 0; i < pointsToNormalize.length; i++) {
            double normalizedValue =
                (pointsToNormalize[i].value / baseValue) * 100;
            spots.add(FlSpot(i.toDouble(), normalizedValue));
          }
          if (spots.isNotEmpty) {
            // Sadece doluysa ekle
            normalizedDataSets[benchmark.name] = spots;
          }
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

    // Ensure all datasets have the same number of points for x-axis consistency if needed,
    // or rely on FlSpot's x value for correct plotting. _normalizeDataPointsToMatchTimeframe should handle this.
    // However, if _portfolioPerformanceData and _benchmarkData have different original date points
    // before normalization to `expectedPoints`, their x-axis might not perfectly align semantically
    // if `_normalizeDataPointsToMatchTimeframe` isn't perfectly aligning them to common date points.
    // For simplicity, we assume `i.toDouble()` as x-axis is sufficient after normalization.

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Comparison',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Normalized to 100 at start of period',
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textSecondary)),
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
                      showTitles: true, reservedSize: 32,
                      interval: expectedPoints > 5
                          ? (expectedPoints / 5).floorToDouble()
                          : 1, // Use floorToDouble
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        List<DateTime> dateSeries = [];

                        // Get dates from a representative dataset (e.g., portfolio or first benchmark)
                        // Ensure the dataset used for dates actually has data and matches expectedPoints count.
                        if (normalizedDataSets['Portfolio'] != null &&
                            _portfolioPerformanceData.length >=
                                expectedPoints) {
                          dateSeries = _normalizeDataPointsToMatchTimeframe(
                                  _portfolioPerformanceData)
                              .map((p) => p.date)
                              .toList();
                        } else if (_benchmarkData.isNotEmpty &&
                            _benchmarkData.first.data.length >=
                                expectedPoints) {
                          dateSeries = _normalizeDataPointsToMatchTimeframe(
                                  _benchmarkData.first.data)
                              .map((p) => p.date)
                              .toList();
                        } else if (_portfolioPerformanceData.isNotEmpty) {
                          // Fallback if counts don't match expectedPoints
                          dateSeries = _portfolioPerformanceData
                              .map((p) => p.date)
                              .toList();
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style:
                                TextStyle(color: textSecondary, fontSize: 10))),
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
                        return LineTooltipItem(
                          '$datasetName: ${spot.y.toStringAsFixed(2)}',
                          TextStyle(
                              color: _getColorForLineId(spot.barIndex,
                                  normalizedDataSets.keys.toList()),
                              fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: normalizedDataSets.keys.map((name) {
              final id = _getBenchmarkIdForName(name); // Get ID from name
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
          dashArray: isCustom ? [4, 4] : null, // Özel ticker için kesikli çizgi
          belowBarData: BarAreaData(
            show: name == 'Portfolio', // Sadece portföy için alanı göster
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
    if (firstStandardBenchmarkId.isEmpty)
      return const SizedBox
          .shrink(); // Karşılaştırılacak standart benchmark yok

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
      if (value < 0 && !higherIsBetter)
        return positiveColor; // e.g. lower beta might be "good" if it's very low
      if (value < 0 && higherIsBetter) return negativeColor;
      if (value > 0 && !higherIsBetter)
        return negativeColor; // e.g. higher beta might be "bad" if too high
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
                  '${_portfolioReturn >= 0 ? '+' : ''}${_portfolioReturn.toStringAsFixed(2)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _portfolioReturn >= 0
                          ? positiveColor
                          : negativeColor),
                  textAlign: TextAlign.right)),
        ],
      ));
    }

    // Sıralamayı, efsanedekiyle tutarlı hale getirmek için _benchmarkData'yı _selectedBenchmarkIds'ye göre sırala
    List<BenchmarkData> sortedBenchmarkData = [];
    for (String id in _selectedBenchmarkIds) {
      var found = _benchmarkData.where((b) => b.id == id);
      if (found.isNotEmpty) {
        sortedBenchmarkData.add(found.first);
      }
    }

    for (final benchmark in sortedBenchmarkData) {
      // Sıralanmış listeyi kullan
      final benchmarkId = benchmark
          .id; // benchmark.id zaten doğru ID'yi ('CUSTOM_XXX' veya 'SP500') içermeli
      final color = _getBenchmarkColor(benchmarkId);
      final isCustom = _isCustomBenchmarkId(benchmarkId);

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
                  '${benchmark.returnPercent >= 0 ? '+' : ''}${benchmark.returnPercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                      color: benchmark.returnPercent >= 0
                          ? positiveColor
                          : negativeColor,
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
          const Text('Return Comparison',
              style: TextStyle(
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
        return '${date.day}'; // Belki gün adı daha iyi olur: DateFormat('E').format(date)
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

  // *** GÜNCELLENMİŞ FONKSİYON ***
  Color _getBenchmarkColor(String benchmarkId) {
    if (_isCustomBenchmarkId(benchmarkId)) {
      String ticker = benchmarkId.substring('CUSTOM_'.length);
      int hashCode = ticker.hashCode.abs();
      if (_customTickerSpecificColors.isNotEmpty) {
        return _customTickerSpecificColors[
            hashCode % _customTickerSpecificColors.length];
      }
      // Fallback if custom colors list is empty
      return Colors.grey.shade700;
    } else {
      // Standart benchmarklar için: ID'nin hash'ini kullanarak _benchmarkColors listesinden bir renk seç.
      // Bu, _selectedBenchmarkIds listesindeki sıradan bağımsız, tutarlı bir renk ataması sağlar.
      int idHash = benchmarkId.hashCode.abs();
      if (_benchmarkColors.isNotEmpty) {
        return _benchmarkColors[idHash % _benchmarkColors.length];
      }
      // Fallback if benchmark colors list is empty
      return Colors.grey.shade500;
    }
  }

  // *** GÜNCELLENMİŞ FONKSİYON ***
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

  // *** GÜNCELLENMİŞ FONKSİYON ***
  String _getBenchmarkIdForName(String name) {
    // Önce _benchmarkData'dan (yani grafikte gerçekten olan verilerden) ID'yi bulmaya çalış
    for (final data in _benchmarkData) {
      if (data.name == name) {
        return data.id; // Bu ID "SP500" veya "CUSTOM_AAPL" olabilir
      }
    }
    // Eğer _benchmarkData'da yoksa (örneğin henüz yüklenmemişse veya efsane dışında bir yerde çağrıldıysa)
    // _availableBenchmarks'tan (standart benchmarklar için) bulmayı dene
    final availableInfo =
        _availableBenchmarks.firstWhere((b) => b.name == name, orElse: () {
      // Eğer bu da bulunamazsa ve isim 'CUSTOM_' ile başlamıyorsa,
      // potansiyel bir özel ticker olabilir, bu durumda 'CUSTOM_' prefix'ini ekleyerek ID oluştur.
      // Bu durum, _benchmarkData henüz tam oluşmadığında efsane çizilirken olabilir.
      // Ancak _isCustomBenchmarkId kontrolü zaten _getBenchmarkColor'da var.
      // En güvenlisi, eğer yukarıdaki kontrollerde bulunamazsa, adı olduğu gibi ID kabul etmek
      // ve _getBenchmarkColor'ın bunu işlemesini beklemek.
      // Veya daha spesifik olarak:
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
    // datasetKeys, _createLineData'da oluşturulan sırayla gelmeli
    if (lineId >= 0 && lineId < datasetKeys.length) {
      return datasetKeys[lineId];
    }
    return 'Unknown';
  }

  Color _getColorForLineId(int lineId, List<String> datasetKeys) {
    if (lineId < 0 || lineId >= datasetKeys.length) return Colors.grey;

    final name = datasetKeys[lineId];
    if (name == 'Portfolio') return _portfolioColor;

    final id = _getBenchmarkIdForName(
        name); // Ensure we get the correct ID ('CUSTOM_XXX' or 'SP500')
    return _getBenchmarkColor(id);
  }
}

// Hem önceden tanımlanmış benchmarklar hem de özel ticker girişi için güncellenmiş BenchmarkComparisonScreen
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/portfolio.dart';
import '../services/portfolio_service.dart' as portfolio_service;
import '../services/portfolio_benchmark_service.dart';
import '../services/stock_api_service.dart';

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

  // Özel ticker için controller ve state değişkenleri
  final TextEditingController _customTickerController = TextEditingController();
  String? _customTicker;
  bool _isCustomTickerValid = false;
  bool _isValidatingTicker = false;

  List<BenchmarkData> _benchmarkData = [];
  PortfolioBenchmarkMetrics? _comparisonMetrics;

  // Portfolio data
  List<PerformancePoint> _portfolioPerformanceData = [];
  double _portfolioReturn = 0.0;

  // Colors for different benchmarks and portfolio
  final Color _portfolioColor = Colors.blue;
  final List<Color> _benchmarkColors = [
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.pink,
    Colors.indigo,
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
        _comparisonMetrics = await PortfolioBenchmarkService.compareToBenchmark(
          widget.portfolio!.id!,
          _selectedBenchmarkIds.first,
          _selectedTimeframe,
        );
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

  // Ticker geçerliliğini kontrol eden function
  Future<bool> _validateTicker(String ticker) async {
    if (ticker.isEmpty) return false;

    setState(() {
      _isValidatingTicker = true;
    });

    try {
      // StockApiService'i kullanarak ticker'ın geçerliliğini kontrol et
      final stockInfo = await StockApiService.getStockInfo(ticker);

      // Eğer price 0 ise, muhtemelen geçersiz bir ticker
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

  // Özel ticker'ı benchmarklara ekle
  Future<void> _addCustomTicker() async {
    final ticker = _customTickerController.text.trim().toUpperCase();
    if (ticker.isEmpty) return;

    // Ticker'ı doğrula
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

    // Özel bir ID oluştur (örn: 'CUSTOM_AAPL')
    final customId = 'CUSTOM_$ticker';

    // Eğer zaten seçilmişse, tekrar ekleme
    if (_selectedBenchmarkIds.contains(customId)) {
      return;
    }

    // Maksimum 3 benchmark kontrolü
    if (_selectedBenchmarkIds.length >= 3) {
      _selectedBenchmarkIds.removeAt(0); // İlk seçilen benchmark'ı kaldır
    }

    setState(() {
      _customTicker = ticker;
      _selectedBenchmarkIds.add(customId);
    });

    // Benchmark verilerini yeniden yükle
    await _loadBenchmarkData();
  }

  Future<void> _loadPortfolioData() async {
    try {
      if (widget.portfolio != null) {
        // Load specific portfolio data
        final performance =
            await portfolio_service.PortfolioService.getPortfolioPerformance(
          widget.portfolio!.id!,
          _selectedTimeframe,
        );

        // Convert performance.data (from portfolio_service) to PerformancePoint (from portfolio_benchmark_service)
        final convertedData = _convertPerformancePoints(performance.data);

        setState(() {
          _portfolioPerformanceData = convertedData;

          // Calculate portfolio return
          if (_portfolioPerformanceData.isNotEmpty) {
            final firstValue = _portfolioPerformanceData.first.value;
            final lastValue = _portfolioPerformanceData.last.value;
            _portfolioReturn = ((lastValue / firstValue) - 1) * 100;
          }
        });
      } else {
        // Load combined portfolio data
        final performance = await portfolio_service.PortfolioService
            .getTotalPortfoliosPerformance(
          _selectedTimeframe,
        );

        // Convert performance.data (from portfolio_service) to PerformancePoint (from portfolio_benchmark_service)
        final convertedData = _convertPerformancePoints(performance.data);

        setState(() {
          _portfolioPerformanceData = convertedData;

          // Calculate portfolio return
          if (_portfolioPerformanceData.isNotEmpty) {
            final firstValue = _portfolioPerformanceData.first.value;
            final lastValue = _portfolioPerformanceData.last.value;
            _portfolioReturn = ((lastValue / firstValue) - 1) * 100;
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

  // Helper method to convert between types
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
      List<String> benchmarkIdsToLoad = [];

      // Normal benchmarkları ekle
      for (String id in _selectedBenchmarkIds) {
        if (!id.startsWith('CUSTOM_')) {
          benchmarkIdsToLoad.add(id);
        }
      }

      // Önce standart benchmarkların verilerini yükle
      if (benchmarkIdsToLoad.isNotEmpty) {
        _benchmarkData =
            await PortfolioBenchmarkService.getBenchmarkPerformance(
          _selectedTimeframe,
          benchmarkIdsToLoad,
        );
      } else {
        _benchmarkData = [];
      }

      // Özel ticker varsa, onun için de veri yükle ve listeye ekle
      for (String id in _selectedBenchmarkIds) {
        if (id.startsWith('CUSTOM_')) {
          final ticker = id.substring('CUSTOM_'.length);

          try {
            // Ticker için veri al (StockApiService'i kullanarak)
            final stockData =
                await StockApiService.getStockData(ticker, _selectedTimeframe);

            if (stockData != null && stockData.isNotEmpty) {
              // Veriyi PerformancePoint formatına dönüştür
              List<PerformancePoint> dataPoints = [];
              for (var point in stockData) {
                if (point.containsKey('date') && point.containsKey('close')) {
                  dataPoints.add(PerformancePoint(
                    date: DateTime.parse(point['date']),
                    value: double.parse(point['close'].toString()),
                  ));
                }
              }

              // İlk ve son değer arasındaki yüzde değişimini hesapla
              double returnPercent = 0;
              if (dataPoints.isNotEmpty && dataPoints.first.value > 0) {
                returnPercent =
                    ((dataPoints.last.value / dataPoints.first.value) - 1) *
                        100;
              }

              // BenchmarkData olarak formatla ve listeye ekle
              _benchmarkData.add(BenchmarkData(
                id: id,
                name: ticker,
                symbol: ticker,
                timeframe: _selectedTimeframe,
                data: dataPoints,
                returnPercent: returnPercent,
              ));
            }
          } catch (e) {
            print('Error loading custom ticker data: $e');
          }
        }
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load benchmark data: $e'),
          backgroundColor: AppTheme.negativeColor,
        ),
      );
    }
  }

  void _updateSelectedBenchmarks(String benchmarkId, bool isSelected) {
    setState(() {
      if (isSelected && !_selectedBenchmarkIds.contains(benchmarkId)) {
        // Limit to 3 benchmarks maximum
        if (_selectedBenchmarkIds.length < 3) {
          _selectedBenchmarkIds.add(benchmarkId);
        } else {
          // Show message that max reached
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Maximum 3 benchmarks can be selected for comparison'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      } else if (!isSelected && _selectedBenchmarkIds.contains(benchmarkId)) {
        _selectedBenchmarkIds.remove(benchmarkId);
      }
    });

    // Reload data with new selections
    _loadBenchmarkData();

    // If portfolio is specified, update metrics for first selected benchmark
    if (widget.portfolio != null && _selectedBenchmarkIds.isNotEmpty) {
      PortfolioBenchmarkService.compareToBenchmark(
        widget.portfolio!.id!,
        _selectedBenchmarkIds.first,
        _selectedTimeframe,
      ).then((metrics) {
        if (mounted) {
          setState(() {
            _comparisonMetrics = metrics;
          });
        }
      });
    }
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
          style: TextStyle(
            color: textPrim,
            fontWeight: FontWeight.bold,
          ),
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
                    // Timeframe selector
                    _buildTimeframeSelector(),

                    const SizedBox(height: 16),

                    // Custom Ticker Input
                    _buildCustomTickerInput(),

                    const SizedBox(height: 16),

                    // Benchmark selector
                    _buildBenchmarkSelector(),

                    const SizedBox(height: 24),

                    // Performance comparison chart
                    _buildPerformanceChart(),

                    const SizedBox(height: 24),

                    // Metrics comparison (if portfolio is specified)
                    if (widget.portfolio != null && _comparisonMetrics != null)
                      _buildMetricsComparison(),

                    // Return statistics table
                    const SizedBox(height: 24),
                    _buildReturnStatistics(),

                    // Add some bottom padding
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  // Custom Ticker Input widget'ı
  Widget _buildCustomTickerInput() {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = ext?.cardColor ?? AppTheme.cardColor;
    final accent = ext?.accentColor ?? AppTheme.accentColor;
    final textPrim = ext?.textPrimary ?? AppTheme.textPrimary;

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custom Ticker',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add any stock ticker to compare with your portfolio',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Ticker Input field
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
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    suffixIcon: _isValidatingTicker
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: accent,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : _isCustomTickerValid
                            ? Icon(Icons.check_circle,
                                color: AppTheme.positiveColor)
                            : null,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    // Tüm karakterleri büyük harfe çevir
                    if (value != value.toUpperCase()) {
                      _customTickerController.value = TextEditingValue(
                        text: value.toUpperCase(),
                        selection: _customTickerController.selection,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Add button
              ElevatedButton(
                onPressed: _isValidatingTicker ? null : _addCustomTicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          if (_customTicker != null) ...[
            const SizedBox(height: 12),
            Chip(
              label: Text(_customTicker!),
              backgroundColor: accent,
              labelStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              deleteIcon:
                  const Icon(Icons.close, size: 16, color: Colors.white),
              onDeleted: () {
                setState(() {
                  // Custom ticker'ı seçilen benchmarklardan kaldır
                  _selectedBenchmarkIds
                      .removeWhere((id) => id == 'CUSTOM_$_customTicker');
                  _customTicker = null;
                  _customTickerController.clear();
                  _isCustomTickerValid = false;
                });
                _loadBenchmarkData();
              },
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
                  setState(() {
                    _selectedTimeframe = timeframe;
                  });

                  // Reload both portfolio and benchmark data
                  _loadPortfolioData().then((_) => _loadBenchmarkData());

                  // Update metrics if portfolio is specified
                  if (widget.portfolio != null &&
                      _selectedBenchmarkIds.isNotEmpty) {
                    PortfolioBenchmarkService.compareToBenchmark(
                      widget.portfolio!.id!,
                      _selectedBenchmarkIds.first,
                      _selectedTimeframe,
                    ).then((metrics) {
                      if (mounted) {
                        setState(() {
                          _comparisonMetrics = metrics;
                        });
                      }
                    });
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
                        AppTheme.textPrimary,
              ),
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
          const Text(
            'Select Benchmarks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Group benchmarks by category
          ...['Equity', 'Currency', 'Commodity', 'Crypto', 'Volatility']
              .map((category) {
            final benchmarksInCategory = _availableBenchmarks
                .where((b) => b.category == category)
                .toList();

            if (benchmarksInCategory.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrim.withOpacity(0.7),
                  ),
                ),
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
                      onSelected: (selected) {
                        _updateSelectedBenchmarks(benchmark.id, selected);
                      },
                      backgroundColor: cardColor,
                      selectedColor: _getBenchmarkColor(benchmark.id),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : textPrim,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
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

    // Create normalized data for better comparison
    Map<String, List<FlSpot>> normalizedDataSets = {};

    // Add portfolio data if available
    if (_portfolioPerformanceData.isNotEmpty) {
      final List<FlSpot> portfolioSpots = [];

      // Normalize the first point to 100 for all data sets
      double baseValue = _portfolioPerformanceData.first.value;
      if (baseValue > 0) {
        for (int i = 0; i < _portfolioPerformanceData.length; i++) {
          double normalizedValue =
              (_portfolioPerformanceData[i].value / baseValue) * 100;
          portfolioSpots.add(FlSpot(i.toDouble(), normalizedValue));
        }

        normalizedDataSets['Portfolio'] = portfolioSpots;
      }
    }

    // Add benchmark data
    for (var benchmark in _benchmarkData) {
      final List<FlSpot> spots = [];

      // Normalize the first point to 100 for all data sets
      if (benchmark.data.isNotEmpty) {
        double baseValue = benchmark.data.first.value;
        if (baseValue > 0) {
          for (int i = 0; i < benchmark.data.length; i++) {
            double normalizedValue =
                (benchmark.data[i].value / baseValue) * 100;
            spots.add(FlSpot(i.toDouble(), normalizedValue));
          }

          normalizedDataSets[benchmark.name] = spots;
        }
      }
    }

    // If there's no data to display
    if (normalizedDataSets.isEmpty) {
      return FuturisticCard(
        child: SizedBox(
          height: 300,
          child: Center(
            child: Text(
              'No data available for comparison',
              style: TextStyle(color: textSecondary),
            ),
          ),
        ),
      );
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Normalized to 100 at start of period',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: textSecondary.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: _benchmarkData.isNotEmpty &&
                              _benchmarkData.first.data.isNotEmpty
                          ? (_benchmarkData.first.data.length / 5).toDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        // Get dates from available sources
                        List<DateTime> dateSeries = [];
                        if (_portfolioPerformanceData.isNotEmpty) {
                          dateSeries = _portfolioPerformanceData
                              .map((p) => p.date)
                              .toList();
                        } else if (_benchmarkData.isNotEmpty &&
                            _benchmarkData.first.data.isNotEmpty) {
                          dateSeries = _benchmarkData.first.data
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
                          child: Text(
                            _getDateLabel(date),
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: _createLineData(normalizedDataSets),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: cardColor.withOpacity(0.8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final datasetName =
                            _getDatasetNameForLineId(spot.barIndex);
                        return LineTooltipItem(
                          '$datasetName: ${spot.y.toStringAsFixed(2)}',
                          TextStyle(
                            color: _getColorForLineId(spot.barIndex),
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),

          // Legend
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: normalizedDataSets.keys.map((name) {
              final color = name == 'Portfolio'
                  ? _portfolioColor
                  : _getBenchmarkColor(_getBenchmarkIdForName(name));

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    name,
                    style: TextStyle(
                      color: textPrim,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
    int index = 0;

    // Always put Portfolio first if it exists
    if (dataSets.containsKey('Portfolio')) {
      lineBarsData.add(
        LineChartBarData(
          spots: dataSets['Portfolio']!,
          isCurved: true,
          color: _portfolioColor,
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _portfolioColor.withOpacity(0.3),
                _portfolioColor.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );

      index++;
    }

    // Add benchmarks
    dataSets.forEach((name, spots) {
      if (name != 'Portfolio') {
        final color = _getBenchmarkColor(_getBenchmarkIdForName(name));

        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: false, // Only show area for portfolio
            ),
          ),
        );

        index++;
      }
    });

    return lineBarsData;
  }

  Widget _buildMetricsComparison() {
    if (_comparisonMetrics == null || _selectedBenchmarkIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final metrics = _comparisonMetrics!;
    final benchmarkName = _getBenchmarkName(_selectedBenchmarkIds.first);
    final textPrim =
        Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
            AppTheme.textPrimary;
    final positiveColor =
        Theme.of(context).extension<AppThemeExtension>()?.positiveColor ??
            AppTheme.positiveColor;
    final negativeColor =
        Theme.of(context).extension<AppThemeExtension>()?.negativeColor ??
            AppTheme.negativeColor;

    // Helper function to get color based on whether higher value is better
    Color getMetricColor(double value, bool higherIsBetter) {
      if (value > 0 && higherIsBetter) return positiveColor;
      if (value < 0 && !higherIsBetter) return positiveColor;
      if (value < 0 && higherIsBetter) return negativeColor;
      if (value > 0 && !higherIsBetter) return negativeColor;
      return textPrim; // Neutral for zero
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparison with $benchmarkName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Alpha & Beta
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Alpha',
                  '${metrics.alpha.toStringAsFixed(2)}%',
                  'Excess return relative to market risk',
                  metrics.alpha > 0 ? Icons.trending_up : Icons.trending_down,
                  getMetricColor(metrics.alpha, true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Beta',
                  metrics.beta.toStringAsFixed(2),
                  'Portfolio volatility relative to benchmark',
                  metrics.beta < 1 ? Icons.shield : Icons.waves,
                  metrics.beta > 1.5
                      ? negativeColor
                      : metrics.beta < 0.5
                          ? Colors.amber
                          : textPrim,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Correlation & R-Squared
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Correlation',
                  '${(metrics.correlation * 100).toStringAsFixed(0)}%',
                  'How closely returns move together',
                  metrics.correlation > 0.7 ? Icons.link : Icons.link_off,
                  textPrim,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'R-Squared',
                  '${(metrics.rSquared * 100).toStringAsFixed(0)}%',
                  'Percentage of returns explained by benchmark',
                  null,
                  textPrim,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Sharpe & Treynor Ratios
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Sharpe Ratio',
                  metrics.sharpeRatio.toStringAsFixed(2),
                  'Return per unit of total risk',
                  null,
                  metrics.sharpeRatio > 1
                      ? positiveColor
                      : metrics.sharpeRatio < 0
                          ? negativeColor
                          : textPrim,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Information Ratio',
                  metrics.informationRatio.toStringAsFixed(2),
                  'Excess return per unit of tracking risk',
                  null,
                  metrics.informationRatio > 0.5
                      ? positiveColor
                      : metrics.informationRatio < -0.5
                          ? negativeColor
                          : textPrim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String description,
    IconData? icon,
    Color color,
  ) {
    final cardColor =
        Theme.of(context).extension<AppThemeExtension>()?.cardColor ??
            AppTheme.cardColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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

    // First check if we have data to display
    if (_benchmarkData.isEmpty && _portfolioPerformanceData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create the table data
    final List<TableRow> rows = [];

    // Header row
    rows.add(
      TableRow(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: textSecondary.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Asset',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textPrim,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Return (${_selectedTimeframe})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textPrim,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );

    // Portfolio row (if available)
    if (_portfolioPerformanceData.isNotEmpty) {
      final portfolioName = widget.portfolio?.name ?? 'All Portfolios';
      rows.add(
        TableRow(
          decoration: BoxDecoration(
            color: _portfolioColor.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: textSecondary.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _portfolioColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      portfolioName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textPrim,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${_portfolioReturn >= 0 ? '+' : ''}${_portfolioReturn.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _portfolioReturn >= 0 ? positiveColor : negativeColor,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }

    // Benchmark rows
    for (int i = 0; i < _benchmarkData.length; i++) {
      final benchmark = _benchmarkData[i];
      final color = _getBenchmarkColor(_getBenchmarkIdForName(benchmark.name));

      rows.add(
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: textSecondary.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benchmark.name,
                      style: TextStyle(
                        color: textPrim,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${benchmark.returnPercent >= 0 ? '+' : ''}${benchmark.returnPercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: benchmark.returnPercent >= 0
                      ? positiveColor
                      : negativeColor,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Return Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: rows,
          ),
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
        return '${date.month}/${date.year}';
      case 'All':
        return '${date.year}';
      default:
        return '${date.day}';
    }
  }

  Color _getBenchmarkColor(String benchmarkId) {
    // Özel ticker'lar için özel koşul ekle
    if (benchmarkId.startsWith('CUSTOM_')) {
      // Özel bir renk döndür (örn. pembe)
      return Colors.pink;
    }

    // Get index of benchmark in selected list
    final index = _selectedBenchmarkIds.indexOf(benchmarkId);
    if (index >= 0 && index < _benchmarkColors.length) {
      return _benchmarkColors[index];
    }
    return _benchmarkColors[0]; // Default color
  }

  String _getBenchmarkName(String benchmarkId) {
    // Özel ticker'lar için özel koşul ekle
    if (benchmarkId.startsWith('CUSTOM_')) {
      return benchmarkId.substring('CUSTOM_'.length);
    }

    // Find benchmark info from available benchmarks
    final benchmark = _availableBenchmarks.firstWhere(
      (b) => b.id == benchmarkId,
      orElse: () => BenchmarkInfo(
        id: benchmarkId,
        name: benchmarkId,
        symbol: benchmarkId,
        description: '',
        category: '',
        region: '',
      ),
    );

    return benchmark.name;
  }

  String _getBenchmarkIdForName(String name) {
    // Özel ticker'lar için kontrol
    if (_customTicker != null && name == _customTicker) {
      return 'CUSTOM_$_customTicker';
    }

    // Find benchmark info from available benchmarks
    final benchmark = _availableBenchmarks.firstWhere(
      (b) => b.name == name,
      orElse: () => BenchmarkInfo(
        id: name,
        name: name,
        symbol: name,
        description: '',
        category: '',
        region: '',
      ),
    );

    return benchmark.id;
  }

  String _getDatasetNameForLineId(int lineId) {
    final datasetNames = normalizedDatasetNames();
    if (lineId >= 0 && lineId < datasetNames.length) {
      return datasetNames[lineId];
    }
    return 'Unknown';
  }

  List<String> normalizedDatasetNames() {
    List<String> names = [];
    if (_portfolioPerformanceData.isNotEmpty) {
      names.add('Portfolio');
    }

    for (var benchmark in _benchmarkData) {
      names.add(benchmark.name);
    }

    return names;
  }

  Color _getColorForLineId(int lineId) {
    final names = normalizedDatasetNames();

    if (lineId < 0 || lineId >= names.length) {
      return Colors.grey;
    }

    final name = names[lineId];
    if (name == 'Portfolio') {
      return _portfolioColor;
    } else {
      return _getBenchmarkColor(_getBenchmarkIdForName(name));
    }
  }
}

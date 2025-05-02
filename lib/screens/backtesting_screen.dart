// backtesting_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/backtest_models.dart';
import '../services/backtest_service.dart';
import 'dart:math';
import 'package:logging/logging.dart';

class BacktestingScreen extends StatefulWidget {
  const BacktestingScreen({Key? key}) : super(key: key);

  @override
  State<BacktestingScreen> createState() => _BacktestingScreenState();
}

class _BacktestingScreenState extends State<BacktestingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _tickerController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  String _selectedTimeframe = '1D';
  final List<String> _timeframes = ['1D', '1H', '30m', '15m', '5m', '1m'];

  List<BacktestStrategy> _strategies = [];
  int _selectedStrategyIndex = -1; // Initially no strategy selected
  bool _isLoading = true;
  BacktestResult? _lastResult;

  // Logging
  final _logger = Logger('BacktestingScreen');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tickerController.text = 'AAPL'; // Default ticker
    _periodController.text = '1 Year'; // Default period
    _loadStrategies();
    BacktestService.initialize(); // Start service logging
    _setupLogging(); // Start screen logging
  }

  void _setupLogging() {
    Logger.root.level = Level.ALL; // Capture all log levels
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print(
          '${record.level.name}: ${record.time}: (${record.loggerName}) ${record.message}');
      if (record.error != null) {
        // ignore: avoid_print
        print('ERROR: ${record.error}');
      }
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('STACKTRACE: ${record.stackTrace}');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tickerController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  Future<void> _loadStrategies() async {
    _logger.info("Loading strategies...");
    setState(() {
      _isLoading = true;
      _strategies = []; // Clear list before loading
      _selectedStrategyIndex = -1; // Reset selection
    });

    try {
      final strategies = await BacktestService.getStrategies();
      
      // Add logging to check what strategies came back
      _logger.info("Received ${strategies.length} strategies from API");
      for (var strategy in strategies) {
        _logger.fine("Strategy: ${strategy.name}, ID: ${strategy.id}");
      }
      
      setState(() {
        _strategies = strategies;
        // Select the first strategy if available
        if (_strategies.isNotEmpty) {
          _selectedStrategyIndex = 0;
          _logger.info("First strategy selected: ${_strategies[0].name}");
        } else {
          _logger.warning("No strategies found.");
        }
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _logger.severe("Error loading strategies", e, stackTrace);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load strategies: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  Future<void> _runBacktest() async {
    // IMPORTANT: Check if a strategy is selected
    if (_selectedStrategyIndex < 0 ||
        _selectedStrategyIndex >= _strategies.length) {
      _logger.warning(
          "Attempted to run backtest but no valid strategy selected. Selected index: $_selectedStrategyIndex, Strategy count: ${_strategies.length}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid strategy.'),
          backgroundColor: AppTheme.negativeColor,
        ),
      );
      return;
    }

    // IMPORTANT: Get the strategy at the selected index.
    // This variable will keep the same value throughout this function block, even if setState is called.
    final int strategyIndexToRun = _selectedStrategyIndex;
    final BacktestStrategy selectedStrategy = _strategies[strategyIndexToRun];

    _logger.info(
        "Starting backtest. Selected Strategy Index: $strategyIndexToRun, Strategy Name: ${selectedStrategy.name}, Strategy ID: ${selectedStrategy.id ?? 'No ID'}");

    // Log strategy details (what will be sent to API)
    _logger.fine("Strategy details to send: ${selectedStrategy.toJson()}");

    setState(() {
      _isLoading = true; // Start loading animation
      _lastResult = null; // Clear old result
    });

    // Optional: Show confirmation dialog
    // _confirmStrategy(selectedStrategy); // Uncomment if confirmation wanted

    try {
      final ticker = _tickerController.text.trim().toUpperCase();
      final period = _periodController.text.trim();
      final timeframe = _selectedTimeframe;

      if (ticker.isEmpty) {
        throw Exception("Stock symbol cannot be empty.");
      }
      if (period.isEmpty) {
        throw Exception("Backtest period cannot be empty.");
      }

      // Log parameters for API call
      _logger.info(
          "Calling BacktestService.runBacktest. Ticker: $ticker, Timeframe: $timeframe, Period: $period, Strategy Name: ${selectedStrategy.name}");

      // IMPORTANT: Use the selected strategy object directly for the API call
      final result = await BacktestService.runBacktest(
        ticker: ticker,
        timeframe: timeframe,
        periodStr: period,
        strategy: selectedStrategy, // Use local variable with selected strategy
      );

      _logger.info(
          "Backtest completed successfully. Total Return: ${result.performanceMetrics['total_return_pct']}%");

      setState(() {
        _lastResult = result;
        _isLoading = false;
      });

      // Navigate to results tab
      _tabController.animateTo(2);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedStrategy.name} backtest completed.'),
            backgroundColor: AppTheme.positiveColor.withOpacity(0.8),
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.severe("Error running backtest", e, stackTrace);
      setState(() {
        _isLoading = false; // Stop loading on error
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backtest error: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  // Strategy selection card widget
  Widget _buildStrategySelectionCard(BacktestStrategy strategy, int index) {
    final isSelected = index == _selectedStrategyIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isSelected ? 4 : 1,
        shadowColor: isSelected
            ? AppTheme.accentColor.withOpacity(0.5)
            : Colors.black.withOpacity(0.2),
        color: isSelected
            ? AppTheme.accentColor.withOpacity(0.15)
            : AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppTheme.accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () {
            _logger.info("Strategy selected. Index: $index, Name: ${strategy.name}");
            setState(() {
              _selectedStrategyIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        strategy.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.accentColor
                              : AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Action icons (edit/delete)
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.edit_note, // Edit icon
                            color: AppTheme.accentColor.withOpacity(0.7),
                            size: 22,
                          ),
                          tooltip: "Edit Strategy",
                          onPressed: () {
                            // TODO: Navigate to strategy edit screen
                            _logger.info("Edit button clicked: ${strategy.name}");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Edit feature coming soon.')),
                            );
                            // Example: _navigateToEditStrategy(strategy);
                            // For now just go to the second tab
                            // _tabController.animateTo(1);
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.delete_outline, // Delete icon
                            color: AppTheme.negativeColor.withOpacity(0.7),
                            size: 20,
                          ),
                          tooltip: "Delete Strategy",
                          onPressed: () {
                            // Delete operation
                            _logger.warning("Delete button clicked: ${strategy.name}");
                            _confirmDeleteStrategy(
                                strategy.id ?? '', strategy.name);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  strategy.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Condition chips
                _buildConditionChipsForRow(strategy),

                // Performance metrics if available
                if (strategy.performance != null &&
                    strategy.performance!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildMiniPerformanceRow(strategy.performance!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Strategy deletion confirmation dialog
  Future<void> _confirmDeleteStrategy(String strategyId, String strategyName) async {
    if (strategyId.isEmpty) {
      _logger.severe("Strategy ID for deletion is empty.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Strategy ID not found, cannot delete.'),
            backgroundColor: AppTheme.negativeColor),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Delete Strategy',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Are you sure you want to permanently delete "$strategyName"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.negativeColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteStrategy(strategyId);
    }
  }

  // Strategy deletion function
  Future<void> _deleteStrategy(String strategyId) async {
    _logger.info("Deleting strategy: ID $strategyId");
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await BacktestService.deleteStrategy(strategyId);
      if (success) {
        _logger.info("Strategy successfully deleted: ID $strategyId");
        // Reload the list
        await _loadStrategies(); // This also sets _isLoading to false
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Strategy successfully deleted.'),
                backgroundColor: AppTheme.positiveColor),
          );
        }
      } else {
        _logger.warning("Failed to delete strategy: ID $strategyId");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('An error occurred while deleting strategy.'),
                backgroundColor: AppTheme.negativeColor),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.severe("Critical error deleting strategy: ID $strategyId", e,
          stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error deleting strategy: $e'),
              backgroundColor: AppTheme.negativeColor),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Condition chips in a row for strategy card
  Widget _buildConditionChipsForRow(BacktestStrategy strategy) {
    final buyConditions = strategy.buyConditions
        .map((c) => _buildConditionChip('BUY', _formatCondition(c),
            AppTheme.positiveColor))
        .toList();
    final sellConditions = strategy.sellConditions
        .map((c) => _buildConditionChip('SELL', _formatCondition(c),
            AppTheme.negativeColor))
        .toList();

    // Combine all chips
    final allChips = [...buyConditions, ...sellConditions];

    if (allChips.isEmpty) {
      return const SizedBox.shrink(); // If no conditions, return empty widget
    }

    return Wrap(
      spacing: 6.0, // Horizontal spacing between chips
      runSpacing: 4.0, // Vertical spacing between rows
      children: allChips,
    );
  }

  // Mini performance metrics row
  Widget _buildMiniPerformanceRow(Map<String, dynamic> performance) {
    // Get metrics with null checking
    final String returnStr = performance.containsKey('return')
        ? '${(performance['return'] as num?)?.toStringAsFixed(1) ?? 'N/A'}%'
        : 'N/A';
    final String sharpeStr = performance.containsKey('sharpe')
        ? (performance['sharpe'] as num?)?.toStringAsFixed(2) ?? 'N/A'
        : 'N/A';
    final String drawdownStr = performance.containsKey('drawdown')
        ? '${(performance['drawdown'] as num?)?.toStringAsFixed(1) ?? 'N/A'}%'
        : 'N/A';
    final String tradesStr = performance.containsKey('trades')
        ? (performance['trades'] as num?)?.toString() ?? 'N/A'
        : 'N/A';

    final bool isPositiveReturn =
        performance.containsKey('return') && (performance['return'] as num? ?? 0) >= 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMiniMetric('Return', returnStr,
            isPositiveReturn ? AppTheme.positiveColor : AppTheme.negativeColor),
        _buildMiniMetric('Sharpe', sharpeStr, Colors.amber.shade700),
        _buildMiniMetric('Max DD', drawdownStr, AppTheme.negativeColor),
        _buildMiniMetric('Trades', tradesStr, AppTheme.accentColor),
      ],
    );
  }

  // Mini metric widget for performance row
  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // EXTRA: Strategy confirmation dialog (optional)
  void _confirmStrategy(BacktestStrategy strategy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text("Strategy Confirmation",
            style: TextStyle(color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "The following strategy will be backtested:",
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strategy.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      strategy.description,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Indicators: ${strategy.indicators.length}",
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    Text(
                      "Buy Conditions: ${strategy.buyConditions.length}",
                      style: const TextStyle(color: AppTheme.positiveColor),
                    ),
                    Text(
                      "Sell Conditions: ${strategy.sellConditions.length}",
                      style: const TextStyle(color: AppTheme.negativeColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Symbol: ${_tickerController.text.toUpperCase()}",
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              Text(
                "Timeframe: $_selectedTimeframe",
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              Text(
                "Period: ${_periodController.text}",
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Cancel run, set _isLoading to false
              setState(() => _isLoading = false);
              _logger.info("User canceled backtest confirmation.");
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Confirmation provided, run backtest continues
              // Since dialog is asynchronous, we should not call _runBacktest again here
              // It should continue from where it left off in the original method
              _logger.info("User confirmed backtest.");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.black,
            ),
            child: const Text("Confirm & Run"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              Color(0xFF101624), // Slightly darker bottom color
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom App Bar
              _buildCustomAppBar(),

              // Tab Bar
              _buildTabBar(),

              // Main Content Area
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentColor,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStrategiesTab(),
                          _buildStrategyBuilderTab(), // Builder Tab
                          _buildResultsTab(), // Results Tab
                        ],
                      ),
              ),

              // Bottom: Run Selected Strategy Button (only on Strategies tab)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SizeTransition(sizeFactor: animation, child: child);
                },
                child: (_tabController.index == 0 &&
                        _selectedStrategyIndex != -1 &&
                        !_isLoading)
                    ? _buildRunSelectedStrategyButton()
                    : const SizedBox.shrink(), // Hide on other tabs or when no selection
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom App Bar Widget
  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(
            Icons.analytics_outlined,
            color: AppTheme.accentColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Strategy Backtesting',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          // Refresh button
          IconButton(
            tooltip: "Refresh Strategies",
            icon: const Icon(Icons.refresh, color: AppTheme.accentColor),
            onPressed: _isLoading ? null : _loadStrategies, // Disable while loading
          ),
          // Other icons (save, share, etc.) can be added here
        ],
      ),
    );
  }

  // Tab Bar Widget
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 45, // Tab height
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: AppTheme.textSecondary.withOpacity(0.8),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10), // Rounded indicator
            color: AppTheme.accentColor.withOpacity(0.2),
            border: Border.all(color: AppTheme.accentColor),
          ),
          indicatorPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: const [
            Tab(text: 'Strategies'),
            Tab(text: 'Builder'),
            Tab(text: 'Results'),
          ],
        ),
      ),
    );
  }

  // Strategies Tab Content
  Widget _buildStrategiesTab() {
    if (_strategies.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'No saved strategies found.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create New Strategy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
              ),
              onPressed: () => _tabController.animateTo(1),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              icon: const Icon(Icons.refresh,
                size: 18,
                color: AppTheme.accentColor,
              ),
              label: const Text('Try Again',
                  style: TextStyle(color: AppTheme.accentColor)),
              onPressed: _loadStrategies,
            ),
          ],
        ),
      );
    }

    // Show strategy list
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title and New Strategy Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Saved Strategies (${_strategies.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Create New'),
              onPressed: () {
                _logger.info("Create New Strategy button clicked.");
                _tabController.animateTo(1); // Go to Builder tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor.withOpacity(0.15),
                foregroundColor: AppTheme.accentColor,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.accentColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Strategy Cards List
        ...List.generate(
          _strategies.length,
          (index) => _buildStrategySelectionCard(_strategies[index], index),
        ),

        // Bottom space
        const SizedBox(height: 80),
      ],
    );
  }

  // Run Selected Strategy Button (bottom of screen)
  Widget _buildRunSelectedStrategyButton() {
    // Ensure _selectedStrategyIndex is valid
    if (_selectedStrategyIndex < 0 || _selectedStrategyIndex >= _strategies.length) {
      return const SizedBox.shrink(); // Don't show button if invalid
    }
    
    final selectedStrategyName = _strategies[_selectedStrategyIndex].name;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.play_circle_fill, color: Colors.black),
        label: Text(
          'RUN BACKTEST FOR "$selectedStrategyName"',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          minimumSize: const Size(double.infinity, 50), // Button height
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isLoading ? null : _runBacktest, // Disable while loading
      ),
    );
  }

  // Strategy Builder Tab Content
  Widget _buildStrategyBuilderTab() {
    // TODO: Replace with actual strategy building components
    // Currently shows configuration and run buttons for demonstration

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strategy Configuration Section
          Card(
            color: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backtest Parameters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stock Symbol Input
                  TextField(
                    controller: _tickerController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Stock/Symbol',
                      labelStyle: const TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.accentColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.accentColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor.withOpacity(0.5),
                    ),
                    onChanged: (value) => _tickerController.text = value.toUpperCase(), // Auto-uppercase
                  ),
                  const SizedBox(height: 16),

                  // Timeframe Selection
                  _buildTimeframeSelector(),
                  const SizedBox(height: 16),

                  // Backtest Period
                  TextField(
                    controller: _periodController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Backtest Period',
                      labelStyle: const TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.date_range, color: AppTheme.accentColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.accentColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: 'Example: 1 Year, 6 Months, 90 Days',
                      hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                      filled: true,
                      fillColor: AppTheme.backgroundColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Strategy Definition Area (Future builder implementation)
          const Text(
            'Strategy Definition (Coming Soon)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text(
                'Here you will be able to drag and drop indicators\n'
                'and define conditions to create new strategies.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Buttons (Create and Run)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle, size: 20),
                  label: const Text('CREATE NEW STRATEGY'),
                  onPressed: () {
                    // TODO: Add new strategy creation logic
                    _logger.info("Create New Strategy button clicked (Builder tab).");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Strategy creation feature coming soon.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.positiveColor.withOpacity(0.8),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // Bottom spacing
        ],
      ),
    );
  }

  // Timeframe Selector Widget
  Widget _buildTimeframeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'Timeframe:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
        SizedBox(
          height: 40, // Button height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _timeframes.length,
            itemBuilder: (context, index) {
              final timeframe = _timeframes[index];
              final isSelected = timeframe == _selectedTimeframe;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: OutlinedButton(
                  onPressed: () {
                    _logger.fine("Timeframe selected: $timeframe");
                    setState(() {
                      _selectedTimeframe = timeframe;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
                    backgroundColor: isSelected ? AppTheme.accentColor.withOpacity(0.1) : AppTheme.backgroundColor.withOpacity(0.3),
                    side: BorderSide(
                      color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary.withOpacity(0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    timeframe,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Results Tab Content
  Widget _buildResultsTab() {
    if (_isLoading && _lastResult == null) {
      // If loading and no previous results
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
    }

    if (_lastResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 60, color: AppTheme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No backtest results yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a strategy and click "Run Backtest".',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text("Go to Strategies"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
              ),
              onPressed: () => _tabController.animateTo(0),
            ),
          ],
        ),
      );
    }

    // Show results
    final result = _lastResult!;
    final metrics = result.performanceMetrics;
    
    // Try to find strategy name
    String strategyName = "Unknown Strategy";
    if (_selectedStrategyIndex >= 0 && _selectedStrategyIndex < _strategies.length) {
      strategyName = _strategies[_selectedStrategyIndex].name;
    } else if (metrics.containsKey('strategy_name')) {
      strategyName = metrics['strategy_name']; // If coming from API
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Strategy Name
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.bar_chart_rounded, // Chart icon
                color: AppTheme.accentColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded( // Prevent title overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_tickerController.text.toUpperCase()} Backtest Results',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Strategy: $strategyName', // Strategy name
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Performance Summary Cards
          _buildPerformanceSummaryCards(metrics),
          const SizedBox(height: 24),

          // Equity Curve Title and Chart
          const Text(
            'Equity Curve',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 250, // Chart height
            padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8, left: 4), // Padding
            decoration: BoxDecoration(
              color: AppTheme.cardColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: result.equityCurve.length > 1 // Require at least 2 points
                ? CustomPaint(
                    painter: EquityCurvePainter(
                      equityCurve: result.equityCurve,
                      initialValue: metrics['initial_capital'] ?? 10000.0, // Initial capital
                      benchmarkValue: metrics['buy_and_hold_return_pct'] ?? 0.0, // Buy & Hold return (if available)
                    ),
                    size: const Size(double.infinity, double.infinity),
                  )
                : const Center(child: Text("Not enough data for chart.", style: TextStyle(color: AppTheme.textSecondary))),
          ),
          const SizedBox(height: 24),

          // Trade History Title and List
          const Text(
            'Trade History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildTradeHistorySection(result.tradeHistory),

          const SizedBox(height: 20), // Bottom spacing
        ],
      ),
    );
  }

  // Trade History Section Widget
  Widget _buildTradeHistorySection(List<Map<String, dynamic>> trades) {
    if (trades.isEmpty) {
      return Card(
        color: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              'No trades were made in this backtest.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    // Show first 5 trades, with a button for more
    final visibleTrades = trades.take(5).toList();

    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0), // Top and bottom padding
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: const [
                  SizedBox(width: 25, child: Text('#', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Entry / Exit Date', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Entry / Exit Price', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Return %', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(color: AppTheme.backgroundColor, height: 1),

            // Trade rows
            ...List.generate(
              visibleTrades.length,
              (index) => _buildTradeHistoryItem(visibleTrades[index], index),
            ),

            // View all trades button (if more than 5)
            if (trades.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  onPressed: () {
                    // TODO: Show screen or dialog with all trades
                    _logger.info("View All Trades clicked.");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Full trade history view coming soon (${trades.length} trades)')),
                    );
                  },
                  child: Text(
                    'View All ${trades.length} Trades',
                    style: const TextStyle(color: AppTheme.accentColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Single trade history item
  Widget _buildTradeHistoryItem(Map<String, dynamic> trade, int index) {
    // Null checks for values
    final num? returnPct = trade['return_pct'] as num?;
    final bool isPositive = returnPct != null && returnPct >= 0;
    final Color returnColor = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;
    final String returnText = returnPct != null
        ? '${isPositive ? '+' : ''}${returnPct.toStringAsFixed(2)}%'
        : 'N/A';

    final String entryDate = _formatTradeDate(trade['entry_date'] as String?);
    final String exitDate = _formatTradeDate(trade['exit_date'] as String?);
    final String entryPrice = (trade['entry_price'] as num?)?.toStringAsFixed(2) ?? 'N/A';
    final String exitPrice = (trade['exit_price'] as num?)?.toStringAsFixed(2) ?? 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        // Thin divider between rows
        border: index > 0
            ? Border(
                top: BorderSide(
                  color: AppTheme.backgroundColor.withOpacity(0.5),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          // Trade Number
          SizedBox(
            width: 25, // Fixed width
            child: Text(
              '#${index + 1}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          // Trade Dates (stacked)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entryDate, // Entry Date
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  exitDate, // Exit Date
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Prices (stacked)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$entryPrice', // Entry Price
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$exitPrice', // Exit Price
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Return (centered pill)
          Expanded(
            flex: 2,
            child: Center( // Center the pill
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: returnColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  returnText,
                  style: TextStyle(
                    color: returnColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Performance Summary Cards Widget
  Widget _buildPerformanceSummaryCards(Map<String, dynamic> metrics) {
    // Null-safe retrieval of metrics with defaults
    final double totalReturn = (metrics['total_return_pct'] as num?)?.toDouble() ?? 0.0;
    final double annualizedReturn = (metrics['annualized_return_pct'] as num?)?.toDouble() ?? 0.0;
    final double maxDrawdown = (metrics['max_drawdown_pct'] as num?)?.toDouble() ?? 0.0;
    final double winRate = (metrics['win_rate_pct'] as num?)?.toDouble() ?? 0.0;
    final double sharpeRatio = (metrics['sharpe_ratio'] as num?)?.toDouble() ?? 0.0;
    final double sortinoRatio = (metrics['sortino_ratio'] as num?)?.toDouble() ?? 0.0; // Extra metric
    final int totalTrades = (metrics['total_trades'] as num?)?.toInt() ?? 0;
    final String avgTradeReturn = (metrics['average_trade_return_pct'] as num?)?.toStringAsFixed(2) ?? 'N/A'; // Extra metric

    final bool isTotalReturnPositive = totalReturn >= 0;
    final bool isAnnualizedReturnPositive = annualizedReturn >= 0;

    // Cards in a 2xN grid layout
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Return',
                '${isTotalReturnPositive ? '+' : ''}${totalReturn.toStringAsFixed(2)}%',
                isTotalReturnPositive ? Icons.trending_up : Icons.trending_down,
                isTotalReturnPositive ? AppTheme.positiveColor : AppTheme.negativeColor,
                tooltip: "Total return percentage over the backtest period.",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Annual Return',
                '${isAnnualizedReturnPositive ? '+' : ''}${annualizedReturn.toStringAsFixed(2)}%',
                Icons.calendar_today,
                isAnnualizedReturnPositive ? AppTheme.positiveColor : AppTheme.negativeColor,
                tooltip: "Return percentage annualized.",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Max Drawdown',
                '${maxDrawdown.toStringAsFixed(2)}%', // Usually negative but shown without sign
                Icons.arrow_downward,
                AppTheme.negativeColor,
                tooltip: "Largest percentage drop from peak to trough.",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Win Rate',
                '${winRate.toStringAsFixed(1)}%',
                Icons.emoji_events_outlined, // Trophy icon
                AppTheme.accentColor,
                tooltip: "Percentage of trades that were profitable.",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Sharpe Ratio',
                sharpeRatio.toStringAsFixed(2),
                Icons.speed, // Speedometer icon
                Colors.amber.shade600,
                tooltip: "Measures risk-adjusted return (higher is better).",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Sortino Ratio', // Extra Metric
                sortinoRatio.toStringAsFixed(2),
                Icons.filter_tilt_shift, // Different icon
                Colors.purple.shade300,
                tooltip: "Measures return against downside risk (higher is better).",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Trades',
                totalTrades.toString(),
                Icons.swap_horiz,
                AppTheme.accentColor.withOpacity(0.8),
                tooltip: "Total number of completed trades during backtest.",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Avg Trade Return', // Extra Metric
                '$avgTradeReturn%',
                Icons.calculate_outlined,
                double.tryParse(avgTradeReturn) == null ? AppTheme.textSecondary : 
                  (double.parse(avgTradeReturn) >= 0 ? AppTheme.positiveColor : AppTheme.negativeColor),
                tooltip: "Average return percentage per trade.",
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Single metric card widget
  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {String? tooltip}) {
    Widget cardContent = Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Vertically center content
          mainAxisSize: MainAxisSize.min, // Size card to content
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Icon on right
              children: [
                Flexible( // Prevent title overflow
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color.withOpacity(0.8), size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20, // Larger value text
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1, // Single line
              overflow: TextOverflow.ellipsis, // Truncate with ... if too long
            ),
          ],
        ),
      ),
    );

    // Wrap with Tooltip if provided
    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(
        message: tooltip,
        preferBelow: false, // Show tooltip above
        waitDuration: const Duration(milliseconds: 500), // Wait before showing
        textStyle: const TextStyle(fontSize: 12, color: Colors.black),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: cardContent,
      );
    } else {
      return cardContent;
    }
  }

  // Condition chip widget
  Widget _buildConditionChip(String type, String condition, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Smaller padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12), // Rounder corners
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10, // Smaller font
            ),
          ),
          const SizedBox(width: 4), // Less spacing
          Flexible( // Prevent overflow
            child: Text(
              condition,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10), // Smaller font
              overflow: TextOverflow.ellipsis, // Truncate if needed
            ),
          ),
        ],
      ),
    );
  }

  // Format condition text for display
  String _formatCondition(Map<String, dynamic> condition) {
    final indicator1 = condition['indicator'] ?? '?';
    final operator = _formatOperator(condition['operator'] ?? '?');
    String value = '?';

    if (condition.containsKey('value') && condition['value'] != null) {
      // Format numeric value (if it's a number)
      if (condition['value'] is num) {
        value = (condition['value'] as num).toStringAsFixed(1); // 1 decimal place
      } else {
        value = condition['value'].toString();
      }
    } else if (condition.containsKey('indicator2') && condition['indicator2'] != null) {
      value = condition['indicator2'].toString(); // Other indicator name
    }

    // Different format for cross operators
    if (operator.contains('crosses')) {
      return '$indicator1 $operator $value';
    }

    return '$indicator1 $operator $value';
  }

  // Format operator for display
  String _formatOperator(String op) {
    switch (op.toLowerCase()) {
      case '>': return '>';
      case '<': return '<';
      case '=': case '==': return '='; // Equality
      case '>=': return '≥'; // Greater than or equal
      case '<=': return '≤'; // Less than or equal
      case 'crosses': return 'crosses'; // General crossing
      case 'crosses_above': return 'crosses above';
      case 'crosses_below': return 'crosses below';
      case '!=': return '≠'; // Not equal
      default: return op; // Return unknown operator as-is
    }
  }

  // Format trade date
  String _formatTradeDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) {
      return 'N/A'; // If date is missing
    }
    try {
      final date = DateTime.parse(isoDate);
      // Year-Month-Day format
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      _logger.warning("Date formatting error: $isoDate", e);
      return isoDate; // Return original string on error
    }
  }
}

// Equity curve painter for the chart
class EquityCurvePainter extends CustomPainter {
  final List<Map<String, dynamic>> equityCurve;
  final dynamic initialValue;
  final double benchmarkValue; // Buy and Hold return (%)

  EquityCurvePainter({
    required this.equityCurve,
    required this.initialValue,
    this.benchmarkValue = 0.0, // Optional
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Need at least two points
    if (equityCurve.length < 2) {
      // Show "Not enough data" message
      final textPainter = TextPainter(
        text: const TextSpan(
            text: 'Not enough data for chart',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(minWidth: size.width);
      textPainter.paint(
          canvas, Offset(0, size.height / 2 - textPainter.height / 2));
      return;
    }

    final double actualInitialCapital =
        (initialValue is num ? (initialValue as num).toDouble() : 10000.0)
            .toDouble();

    // Find min/max values (for both strategy and benchmark)
    double minValue = actualInitialCapital; // Start with initial capital as min
    double maxValue = actualInitialCapital; // Start with initial capital as max

    List<double> strategyValues = [];
    List<double> benchmarkValues = []; // Buy & Hold values

    // Process strategy values
    for (var point in equityCurve) {
      final value = (point['value'] is num
              ? (point['value'] as num).toDouble()
              : actualInitialCapital)
          .toDouble();
      strategyValues.add(value);
      if (value < minValue) minValue = value;
      if (value > maxValue) maxValue = value;
    }

    // Calculate benchmark values if provided
    if (benchmarkValue != 0.0 && equityCurve.isNotEmpty) {
      final double totalReturnFactor = 1.0 + (benchmarkValue / 100.0);
      final int numPoints = equityCurve.length;

      // Simple linear interpolation for benchmark curve
      for (int i = 0; i < numPoints; i++) {
        double progress = i / (numPoints - 1);
        double benchmarkCurrentValue =
            actualInitialCapital * (1 + (totalReturnFactor - 1) * progress);
        benchmarkValues.add(benchmarkCurrentValue);
        if (benchmarkCurrentValue < minValue) minValue = benchmarkCurrentValue;
        if (benchmarkCurrentValue > maxValue) maxValue = benchmarkCurrentValue;
      }
    }

    // Add padding to value range
    final range = maxValue - minValue;
    // If range is very small (or zero), use a default range
    final effectiveRange = (range <= 1e-6)
        ? actualInitialCapital * 0.2
        : range; // 20% of initial capital as default
    minValue = max(0, minValue - effectiveRange * 0.1); // 10% padding below, but not below zero
    maxValue = maxValue + effectiveRange * 0.1; // 10% padding above
    final finalRange = maxValue - minValue; // Final range after padding

    // Define paints
    final Paint linePaint = Paint()
      ..color = AppTheme.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 // Thinner line
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.accentColor.withOpacity(0.4), // More transparent
          AppTheme.accentColor.withOpacity(0.05), // Very transparent at bottom
        ],
        stops: const [0.0, 0.9], // Gradient stops
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final Paint benchmarkLinePaint = Paint()
      ..color = Colors.orange.withOpacity(0.7) // Orange for benchmark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final Paint initialCapitalLinePaint = Paint()
      ..color = AppTheme.textSecondary.withOpacity(0.5) // Initial capital line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.butt;

    final Paint gridPaint = Paint()
      ..color = AppTheme.textSecondary.withOpacity(0.15) // Fainter grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    // --- Drawing Begins ---

    // 1. Grid Lines and Y-Axis Labels
    const int gridLines = 5; // Horizontal grid lines (including 0)
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height - (i / gridLines) * size.height;
      // Horizontal grid line
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      // Y-axis label
      final value = minValue + (i / gridLines) * finalRange;
      textPainter.text = TextSpan(
        text: _formatAxisValue(value), // Formatted value
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
      );
      textPainter.layout();
      // Place label above line and left-aligned
      textPainter.paint(canvas, Offset(5, y - textPainter.height - 2));
    }

    // 2. Initial Capital Line
    // Ensure finalRange is non-zero
    if (finalRange > 1e-6) {
      final initialY = size.height -
          ((actualInitialCapital - minValue) / finalRange) * size.height;
      // Dashed line effect using Path
      Path initialLinePath = Path();
      const double dashWidth = 4.0;
      const double dashSpace = 3.0;
      double startX = 0;
      while (startX < size.width) {
        initialLinePath.moveTo(startX, initialY);
        initialLinePath.lineTo(startX + dashWidth, initialY);
        startX += dashWidth + dashSpace;
      }
      canvas.drawPath(initialLinePath, initialCapitalLinePaint);
    }

    // 3. Equity Curve and Fill
    final Path linePath = Path();
    final Path fillPath = Path();
    final double xStep = size.width / (strategyValues.length - 1);

    // Starting points
    double startX = 0;
    double startY = size.height; // Default to bottom
    if (finalRange > 1e-6) {
      startY = size.height -
          ((strategyValues[0] - minValue) / finalRange) * size.height;
    }

    linePath.moveTo(startX, startY);
    fillPath.moveTo(startX, size.height); // Fill starts from bottom
    fillPath.lineTo(startX, startY);

    // Add curve points
    for (int i = 1; i < strategyValues.length; i++) {
      final x = i * xStep;
      double y = size.height; // Default to bottom
      if (finalRange > 1e-6) {
        y = size.height -
            ((strategyValues[i] - minValue) / finalRange) * size.height;
      }
      linePath.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    // Close fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill and line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    // 4. Benchmark (Buy & Hold) Curve if available
    if (benchmarkValues.isNotEmpty &&
        benchmarkValues.length == strategyValues.length &&
        finalRange > 1e-6) {
      final Path benchmarkPath = Path();
      double benchStartY = size.height -
          ((benchmarkValues[0] - minValue) / finalRange) * size.height;
      benchmarkPath.moveTo(0, benchStartY);

      for (int i = 1; i < benchmarkValues.length; i++) {
        final x = i * xStep;
        final y = size.height -
            ((benchmarkValues[i] - minValue) / finalRange) * size.height;
        benchmarkPath.lineTo(x, y);
      }
      canvas.drawPath(benchmarkPath, benchmarkLinePaint);
    }
  }

  // Helper to format axis values
  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '\${(value / 1000000).toStringAsFixed(1)}M'; // Millions
    } else if (value >= 1000) {
      return '\${(value / 1000).toStringAsFixed(1)}K'; // Thousands
    } else {
      return '\${value.toStringAsFixed(0)}'; // Normal value
    }
  }

  @override
  bool shouldRepaint(covariant EquityCurvePainter oldDelegate) {
    // Repaint when data changes
    return oldDelegate.equityCurve != equityCurve ||
        oldDelegate.initialValue != initialValue ||
        oldDelegate.benchmarkValue != benchmarkValue;
  }
}
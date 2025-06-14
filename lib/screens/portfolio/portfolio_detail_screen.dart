// screens/portfolio_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mini_chart.dart';
import '../../widgets/switchable_performance_chart.dart'; // Add this import
import '../../models/portfolio.dart';
import '../../models/position.dart';
import '../../services/portfolio_service.dart';
import 'add_position_screen.dart';
import 'position_detail_screen.dart';

class PortfolioDetailScreen extends StatefulWidget {
  final Portfolio portfolio;

  const PortfolioDetailScreen({
    Key? key,
    required this.portfolio,
  }) : super(key: key);

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  late Portfolio _portfolio;
  bool _isLoading = true;
  String _selectedTimeframe = '1M';
  final List<String> _timeframes = ['1W', '1M', '3M', '6M', '1Y', 'All'];

  // Track which positions are expanded
  final Set<String> _expandedPositions = {};

  @override
  void initState() {
    super.initState();
    _portfolio = widget.portfolio;
    _loadPortfolioDetails();
  }

  Future<void> _loadPortfolioDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final portfolio = await PortfolioService.getPortfolio(_portfolio.id!);
      setState(() {
        _portfolio = portfolio;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load portfolio details: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadPortfolioDetails();
  }

  void _navigateToAddPosition() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPositionScreen(portfolioId: _portfolio.id!),
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  void _navigateToPositionDetail(Position position) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PositionDetailScreen(
          position: position,
          portfolioId: _portfolio.id!,
        ),
      ),
    ).then((_) {
      _refreshData();
    });
  }

  void _togglePosition(String positionId) {
    setState(() {
      if (_expandedPositions.contains(positionId)) {
        _expandedPositions.remove(positionId);
      } else {
        _expandedPositions.add(positionId);
      }
    });
  }

  void _showDeletePortfolioDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text(
            'Delete Portfolio',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: Text(
            'Are you sure you want to delete "${_portfolio.name}"? This action cannot be undone.',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _deletePortfolio(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.negativeColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePortfolio() async {
    Navigator.of(context).pop(); // Close dialog

    try {
      await PortfolioService.deletePortfolio(_portfolio.id!);
      if (mounted) {
        Navigator.of(context).pop(true); // Return to portfolios list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portfolio deleted successfully'),
            backgroundColor: AppTheme.positiveColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete portfolio: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final textPrim = ext?.textPrimary ?? AppTheme.textPrimary;
    final accent = ext?.accentColor ?? AppTheme.accentColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _portfolio.name,
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
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: accent),
            onPressed: _navigateToAddPosition,
            tooltip: 'Add Position',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.negativeColor),
            onPressed: _showDeletePortfolioDialog,
            tooltip: 'Delete Portfolio',
          ),
        ],
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
        child: RefreshIndicator(
          onRefresh: _refreshData,
          backgroundColor: ext?.cardColor ?? AppTheme.cardColor,
          color: accent,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: accent))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Portfolio summary
                      _buildPortfolioSummary(),

                      const SizedBox(height: 24),

                      // Performance chart section - UPDATED WITH SWITCHABLE CHART
                      _buildPerformanceSection(),

                      const SizedBox(height: 24),

                      // Asset allocation
                      _buildAssetAllocation(),

                      const SizedBox(height: 24),

                      // Positions list
                      _buildPositionsList(),

                      // Add some bottom padding
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPortfolioSummary() {
    final isPositive = _portfolio.totalGainLossPercent != null &&
        _portfolio.totalGainLossPercent! >= 0;
    final color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '\$${_portfolio.totalValue?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Gain/loss row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Gain/Loss',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: color,
                    size: 16,
                  ),
                  Text(
                    '\$${_portfolio.totalGainLoss?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Percent gain/loss row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Percent Gain/Loss',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${_portfolio.totalGainLossPercent?.toStringAsFixed(2) ?? '0.00'}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Positions count row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Positions',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${_portfolio.positions.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with timeframe selector
        Row(
          children: [
            const Text(
              'Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            _buildTimeframeSelector(),
          ],
        ),

        const SizedBox(height: 16),

        // UPDATED: Use SwitchablePerformanceChart instead of the old chart
        FuturisticCard(
          padding: const EdgeInsets.all(16),
          child: SwitchablePerformanceChart(
            portfolioId: _portfolio.id!,
            timeframe: _selectedTimeframe,
            height: 320, // Slightly taller to accommodate the toggle and extra info
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _timeframes.map((timeframe) {
          final isSelected = _selectedTimeframe == timeframe;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeframe = timeframe;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                timeframe,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAssetAllocation() {
    // Group positions by ticker or asset type
    Map<String, double> allocation = {};

    for (var position in _portfolio.positions) {
      if (position.currentValue != null) {
        allocation[position.ticker] =
            (allocation[position.ticker] ?? 0) + position.currentValue!;
      }
    }

    // Calculate percentages
    Map<String, double> percentages = {};
    final totalValue = _portfolio.totalValue ?? 0;

    if (totalValue > 0) {
      allocation.forEach((key, value) {
        percentages[key] = (value / totalValue) * 100;
      });
    }

    // Sort by value (descending)
    final sortedEntries = percentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asset Allocation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        FuturisticCard(
          child: Column(
            children: [
              if (percentages.isEmpty) ...[
                const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'No allocation data available',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ] else ...[
                // Allocation bars
                ...sortedEntries.map((entry) => _buildAllocationBar(
                      entry.key,
                      entry.value,
                      _getColorForAsset(entry.key),
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationBar(String ticker, double percentage, Color color) {
    // Find company name
    final position = _portfolio.positions.firstWhere(
      (p) => p.ticker == ticker,
      orElse: () => Position(
        ticker: ticker,
        companyName: ticker,
        quantity: 0,
        averagePrice: 0,
        purchaseDate: DateTime.now(),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  position.companyName ?? ticker,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppTheme.cardColorLight,
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForAsset(String ticker) {
    // Generate a deterministic color based on the ticker
    final colors = [
      AppTheme.accentColor,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];

    final index = ticker.hashCode % colors.length;
    return colors[index.abs()];
  }

  Widget _buildPositionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Positions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (_portfolio.positions.isEmpty)
          FuturisticCard(
            child: SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No positions in this portfolio',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _navigateToAddPosition,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Position'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...(_portfolio.positions
                  .asMap()
                  .entries
                  .map((entry) => _buildPositionCard(entry.value, entry.key)))
              .toList(),
      ],
    );
  }

  Widget _buildPositionCard(Position position, int index) {
    final isPositive =
        position.gainLossPercent != null && position.gainLossPercent! >= 0;
    final color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;
    final isExpanded =
        position.id != null && _expandedPositions.contains(position.id!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FuturisticCard(
        onTap: () => _navigateToPositionDetail(position),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main position row
            Row(
              children: [
                // Left section: Ticker and name
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position.ticker,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      if (position.companyName != null)
                        Text(
                          position.companyName!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Middle section: Chart if available
                if (position.performanceData != null &&
                    position.performanceData!.isNotEmpty)
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 40,
                      child: MiniChart(
                        data: position.performanceData!,
                        isPositive: isPositive,
                        showGradient: true,
                      ),
                    ),
                  )
                else
                  Expanded(
                    flex: 3,
                    child: Container(),
                  ),

                // Right section: Value and change
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${position.currentValue?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${position.gainLossPercent?.toStringAsFixed(2) ?? '0.00'}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expand button
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => position.id != null
                      ? _togglePosition(position.id!)
                      : null,
                ),
              ],
            ),

            // Expanded details
            if (isExpanded) ...[
              const Divider(height: 16, color: AppTheme.backgroundColor),

              // Additional position details
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Quantity',
                      '${position.quantity.toStringAsFixed(4)} shares',
                    ),
                    _buildDetailRow(
                      'Avg Price',
                      '\$${position.averagePrice.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      'Current Price',
                      '\$${position.currentPrice?.toStringAsFixed(2) ?? 'N/A'}',
                    ),
                    _buildDetailRow(
                      'Total Cost',
                      '\$${(position.quantity * position.averagePrice).toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      'Gain/Loss',
                      '\$${position.gainLoss?.toStringAsFixed(2) ?? '0.00'}',
                      valueColor: color,
                    ),
                    _buildDetailRow(
                      'Purchase Date',
                      _formatDate(position.purchaseDate),
                    ),
                  ],
                ),
              ),

              // View details button
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () => _navigateToPositionDetail(position),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
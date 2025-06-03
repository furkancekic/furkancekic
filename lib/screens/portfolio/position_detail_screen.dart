// screens/position_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/position.dart';
import '../../models/transaction.dart';
import '../../services/portfolio_service.dart';

class PositionDetailScreen extends StatefulWidget {
  final Position position;
  final String portfolioId;

  const PositionDetailScreen({
    Key? key,
    required this.position,
    required this.portfolioId,
  }) : super(key: key);

  @override
  State<PositionDetailScreen> createState() => _PositionDetailScreenState();
}

class _PositionDetailScreenState extends State<PositionDetailScreen> {
  late Position _position;
  bool _isLoading = false;
  String _selectedTimeframe = '1M';
  final List<String> _timeframes = ['1W', '1M', '3M', '6M', '1Y', 'All'];

  @override
  void initState() {
    super.initState();
    _position = widget.position;
    _loadPositionDetails();
  }

  Future<void> _loadPositionDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await PortfolioService.getPosition(
        portfolioId: widget.portfolioId,
        positionId: _position.id!,
        timeframe: _selectedTimeframe,
      );
      setState(() {
        _position = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load position details: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  void _showDeletePositionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text(
            'Delete Position',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: Text(
            'Are you sure you want to delete ${_position.ticker} from your portfolio? This action cannot be undone.',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _deletePosition(),
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

  Future<void> _deletePosition() async {
    Navigator.of(context).pop(); // Close dialog

    try {
      await PortfolioService.deletePosition(
        portfolioId: widget.portfolioId,
        positionId: _position.id!,
      );
      if (mounted) {
        Navigator.of(context).pop(true); // Return to portfolio detail
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position deleted successfully'),
            backgroundColor: AppTheme.positiveColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete position: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  void _showAddTransactionDialog() {
    // TODO: Implement add transaction dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add transaction feature coming soon'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final textPrim = ext?.textPrimary ?? AppTheme.textPrimary;
    final accent = ext?.accentColor ?? AppTheme.accentColor;

    // Calculate if position is profitable
    final isPositive =
        _position.gainLossPercent != null && _position.gainLossPercent! >= 0;
    final color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _position.ticker,
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
            icon: Icon(Icons.add_circle_outline, color: accent),
            onPressed: _showAddTransactionDialog,
            tooltip: 'Add Transaction',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.negativeColor),
            onPressed: _showDeletePositionDialog,
            tooltip: 'Delete Position',
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
          onRefresh: _loadPositionDetails,
          backgroundColor: ext?.cardColor ?? AppTheme.cardColor,
          color: accent,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: accent))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Position header with company name
                      if (_position.companyName != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _position.companyName!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),

                      // Position summary
                      _buildPositionSummary(color, isPositive),

                      const SizedBox(height: 24),

                      // Performance chart
                      _buildPerformanceChart(accent),

                      const SizedBox(height: 24),

                      // Transaction history
                      _buildTransactionHistory(),

                      const SizedBox(height: 24),

                      // Holdings breakdown
                      _buildHoldingsBreakdown(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPositionSummary(Color color, bool isPositive) {
    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '\$${_position.currentValue?.toStringAsFixed(2) ?? '0.00'}',
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
                'Gain/Loss',
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
                  const SizedBox(width: 4),
                  Text(
                    '\$${_position.gainLoss?.toStringAsFixed(2) ?? '0.00'}',
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
                  '${isPositive ? '+' : ''}${_position.gainLossPercent?.toStringAsFixed(2) ?? '0.00'}%',
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

          // Current price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Price',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '\$${_position.currentPrice?.toStringAsFixed(2) ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Average cost
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Average Cost',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '\$${_position.averagePrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Shares owned
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shares Owned',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                _position.quantity.toStringAsFixed(
                  _position.quantity.truncateToDouble() == _position.quantity
                      ? 0
                      : 4,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Purchase date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Purchase Date',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                _formatDate(_position.purchaseDate),
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

  Widget _buildPerformanceChart(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with timeframe selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: _timeframes.length,
                itemBuilder: (context, index) {
                  final timeframe = _timeframes[index];
                  final isSelected = timeframe == _selectedTimeframe;

                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(
                        timeframe,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.black
                              : AppTheme.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.accentColor,
                      backgroundColor: AppTheme.cardColor,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTimeframe = timeframe;
                          });
                          _loadPositionDetails();
                        }
                      },
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      labelPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Performance chart
        FuturisticCard(
          padding: const EdgeInsets.all(12),
          child: _position.performanceData == null ||
                  _position.performanceData!.isEmpty
              ? const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'No performance data available',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _createChartSpots(),
                          isCurved: true,
                          color: accent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            // Replace the three incorrect parameters with gradient
                            gradient: LinearGradient(
                              colors: [
                                accent.withOpacity(0.3),
                                accent.withOpacity(0.0),
                              ],
                              stops: [0.5, 1.0],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  List<FlSpot> _createChartSpots() {
    if (_position.performanceData == null) return [];

    List<FlSpot> spots = [];
    final data = _position.performanceData!;

    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }

    return spots;
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Text(
          'Transaction History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        FuturisticCard(
          child: _position.transactions.isEmpty
              ? const SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      'No transactions recorded',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Table header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: const [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Date',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Type',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Shares',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Price',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: AppTheme.backgroundColor),

                    // Transaction rows
                    ..._position.transactions.map(
                        (transaction) => _buildTransactionRow(transaction)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionRow(Transaction transaction) {
    // Get transaction type color
    Color typeColor;
    switch (transaction.type) {
      case TransactionType.buy:
        typeColor = AppTheme.positiveColor;
        break;
      case TransactionType.sell:
        typeColor = AppTheme.negativeColor;
        break;
      case TransactionType.dividend:
        typeColor = Colors.amber;
        break;
      case TransactionType.split:
        typeColor = AppTheme.accentColor;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(transaction.date),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transaction.type.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              transaction.quantity.toString(),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '\$${transaction.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingsBreakdown() {
    // Calculate total cost and total value
    final totalCost = _position.quantity * _position.averagePrice;
    final totalValue = _position.currentValue ?? 0;

    // Calculate percentages for the breakdown chart
    double gainLossValue = totalValue - totalCost;
    double gainPercent = 0;
    if (totalCost > 0) {
      gainPercent = gainLossValue / totalCost * 100;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Text(
          'Holdings Breakdown',
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
              // Cost vs. Current Value
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Cost',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Value',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Visual breakdown
              Stack(
                children: [
                  // Base bar (total cost)
                  Container(
                    height: 24,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),

                  // Gain/Loss bar
                  if (gainLossValue != 0 && totalCost > 0)
                    Positioned(
                      left: gainLossValue < 0 ? null : 0,
                      right: gainLossValue < 0 ? 0 : null,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        height: 24,
                        // If loss, calculate width from right side, otherwise from left
                        width: (gainLossValue.abs() /
                                (totalCost + gainLossValue.abs())) *
                            MediaQuery.of(context).size.width *
                            0.8, // Approximate card width
                        decoration: BoxDecoration(
                          color: gainLossValue >= 0
                              ? AppTheme.positiveColor
                              : AppTheme.negativeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Cost Basis',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: gainLossValue >= 0
                          ? AppTheme.positiveColor
                          : AppTheme.negativeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    gainLossValue >= 0 ? 'Gain' : 'Loss',
                    style: TextStyle(
                      fontSize: 12,
                      color: gainLossValue >= 0
                          ? AppTheme.positiveColor
                          : AppTheme.negativeColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Gain/Loss Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (gainLossValue >= 0
                          ? AppTheme.positiveColor
                          : AppTheme.negativeColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (gainLossValue >= 0
                            ? AppTheme.positiveColor
                            : AppTheme.negativeColor)
                        .withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      gainLossValue >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: gainLossValue >= 0
                          ? AppTheme.positiveColor
                          : AppTheme.negativeColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      gainLossValue >= 0
                          ? 'This position is up ${gainPercent.toStringAsFixed(2)}% since purchase'
                          : 'This position is down ${gainPercent.abs().toStringAsFixed(2)}% since purchase',
                      style: TextStyle(
                        color: gainLossValue >= 0
                            ? AppTheme.positiveColor
                            : AppTheme.negativeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

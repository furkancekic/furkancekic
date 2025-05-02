// screens/portfolio_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/portfolio.dart';
import '../services/portfolio_service.dart';
import 'portfolio_detail_screen.dart';
import 'add_portfolio_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  bool _isLoading = true;
  List<Portfolio> _portfolios = [];
  String _selectedTimeframe = '1M'; // Default to 1 month view
  final List<String> _timeframes = ['1W', '1M', '3M', '6M', '1Y', 'All'];

  @override
  void initState() {
    super.initState();
    _loadPortfolios();
  }

  Future<void> _loadPortfolios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final portfolios = await PortfolioService.getPortfolios();
      setState(() {
        _portfolios = portfolios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load portfolios: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  void _navigateToAddPortfolio() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPortfolioScreen()),
    );

    if (result == true) {
      _loadPortfolios(); // Refresh portfolios
    }
  }

  void _navigateToPortfolioDetail(Portfolio portfolio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PortfolioDetailScreen(portfolio: portfolio),
      ),
    ).then((_) {
      _loadPortfolios(); // Refresh when returning
    });
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final textPrim = ext?.textPrimary ?? AppTheme.textPrimary;
    final accent = ext?.accentColor ?? AppTheme.accentColor;

    return Container(
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
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPortfolios,
          backgroundColor: ext?.cardColor ?? AppTheme.cardColor,
          color: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: accent, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'My Portfolios',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrim,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.add, color: accent),
                      onPressed: _navigateToAddPortfolio,
                      tooltip: 'Add New Portfolio',
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: accent),
                      onPressed: _loadPortfolios,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),

              // Timeframe selector
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
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
                              _loadPortfolios(); // Reload with new timeframe
                            }
                          },
                          backgroundColor: ext?.cardColor ?? AppTheme.cardColor,
                          selectedColor: accent,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : textPrim,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Portfolio Summary
              if (!_isLoading && _portfolios.isNotEmpty)
                _buildPortfolioSummary(),

              // Portfolios List
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: accent),
                      )
                    : _portfolios.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _portfolios.length,
                            itemBuilder: (context, index) {
                              return _buildPortfolioCard(_portfolios[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioSummary() {
    if (_portfolios.isEmpty) return const SizedBox.shrink();

    // Calculate total portfolio value
    double totalValue = 0;
    double totalGainLoss = 0;
    double totalInitialValue = 0;

    for (var portfolio in _portfolios) {
      if (portfolio.totalValue != null) {
        totalValue += portfolio.totalValue!;
      }
      if (portfolio.totalGainLoss != null) {
        totalGainLoss += portfolio.totalGainLoss!;
        totalInitialValue += portfolio.totalValue! - portfolio.totalGainLoss!;
      }
    }

    double totalGainLossPercent =
        totalInitialValue > 0 ? (totalGainLoss / totalInitialValue) * 100 : 0;

    final isPositive = totalGainLoss >= 0;
    final color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: FuturisticCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Portfolio Value',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${totalValue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}\$${totalGainLoss.toStringAsFixed(2)} (${isPositive ? '+' : ''}${totalGainLossPercent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'All time',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioCard(Portfolio portfolio) {
    final isPositive = portfolio.totalGainLossPercent != null &&
        portfolio.totalGainLossPercent! >= 0;
    final color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FuturisticCard(
        onTap: () => _navigateToPortfolioDetail(portfolio),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portfolio name and value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        portfolio.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (portfolio.description.isNotEmpty)
                        Text(
                          portfolio.description,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${portfolio.totalValue?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (portfolio.totalGainLossPercent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${portfolio.totalGainLossPercent!.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Portfolio mini chart (if available)
            if (portfolio.positions.any((p) =>
                p.performanceData != null && p.performanceData!.isNotEmpty))
              SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    // Draw charts for each position
                    ...portfolio.positions
                        .where((p) =>
                            p.performanceData != null &&
                            p.performanceData!.isNotEmpty)
                        .map((position) {
                      final isPositive = position.gainLossPercent != null &&
                          position.gainLossPercent! >= 0;
                      return Opacity(
                        opacity: 0.5, // Make semi-transparent for layering
                        child: MiniChart(
                          data: position.performanceData!,
                          isPositive: isPositive,
                          height: 60,
                          width: double.infinity,
                          showGradient: false, // Disable gradient for layering
                        ),
                      );
                    }),

                    // Position labels on the right
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        color: AppTheme.cardColor.withOpacity(0.8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${portfolio.positions.length} positions',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Last updated date
            Text(
              'Last updated: ${_formatDate(portfolio.updatedAt)}',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No portfolios found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to create your first portfolio',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddPortfolio,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Portfolio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} mins ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}

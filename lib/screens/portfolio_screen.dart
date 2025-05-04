// screens/portfolio_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/portfolio.dart';
import '../services/portfolio_service.dart';
import 'portfolio_detail_screen.dart';
import 'add_portfolio_screen.dart';
import '../widgets/mini_chart.dart';
import '../widgets/benchmark_comparison_chart.dart';
import '../widgets/interactive_pie_chart.dart';
import '../models/position.dart';

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
  List<PerformancePoint> _selectedPortfolioPerformanceData = [];
  String? _selectedPortfolioId; // null means showing total portfolio
  bool _isLoadingChart = true;
  
  @override
  void initState() {
    super.initState();
    _loadPortfolios();
  }

  Future<void> _loadPerformanceData() async {
    setState(() {
      _isLoadingChart = true;
    });

    try {
      if (_selectedPortfolioId == null) {
        // Load total portfolio performance
        final totalPerformance =
            await PortfolioService.getTotalPortfoliosPerformance(
                _selectedTimeframe);
        setState(() {
          _selectedPortfolioPerformanceData = totalPerformance.data;
          _isLoadingChart = false;
        });
      } else {
        // Load specific portfolio performance
        final portfolioPerformance =
            await PortfolioService.getPortfolioPerformance(
          _selectedPortfolioId!,
          _selectedTimeframe,
        );
        setState(() {
          _selectedPortfolioPerformanceData = portfolioPerformance.data;
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingChart = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load performance data: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  // Add this method to get the total value of all portfolios
  double _getTotalValueOfAllPortfolios() {
    double total = 0;
    for (var portfolio in _portfolios) {
      if (portfolio.totalValue != null) {
        total += portfolio.totalValue!;
      }
    }
    return total;
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
      _loadPerformanceData(); // Load performance data after portfolios are loaded
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

  // Yeni eklenen metod: Portföyün pie chart modalını göster
  void _showPortfolioPieChartModal(Portfolio portfolio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).extension<AppThemeExtension>()?.cardColor ?? 
                      AppTheme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Pull handle
                  Container(
                    margin: EdgeInsets.only(top: 12, bottom: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Asset Allocation',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
                                        AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                portfolio.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).extension<AppThemeExtension>()?.textSecondary ??
                                        AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          color: Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
                                AppTheme.textPrimary,
                        ),
                      ],
                    ),
                  ),
                  
                  Divider(),
                  
                  // Portfolio value
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total Value: ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).extension<AppThemeExtension>()?.textSecondary ??
                                  AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '\$${portfolio.totalValue?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
                                  AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Pie chart (taking most of the modal space)
                  Expanded(
                    child: InteractivePieChart(
                      portfolio: portfolio,
                      size: MediaQuery.of(context).size.width * 0.8,
                      showPercentage: true,
                      showLabels: true,
                    ),
                  ),
                  
                  // Bottom padding
                  SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Aynı şekilde toplam portföy dağılımını gösteren modal
  void _showTotalPortfolioPieChartModal() {
    // Tüm pozisyonları birleştir
    final allPositions = <Position>[];
    for (var portfolio in _portfolios) {
      allPositions.addAll(portfolio.positions);
    }

    // Birleştirilmiş portföy nesnesi oluştur
    final combinedPortfolio = Portfolio(
      id: 'combined',
      name: 'Total Portfolio',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalValue: _getTotalValueOfAllPortfolios(),
      positions: allPositions,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).extension<AppThemeExtension>()?.cardColor ?? 
                      AppTheme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Pull handle
                  Container(
                    margin: EdgeInsets.only(top: 12, bottom: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Asset Allocation',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
                                        AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'All Portfolios',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).extension<AppThemeExtension>()?.textSecondary ??
                                        AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          color: Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
                                AppTheme.textPrimary,
                        ),
                      ],
                    ),
                  ),
                  
                  Divider(),
                  
                  // Portfolio value
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total Value: ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).extension<AppThemeExtension>()?.textSecondary ??
                                  AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '\$${combinedPortfolio.totalValue?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
                                  AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Pie chart (taking most of the modal space)
                  Expanded(
                    child: InteractivePieChart(
                      portfolio: combinedPortfolio,
                      size: MediaQuery.of(context).size.width * 0.8,
                      showPercentage: true,
                      showLabels: true,
                    ),
                  ),
                  
                  // Bottom padding
                  SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
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
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: FuturisticCard(
        onTap: _showTotalPortfolioPieChartModal, // Modal göstermek için tıklama
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Portfolio Value',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                // Modal açma göstergesi olarak ikon ekleme
                Icon(
                  Icons.pie_chart,
                  size: 18,
                  color: Theme.of(context).extension<AppThemeExtension>()?.accentColor ?? 
                        AppTheme.accentColor,
                ),
              ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      padding: const EdgeInsets.only(bottom: 16),
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

                    // Position labels and pie chart icon on the right
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        color: AppTheme.cardColor.withOpacity(0.8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${portfolio.positions.length} positions',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Pie chart butonu ekledik
                            GestureDetector(
                              onTap: () => _showPortfolioPieChartModal(portfolio),
                              child: Icon(
                                Icons.pie_chart,
                                size: 18,
                                color: Theme.of(context).extension<AppThemeExtension>()?.accentColor ?? 
                                      AppTheme.accentColor,
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

  Widget _buildPerformanceChart() {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final accent = ext?.accentColor ?? AppTheme.accentColor;
    final cardColor = ext?.cardColor ?? AppTheme.cardColor;
    final textPrimary = ext?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = ext?.textSecondary ?? AppTheme.textSecondary;

    if (_isLoadingChart) {
      return FuturisticCard(
        child: SizedBox(
          height: 250,
          child: Center(
            child: CircularProgressIndicator(color: accent),
          ),
        ),
      );
    }

    if (_selectedPortfolioPerformanceData.isEmpty) {
      return FuturisticCard(
        child: SizedBox(
          height: 250,
          child: Center(
            child: Text(
              'No performance data available',
              style: TextStyle(color: textSecondary),
            ),
          ),
        ),
      );
    }

    // Portfolio selector dropdown widget
    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio Performance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Portfolio dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedPortfolioId,
                      isExpanded: true,
                      dropdownColor: cardColor,
                      icon: Icon(Icons.arrow_drop_down, color: accent),
                      style: TextStyle(color: textPrimary),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All Portfolios',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: _selectedPortfolioId == null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            ),
                          ),
                        ),
                        ..._portfolios.map((portfolio) {
                          return DropdownMenuItem<String?>(
                            value: portfolio.id,
                            child: Text(
                              portfolio.name,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: _selectedPortfolioId == portfolio.id
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedPortfolioId = value;
                        });
                        _loadPerformanceData();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Here you would add your chart visualization
          // For example, using a LineChart from fl_chart
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: const Center(
                child: Text('Portfolio performance chart would go here'),
              ),
            ),
          ),
        ],
      ),
    );
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
                              _loadPerformanceData(); // Reload chart data
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

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Portfolio Performance Chart
                    const SizedBox(height: 8),
                    _buildPerformanceChart(),
                    const SizedBox(height: 24),

                    // Benchmark Comparison Chart
                    if (!_isLoading &&
                        _portfolios.isNotEmpty &&
                        _selectedPortfolioPerformanceData.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BenchmarkComparisonChart(
                            portfolioData: _selectedPortfolioPerformanceData,
                            timeframe: _selectedTimeframe,
                            selectedPortfolioId: _selectedPortfolioId,
                            portfolioStartValue:
                                _selectedPortfolioPerformanceData.first.value,
                            portfolioEndValue:
                                _selectedPortfolioPerformanceData.last.value,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                    // Portfolio Summary
                    if (!_isLoading && _portfolios.isNotEmpty)
                      _buildPortfolioSummary(),

                    // Portfolios List Title
                    if (!_isLoading && _portfolios.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                        child: Text(
                          'Your Portfolios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrim,
                          ),
                        ),
                      ),

                    // Portfolios List
                    if (_isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: accent),
                        ),
                      )
                    else if (_portfolios.isEmpty)
                      _buildEmptyState()
                    else
                      ..._portfolios
                          .map((portfolio) => _buildPortfolioCard(portfolio))
                          .toList(),

                    // Add some bottom padding
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
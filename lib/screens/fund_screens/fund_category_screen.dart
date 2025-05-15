import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/fund_api_service.dart';
import '../../models/fund.dart';
import '../../widgets/fund_widgets/fund_card.dart';
import 'fund_detail_screen.dart';

class FundCategoryScreen extends StatefulWidget {
  final String category;

  const FundCategoryScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<FundCategoryScreen> createState() => _FundCategoryScreenState();
}

class _FundCategoryScreenState extends State<FundCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Fund> _funds = [];
  List<Fund> _filteredFunds = [];
  bool _isLoading = true;
  String _error = '';
  String _sortBy = 'daily_return';
  bool _isAscending = false;

  final List<Map<String, dynamic>> _sortOptions = [
    {'key': 'daily_return', 'label': 'Günlük Getiri', 'icon': Icons.trending_up},
    {'key': 'total_value', 'label': 'Toplam Değer', 'icon': Icons.attach_money},
    {'key': 'investor_count', 'label': 'Yatırımcı Sayısı', 'icon': Icons.people},
    {'key': 'market_share', 'label': 'Pazar Payı', 'icon': Icons.pie_chart},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadFunds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterFunds();
  }

  void _filterFunds() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFunds = List.from(_funds);
      } else {
        _filteredFunds = _funds.where((fund) {
          return fund.kod.toLowerCase().contains(query) ||
              fund.name.toLowerCase().contains(query);
        }).toList();
      }
      _sortFunds();
    });
  }

  void _sortFunds() {
    _filteredFunds.sort((a, b) {
      late double aValue, bValue;
      
      switch (_sortBy) {
        case 'daily_return':
          aValue = a.dailyReturnValue;
          bValue = b.dailyReturnValue;
          break;
        case 'total_value':
          aValue = a.totalValue;
          bValue = b.totalValue;
          break;
        case 'investor_count':
          aValue = a.investorCount.toDouble();
          bValue = b.investorCount.toDouble();
          break;
        case 'market_share':
          // Parse market share percentage
          aValue = _parseMarketShare(a.pazarPayi);
          bValue = _parseMarketShare(b.pazarPayi);
          break;
        default:
          return 0;
      }
      
      if (_isAscending) {
        return aValue.compareTo(bValue);
      } else {
        return bValue.compareTo(aValue);
      }
    });
  }

  double _parseMarketShare(String? marketShare) {
    if (marketShare == null) return 0.0;
    try {
      return double.parse(marketShare.replaceAll('%', '').replaceAll(',', '.'));
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _loadFunds() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final funds = await FundApiService.getFundsByCategory(widget.category);
      setState(() {
        _funds = funds;
        _filteredFunds = List.from(funds);
        _isLoading = false;
        _sortFunds();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category,
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: accentColor),
            onSelected: (value) {
              setState(() {
                if (value == _sortBy) {
                  _isAscending = !_isAscending;
                } else {
                  _sortBy = value;
                  _isAscending = false;
                }
                _sortFunds();
              });
            },
            itemBuilder: (context) => _sortOptions.map((option) {
              final isSelected = option['key'] == _sortBy;
              return PopupMenuItem<String>(
                value: option['key'],
                child: Row(
                  children: [
                    Icon(
                      option['icon'],
                      color: isSelected ? accentColor : textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      option['label'],
                      style: TextStyle(
                        color: isSelected ? accentColor : textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      Icon(
                        _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: accentColor,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchField(
              controller: _searchController,
              hintText: 'Fon ara...',
              onChanged: (value) => _filterFunds(),
            ),
          ),

          // Stats
          _buildCategoryStats(),

          // Fund List
          Expanded(
            child: _buildFundList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;

    if (_funds.isEmpty) return const SizedBox.shrink();

    // Calculate statistics
    final totalValue = _funds.fold<double>(0.0, (sum, fund) => sum + fund.totalValue);
    final averageReturn = _funds.isNotEmpty 
        ? _funds.fold<double>(0.0, (sum, fund) => sum + fund.dailyReturnValue) / _funds.length
        : 0.0;
    final totalInvestors = _funds.fold<int>(0, (sum, fund) => sum + fund.investorCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Toplam Fon',
              _filteredFunds.length.toString(),
              textPrimary,
              textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Toplam Değer',
              _formatCurrency(totalValue),
              textPrimary,
              textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Ort. Getiri',
              '${averageReturn >= 0 ? '+' : ''}${averageReturn.toStringAsFixed(2)}%',
              textPrimary,
              textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Toplam Yatırımcı',
              _formatNumber(totalInvestors),
              textPrimary,
              textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color textPrimary, Color textSecondary) {
    return FuturisticCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFundList() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              color: themeExtension?.negativeColor ?? AppTheme.negativeColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              style: TextStyle(
                color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFunds,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_filteredFunds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty 
                  ? 'Aranan kriterlere uygun fon bulunamadı'
                  : 'Bu kategoride fon bulunamadı',
              style: TextStyle(
                color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFunds,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _filteredFunds.length,
        itemBuilder: (context, index) {
          final fund = _filteredFunds[index];
          return FundCard(
            fund: fund.toJson(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FundDetailScreen(fund: fund.toJson()),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1e12) {
      return '${(value / 1e12).toStringAsFixed(1)}T ₺';
    } else if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}B ₺';
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M ₺';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K ₺';
    } else {
      return '${value.toStringAsFixed(0)} ₺';
    }
  }

  String _formatNumber(int value) {
    if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      return value.toString();
    }
  }
}
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/fund_api_service.dart';
import '../models/fund.dart';
import '../widgets/fund_card.dart';
import '../widgets/fund_filter_sheet.dart';
import 'fund_detail_screen.dart';
import 'fund_market_overview_screen.dart';

class FundListScreen extends StatefulWidget {
  const FundListScreen({Key? key}) : super(key: key);

  @override
  State<FundListScreen> createState() => _FundListScreenState();
}

class _FundListScreenState extends State<FundListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State variables
  List<Fund> _funds = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;

  // Filter variables
  String? _selectedCategory;
  String _sortBy = 'total_value'; // total_value, daily_return, investor_count
  bool _isAscending = false;
  double? _minReturn;
  double? _maxReturn;
  bool _onlyTefas = false;

  static const int _fundsPerPage = 25;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFunds(refresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      if (!_isLoading && _hasMore) {
        _loadFunds();
      }
    }
  }

  Future<void> _loadFunds({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 0;
        _funds.clear();
        _hasMore = true;
      }
    });

    try {
      final params = {
        'page': _currentPage.toString(),
        'limit': _fundsPerPage.toString(),
        'sort_by': _sortBy,
        'order': _isAscending ? 'asc' : 'desc',
        if (_selectedCategory != null) 'category': _selectedCategory!,
        if (_minReturn != null) 'min_return': _minReturn.toString(),
        if (_maxReturn != null) 'max_return': _maxReturn.toString(),
        if (_onlyTefas) 'only_tefas': 'true',
        if (_searchController.text.isNotEmpty) 'search': _searchController.text,
      };

      // API çağrısı burada yapılacak
      final newFunds = await FundApiService.getFunds(params);

      setState(() {
        if (refresh) {
          _funds = newFunds;
        } else {
          _funds.addAll(newFunds);
        }
        _hasMore = newFunds.length == _fundsPerPage;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fonlar yüklenemedi: $e')),
      );
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FundFilterSheet(
        selectedCategory: _selectedCategory,
        sortBy: _sortBy,
        isAscending: _isAscending,
        minReturn: _minReturn,
        maxReturn: _maxReturn,
        onlyTefas: _onlyTefas,
        onApplyFilters:
            (category, sortBy, isAscending, minReturn, maxReturn, onlyTefas) {
          setState(() {
            _selectedCategory = category;
            _sortBy = sortBy;
            _isAscending = isAscending;
            _minReturn = minReturn;
            _maxReturn = maxReturn;
            _onlyTefas = onlyTefas;
          });
          _loadFunds(refresh: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = ext?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = ext?.textSecondary ?? AppTheme.textSecondary;
    final accent = ext?.accentColor ?? AppTheme.accentColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(textPrimary, accent),
            // Search & Filter Bar
            _buildSearchAndFilter(accent),
            // Quick Stats
            _buildQuickStats(textPrimary, textSecondary),
            // Fund List
            Expanded(
              child: _buildFundList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.account_balance, color: accent, size: 28),
          const SizedBox(width: 12),
          Text(
            'Yatırım Fonları',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FundMarketOverviewScreen(),
                ),
              );
            },
            icon: Icon(Icons.analytics, color: accent),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SearchField(
              controller: _searchController,
              hintText: 'Fon ara...',
              onSubmitted: () => _loadFunds(refresh: true),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).extension<AppThemeExtension>()?.cardColor ??
                      AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.2)),
            ),
            child: IconButton(
              onPressed: _showFilterSheet,
              icon: Icon(Icons.tune, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Toplam Fon',
              '${_funds.length}+',
              Icons.account_balance_wallet,
              textPrimary,
              textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Ortalama Getiri',
              '+${_calculateAverageReturn().toStringAsFixed(2)}%',
              Icons.trending_up,
              textPrimary,
              textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Aktif Kategori',
              '${_getUniqueCategories()}',
              Icons.category,
              textPrimary,
              textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color textPrimary, Color textSecondary) {
    return FuturisticCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: textSecondary, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundList() {
    if (_funds.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_funds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Fon bulunamadı', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFunds(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _funds.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _funds.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final fund = _funds[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FundCard(
              fund: fund,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FundDetailScreen(fund: fund),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  double _calculateAverageReturn() {
    if (_funds.isEmpty) return 0.0;
    double total = 0.0;
    int count = 0;
    for (final fund in _funds) {
      final returnStr =
          fund.dailyReturn?.replaceAll('%', '').replaceAll(',', '.');
      if (returnStr != null) {
        final returnValue = double.tryParse(returnStr);
        if (returnValue != null) {
          total += returnValue;
          count++;
        }
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  int _getUniqueCategories() {
    final categories = <String>{};
    for (final fund in _funds) {
      if (fund.category != null) {
        categories.add(fund.category!);
      }
    }
    return categories.length;
  }
}

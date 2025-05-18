// lib/screens/fund_screens/fund_list_screen.dart - Updated version
import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/fund_api_service.dart';
import '../../models/fund.dart';
import '../../widgets/fund_widgets/fund_card.dart';
import '../../widgets/fund_widgets/fund_filter_sheet.dart';
import '../../widgets/fund_widgets/fund_loading_shimmer.dart';
import 'fund_detail_screen.dart';
import 'fund_market_overview_screen.dart';

class FundListScreen extends StatefulWidget {
  const FundListScreen({Key? key}) : super(key: key);

  @override
  State<FundListScreen> createState() => _FundListScreenState();
}

class _FundListScreenState extends State<FundListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  // State variables
  List<Fund> _funds = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  int _totalCount = 0;
  String _error = '';

  // Filter variables
  Map<String, dynamic> _currentFilters = {};

  // Debounce timer for search
  Timer? _debounceTimer;

  static const int _fundsPerPage = 25;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadFunds(refresh: true);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
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

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadFunds(refresh: true);
      }
    });
  }

// FundListScreen _loadFunds metodundaki optimizasyon
Future<void> _loadFunds({bool refresh = false}) async {
  if (_isLoading && !refresh) return;

  setState(() {
    _isLoading = true;
    _error = '';
    if (refresh) {
      _currentPage = 0;
      _funds.clear();
      _hasMore = true;
    }
  });

  try {
    final params = <String, dynamic>{
      'page': _currentPage.toString(),
      'limit': _fundsPerPage.toString(),
      ..._currentFilters,
      if (_searchController.text.isNotEmpty) 'search': _searchController.text,
    };

    final response = await FundApiService.getFundsWithPagination(params);
    final List<Fund> newFunds = response['funds'] as List<Fund>;
    final int total = response['total'] as int;

    // API hazır değilse, demo verileri kullan
    // List<Fund> enrichedFunds = DemoDataGenerator.enrichFundsWithDemoData(newFunds);
    
    // Ya da optimize edilmiş API çağrısı ile zenginleştir
    List<Fund> enrichedFunds = await FundApiService.enrichFundsWithPerformanceMetrics(newFunds);

    if (mounted) {
      setState(() {
        if (refresh) {
          _funds = enrichedFunds;
        } else {
          _funds.addAll(enrichedFunds);
        }
        _totalCount = total;
        _hasMore = enrichedFunds.length == _fundsPerPage;
        _currentPage++;
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _error = "Bir hata oluştu: ${e.toString()}";
        _hasMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fonlar yüklenemedi: $_error'),
          action: SnackBarAction(
            label: 'Tekrar Dene',
            onPressed: () => _loadFunds(refresh: true),
          ),
        ),
      );
    }
  }
}
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FundFilterSheet(
        currentFilters: Map<String, dynamic>.from(_currentFilters),
        onFiltersChanged: (filters) {
          if (mounted) {
            setState(() {
              _currentFilters = filters;
            });
            _loadFunds(refresh: true);
          }
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
    final cardColor = ext?.cardColor ?? AppTheme.cardColor;
    final negativeColor = ext?.negativeColor ?? AppTheme.negativeColor;
    final positiveColor = ext?.positiveColor ?? AppTheme.positiveColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(textPrimary, accent),
            _buildSearchAndFilter(accent, cardColor, textSecondary),
            if (_funds.isNotEmpty || _isLoading)
              _buildTabBar(accent, textPrimary),
            if (_funds.isNotEmpty || _isLoading)
              _buildStatsTabView(textPrimary, textSecondary, accent, positiveColor, negativeColor),
            Expanded(
              child: _buildFundList(textSecondary, negativeColor, accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: accent, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yatırım Fonları',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                if (_totalCount > 0 || _funds.isNotEmpty)
                  Text(
                    _isLoading && _funds.isEmpty
                        ? 'Yükleniyor...'
                        : '${_funds.length} / $_totalCount fon bulundu',
                    style: TextStyle(
                      fontSize: 12,
                      color: textPrimary.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FundMarketOverviewScreen(),
                ),
              );
            },
            icon: Icon(Icons.show_chart_rounded, color: accent, size: 28),
            tooltip: 'Piyasa Özeti',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(
      Color accent, Color cardColor, Color textSecondary) {
    final hasActiveFilters = _currentFilters.entries
        .any((e) => e.value != null && e.value.toString().isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SearchField(
              controller: _searchController,
              hintText: 'Fon adı veya kodu ile ara...',
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Filtrele ve Sırala',
            child: InkWell(
              onTap: _showFilterSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasActiveFilters
                        ? accent
                        : Colors.grey.withOpacity(0.3),
                    width: hasActiveFilters ? 1.5 : 1.0,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      color: hasActiveFilters
                          ? accent
                          : textSecondary.withOpacity(0.8),
                      size: 24,
                    ),
                    if (hasActiveFilters)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  width: 1)),
                          constraints:
                              const BoxConstraints(minWidth: 8, minHeight: 8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color accent, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        labelColor: accent,
        unselectedLabelColor: textPrimary.withOpacity(0.6),
        indicatorColor: accent,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Genel İstatistikler'),
          Tab(text: 'Dönemsel Getiriler'),
        ],
      ),
    );
  }

  Widget _buildStatsTabView(Color textPrimary, Color textSecondary, Color accent, Color positiveColor, Color negativeColor) {
    return SizedBox(
      height: 120,
      child: TabBarView(
        controller: _tabController,
        children: [
          // İlk Tab: Genel İstatistikler
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Yüklendi',
                    _funds.length.toString(),
                    Icons.file_download_done_outlined,
                    textPrimary,
                    textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Toplam (Filtre)',
                    _totalCount.toString(),
                    Icons.inventory_2_outlined,
                    textPrimary,
                    textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Ort. Günlük',
                    _funds.isNotEmpty ? _formatPercent(_calculateAverageReturn()) : "-",
                    Icons.trending_up_rounded,
                    textPrimary,
                    textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Kategori',
                    _funds.isNotEmpty ? _getUniqueCategories().toString() : "-",
                    Icons.category_outlined,
                    textPrimary,
                    textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // İkinci Tab: Dönemsel Getiriler
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildReturnCard(
                    'Haftalık Ort.',
                    _calculateAverageWeeklyReturn(),
                    Icons.date_range_outlined,
                    textPrimary,
                    textSecondary,
                    positiveColor,
                    negativeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildReturnCard(
                    'Aylık Ort.',
                    _calculateAverageMonthlyReturn(),
                    Icons.calendar_month_outlined,
                    textPrimary,
                    textSecondary,
                    positiveColor,
                    negativeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildReturnCard(
                    '6 Aylık Ort.',
                    _calculateAverageSixMonthReturn(),
                    Icons.calendar_today_outlined,
                    textPrimary,
                    textSecondary,
                    positiveColor,
                    negativeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildReturnCard(
                    'Yıllık Ort.',
                    _calculateAverageYearlyReturn(),
                    Icons.calendar_view_month_outlined,
                    textPrimary,
                    textSecondary,
                    positiveColor,
                    negativeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color textPrimary, Color textSecondary) {
    return FuturisticCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textSecondary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReturnCard(
      String title, double value, IconData icon,
      Color textPrimary, Color textSecondary, Color positiveColor, Color negativeColor) {
    final isPositive = value >= 0;
    final returnColor = isPositive ? positiveColor : negativeColor;
    final displayValue = _formatPercent(value);
    
    return FuturisticCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textSecondary, size: 20),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: returnColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFundList(
      Color textSecondary, Color negativeColor, Color accentColor) {
    if (_funds.isEmpty && _isLoading) {
      return const FundLoadingShimmer(itemCount: 8);
    }

    if (_error.isNotEmpty && _funds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: negativeColor),
              const SizedBox(height: 16),
              Text(
                'Fonlar Yüklenemedi',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textSecondary.withOpacity(0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error,
                style: TextStyle(
                    color: textSecondary.withOpacity(0.6), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar Dene'),
                onPressed: () => _loadFunds(refresh: true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12)),
              ),
            ],
          ),
        ),
      );
    }

    if (_funds.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 64, color: textSecondary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isNotEmpty || _currentFilters.isNotEmpty
                    ? 'Filtrelerinize uygun fon bulunamadı.'
                    : 'Gösterilecek fon bulunmuyor.',
                style: TextStyle(
                    color: textSecondary.withOpacity(0.8), fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Arama veya filtre kriterlerinizi değiştirmeyi deneyin.',
                style: TextStyle(
                    color: textSecondary.withOpacity(0.6), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFunds(refresh: true),
      color: accentColor,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _funds.length + (_hasMore ? 1 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          if (index >= _funds.length) {
            return _isLoading
                ? Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }

          final fund = _funds[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: FundCard(
              fund: fund.toJson(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FundDetailScreen(fund: fund.toJson()),
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
    double totalReturn = 0.0;
    int validCount = 0;
    for (final fund in _funds) {
      final returnValue = fund.dailyReturnValue;
      if (!returnValue.isNaN) {
        totalReturn += returnValue;
        validCount++;
      }
    }
    return validCount > 0 ? totalReturn / validCount : 0.0;
  }

  double _calculateAverageWeeklyReturn() {
    if (_funds.isEmpty) return 0.0;
    double totalReturn = 0.0;
    int validCount = 0;
    for (final fund in _funds) {
      final returnValue = fund.weeklyReturnValue;
      if (!returnValue.isNaN) {
        totalReturn += returnValue;
        validCount++;
      }
    }
    return validCount > 0 ? totalReturn / validCount : 0.0;
  }

  double _calculateAverageMonthlyReturn() {
    if (_funds.isEmpty) return 0.0;
    double totalReturn = 0.0;
    int validCount = 0;
    for (final fund in _funds) {
      final returnValue = fund.monthlyReturnValue;
      if (!returnValue.isNaN) {
        totalReturn += returnValue;
        validCount++;
      }
    }
    return validCount > 0 ? totalReturn / validCount : 0.0;
  }

  double _calculateAverageSixMonthReturn() {
    if (_funds.isEmpty) return 0.0;
    double totalReturn = 0.0;
    int validCount = 0;
    for (final fund in _funds) {
      final returnValue = fund.sixMonthReturnValue;
      if (!returnValue.isNaN) {
        totalReturn += returnValue;
        validCount++;
      }
    }
    return validCount > 0 ? totalReturn / validCount : 0.0;
  }

  double _calculateAverageYearlyReturn() {
    if (_funds.isEmpty) return 0.0;
    double totalReturn = 0.0;
    int validCount = 0;
    for (final fund in _funds) {
      final returnValue = fund.yearlyReturnValue;
      if (!returnValue.isNaN) {
        totalReturn += returnValue;
        validCount++;
      }
    }
    return validCount > 0 ? totalReturn / validCount : 0.0;
  }

  String _formatPercent(double value) {
    String prefix = value >= 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(2)}%';
  }

  int _getUniqueCategories() {
    if (_funds.isEmpty) return 0;
    final categories = _funds.map((fund) => fund.category).toSet();
    categories.removeWhere((category) => category.isEmpty);
    return categories.length;
  }
}
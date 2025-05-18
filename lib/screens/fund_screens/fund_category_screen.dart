// lib/screens/fund_screens/fund_category_screen.dart - Fixed with correct statistics and sorting
import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/fund_api_service.dart';
import '../../models/fund.dart';
import '../../widgets/fund_widgets/fund_card.dart';
import '../../widgets/fund_widgets/fund_loading_shimmer.dart';
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

  // Current displayed funds (with pagination)
  List<Fund> _funds = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  int _totalCount = 0;
  String _error = '';
  String _sortBy = 'kayit_tarihi_desc';

  // Category statistics (for ALL funds in category)
  Map<String, dynamic> _categoryStats = {};
  bool _isLoadingStats = false;

  Timer? _debounceTimer;
  static const int _fundsPerPage = 25;

  final List<Map<String, dynamic>> _sortOptions = [
    {
      'key': 'daily_return_desc',
      'label': 'Günlük Getiri ↓',
      'icon': Icons.trending_up
    },
    {
      'key': 'daily_return_asc',
      'label': 'Günlük Getiri ↑',
      'icon': Icons.trending_down
    },
    {
      'key': 'total_value_desc',
      'label': 'Toplam Değer ↓',
      'icon': Icons.attach_money
    },
    {'key': 'total_value_asc', 'label': 'Toplam Değer ↑', 'icon': Icons.money},
    {
      'key': 'investor_count_desc',
      'label': 'Yatırımcı Sayısı ↓',
      'icon': Icons.people
    },
    {
      'key': 'investor_count_asc',
      'label': 'Yatırımcı Sayısı ↑',
      'icon': Icons.person
    },
    {
      'key': 'kayit_tarihi_desc',
      'label': 'Kayıt Tarihi ↓',
      'icon': Icons.calendar_today
    },
    {
      'key': 'kayit_tarihi_asc',
      'label': 'Kayıt Tarihi ↑',
      'icon': Icons.calendar_today_outlined
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadFunds(refresh: true);
    _loadCategoryStats();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadFunds(refresh: true);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      if (!_isLoading && _hasMore) {
        _loadFunds();
      }
    }
  }

  Future<void> _loadCategoryStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      // Load ALL funds in category to calculate correct statistics
      final response =
          await FundApiService.getCategoryStatistics(widget.category);

      if (mounted) {
        setState(() {
          _categoryStats = response;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

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
      'sort_by': _sortBy,
      if (_searchController.text.isNotEmpty) 'search': _searchController.text,
    };

    final response = await FundApiService.getFundsByCategoryWithPagination(
        widget.category, params);

    final List<Fund> newFunds = response['funds'] as List<Fund>;
    final int total = response['total'] as int;

    // Fonları performans metrikleriyle zenginleştir
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
        _error = "Bir hata oluştu: ${e.toString()}";
        _isLoading = false;
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


  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category,
              style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            if (_totalCount > 0 || _funds.isNotEmpty)
              Text(
                _isLoading && _funds.isEmpty
                    ? 'Yükleniyor...'
                    : '${_funds.length} / $_totalCount fon görüntüleniyor',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: accentColor),
            onSelected: (value) {
              if (_sortBy != value) {
                setState(() {
                  _sortBy = value;
                });
                _loadFunds(refresh: true);
              }
            },
            itemBuilder: (context) => _sortOptions.map((option) {
              final isSelected = option['key'] == _sortBy;
              return PopupMenuItem<String>(
                value: option['key'] as String,
                child: Row(
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: isSelected ? accentColor : textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      option['label'] as String,
                      style: TextStyle(
                        color: isSelected ? accentColor : textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
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
              hintText: 'Kategori içinde ara...',
            ),
          ),

          // Category Statistics - Shows stats for ALL funds in category
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
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            4,
            (index) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ShimmerLoading(
                  width: double.infinity,
                  height: 60,
                  borderRadius: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalFunds = _categoryStats['total_funds'] ?? 0;
    final totalValue = _categoryStats['total_market_value'] ?? 0.0;
    final averageReturn = _categoryStats['average_return'] ?? 0.0;
    final totalInvestors = _categoryStats['total_investors'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildStatCard(
              'Toplam Fon',
              totalFunds.toString(),
              textPrimary,
              textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Toplam Değer',
              _formatCurrency(totalValue),
              textPrimary,
              textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Ort. Getiri',
              '${averageReturn >= 0 ? '+' : ''}${averageReturn.toStringAsFixed(2)}%',
              textPrimary,
              textSecondary,
            ),
          ),
          const SizedBox(width: 8),
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

  Widget _buildStatCard(
      String title, String value, Color textPrimary, Color textSecondary) {
    return FuturisticCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFundList() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    if (_funds.isEmpty && _isLoading) {
      return const FundLoadingShimmer(itemCount: 8);
    }

    if (_error.isNotEmpty && _funds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: themeExtension?.negativeColor ?? AppTheme.negativeColor,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _error,
                style: TextStyle(
                  color:
                      themeExtension?.textSecondary ?? AppTheme.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadFunds(refresh: true),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      themeExtension?.accentColor ?? AppTheme.accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_funds.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                    ? 'Aranan kriterlere uygun fon bulunamadı.'
                    : 'Bu kategoride henüz fon bulunmuyor.',
                style: TextStyle(
                  color:
                      themeExtension?.textSecondary ?? AppTheme.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFunds(refresh: true),
      color: themeExtension?.accentColor ?? AppTheme.accentColor,
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeExtension?.accentColor ?? AppTheme.accentColor,
                        ),
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

  String _formatCurrency(double value) {
    if (value.abs() >= 1e12) {
      return '${(value / 1e12).toStringAsFixed(1)}T ₺';
    } else if (value.abs() >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}B ₺';
    } else if (value.abs() >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M ₺';
    } else if (value.abs() >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K ₺';
    } else {
      return '${value.toStringAsFixed(0)} ₺';
    }
  }

  String _formatNumber(int value) {
    if (value.abs() >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      return value.toString();
    }
  }
}

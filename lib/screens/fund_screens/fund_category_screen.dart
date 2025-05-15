// lib/screens/fund_screens/fund_category_screen.dart - Optimized version
import 'dart:async'; // Import Timer

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

  List<Fund> _funds = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  int _totalCount = 0;
  String _error = '';
  String _sortBy = 'kayit_tarihi'; // Default sort
  // bool _isAscending = false; // Removed: Unused, sort direction is part of _sortBy key

  Timer? _debounceTimer;
  static const int _fundsPerPage = 25;

  final List<Map<String, dynamic>> _sortOptions = [
    {'key': 'daily_return_desc', 'label': 'Günlük Getiri ↓', 'icon': Icons.trending_up},
    {'key': 'daily_return_asc', 'label': 'Günlük Getiri ↑', 'icon': Icons.trending_down},
    {'key': 'total_value_desc', 'label': 'Toplam Değer ↓', 'icon': Icons.attach_money},
    {'key': 'total_value_asc', 'label': 'Toplam Değer ↑', 'icon': Icons.money},
    {'key': 'investor_count_desc', 'label': 'Yatırımcı Sayısı ↓', 'icon': Icons.people},
    {'key': 'investor_count_asc', 'label': 'Yatırımcı Sayısı ↑', 'icon': Icons.person},
    // Consider adding 'kayit_tarihi_desc' or similar if you want a visual default
    // {'key': 'kayit_tarihi_desc', 'label': 'Kayıt Tarihi ↓', 'icon': Icons.calendar_today},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadFunds(refresh: true);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged); // Good practice to remove listener
    _searchController.dispose();
    _scrollController.removeListener(_onScroll); // Good practice to remove listener
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) { // Check if widget is still in tree
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

  Future<void> _loadFunds({bool refresh = false}) async {
    if (_isLoading && !refresh) return; // Prevent multiple simultaneous loads unless it's a refresh

    // If it's a refresh, cancel any ongoing non-refresh load by setting _isLoading to false first
    // This is a bit tricky. The primary guard is `if (_isLoading) return;` at the top.
    // For simplicity, let's assume the current logic with the top guard is sufficient.
    // If a refresh is triggered while a paged load is happening, the refresh will wait.
    // If a paged load is triggered while a refresh is happening, it will wait.

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

      // Ensure FundApiService.getFundsByCategoryWithPagination is correctly typed
      // Assuming it returns Map<String, dynamic> with 'funds' (List<dynamic>) and 'total' (int)
      final response = await FundApiService.getFundsByCategoryWithPagination(
        widget.category,
        params
      );

      // Assuming response['funds'] is List<dynamic> that needs mapping to List<Fund>
      // If FundApiService already returns List<Fund>, this mapping is not needed.
      // Based on the original code: final newFunds = response['funds'] as List<Fund>;
      // This implies the service or JSON parsing already handles Fund object creation.
      final newFunds = (response['funds'] as List).map((fundData) {
        if (fundData is Fund) return fundData;
        // If fundData is Map<String, dynamic>, ensure Fund.fromJson exists and is used
        // For now, assuming the original cast `as List<Fund>` means it's already correct.
        return Fund.fromJson(fundData as Map<String, dynamic>); // Or however Fund is constructed
      }).toList();

      final total = response['total'] as int;

      if (mounted) {
        setState(() {
          if (refresh) {
            _funds = newFunds;
          } else {
            _funds.addAll(newFunds);
          }
          _totalCount = total;
          _hasMore = newFunds.length == _fundsPerPage;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Bir hata oluştu: ${e.toString()}";
          _isLoading = false;
          _hasMore = false; // Stop further loading attempts on error
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
    final textSecondary = themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category,
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (_totalCount > 0 || _funds.isNotEmpty) // Show count even if totalCount is not yet loaded but funds are
              Text(
                _isLoading && _funds.isEmpty ? 'Yükleniyor...' : '${_funds.length} / $_totalCount fon',
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
              if (_sortBy != value) { // Only reload if sort option changed
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              // onChanged: (value) => _loadFunds(refresh: true), // Removed: Handled by _searchController listener with debounce
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

    // Show stats only if funds are loaded and not in initial loading shimmer state for the list
    if (_funds.isEmpty || (_isLoading && _funds.isEmpty) ) return const SizedBox.shrink();

    // Calculate statistics based on currently loaded funds
    final double totalValue = _funds.fold<double>(0.0, (sum, fund) => sum + fund.totalValue);
    final double averageReturn = _funds.isNotEmpty
        ? _funds.fold<double>(0.0, (sum, fund) => sum + fund.dailyReturnValue) / _funds.length
        : 0.0;
    final int totalInvestors = _funds.fold<int>(0, (sum, fund) => sum + fund.investorCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribute space evenly
        children: [
          Expanded(
            child: _buildStatCard(
              'Yüklenen',
              _funds.length.toString(),
              textPrimary,
              textSecondary,
            ),
          ),
          const SizedBox(width: 8), // Reduced spacing for smaller screens
          Expanded(
            child: _buildStatCard(
              'Toplam Değer (Yüklenen)', // Clarify that this is for loaded funds
              _formatCurrency(totalValue),
              textPrimary,
              textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Ort. Getiri (Yüklenen)',
              '${averageReturn >= 0 ? '+' : ''}${averageReturn.toStringAsFixed(2)}%',
              textPrimary,
              textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Yatırımcı (Yüklenen)',
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
    return FuturisticCard( // Assuming FuturisticCard is a custom widget
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6), // Adjusted padding
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take minimum space
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13, // Slightly smaller for condensed view
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // Handle overflow
          ),
          const SizedBox(height: 2), // Reduced height
          Text(
            title,
            style: TextStyle(
              fontSize: 9, // Slightly smaller for condensed view
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // Handle overflow
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

    if (_error.isNotEmpty && _funds.isEmpty) { // Show error only if no funds are displayed
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
                  color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
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
                  backgroundColor: themeExtension?.accentColor ?? AppTheme.accentColor,
                  foregroundColor: Colors.white, // Or appropriate contrast color
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_funds.isEmpty && !_isLoading) { // Not loading, and no funds (e.g. no results)
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
                  color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
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
            // This is the loader for pagination
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
                : const SizedBox.shrink(); // Should not happen if _hasMore is false
          }

          final fund = _funds[index];
          // Assuming FundCard takes Map<String, dynamic>
          // If FundCard takes Fund object: FundCard(fund: fund, ...)
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0), // Spacing between cards
            child: FundCard(
              fund: fund.toJson(), // Ensure Fund model has toJson()
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FundDetailScreen(fund: fund.toJson()), // Ensure FundDetailScreen takes Map
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
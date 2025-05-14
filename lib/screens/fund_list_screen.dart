// lib/screens/fund_list_screen.dart
import 'package:flutter/material.dart';
import '../models/fund.dart';
import '../services/fund_api_service.dart';
import '../widgets/fund_card.dart';
import '../widgets/fund_filter_sheet.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import 'fund_detail_screen.dart';

class FundListScreen extends StatefulWidget {
  const FundListScreen({Key? key}) : super(key: key);

  @override
  State<FundListScreen> createState() => _FundListScreenState();
}

class _FundListScreenState extends State<FundListScreen> {
  late AppLogger _logger;
  late ScrollController _scrollController;
  late TextEditingController _searchController;

  List<Fund> _allFunds = [];
  List<Fund> _filteredFunds = [];
  Set<String> _availableCategories = {};

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSearching = false;

  FundFilter _currentFilter = FundFilter();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _logger = AppLogger('FundListScreen');
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _loadFunds();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterFunds();
    });
  }

  Future<void> _loadFunds() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final funds = await FundApiService.getAllFunds();
      final categories = await FundApiService.getFundCategories();

      if (mounted) {
        setState(() {
          _allFunds = funds;
          _availableCategories = categories;
          _filterFunds();
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error loading funds', e);
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterFunds() {
    setState(() {
      _isSearching = _searchQuery.isNotEmpty;

      _filteredFunds = _allFunds.where((fund) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          if (!fund.kod.toLowerCase().contains(searchLower) &&
              !fund.fonAdi.toLowerCase().contains(searchLower)) {
            return false;
          }
        }

        // Category filter
        if (_currentFilter.category != null &&
            fund.kategori != _currentFilter.category) {
          return false;
        }

        // TEFAS filter
        if (_currentFilter.onlyTefas != null) {
          if (_currentFilter.onlyTefas! && !fund.isTefasActive) {
            return false;
          }
          if (!_currentFilter.onlyTefas! && fund.isTefasActive) {
            return false;
          }
        }

        // Return filter
        if (_currentFilter.minReturn != null ||
            _currentFilter.maxReturn != null) {
          final returnValue = fund.gunlukGetiriDouble;
          if (_currentFilter.minReturn != null &&
              returnValue < _currentFilter.minReturn!) {
            return false;
          }
          if (_currentFilter.maxReturn != null &&
              returnValue > _currentFilter.maxReturn!) {
            return false;
          }
        }

        // Risk filter
        if (_currentFilter.minRiskLevel != null ||
            _currentFilter.maxRiskLevel != null) {
          final riskLevel = fund.riskLevel;
          if (_currentFilter.minRiskLevel != null &&
              riskLevel < _currentFilter.minRiskLevel!) {
            return false;
          }
          if (_currentFilter.maxRiskLevel != null &&
              riskLevel > _currentFilter.maxRiskLevel!) {
            return false;
          }
        }

        return true;
      }).toList();

      // Sorting
      if (_currentFilter.sortBy != null) {
        _filteredFunds.sort((a, b) {
          int comparison = 0;
          switch (_currentFilter.sortBy) {
            case 'name':
              comparison = a.fonAdi.compareTo(b.fonAdi);
              break;
            case 'return':
              comparison = a.gunlukGetiriDouble.compareTo(b.gunlukGetiriDouble);
              break;
            case 'risk':
              comparison = a.riskLevel.compareTo(b.riskLevel);
              break;
            case 'value':
              comparison = a.fonToplamDeger.compareTo(b.fonToplamDeger);
              break;
            default:
              comparison = a.kod.compareTo(b.kod);
          }
          return _currentFilter.sortDescending ? -comparison : comparison;
        });
      }
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FundFilterSheet(
          currentFilter: _currentFilter,
          availableCategories: _availableCategories,
          onFilterChanged: (filter) {
            setState(() {
              _currentFilter = filter;
              _filterFunds();
            });
          },
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = FundFilter();
      _searchController.clear();
      _filterFunds();
    });
  }

  void _navigateToFundDetail(Fund fund) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FundDetailScreen(fundCode: fund.kod),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();

    final bgGradientColors = themeExtension?.gradientBackgroundColors ??
        [
          theme.scaffoldBackgroundColor,
          theme.scaffoldBackgroundColor,
        ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              _buildFilterSummary(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingContent()
                    : _hasError
                        ? _buildErrorContent()
                        : _filteredFunds.isEmpty
                            ? _buildEmptyContent()
                            : _buildFundsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Yatırım Fonları',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: _showFilterSheet,
            icon: Icon(Icons.filter_list, color: accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SearchField(
        controller: _searchController,
        hintText: 'Fon ara...',
        onChanged: (value) => _onSearchChanged(),
        onClear: () => _searchController.clear(),
      ),
    );
  }

  Widget _buildFilterSummary() {
    return FilterSummary(
      filter: _currentFilter,
      onClear: _clearFilters,
    );
  }

  Widget _buildLoadingContent() {
    final theme = Theme.of(context);
    final accentColor = theme.extension<AppThemeExtension>()?.accentColor ??
        AppTheme.accentColor;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: 10, // Shimmer için sabit sayı
            itemBuilder: (context, index) => const FundCardShimmer(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent() {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Hata Oluştu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFunds,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent() {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Fon Bulunamadı',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Arama kriterlerinizi değiştirmeyi deneyin.',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFundsList() {
    return RefreshIndicator(
      onRefresh: _loadFunds,
      color: Theme.of(context).extension<AppThemeExtension>()?.accentColor ??
          AppTheme.accentColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredFunds.length,
        itemBuilder: (context, index) {
          final fund = _filteredFunds[index];
          return FundCard(
            fund: fund,
            onTap: () => _navigateToFundDetail(fund),
          );
        },
      ),
    );
  }
}

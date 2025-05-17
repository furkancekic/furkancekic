import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/fund_api_service.dart';

class FundMarketOverviewScreen extends StatefulWidget {
  const FundMarketOverviewScreen({Key? key}) : super(key: key);

  @override
  State<FundMarketOverviewScreen> createState() =>
      _FundMarketOverviewScreenState();
}

class _FundMarketOverviewScreenState extends State<FundMarketOverviewScreen> {
  Map<String, dynamic>? _marketData;
  Map<String, dynamic>? _categoryPerformanceDetails;
  bool _isLoading = true;
  String _error = '';

  // For category filter
  Set<String> _selectedCategories = {};
  List<String> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    // Paralel olarak yükleme
    await Future.wait([
      _loadMarketOverview(),
      _loadCategoryPerformanceDetails(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMarketOverview() async {
    // _loadData içinde isLoading ayarlandığı için burada tekrar ayarlamaya gerek yok
    // setState(() {
    //   _isLoading = true; // Bu satır _loadData'ya taşındı
    //   _error = '';
    // });

    try {
      final marketData = await FundApiService.getMarketOverview();
      print('Market data received: $marketData'); // Debug log

      if (mounted) {
        // Widget ağaçta mı diye kontrol et
        setState(() {
          _marketData = marketData;

          // Initialize category selection and clean duplicates
          if (_marketData != null &&
              _marketData!['category_distribution'] != null) {
            final categories =
                _marketData!['category_distribution'] as Map<String, dynamic>;

            final cleanedCategories = <String, int>{};
            for (final entry in categories.entries) {
              final cleanKey = _normalizeCategoryName(entry.key);
              cleanedCategories[cleanKey] =
                  (cleanedCategories[cleanKey] ?? 0) + (entry.value as int);
            }

            _marketData!['category_distribution'] = cleanedCategories;
            _allCategories = cleanedCategories.keys.toList();
            _selectedCategories = Set.from(_allCategories);
          }
          // _isLoading = false; // Bu satır _loadData'ya taşındı
        });
      }
    } catch (e) {
      print('Error loading market data: $e'); // Debug log
      if (mounted) {
        setState(() {
          _error =
              'Pazar verileri yüklenirken bir hata oluştu: ${e.toString()}';
          // _isLoading = false; // Bu satır _loadData'ya taşındı
        });
      }
    }
  }

  Future<void> _loadCategoryPerformanceDetails() async {
    try {
      final categoryDetails =
          await FundApiService.getCategoryPerformanceDetails();
      if (mounted) {
        setState(() {
          _categoryPerformanceDetails = categoryDetails;
        });
      }
    } catch (e) {
      print('Error loading category performance details: $e');
      if (mounted) {
        setState(() {
          // _error state'ini market overview hatasıyla birleştirebilir veya ayrı bir hata state'i tutabilirsiniz.
          // Şimdilik sadece market overview hatasına odaklanıyoruz.
          if (_error.isEmpty) {
            // Eğer başka bir hata yoksa bunu ata
            _error =
                'Kategori performans detayları yüklenirken bir hata oluştu: ${e.toString()}';
          }
        });
      }
    }
  }

  String _normalizeCategoryName(String category) {
    final normalized = category.toLowerCase().trim();
    final categoryMap = {
      'altın fonu': 'Altın Fonu',
      'altın': 'Altın Fonu',
      'hisse senedi fonu': 'Hisse Senedi Fonu',
      'hisse': 'Hisse Senedi Fonu',
      'serbest fon': 'Serbest Fon',
      'serbest': 'Serbest Fon',
      'para piyasası fonu': 'Para Piyasası Fonu',
      'para piyasası': 'Para Piyasası Fonu',
      'karma fon': 'Karma Fon',
      'karma': 'Karma Fon',
      'tahvil fonu': 'Tahvil Fonu',
      'tahvil': 'Tahvil Fonu',
      'endeks fonu': 'Endeks Fonu',
      'endeks': 'Endeks Fonu',
      'bes emeklilik fonu': 'BES Emeklilik Fonu',
      'bes': 'BES Emeklilik Fonu',
      'yabancı menkul kıymet fonu': 'Yabancı Menkul Kıymet Fonu',
      'yabancı': 'Yabancı Menkul Kıymet Fonu',
    };
    return categoryMap[normalized] ??
        category
            .split(' ')
            .map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : '')
            .join(' ');
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
        title: Text(
          'Pazar Genel Bakış',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: accentColor),
                  const SizedBox(height: 16),
                  Text('Pazar verileri yükleniyor...',
                      style: TextStyle(color: textSecondary)),
                ],
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    // Hata mesajı için padding
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, // Daha genel bir hata ikonu
                            color: themeExtension?.negativeColor ??
                                AppTheme.negativeColor,
                            size: 64),
                        const SizedBox(height: 16),
                        Text('Bir sorun oluştu:',
                            style: TextStyle(
                                color: textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_error,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textSecondary)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed:
                              _loadData, // _loadMarketOverview yerine _loadData
                          style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 12),
                              textStyle: const TextStyle(fontSize: 16)),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh:
                      _loadData, // _loadMarketOverview ve _loadCategoryPerformanceDetails yerine _loadData
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMarketStats(),
                        const SizedBox(height: 24),
                        _buildCategoryDistribution(),
                        const SizedBox(height: 24),
                        _buildPerformanceAnalysis(),
                        const SizedBox(height: 24),
                        _buildRiskDistribution(),
                        const SizedBox(height: 24),
                        _buildTefasAndMarketShare(),
                        const SizedBox(height: 24),
                        _buildCategoryPerformanceRanking(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMarketStats() {
    if (_marketData == null) return const SizedBox.shrink();

    final totalFunds = (_marketData!['total_funds'] ?? 0) as int;
    final totalMarketValue =
        (_marketData!['total_market_value'] ?? 0.0) as double;
    final totalInvestors = (_marketData!['total_investors'] ?? 0) as int;
    final averageReturn = (_marketData!['average_return'] ?? 0.0) as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pazar İstatistikleri',
          style: TextStyle(
            color:
                Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
                    AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildEnhancedStatCard(
              'Toplam Fon Sayısı',
              totalFunds.toString(),
              Icons.account_balance_outlined,
              Theme.of(context).extension<AppThemeExtension>()?.accentColor ??
                  AppTheme.accentColor,
              subtitle: 'Aktif İşlem Gören',
            ),
            _buildEnhancedStatCard(
              'Toplam Pazar Değeri',
              _formatCurrency(totalMarketValue),
              Icons.trending_up_rounded,
              Theme.of(context).extension<AppThemeExtension>()?.positiveColor ??
                  AppTheme.positiveColor,
              subtitle: 'Türk Lirası',
            ),
            _buildEnhancedStatCard(
              'Toplam Yatırımcı',
              _formatNumber(totalInvestors),
              Icons.people_alt_outlined,
              Colors.blue, // Bu renk AppTheme'den gelmeli veya sabit kalabilir
              subtitle: 'Bireysel & Kurumsal',
            ),
            _buildEnhancedStatCard(
              'Ortalama Getiri',
              _formatReturn(averageReturn),
              averageReturn >= 0
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              averageReturn >= 0
                  ? (Theme.of(context)
                          .extension<AppThemeExtension>()
                          ?.positiveColor ??
                      AppTheme.positiveColor)
                  : (Theme.of(context)
                          .extension<AppThemeExtension>()
                          ?.negativeColor ??
                      AppTheme.negativeColor),
              subtitle: 'Günlük Ortalama',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedStatCard(
      String title, String value, IconData icon, Color color,
      {String? subtitle}) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(Icons.more_vert, color: textSecondary.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    if (_marketData == null || _marketData!['category_distribution'] == null) {
      return _buildEmptySection(
          'Kategori Dağılımı', 'Kategori verileri mevcut değil');
    }

    final categories =
        _marketData!['category_distribution'] as Map<String, dynamic>;

    if (categories.isEmpty) {
      return _buildEmptySection('Kategori Dağılımı', 'Kategori verileri boş');
    }

    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kategori Dağılımı',
                style: TextStyle(
                  color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.pie_chart, // DÜZELTİLDİ
                color: themeExtension?.accentColor ?? AppTheme.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCategoryFilterChips(categories),
          const SizedBox(height: 24),
          SizedBox(
            height: 350,
            child: _buildModernBarChart(categories),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBarChart(Map<String, dynamic> categories) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final filteredCategories = _getFilteredCategories(categories);

    if (filteredCategories.isEmpty) {
      return Center(
        child: Text(
          'Seçilen kategori yok',
          style: TextStyle(
              color: themeExtension?.textSecondary ?? AppTheme.textSecondary),
        ),
      );
    }

    final maxY = _getMaxYForSelectedCategories(categories);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: maxY * 1.2,
        backgroundColor: Colors.transparent,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: (themeExtension?.cardColor ?? AppTheme.cardColor)
                .withOpacity(0.95),
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.all(12),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final currentFilteredCategories = _getFilteredCategories(
                  categories); // Her zaman güncel listeyi al
              if (groupIndex >= currentFilteredCategories.length) return null;
              final category =
                  currentFilteredCategories.keys.elementAt(groupIndex);
              return BarTooltipItem(
                '$category\n${rod.toY.toInt()} fon',
                TextStyle(
                  color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final currentFilteredCategories = _getFilteredCategories(
                    categories); // Her zaman güncel listeyi al
                final index = value.toInt();
                if (index >= 0 && index < currentFilteredCategories.length) {
                  final categoryName =
                      currentFilteredCategories.keys.elementAt(index);
                  final shortName = _getShortCategoryName(categoryName);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 16,
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        shortName,
                        style: TextStyle(
                          color: themeExtension?.textSecondary ??
                              AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxY / 5).ceilToDouble() == 0
                  ? 1
                  : (maxY / 5).ceilToDouble(), // Dinamik interval
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color:
                        themeExtension?.textSecondary ?? AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _createModernBarGroups(categories),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 5).ceilToDouble() == 0
              ? 1
              : (maxY / 5).ceilToDouble(), // Dinamik interval
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: themeExtension?.textSecondary?.withOpacity(0.1) ??
                  Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
      ),
    );
  }

  List<BarChartGroupData> _createModernBarGroups(
      Map<String, dynamic> categories) {
    final filteredCategories = _getFilteredCategories(categories);

    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFF10B981),
      const Color(0xFF06B6D4),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF84CC16),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];

    return filteredCategories.entries
        .toList()
        .asMap()
        .entries
        .map((entryIndexed) {
      // asMap() için toList()
      final index = entryIndexed.key;
      final entry = entryIndexed.value;
      final color = colors[index % colors.length];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (entry.value as num).toDouble(),
            color: color,
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildCategoryFilterChips(Map<String, dynamic> categories) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return SizedBox(
      // Container yerine SizedBox
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  _selectedCategories.length == _allCategories.length
                      ? 'Tümünü Kaldır'
                      : 'Tümünü Seç',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: true, // Bu her zaman seçili gibi duracak
                backgroundColor: accentColor.withOpacity(
                    0.8), // Arka plan rengini biraz farklı yapabiliriz
                selectedColor: accentColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onSelected: (_) {
                  setState(() {
                    if (_selectedCategories.length == _allCategories.length) {
                      _selectedCategories.clear();
                    } else {
                      _selectedCategories = Set.from(_allCategories);
                    }
                  });
                },
              ),
            ),
            ..._allCategories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    _getShortCategoryName(category),
                    style: TextStyle(
                      color: isSelected ? Colors.white : textPrimary,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: accentColor,
                  backgroundColor: cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  side: BorderSide(
                    color:
                        isSelected ? accentColor : textPrimary.withOpacity(0.2),
                    width: 1,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceAnalysis() {
    if (_marketData == null || _marketData!['performance_metrics'] == null) {
      return _buildEmptySection(
          'Performans Analizi', 'Performans verileri mevcut değil');
    }

    final metrics = _marketData!['performance_metrics'] as Map<String, dynamic>;
    final positiveReturns = (metrics['positive_returns'] ?? 0) as int;
    final negativeReturns = (metrics['negative_returns'] ?? 0) as int;
    final neutralReturns = (metrics['neutral_returns'] ?? 0) as int;
    final bestReturn = (metrics['best_return'] ?? 0.0) as double;
    final worstReturn = (metrics['worst_return'] ?? 0.0) as double;

    final totalReturns = positiveReturns + negativeReturns + neutralReturns;

    if (totalReturns == 0) {
      return _buildEmptySection(
          'Performans Analizi', 'Performans verileri hesaplanamadı');
    }

    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Performans Analizi',
                style: TextStyle(
                  color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.analytics_outlined,
                color: themeExtension?.accentColor ?? AppTheme.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: themeExtension?.positiveColor ??
                              AppTheme.positiveColor,
                          value: positiveReturns.toDouble(),
                          title: totalReturns > 0
                              ? '${(positiveReturns / totalReturns * 100).toStringAsFixed(1)}%'
                              : '0%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          badgeWidget: _buildPieBadge(
                              Icons.trending_up,
                              themeExtension?.positiveColor ??
                                  AppTheme.positiveColor),
                          badgePositionPercentageOffset: 0.98,
                        ),
                        PieChartSectionData(
                          color: themeExtension?.negativeColor ??
                              AppTheme.negativeColor,
                          value: negativeReturns.toDouble(),
                          title: totalReturns > 0
                              ? '${(negativeReturns / totalReturns * 100).toStringAsFixed(1)}%'
                              : '0%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          badgeWidget: _buildPieBadge(
                              Icons.trending_down,
                              themeExtension?.negativeColor ??
                                  AppTheme.negativeColor),
                          badgePositionPercentageOffset: 0.98,
                        ),
                        PieChartSectionData(
                          color: Colors.grey.shade600,
                          value: neutralReturns.toDouble(),
                          title: totalReturns > 0
                              ? '${(neutralReturns / totalReturns * 100).toStringAsFixed(1)}%'
                              : '0%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          badgeWidget: _buildPieBadge(
                              Icons.trending_flat, Colors.grey.shade600),
                          badgePositionPercentageOffset: 0.98,
                        ),
                      ],
                      sectionsSpace: 3,
                      centerSpaceRadius: 35,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    children: [
                      _buildEnhancedPerformanceMetric(
                        'Pozitif Getiri',
                        positiveReturns,
                        Icons.trending_up_rounded,
                        themeExtension?.positiveColor ?? AppTheme.positiveColor,
                      ),
                      const SizedBox(height: 16),
                      _buildEnhancedPerformanceMetric(
                        'Negatif Getiri',
                        negativeReturns,
                        Icons.trending_down_rounded,
                        themeExtension?.negativeColor ?? AppTheme.negativeColor,
                      ),
                      const SizedBox(height: 16),
                      _buildEnhancedPerformanceMetric(
                        'Nötr',
                        neutralReturns,
                        Icons.trending_flat_rounded,
                        Colors.grey.shade600,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (themeExtension?.cardColorLight ??
                                  AppTheme.cardColorLight)
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (themeExtension?.accentColor ??
                                    AppTheme.accentColor)
                                .withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBestWorstMetric(
                                'En İyi',
                                _formatReturn(bestReturn),
                                themeExtension?.positiveColor ??
                                    AppTheme.positiveColor),
                            Container(
                              width: 1,
                              height: 40,
                              color: (themeExtension?.textSecondary ??
                                      AppTheme.textSecondary)
                                  .withOpacity(0.3),
                            ),
                            _buildBestWorstMetric(
                                'En Kötü',
                                _formatReturn(worstReturn),
                                themeExtension?.negativeColor ??
                                    AppTheme.negativeColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  Widget _buildBestWorstMetric(String label, String value, Color valueColor) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: themeExtension?.textSecondary ?? AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedPerformanceMetric(
      String label, int value, IconData icon, Color color) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistribution() {
    if (_marketData == null || _marketData!['risk_distribution'] == null) {
      return _buildEmptySection(
          'Risk Seviyesi Dağılımı', 'Risk verileri mevcut değil');
    }

    final risks = _marketData!['risk_distribution'] as Map<String, dynamic>;

    if (risks.isEmpty) {
      return _buildEmptySection('Risk Seviyesi Dağılımı', 'Risk verileri boş');
    }

    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Risk Seviyesi Dağılımı',
                style: TextStyle(
                  color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.security_outlined,
                color: themeExtension?.accentColor ?? AppTheme.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...risks.entries.map((entry) {
            final total = risks.values
                .fold(0, (sum, val) => sum + ((val as num?)?.toInt() ?? 0));
            final value = (entry.value as num?)?.toInt() ?? 0;
            final percentage = total > 0 ? (value / total * 100) : 0.0;
            Color riskColor = Colors.grey;

            String keyLower = entry.key.toLowerCase();
            if (keyLower.contains('düşük') || keyLower.contains('low')) {
              riskColor =
                  themeExtension?.positiveColor ?? AppTheme.positiveColor;
            } else if (keyLower.contains('orta') ||
                keyLower.contains('medium')) {
              riskColor = themeExtension?.warningColor ?? AppTheme.warningColor;
            } else if (keyLower.contains('yüksek') ||
                keyLower.contains('high')) {
              riskColor =
                  themeExtension?.negativeColor ?? AppTheme.negativeColor;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: riskColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getRiskIcon(entry.key),
                      color: riskColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: themeExtension?.textPrimary ??
                                AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          // Daha modern bir gösterim
                          value: percentage / 100,
                          backgroundColor: riskColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value.toString(),
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: themeExtension?.textSecondary ??
                              AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  IconData _getRiskIcon(String riskLevel) {
    String lowerRisk = riskLevel.toLowerCase();
    if (lowerRisk.contains('düşük') || lowerRisk.contains('low')) {
      return Icons.shield_outlined; // Daha uygun bir ikon
    } else if (lowerRisk.contains('orta') || lowerRisk.contains('medium')) {
      return Icons.warning_amber_rounded;
    } else if (lowerRisk.contains('yüksek') || lowerRisk.contains('high')) {
      return Icons.dangerous_outlined;
    }
    return Icons.help_outline;
  }

  Widget _buildTefasAndMarketShare() {
    if (_marketData == null) return const SizedBox.shrink();

    final tefas =
        _marketData!['tefas_distribution'] as Map<String, dynamic>? ?? {};
    final marketShare =
        _marketData!['market_share_distribution'] as Map<String, dynamic>? ??
            {};

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Kartların yüksekliği farklı olabilir
      children: [
        Expanded(
          child: _buildEnhancedDistributionCard(
            'TEFAS Dağılımı',
            Icons.storefront_outlined, // TEFAS için daha uygun bir ikon
            tefas,
            isTefas: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildEnhancedDistributionCard(
            'Pazar Payı Dağılımı',
            Icons.pie_chart, // DÜZELTİLDİ
            marketShare,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDistributionCard(
    String title,
    IconData icon,
    Map<String, dynamic> data, {
    bool isTefas = false,
  }) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: themeExtension?.accentColor ?? AppTheme.accentColor),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Veri mevcut değil',
                  style: TextStyle(
                    color:
                        themeExtension?.textSecondary ?? AppTheme.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...data.entries.map((entry) {
              Color itemColor;
              IconData itemIcon;

              if (isTefas) {
                bool isTrading =
                    entry.key.toLowerCase().contains('işlem gören') ||
                        entry.key.toLowerCase().contains('tefasta');
                itemColor = isTrading
                    ? (themeExtension?.positiveColor ?? AppTheme.positiveColor)
                    : (themeExtension?.textSecondary ?? AppTheme.textSecondary);
                itemIcon = isTrading
                    ? Icons.check_circle_outline // Outlined versiyon
                    : Icons.highlight_off_outlined; // Outlined versiyon
              } else {
                // Pazar payı için renkleri dinamik yapabiliriz veya sabit bir renk kullanabiliriz
                // Şimdilik accentColor kullanalım
                itemColor = themeExtension?.accentColor ?? AppTheme.accentColor;
                itemIcon = Icons.donut_small_outlined; // Daha uygun bir ikon
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: itemColor.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(itemIcon, color: itemColor, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: themeExtension?.textPrimary ??
                              AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: itemColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.value.toString(),
                        style: TextStyle(
                          color: itemColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformanceRanking() {
    if (_categoryPerformanceDetails == null) {
      return _buildEmptySection('Kategori Performans Sıralaması',
          'Kategori performans verileri mevcut değil');
    }

    final topCategories =
        (_categoryPerformanceDetails!['top_performing_categories']
                as List<dynamic>?) ??
            [];
    final bottomCategories =
        (_categoryPerformanceDetails!['bottom_performing_categories']
                as List<dynamic>?) ??
            [];

    if (topCategories.isEmpty && bottomCategories.isEmpty) {
      return _buildEmptySection('Kategori Performans Sıralaması',
          'Performans sıralaması hesaplanamadı');
    }

    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: themeExtension?.accentColor ?? AppTheme.accentColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Kategori Performans Sıralaması',
                style: TextStyle(
                  color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (topCategories.isNotEmpty) ...[
            _buildRankingSectionHeader(
              'En İyi Performans Gösterenler',
              Icons.trending_up_rounded,
              themeExtension?.positiveColor ?? AppTheme.positiveColor,
            ),
            ...topCategories.take(3).toList().asMap().entries.map((entry) {
              // DÜZELTİLDİ .toList()
              return _buildEnhancedCategoryPerformanceCard(
                  entry.value, true, entry.key);
            }).toList(),
            if (bottomCategories.isNotEmpty) const SizedBox(height: 24),
          ],
          if (bottomCategories.isNotEmpty) ...[
            _buildRankingSectionHeader(
              'En Düşük Performans Gösterenler',
              Icons.trending_down_rounded,
              themeExtension?.negativeColor ?? AppTheme.negativeColor,
            ),
            ...bottomCategories.take(3).toList().asMap().entries.map((entry) {
              // DÜZELTİLDİ .toList()
              return _buildEnhancedCategoryPerformanceCard(
                  entry.value, false, entry.key);
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildRankingSectionHeader(String title, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEnhancedCategoryPerformanceCard(
      dynamic categoryDataDynamic, bool isPositive, int index) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    if (categoryDataDynamic is! List || categoryDataDynamic.length < 2) {
      return const SizedBox.shrink(); // Hatalı veri için boş widget
    }

    final categoryName = categoryDataDynamic[0] as String;
    final performance = categoryDataDynamic[1] as Map<String, dynamic>;

    final averageReturn = (performance['average_return'] ?? 0.0) as double;
    final fundCount = (performance['fund_count'] ?? 0) as int;
    // top_5_funds'ın List<dynamic> olmasını ve içindeki elemanların Map<String, dynamic> olmasını bekliyoruz.
    final top5Funds = (performance['top_5_funds'] as List<dynamic>?) ?? [];

    final primaryColor = isPositive
        ? (themeExtension?.positiveColor ?? AppTheme.positiveColor)
        : (themeExtension?.negativeColor ?? AppTheme.negativeColor);

    final rankColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];
    final rankIconColor = Colors.black87; // Gold, Silver, Bronze ikon rengi

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: primaryColor.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.05), // Daha hafif gölge
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: index < 3
                        ? rankColors[index]
                        : primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (index < 3 ? rankColors[index] : primaryColor)
                            .withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: index < 3
                        ? Icon(
                            index == 0
                                ? Icons.emoji_events
                                : Icons
                                    .military_tech, // military_tech daha uygun olabilir
                            color: index == 0
                                ? rankIconColor.withOpacity(0.8)
                                : rankIconColor
                                    .withOpacity(0.7), // Altın için daha parlak
                            size: 22,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _normalizeCategoryName(
                            categoryName), // Normalleştirilmiş isim kullan
                        style: TextStyle(
                          color: themeExtension?.textPrimary ??
                              AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$fundCount fon',
                        style: TextStyle(
                          color: themeExtension?.textSecondary ??
                              AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatReturn(averageReturn),
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (top5Funds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    (themeExtension?.cardColorLight ?? AppTheme.cardColorLight)
                        .withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (themeExtension?.accentColor ?? AppTheme.accentColor)
                      .withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Öne Çıkan ${top5Funds.length} Fon:',
                    style: TextStyle(
                      color: themeExtension?.textSecondary ??
                          AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...top5Funds.asMap().entries.map((entry) {
                    // Burada entry.value'nun Map<String, dynamic> olduğundan emin olmalıyız.
                    final fundData = entry.value as Map<String, dynamic>;
                    return _buildEnhancedTop5FundItem(fundData, entry.key);
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedTop5FundItem(Map<String, dynamic> fund, int index) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final kod = (fund['kod'] ?? '') as String;
    final fonAdi = (fund['fon_adi'] ?? '') as String;
    final gunlukGetiriStr = (fund['gunluk_getiri'] ?? '0%') as String;

    double returnValue = 0.0;
    try {
      returnValue = double.parse(
          gunlukGetiriStr.replaceAll('%', '').replaceAll(',', '.'));
    } catch (e) {
      // Hata durumunda 0.0 kalır
      print("Error parsing gunluk_getiri '$gunlukGetiriStr': $e");
    }

    final returnColor = returnValue >= 0
        ? (themeExtension?.positiveColor ?? AppTheme.positiveColor)
        : (themeExtension?.negativeColor ?? AppTheme.negativeColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            (themeExtension?.cardColor ?? AppTheme.cardColor).withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (themeExtension?.accentColor ?? AppTheme.accentColor)
              .withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: (themeExtension?.accentColor ?? AppTheme.accentColor)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: themeExtension?.accentColor ?? AppTheme.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            kod,
            style: TextStyle(
              color: themeExtension?.accentColor ?? AppTheme.accentColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fonAdi,
              style: TextStyle(
                color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: returnColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _formatReturn(returnValue), // Formatlanmış değeri kullan
              style: TextStyle(
                color: returnColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getFilteredCategories(Map<String, dynamic> categories) {
    final filtered = <String, dynamic>{};
    for (String category in _selectedCategories) {
      if (categories.containsKey(category)) {
        filtered[category] = categories[category];
      }
    }
    return filtered;
  }

  double _getMaxYForSelectedCategories(Map<String, dynamic> categories) {
    final filtered = _getFilteredCategories(categories);
    if (filtered.isEmpty) return 10.0; // Boşsa minimum bir değer
    double maxVal = filtered.values
        .map((v) => (v as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return maxVal == 0 ? 10.0 : maxVal; // Eğer max 0 ise yine minimum bir değer
  }

  Widget _buildEmptySection(String title, String message) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: themeExtension?.textPrimary ?? AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 48,
                    color: themeExtension?.textSecondary?.withOpacity(0.5) ??
                        AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      color: themeExtension?.textSecondary ??
                          AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getShortCategoryName(String category) {
    final mappings = {
      'Hisse Senedi Fonu': 'Hisse',
      'Serbest Fon': 'Serbest',
      'BES Emeklilik Fonu': 'BES',
      'Para Piyasası Fonu': 'Para P.',
      'Karma Fon': 'Karma',
      'Tahvil Fonu': 'Tahvil',
      'Altın Fonu': 'Altın',
      'Endeks Fonu': 'Endeks',
      'Yabancı Menkul Kıymet Fonu': 'Yabancı',
    };
    return mappings[category] ?? category.split(' ').first;
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

  String _formatReturn(double value) {
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';
  }
}

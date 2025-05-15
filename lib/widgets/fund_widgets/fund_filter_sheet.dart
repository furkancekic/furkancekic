import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class FundFilterSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const FundFilterSheet({
    Key? key,
    required this.currentFilters,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  State<FundFilterSheet> createState() => _FundFilterSheetState();
}

class _FundFilterSheetState extends State<FundFilterSheet> {
  late Map<String, dynamic> _filters;
  final TextEditingController _minReturnController = TextEditingController();
  final TextEditingController _maxReturnController = TextEditingController();

  final List<String> _categories = [
    'Hisse Senedi Fonu',
    'Serbest Fon',
    'BES Emeklilik Fonu',
    'Para Piyasası Fonu',
    'Karma Fon',
    'Tahvil Fonu',
    'Altın Fonu',
    'Endeks Fonu',
  ];

  final List<String> _sortOptions = [
    'Günlük Getiri (Yüksek)',
    'Günlük Getiri (Düşük)',
    'Toplam Değer (Yüksek)',
    'Toplam Değer (Düşük)',
    'Yatırımcı Sayısı (Çok)',
    'Yatırımcı Sayısı (Az)',
    'Pazar Payı (Yüksek)',
    'Pazar Payı (Düşük)',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);

    // Initialize text controllers
    if (_filters['min_return'] != null) {
      _minReturnController.text = _filters['min_return'].toString();
    }
    if (_filters['max_return'] != null) {
      _maxReturnController.text = _filters['max_return'].toString();
    }
  }

  @override
  void dispose() {
    _minReturnController.dispose();
    _maxReturnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final positiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtreler',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Temizle',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Filter
                  _buildSectionTitle('Kategori'),
                  const SizedBox(height: 12),
                  _buildCategoryChips(),

                  const SizedBox(height: 32),

                  // Return Filter
                  _buildSectionTitle('Günlük Getiri Aralığı (%)'),
                  const SizedBox(height: 12),
                  _buildReturnRangeInputs(),

                  const SizedBox(height: 32),

                  // TEFAS Filter
                  _buildSectionTitle('TEFAS Durumu'),
                  const SizedBox(height: 12),
                  _buildTefasFilter(),

                  const SizedBox(height: 32),

                  // Sort Options
                  _buildSectionTitle('Sıralama'),
                  const SizedBox(height: 12),
                  _buildSortOptions(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardColor,
                      foregroundColor: textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: textSecondary.withOpacity(0.3)),
                      ),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Uygula',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final textPrimary =
        Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
            AppTheme.textPrimary;

    return Text(
      title,
      style: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final isSelected = _filters['category'] == category;
        final accentColor =
            Theme.of(context).extension<AppThemeExtension>()?.accentColor ??
                AppTheme.accentColor;
        final cardColor =
            Theme.of(context).extension<AppThemeExtension>()?.cardColor ??
                AppTheme.cardColor;
        final textPrimary =
            Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
                AppTheme.textPrimary;

        return FilterChip(
          label: Text(
            category,
            style: TextStyle(
              color: isSelected ? Colors.white : textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters['category'] = selected ? category : null;
            });
          },
          selectedColor: accentColor,
          backgroundColor: cardColor,
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected ? accentColor : textPrimary.withOpacity(0.3),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReturnRangeInputs() {
    final cardColor =
        Theme.of(context).extension<AppThemeExtension>()?.cardColor ??
            AppTheme.cardColor;
    final textPrimary =
        Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
            AppTheme.textPrimary;
    final textSecondary =
        Theme.of(context).extension<AppThemeExtension>()?.textSecondary ??
            AppTheme.textSecondary;
    final accentColor =
        Theme.of(context).extension<AppThemeExtension>()?.accentColor ??
            AppTheme.accentColor;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minReturnController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              labelText: 'Min %',
              labelStyle: TextStyle(color: textSecondary),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
            ),
            onChanged: (value) {
              try {
                final val = double.parse(value);
                _filters['min_return'] = val;
              } catch (e) {
                _filters['min_return'] = null;
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _maxReturnController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              labelText: 'Max %',
              labelStyle: TextStyle(color: textSecondary),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
            ),
            onChanged: (value) {
              try {
                final val = double.parse(value);
                _filters['max_return'] = val;
              } catch (e) {
                _filters['max_return'] = null;
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTefasFilter() {
    final accentColor =
        Theme.of(context).extension<AppThemeExtension>()?.accentColor ??
            AppTheme.accentColor;
    final textPrimary =
        Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
            AppTheme.textPrimary;

    return SwitchListTile(
      title: Text(
        'Sadece TEFAS\'ta işlem gören fonlar',
        style: TextStyle(color: textPrimary),
      ),
      value: _filters['only_tefas'] ?? false,
      onChanged: (value) {
        setState(() {
          _filters['only_tefas'] = value;
        });
      },
      activeColor: accentColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSortOptions() {
    final currentSort = _filters['sort_by'];
    final accentColor =
        Theme.of(context).extension<AppThemeExtension>()?.accentColor ??
            AppTheme.accentColor;
    final cardColor =
        Theme.of(context).extension<AppThemeExtension>()?.cardColor ??
            AppTheme.cardColor;
    final textPrimary =
        Theme.of(context).extension<AppThemeExtension>()?.textPrimary ??
            AppTheme.textPrimary;

    final sortMappings = {
      'Günlük Getiri (Yüksek)': 'daily_return_desc',
      'Günlük Getiri (Düşük)': 'daily_return_asc',
      'Toplam Değer (Yüksek)': 'total_value_desc',
      'Toplam Değer (Düşük)': 'total_value_asc',
      'Yatırımcı Sayısı (Çok)': 'investor_count_desc',
      'Yatırımcı Sayısı (Az)': 'investor_count_asc',
      'Pazar Payı (Yüksek)': 'market_share_desc',
      'Pazar Payı (Düşük)': 'market_share_asc',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _sortOptions.map((option) {
        final sortValue = sortMappings[option];
        final isSelected = currentSort == sortValue;

        return GestureDetector(
          onTap: () {
            setState(() {
              _filters['sort_by'] = isSelected ? null : sortValue;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accentColor : cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? accentColor : textPrimary.withOpacity(0.3),
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _resetFilters() {
    setState(() {
      _filters.clear();
      _minReturnController.clear();
      _maxReturnController.clear();
    });
  }

  void _applyFilters() {
    // Update return filters from text controllers
    if (_minReturnController.text.isNotEmpty) {
      try {
        _filters['min_return'] = double.parse(_minReturnController.text);
      } catch (e) {
        _filters['min_return'] = null;
      }
    }

    if (_maxReturnController.text.isNotEmpty) {
      try {
        _filters['max_return'] = double.parse(_maxReturnController.text);
      } catch (e) {
        _filters['max_return'] = null;
      }
    }

    widget.onFiltersChanged(_filters);
    Navigator.pop(context);
  }
}

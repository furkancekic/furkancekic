// lib/widgets/fund_filter_sheet.dart
import 'package:flutter/material.dart';
import '../models/fund.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class FundFilterSheet extends StatefulWidget {
  final FundFilter currentFilter;
  final Set<String> availableCategories;
  final Function(FundFilter) onFilterChanged;

  const FundFilterSheet({
    Key? key,
    required this.currentFilter,
    required this.availableCategories,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  State<FundFilterSheet> createState() => _FundFilterSheetState();
}

class _FundFilterSheetState extends State<FundFilterSheet> {
  late FundFilter _filter;
  late RangeValues _returnRange;
  late RangeValues _riskRange;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    _returnRange = RangeValues(
      _filter.minReturn ?? -20.0,
      _filter.maxReturn ?? 20.0,
    );
    _riskRange = RangeValues(
      (_filter.minRiskLevel ?? 1).toDouble(),
      (_filter.maxRiskLevel ?? 7).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();

    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtreler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _resetFilters,
                      child: Text(
                        'Sıfırla',
                        style: TextStyle(color: accentColor),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori seçimi
                  _buildSectionTitle('Kategori'),
                  const SizedBox(height: 8),
                  _buildCategorySelector(),
                  const SizedBox(height: 24),

                  // TEFAS durumu
                  _buildSectionTitle('TEFAS Durumu'),
                  const SizedBox(height: 8),
                  _buildTefasSelector(),
                  const SizedBox(height: 24),

                  // Günlük getiri aralığı
                  _buildSectionTitle('Günlük Getiri Aralığı (%)'),
                  const SizedBox(height: 8),
                  _buildReturnRangeSlider(),
                  const SizedBox(height: 24),

                  // Risk seviyesi aralığı
                  _buildSectionTitle('Risk Seviyesi'),
                  const SizedBox(height: 8),
                  _buildRiskRangeSlider(),
                  const SizedBox(height: 32),

                  // Uygula butonu
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: 'Filtreleri Uygula',
                      onPressed: _applyFilters,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;

    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
    );
  }

  Widget _buildCategorySelector() {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final cardColorLight =
        themeExtension?.cardColorLight ?? AppTheme.cardColorLight;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "Tümü" seçeneği
        FilterChip(
          label: const Text('Tümü'),
          selected: _filter.category == null,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _filter = _filter.copyWith(category: null);
              });
            }
          },
          selectedColor: accentColor.withOpacity(0.2),
          backgroundColor: cardColorLight,
        ),
        // Kategoriler
        ...widget.availableCategories.map((category) {
          return FilterChip(
            label: Text(category),
            selected: _filter.category == category,
            onSelected: (selected) {
              setState(() {
                _filter = _filter.copyWith(
                  category: selected ? category : null,
                );
              });
            },
            selectedColor: accentColor.withOpacity(0.2),
            backgroundColor: cardColorLight,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTefasSelector() {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final cardColorLight =
        themeExtension?.cardColorLight ?? AppTheme.cardColorLight;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Tümü'),
          selected: _filter.onlyTefas == null,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _filter = _filter.copyWith(onlyTefas: null);
              });
            }
          },
          selectedColor: accentColor.withOpacity(0.2),
          backgroundColor: cardColorLight,
        ),
        FilterChip(
          label: const Text('Sadece TEFAS'),
          selected: _filter.onlyTefas == true,
          onSelected: (selected) {
            setState(() {
              _filter = _filter.copyWith(onlyTefas: selected ? true : null);
            });
          },
          selectedColor: accentColor.withOpacity(0.2),
          backgroundColor: cardColorLight,
        ),
        FilterChip(
          label: const Text('Sadece Özel'),
          selected: _filter.onlyTefas == false,
          onSelected: (selected) {
            setState(() {
              _filter = _filter.copyWith(onlyTefas: selected ? false : null);
            });
          },
          selectedColor: accentColor.withOpacity(0.2),
          backgroundColor: cardColorLight,
        ),
      ],
    );
  }

  Widget _buildReturnRangeSlider() {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Column(
      children: [
        RangeSlider(
          values: _returnRange,
          min: -20.0,
          max: 20.0,
          divisions: 80,
          activeColor: accentColor,
          inactiveColor: accentColor.withOpacity(0.3),
          onChanged: (values) {
            setState(() {
              _returnRange = values;
              _filter = _filter.copyWith(
                minReturn: values.start,
                maxReturn: values.end,
              );
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_returnRange.start.toStringAsFixed(1)}%',
              style: TextStyle(color: textSecondary),
            ),
            Text(
              'Günlük Getiri',
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
            ),
            Text(
              '${_returnRange.end.toStringAsFixed(1)}%',
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiskRangeSlider() {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Column(
      children: [
        RangeSlider(
          values: _riskRange,
          min: 1.0,
          max: 7.0,
          divisions: 6,
          activeColor: accentColor,
          inactiveColor: accentColor.withOpacity(0.3),
          onChanged: (values) {
            setState(() {
              _riskRange = values;
              _filter = _filter.copyWith(
                minRiskLevel: values.start.round(),
                maxRiskLevel: values.end.round(),
              );
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Risk ${_riskRange.start.round()}',
              style: TextStyle(color: textSecondary),
            ),
            Text(
              'Risk Seviyesi',
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
            ),
            Text(
              'Risk ${_riskRange.end.round()}',
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _filter = FundFilter();
      _returnRange = const RangeValues(-20.0, 20.0);
      _riskRange = const RangeValues(1.0, 7.0);
    });
  }

  void _applyFilters() {
    widget.onFilterChanged(_filter);
    Navigator.of(context).pop();
  }
}

// Filter summary widget
class FilterSummary extends StatelessWidget {
  final FundFilter filter;
  final VoidCallback onClear;

  const FilterSummary({
    Key? key,
    required this.filter,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    final hasFilters = filter.category != null ||
        filter.onlyTefas != null ||
        filter.minReturn != null ||
        filter.maxReturn != null;

    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getFilterSummary(),
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Temizle',
              style: TextStyle(color: accentColor),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterSummary() {
    final filters = <String>[];

    if (filter.category != null) {
      filters.add(filter.category!);
    }

    if (filter.onlyTefas == true) {
      filters.add('TEFAS');
    } else if (filter.onlyTefas == false) {
      filters.add('Özel');
    }

    if (filter.minReturn != null || filter.maxReturn != null) {
      final min = filter.minReturn?.toStringAsFixed(1) ?? '-∞';
      final max = filter.maxReturn?.toStringAsFixed(1) ?? '∞';
      filters.add('Getiri: $min% - $max%');
    }

    return filters.join(' • ');
  }
}

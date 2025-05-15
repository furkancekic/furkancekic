import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';

class FundDistributionChart extends StatefulWidget {
  final Map<String, dynamic> distributions;
  final double? height;

  const FundDistributionChart({
    Key? key,
    required this.distributions,
    this.height,
  }) : super(key: key);

  @override
  State<FundDistributionChart> createState() => _FundDistributionChartState();
}

class _FundDistributionChartState extends State<FundDistributionChart> {
  int touchedIndex = -1;

  // Modern and appealing colors for the pie chart
  static const List<Color> sectionColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFF84CC16), // Lime
    Color(0xFF6B7280), // Gray
    Color(0xFFA855F7), // Purple
  ];

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    if (widget.distributions.isEmpty) {
      return Container(
        height: widget.height ?? 300,
        child: Center(
          child: Text(
            'Dağılım verisi mevcut değil',
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }

    // Convert distributions to pie chart sections
    final sections = _createPieChartSections();

    return Container(
      height: widget.height ?? 350,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portföy Dağılımı',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: sections,
                    ),
                  ),
                ),
                // Legend
                Expanded(
                  flex: 2,
                  child: _buildLegend(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _createPieChartSections() {
    final entries = widget.distributions.entries.toList();
    final sections = <PieChartSectionData>[];

    // Calculate total for percentage conversion
    double total = 0;
    for (final entry in entries) {
      final value = _parseValue(entry.value);
      total += value;
    }

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final value = _parseValue(entry.value);
      final percentage = total > 0 ? (value / total) * 100 : 0;
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 110.0 : 100.0;
      final color = sectionColors[i % sectionColors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: isTouched ? 16 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 2,
                color: Colors.black45,
              ),
            ],
          ),
          badgeWidget: isTouched
              ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          badgePositionPercentageOffset: 1.3,
        ),
      );
    }

    return sections;
  }

  Widget _buildLegend() {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    final entries = widget.distributions.entries.toList();

    // Calculate total for percentage conversion
    double total = 0;
    for (final entry in entries) {
      final value = _parseValue(entry.value);
      total += value;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(entries.length, (index) {
          final entry = entries[index];
          final value = _parseValue(entry.value);
          final percentage = total > 0 ? (value / total) * 100 : 0;
          final color = sectionColors[index % sectionColors.length];
          final isTouched = index == touchedIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                touchedIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isTouched ? cardColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatAssetName(entry.key),
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight:
                                isTouched ? FontWeight.bold : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  double _parseValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value.replaceAll(',', '.'));
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  String _formatAssetName(String name) {
    // Capitalize first letter and format common asset names
    if (name.isEmpty) return name;

    final formatted = name.toLowerCase();

    // Common mappings for better display
    final mappings = {
      'hisse senedi': 'Hisse Senedi',
      'devlet tahvili': 'Devlet Tahvili',
      'özel sektör tahvili': 'Özel Sektör Tahvili',
      'yabancı hisse senedi': 'Yabancı Hisse',
      'finansman bonosu': 'Finansman Bonosu',
      'ters-repo': 'Ters Repo',
      'takasbank para piyasası': 'Para Piyasası',
      'vadeli işlemler nakit teminatları': 'Vadeli İşlemler',
      'yatırım fonları katılma payları': 'Yatırım Fonları',
      'diğer': 'Diğer',
    };

    return mappings[formatted] ??
        name
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : word)
            .join(' ');
  }
}

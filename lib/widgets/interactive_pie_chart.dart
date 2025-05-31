import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/portfolio.dart';
import '../models/position.dart';
import '../utils/logger.dart';

class InteractivePieChart extends StatefulWidget {
  final Portfolio portfolio;
  final double size;
  final bool showPercentage;
  final bool showLabels;
  final String? chartTitle;

  const InteractivePieChart({
    Key? key,
    required this.portfolio,
    this.size = 200,
    this.showPercentage = true,
    this.showLabels = true,
    this.chartTitle,
  }) : super(key: key);

  @override
  State<InteractivePieChart> createState() => _InteractivePieChartState();
}

class _InteractivePieChartState extends State<InteractivePieChart>
    with SingleTickerProviderStateMixin {
  int touchedIndex = -1;
  Map<String, double> _allocations = {};
  late AnimationController _animationController;
  late Animation<double> _animation;
  Position? _selectedPosition;
  final _logger = AppLogger('InteractivePieChart');

  // Beautiful modern colors for the pie chart
  final List<Color> sectionColors = [
    const Color(0xFF6366F1), // Purple
    const Color(0xFF10B981), // Green
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFF97316), // Orange
    const Color(0xFF84CC16), // Lime
  ];

  @override
  void initState() {
    super.initState();
    _calculateAllocations();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(InteractivePieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portfolio != widget.portfolio) {
      _calculateAllocations();
      // Reset touched index when portfolio changes
      setState(() {
        touchedIndex = -1;
        _selectedPosition = null;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _calculateAllocations() {
    final allocations = <String, double>{};
    final totalValue = widget.portfolio.totalValue ?? 0;

    for (var position in widget.portfolio.positions) {
      final value = position.currentValue ?? 0;
      if (value > 0) {
        allocations[position.ticker] = value.toDouble();
      }
    }

    setState(() {
      _allocations = allocations;
    });
  }

  void _showPositionDetails(int index) {
    // Get the position based on the sorted allocations
    final sortedEntries = _allocations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (index >= 0 && index < sortedEntries.length) {
      final ticker = sortedEntries[index].key;

      // Find corresponding position
      final position = widget.portfolio.positions.firstWhere(
        (p) => p.ticker == ticker,
        orElse: () => Position(
          ticker: ticker,
          quantity: 0,
          averagePrice: 0,
          purchaseDate: DateTime.now(),
        ),
      );

      setState(() {
        _selectedPosition = position;
        touchedIndex = index;
      });

      // Start animation
      _animationController.forward(from: 0.0);
    } else {
      setState(() {
        _selectedPosition = null;
        touchedIndex = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = ext?.cardColor ?? AppTheme.cardColor;
    final textPrimary = ext?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary = ext?.textSecondary ?? AppTheme.textSecondary;
    final accent = ext?.accentColor ?? AppTheme.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.chartTitle ?? 'Asset Allocation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              // Pie Chart
              SizedBox(
                height: widget.size,
                width: double.infinity,
                child: PieChart(
                  PieChartData(
                    sections: _getSections(),
                    centerSpaceRadius: widget.size * 0.25,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            return;
                          }
                          final index = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                          _showPositionDetails(index);
                        });
                      },
                    ),
                  ),
                ),
              ),

              // Center text showing total value or selected position
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedPosition == null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total Value',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '\$${widget.portfolio.totalValue?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedPosition!.ticker,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedPosition!.companyName != null)
                                Text(
                                  _selectedPosition!.companyName!,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${_selectedPosition!.currentValue?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedPosition!.gainLossPercent != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        (_selectedPosition!.gainLossPercent! >=
                                                    0
                                                ? AppTheme.positiveColor
                                                : AppTheme.negativeColor)
                                            .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${_selectedPosition!.gainLossPercent! >= 0 ? '+' : ''}${_selectedPosition!.gainLossPercent!.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      color:
                                          _selectedPosition!.gainLossPercent! >=
                                                  0
                                              ? AppTheme.positiveColor
                                              : AppTheme.negativeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),

              // Position detail popup when a sector is tapped
              if (_selectedPosition != null)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FadeTransition(
                    opacity: _animation,
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to position detail
                        // This would be implemented in the full screen
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Legend
          if (widget.showLabels)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _buildLegendItems(),
              ),
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getSections() {
    if (widget.portfolio.positions.isEmpty) {
      return [
        PieChartSectionData(
          color: sectionColors[0].withOpacity(0.3),
          value: 100,
          title: 'Empty',
          radius: widget.size * 0.3,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    // Sort by value (highest first)
    final sortedEntries = _allocations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate percentages
    final totalValue = widget.portfolio.totalValue ?? 0;

    // Calculate percentages and create sections
    final sections = <PieChartSectionData>[];
    double othersValue = 0;

    for (var i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final percentage =
          totalValue > 0 ? (entry.value / totalValue) * 100 : 0.0;

      // Group small percentages as "Others"
      if (percentage < 3 && i >= 8) {
        othersValue += entry.value;
        continue;
      }

      final radius =
          touchedIndex == i ? widget.size * 0.38 : widget.size * 0.33;
      final isTouched = touchedIndex == i;

      sections.add(
        PieChartSectionData(
          color: sectionColors[i % sectionColors.length],
          value: entry.value,
          title: isTouched || percentage > 5
              ? '${percentage.toStringAsFixed(1)}%'
              : '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: isTouched ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 2,
                color: Colors.black54,
              ),
            ],
          ),
          badgeWidget: isTouched
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: sectionColors[i % sectionColors.length]
                        .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    entry.key,
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

    // Add "Others" section if needed
    if (othersValue > 0) {
      final percentage =
          totalValue > 0 ? (othersValue / totalValue) * 100 : 0.0;
      sections.add(
        PieChartSectionData(
          color: Colors.grey.shade600,
          value: othersValue,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: widget.size * 0.33,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  List<Widget> _buildLegendItems() {
    final items = <Widget>[];

    // Sort by value
    final sortedEntries = _allocations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalValue = widget.portfolio.totalValue ?? 0;

    // Build legend items
    for (var i = 0; i < sortedEntries.length && i < 8; i++) {
      final entry = sortedEntries[i];
      final percentage =
          totalValue > 0 ? (entry.value / totalValue) * 100 : 0.0;

      final position = widget.portfolio.positions.firstWhere(
        (p) => p.ticker == entry.key,
        orElse: () => Position(
          ticker: entry.key,
          quantity: 0,
          averagePrice: 0,
          purchaseDate: DateTime.now(),
        ),
      );

      items.add(
        InkWell(
          onTap: () => _showPositionDetails(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: touchedIndex == i
                  ? sectionColors[i % sectionColors.length].withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: sectionColors[i % sectionColors.length],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: sectionColors[i % sectionColors.length]
                            .withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: touchedIndex == i
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    if (position.companyName != null)
                      Text(
                        position.companyName!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight:
                        touchedIndex == i ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Add "Others" if there are more than 8 positions
    if (sortedEntries.length > 8) {
      double othersValue = 0;
      for (var i = 8; i < sortedEntries.length; i++) {
        othersValue += sortedEntries[i].value;
      }
      final percentage =
          totalValue > 0 ? (othersValue / totalValue) * 100 : 0.0;

      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade600.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Others',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return items;
  }
}

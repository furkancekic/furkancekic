import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class FundCard extends StatelessWidget {
  final Map<String, dynamic> fund;
  final VoidCallback? onTap;

  const FundCard({
    Key? key,
    required this.fund,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Theme colors
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final cardColorLight =
        themeExtension?.cardColorLight ?? AppTheme.cardColorLight;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final positiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;

    // Fund data
    final fundCode = fund['kod'] ?? '';
    final fundName = fund['fon_adi'] ?? '';
    final dailyReturn = fund['gunluk_getiri'] ?? '0%';
    final totalValue = fund['fon_toplam_deger'] ?? 0.0;
    final investorCount = fund['yatirimci_sayisi'] ?? 0;
    final category = fund['kategori'] ?? '';
    final marketShare = fund['pazar_payi'] ?? '0%';

    // Parse daily return
    final returnStr =
        dailyReturn.toString().replaceAll('%', '').replaceAll(',', '.');
    double returnValue = 0.0;
    try {
      returnValue = double.parse(returnStr);
    } catch (e) {
      returnValue = 0.0;
    }

    final isPositive = returnValue >= 0;
    final returnColor = isPositive ? positiveColor : negativeColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cardColorLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Code and Performance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fundCode,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: returnColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: returnColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dailyReturn,
                              style: TextStyle(
                                color: returnColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Fund Name
                  Text(
                    fundName,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // GÜNCELLEME: Metrics Row - Kutu şeklinde vurgulu
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColorLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetricColumn(
                            'Toplam Değer',
                            _formatCurrency(totalValue),
                            textSecondary,
                            textPrimary,
                            Icons.account_balance,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: textSecondary.withOpacity(0.2),
                        ),
                        Expanded(
                          child: _buildMetricColumn(
                            'Yatırımcı',
                            _formatNumber(investorCount),
                            textSecondary,
                            textPrimary,
                            Icons.people,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: textSecondary.withOpacity(0.2),
                        ),
                        Expanded(
                          child: _buildMetricColumn(
                            'Pazar Payı',
                            marketShare,
                            textSecondary,
                            textPrimary,
                            Icons.pie_chart,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tags
                  Row(
                    children: [
                      if (fund['tefas']?.toString().contains('işlem görüyor') ==
                          true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: positiveColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TEFAS',
                            style: TextStyle(
                              color: positiveColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Kategori: ${fund['kategori_drecece'] ?? ''}',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: valueColor, size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null || value == 0) return '0 ₺';

    double val = 0.0;
    if (value is String) {
      try {
        val = double.parse(value.replaceAll(',', '.'));
      } catch (e) {
        return '0 ₺';
      }
    } else {
      val = value.toDouble();
    }

    if (val >= 1e9) {
      return '${(val / 1e9).toStringAsFixed(1)}B ₺';
    } else if (val >= 1e6) {
      return '${(val / 1e6).toStringAsFixed(1)}M ₺';
    } else if (val >= 1e3) {
      return '${(val / 1e3).toStringAsFixed(1)}K ₺';
    } else {
      return '${val.toStringAsFixed(0)} ₺';
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null || value == 0) return '0';

    int val = 0;
    if (value is String) {
      try {
        val = int.parse(value);
      } catch (e) {
        return '0';
      }
    } else {
      val = value.toInt();
    }

    if (val >= 1e6) {
      return '${(val / 1e6).toStringAsFixed(1)}M';
    } else if (val >= 1e3) {
      return '${(val / 1e3).toStringAsFixed(1)}K';
    } else {
      return val.toString();
    }
  }
}

// lib/widgets/fund_widgets/fund_card.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common_widgets.dart';

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
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final positiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    // Parse fund data
    final fundCode = fund['kod'] ?? '';
    final fundName = fund['fon_adi'] ?? '';
    final category = fund['kategori'] ?? '';
    final dailyReturn = fund['gunluk_getiri'] ?? '0%';
    final totalValue = fund['fon_toplam_deger'];
    final investorCount = fund['yatirimci_sayisi'];
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

    return FuturisticCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: returnColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: returnColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: returnColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dailyReturn.toString(),
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

          // Fund name
          if (fundName.isNotEmpty) ...[
            const SizedBox(height: 8),
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
          ],

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Toplam Değer',
                  _formatCurrency(totalValue),
                  Icons.account_balance,
                  textPrimary,
                  textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Yatırımcı',
                  _formatNumber(investorCount),
                  Icons.people,
                  textPrimary,
                  textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pazar Payı',
                  marketShare.toString(),
                  Icons.pie_chart,
                  textPrimary,
                  textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: textSecondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: textSecondary, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: textSecondary,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

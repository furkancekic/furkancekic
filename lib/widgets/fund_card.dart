// lib/widgets/fund_card.dart
import 'package:flutter/material.dart';
import '../models/fund.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class FundCard extends StatelessWidget {
  final Fund fund;
  final VoidCallback? onTap;

  const FundCard({
    Key? key,
    required this.fund,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();

    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final positiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    final isPositive = fund.gunlukGetiriDouble >= 0;
    final changeColor = isPositive ? positiveColor : negativeColor;
    final riskColor = fund.getRiskColor(themeExtension!);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FuturisticCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: Fon kodu ve TEFAS durumu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fund.kod,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Row(
                  children: [
                    // Risk seviyesi badge'i
                    if (fund.riskLevel > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: riskColor),
                        ),
                        child: Text(
                          'Risk ${fund.riskLevel}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // TEFAS durumu
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: fund.isTefasActive
                            ? positiveColor.withOpacity(0.2)
                            : textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        fund.isTefasActive ? 'TEFAS' : 'Özel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: fund.isTefasActive
                              ? positiveColor
                              : textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Fon adı
            Text(
              fund.fonAdi,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Alt satır: Fiyat, getiri ve kategori
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Fiyat ve getiri
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fund.sonFiyat} TL',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: changeColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fund.gunlukGetiri,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Kategori ve pazar payı
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: textSecondary.withOpacity(0.3)),
                      ),
                      child: Text(
                        fund.kategori,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pazar Payı: ${fund.pazarPayi}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Ekstra bilgiler (toplam değer ve yatırımcı sayısı)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatCurrency(fund.fonToplamDeger)} TL',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_formatNumber(fund.yatirimciSayisi)} yatırımcı',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}M';
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}B';
    }
    return value.toStringAsFixed(0);
  }

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}B';
    }
    return value.toString();
  }
}

// Fund Card Shimmer Loader
class FundCardShimmer extends StatelessWidget {
  const FundCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FuturisticCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerLoading(width: 80, height: 24, borderRadius: 4),
                Row(
                  children: [
                    ShimmerLoading(width: 60, height: 24, borderRadius: 12),
                    const SizedBox(width: 8),
                    ShimmerLoading(width: 50, height: 24, borderRadius: 12),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Fon adı shimmer
            ShimmerLoading(width: double.infinity, height: 16, borderRadius: 4),
            const SizedBox(height: 8),
            ShimmerLoading(width: 200, height: 16, borderRadius: 4),
            const SizedBox(height: 12),

            // Alt satır shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(width: 100, height: 24, borderRadius: 4),
                    const SizedBox(height: 4),
                    ShimmerLoading(width: 80, height: 16, borderRadius: 4),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerLoading(width: 120, height: 20, borderRadius: 8),
                    const SizedBox(height: 8),
                    ShimmerLoading(width: 100, height: 14, borderRadius: 4),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Son satır shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerLoading(width: 100, height: 14, borderRadius: 4),
                ShimmerLoading(width: 80, height: 14, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

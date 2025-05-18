// lib/widgets/fund_widgets/fund_card.dart - Güncellenen kısım
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
    
    // Yeni veriler
    final weeklyReturn = fund['haftalik_getiri'] ?? '0%';
    final monthlyReturn = fund['aylik_getiri'] ?? '0%';
    final sixMonthReturn = fund['alti_aylik_getiri'] ?? '0%';
    final yearlyReturn = fund['yillik_getiri'] ?? '0%';
    final investorChange = fund['yatirimci_degisim'] ?? '0';
    final valueChange = fund['deger_degisim'] ?? '0%';

    // Parse return values
    final returnStr = dailyReturn.toString().replaceAll('%', '').replaceAll(',', '.');
    final weeklyReturnStr = weeklyReturn.toString().replaceAll('%', '').replaceAll(',', '.');
    final monthlyReturnStr = monthlyReturn.toString().replaceAll('%', '').replaceAll(',', '.');
    final sixMonthReturnStr = sixMonthReturn.toString().replaceAll('%', '').replaceAll(',', '.');
    final yearlyReturnStr = yearlyReturn.toString().replaceAll('%', '').replaceAll(',', '.');
    final valueChangeStr = valueChange.toString().replaceAll('%', '').replaceAll(',', '.');
    
    double returnValue = 0.0;
    double weeklyReturnValue = 0.0;
    double monthlyReturnValue = 0.0;
    double sixMonthReturnValue = 0.0;
    double yearlyReturnValue = 0.0;
    double valueChangeValue = 0.0;
    int investorChangeValue = 0;
    
    try {
      returnValue = double.parse(returnStr);
      weeklyReturnValue = double.parse(weeklyReturnStr);
      monthlyReturnValue = double.parse(monthlyReturnStr);
      sixMonthReturnValue = double.parse(sixMonthReturnStr);
      yearlyReturnValue = double.parse(yearlyReturnStr);
      valueChangeValue = double.parse(valueChangeStr);
      investorChangeValue = int.parse(investorChange.toString().replaceAll('+', ''));
    } catch (e) {
      // Parse hatası durumunda varsayılan değerleri kullan
    }

    final isPositive = returnValue >= 0;
    final isWeeklyPositive = weeklyReturnValue >= 0;
    final isMonthlyPositive = monthlyReturnValue >= 0;
    final isSixMonthPositive = sixMonthReturnValue >= 0;
    final isYearlyPositive = yearlyReturnValue >= 0;
    final isValueChangePositive = valueChangeValue >= 0;
    final isInvestorChangePositive = investorChangeValue >= 0;

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

          const SizedBox(height: 12),

          // Getiri tablosu
  Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: BoxDecoration(
      color: textSecondary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: textSecondary.withOpacity(0.1), width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performans',
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Getiri & Değişim',
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _buildReturnItem('Günlük', dailyReturn, isPositive, textPrimary),
            _buildReturnItem('Haftalık', weeklyReturn, isWeeklyPositive, textPrimary),
            _buildReturnItem('Aylık', monthlyReturn, isMonthlyPositive, textPrimary),
            _buildReturnItem('6 Aylık', sixMonthReturn, isSixMonthPositive, textPrimary),
            _buildReturnItem('Yıllık', yearlyReturn, isYearlyPositive, textPrimary),
            _buildReturnItem('Büyüklük Değişimi', valueChange, isValueChangePositive, textPrimary),
            _buildReturnItem(
              'Yatırımcı Sayısı Değişimi', 
              investorChangeValue > 0 ? "+$investorChangeValue" : "$investorChangeValue", 
              isInvestorChangePositive, 
              textPrimary,
            ),
          ],
        ),
      ],
    ),
  ),


          const SizedBox(height: 12),

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
            ],
          ),
        ],
      ),
    );
  }

Widget _buildReturnItem(String label, String value, bool isPositive, Color textColor, {bool showPlusSign = false}) {
  Color displayColor = isPositive ? Colors.green.shade700 : Colors.red.shade700;
  String displayValue = value;
  
  if (showPlusSign && isPositive && !value.startsWith('+')) {
    displayValue = '+$value';
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    decoration: BoxDecoration(
      color: displayColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: displayColor.withOpacity(0.3), width: 0.5),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Artış/Azalış ikonu yerine daha modern bir gösterim
            Icon(
              isPositive 
                ? Icons.trending_up_rounded  // Modern artış ikonu
                : Icons.trending_down_rounded, // Modern azalış ikonu
              color: displayColor,
              size: 12,
            ),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                displayValue,
                style: TextStyle(
                  color: displayColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
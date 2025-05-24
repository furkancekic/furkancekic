// widgets/common_widgets.dart
// Güncellenmiş versiyon - tema stiline göre widget seçimi
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_styles.dart';
import 'glassmorphism_widgets.dart';

class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final VoidCallback? onTap;
  final Color? color;

  const AdaptiveCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.elevation = 4,
    this.onTap,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final themeStyle = themeExtension?.themeStyle ?? ThemeStyle.modern;

    if (themeStyle == ThemeStyle.glassmorphism) {
      return GlassCard(
        child: child,
        padding: padding,
        onTap: onTap,
        color: color,
      );
    } else {
      return FuturisticCard(
        child: child,
        padding: padding,
        elevation: elevation,
        onTap: onTap,
        color: color,
      );
    }
  }
}

class FuturisticCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final VoidCallback? onTap;
  final Color? color;

  const FuturisticCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.elevation = 4,
    this.onTap,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<AppThemeExtension>();
    final cardColor = color ?? themeExtension?.cardColor ?? AppTheme.cardColor;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Card(
      elevation: elevation,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// Diğer common widget'lar aynı kalabilir
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final isDark = themeExtension?.isDark ?? true;

    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: const [0.1, 0.3, 0.4],
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
        ),
      ),
    );
  }
}

class GlowingText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final Color? glowColor;
  final double glowRadius;

  const GlowingText(
    this.text, {
    Key? key,
    this.fontSize = 16,
    this.fontWeight = FontWeight.normal,
    this.color,
    this.glowColor,
    this.glowRadius = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textColor =
        color ?? themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final glow =
        glowColor ?? themeExtension?.accentColor ?? AppTheme.accentColor;

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: textColor,
        shadows: [
          Shadow(
            blurRadius: glowRadius,
            color: glow.withOpacity(0.7),
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );
  }
}

class StockPriceChange extends StatelessWidget {
  final double priceChange;
  final double percentChange;
  final bool showIcon;
  final bool compactMode;

  const StockPriceChange({
    Key? key,
    required this.priceChange,
    required this.percentChange,
    this.showIcon = true,
    this.compactMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = priceChange >= 0;

    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final color = isPositive
        ? (themeExtension?.positiveColor ?? AppTheme.positiveColor)
        : (themeExtension?.negativeColor ?? AppTheme.negativeColor);

    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final priceText = isPositive
        ? '+${priceChange.toStringAsFixed(2)}'
        : priceChange.toStringAsFixed(2);
    final percentText = isPositive
        ? '+${percentChange.toStringAsFixed(2)}%'
        : '${percentChange.toStringAsFixed(2)}%';

    if (compactMode) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) Icon(icon, color: color, size: 12),
          const SizedBox(width: 2),
          Text(
            percentText,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '$priceText ($percentText)',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class AdaptiveSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;

  const AdaptiveSearchField({
    Key? key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final themeStyle = themeExtension?.themeStyle ?? ThemeStyle.modern;

    if (themeStyle == ThemeStyle.glassmorphism) {
      return GlassSearchField(
        controller: controller,
        hintText: hintText,
        onChanged: onChanged,
        onClear: onClear,
        onSubmitted: onSubmitted,
      );
    } else {
      return SearchField(
        controller: controller,
        hintText: hintText,
        onChanged: onChanged,
        onClear: onClear,
        onSubmitted: onSubmitted,
      );
    }
  }
}

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;

  const SearchField({
    Key? key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted?.call(),
        style: TextStyle(color: textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: textSecondary),
          prefixIcon: Icon(Icons.search, color: accentColor),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: textSecondary),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}

class NeonBorder extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double width;
  final double borderRadius;

  const NeonBorder({
    Key? key,
    required this.child,
    this.color,
    this.width = 1.5,
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final borderColor =
        color ?? themeExtension?.accentColor ?? AppTheme.accentColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: borderColor, width: width),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - width),
        child: child,
      ),
    );
  }
}

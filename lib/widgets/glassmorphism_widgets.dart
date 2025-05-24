// widgets/glassmorphism_widgets.dart
// Yeni dosya - Glassmorphism tema için özel widget'lar

import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../theme/theme_styles.dart';

// Glassmorphism Card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double opacity;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.blur = 10,
    this.opacity = 0.1,
    this.onTap,
    this.color,
    this.borderRadius = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final isDark = themeExtension?.isDark ?? true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color ??
                (isDark
                    ? Colors.white.withOpacity(opacity)
                    : Colors.white.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Glassmorphism Navigation Bar
class GlassCurvedNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;

  const GlassCurvedNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onIndexSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final isDark = ext?.isDark ?? true;
    final accentColor = ext?.accentColor ?? AppTheme.accentColor;
    final textSec = ext?.textSecondary ?? AppTheme.textSecondary;

    return Container(
      height: 85,
      padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(context, 0, Icons.home_rounded, 'Home'),
                _buildNavItem(
                    context, 1, Icons.filter_list_rounded, 'Screener'),
                _buildCenterButton(context, 2, Icons.candlestick_chart),
                _buildNavItem(context, 3, Icons.analytics_rounded, 'Backtest'),
                _buildNavItem(context, 4, Icons.slideshow_rounded, 'Reels'),
                _buildNavItem(context, 5, Icons.account_balance, 'Funds'),
                _buildNavItem(
                    context, 6, Icons.account_balance_wallet, 'Portfolio'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, int index, IconData icon, String label) {
    final sel = currentIndex == index;
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final accent = ext?.accentColor ?? AppTheme.accentColor;
    final textSec = ext?.textSecondary ?? AppTheme.textSecondary;

    return InkWell(
      onTap: () => onIndexSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: sel
            ? BoxDecoration(
                color: accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: sel ? accent : textSec,
              size: sel ? 26 : 22,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: sel ? accent : textSec,
                fontSize: sel ? 11 : 10,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context, int index, IconData icon) {
    final sel = currentIndex == index;
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final accent = ext?.accentColor ?? AppTheme.accentColor;

    return GestureDetector(
      onTap: () => onIndexSelected(index),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              sel ? accent : accent.withOpacity(0.8),
              sel ? accent.withOpacity(0.8) : accent.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

// Glassmorphism Search Field
class GlassSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;

  const GlassSearchField({
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
    final isDark = themeExtension?.isDark ?? true;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
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
        ),
      ),
    );
  }
}

// Glassmorphism Feature Card
class GlassFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const GlassFeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final isDark = themeExtension?.isDark ?? true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(isDark ? 0.3 : 0.2),
                color.withOpacity(isDark ? 0.1 : 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

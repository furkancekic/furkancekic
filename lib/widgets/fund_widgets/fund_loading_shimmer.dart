// lib/widgets/fund_widgets/fund_loading_shimmer.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common_widgets.dart';

class FundLoadingShimmer extends StatelessWidget {
  final int itemCount;

  const FundLoadingShimmer({
    Key? key,
    this.itemCount = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ShimmerLoading(
        width: double.infinity,
        height: 160,
        borderRadius: 16,
      ),
    );
  }
}

class FundDetailShimmer extends StatelessWidget {
  const FundDetailShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header shimmer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ShimmerLoading(width: 150, height: 24),
                const SizedBox(height: 8),
                ShimmerLoading(width: 200, height: 16),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        ShimmerLoading(width: 60, height: 20),
                        const SizedBox(height: 4),
                        ShimmerLoading(width: 40, height: 14),
                      ],
                    ),
                    Column(
                      children: [
                        ShimmerLoading(width: 60, height: 20),
                        const SizedBox(height: 4),
                        ShimmerLoading(width: 40, height: 14),
                      ],
                    ),
                    Column(
                      children: [
                        ShimmerLoading(width: 60, height: 20),
                        const SizedBox(height: 4),
                        ShimmerLoading(width: 40, height: 14),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Chart shimmer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ShimmerLoading(width: 120, height: 20),
                const SizedBox(height: 16),
                ShimmerLoading(width: double.infinity, height: 200),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tab content shimmer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (int i = 0; i < 6; i++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerLoading(width: 100, height: 16),
                      ShimmerLoading(width: 80, height: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

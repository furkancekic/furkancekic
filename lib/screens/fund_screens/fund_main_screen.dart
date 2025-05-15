// lib/screens/fund_screens/fund_main_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'fund_list_screen.dart';
import 'fund_market_overview_screen.dart';
import 'fund_category_screen.dart';

class FundMainScreen extends StatefulWidget {
  const FundMainScreen({Key? key}) : super(key: key);

  @override
  State<FundMainScreen> createState() => _FundMainScreenState();
}

class _FundMainScreenState extends State<FundMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = [
    'Tümü',
    'Hisse Senedi Fonu',
    'Serbest Fon',
    'Para Piyasası Fonu',
    'Karma Fon',
    'Tahvil Fonu',
    'Altın Fonu',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(textPrimary, accentColor),
          _buildTabBar(accentColor, cardColor),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _categories.map((category) {
            if (category == 'Tümü') {
              return const FundListScreen();
            } else {
              return FundCategoryScreen(category: category);
            }
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppBar(Color textPrimary, Color accentColor) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Yatırım Fonları',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Yatırım Fonları',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Profesyonel fon yönetimi',
                    style: TextStyle(
                      color: textPrimary.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FundMarketOverviewScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.analytics, color: accentColor, size: 28),
                tooltip: 'Pazar Genel Bakış',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(Color accentColor, Color cardColor) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.grey,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: accentColor.withOpacity(0.1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: _categories.map((category) {
            final shortName = _getShortCategoryName(category);
            return Tab(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(shortName),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getShortCategoryName(String category) {
    final mappings = {
      'Hisse Senedi Fonu': 'Hisse',
      'Serbest Fon': 'Serbest',
      'Para Piyasası Fonu': 'Para Piyasası',
      'Karma Fon': 'Karma',
      'Tahvil Fonu': 'Tahvil',
      'Altın Fonu': 'Altın',
    };
    return mappings[category] ?? category;
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

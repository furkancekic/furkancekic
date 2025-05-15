// home_screen.dart - CurvedNavigationBar güncellenmiş versiyonu
// lib/screens/home_screen.dart - Fund navigation eklenmiş
import 'package:flutter/material.dart';
import 'portfolio_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/mini_chart.dart';
import '../widgets/intraday_chart.dart';
import '../services/stock_api_service.dart' as api_service;
import '../widgets/app_drawer.dart';
import 'screener_screen.dart';
import 'chart_screen.dart';
import 'stock_reels_screen.dart';
import 'backtesting_screen.dart';
import 'fund_screens/fund_main_screen.dart';

/// ====================================================================
///  FeatureCard
/// ====================================================================
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 28),
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
    );
  }
}

/// ====================================================================
///  HomeScreen
/// ====================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeContent(),
    ScreenerScreen(),
    ChartScreen(),
    BacktestingScreen(),
    StockReelsScreen(),
    FundMainScreen(), // Fund screen eklendi
    PortfolioScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: const AppDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        currentIndex: _currentIndex,
        onIndexSelected: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// ====================================================================
///  CurvedNavigationBar - Fonds eklendi
/// ====================================================================
class CurvedNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;

  const CurvedNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onIndexSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = ext?.cardColor ?? AppTheme.cardColor;
    final accentColor = ext?.accentColor ?? AppTheme.accentColor;
    final textSec = ext?.textSecondary ?? AppTheme.textSecondary;

    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          // arka plan eğrisi
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
            ),
          ),

          // orta buton (Chart Screen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => onIndexSelected(2),
              child: Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      currentIndex == 2 ? accentColor : const Color(0xFF00BFA5),
                      currentIndex == 2
                          ? accentColor.withOpacity(0.8)
                          : const Color(0xFF00BFA5).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.candlestick_chart, color: Colors.white),
              ),
            ),
          ),

          // menü - Fund screen eklendi
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 65,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(context, 0, Icons.home_rounded, 'Home'),
                  _buildNavItem(
                      context, 1, Icons.filter_list_rounded, 'Screener'),
                  const SizedBox(width: 60), // Orta buton için boşluk
                  _buildNavItem(
                      context, 3, Icons.analytics_rounded, 'Backtest'),
                  _buildNavItem(context, 4, Icons.slideshow_rounded, 'Reels'),
                  _buildNavItem(context, 5, Icons.account_balance,
                      'Funds'), // Fund eklendi
                  _buildNavItem(
                      context, 6, Icons.account_balance_wallet, 'Portfolio'),
                ],
              ),
            ),
          ),
        ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: sel ? accent : textSec, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: sel ? accent : textSec,
              fontSize: 10,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// ====================================================================
///  HomeContent
/// ====================================================================
class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();

  // API verileri
  List<api_service.MarketIndex> _marketIndices = [];
  List<api_service.StockInfo> _watchlistStocks = [];

  bool _isLoadingIndices = true;
  bool _isLoadingWatchlist = true;

  // Arama
  List<api_service.SearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadMarketIndices();
    _loadWatchlistStocks();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  /* -------------------- Arama -------------------- */
  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    } else {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _performSearch(String q) async {
    setState(() => _isSearching = true);
    try {
      final res = await api_service.StockApiService.searchStocks(q);
      setState(() {
        _searchResults = res;
        _isSearching = false;
      });
    } catch (_) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  /* -------------------- Veri yükle -------------------- */
  Future<void> _loadMarketIndices() async {
    try {
      final res = await api_service.StockApiService.getMarketIndices();
      setState(() {
        _marketIndices = res;
        _isLoadingIndices = false;
      });
    } catch (_) {
      setState(() => _isLoadingIndices = false);
    }
  }

  Future<void> _loadWatchlistStocks() async {
    try {
      final res = await api_service.StockApiService.getWatchlistStocks();
      setState(() {
        _watchlistStocks = res;
        _isLoadingWatchlist = false;
      });
    } catch (_) {
      setState(() => _isLoadingWatchlist = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoadingIndices = true;
      _isLoadingWatchlist = true;
    });
    await Future.wait([_loadMarketIndices(), _loadWatchlistStocks()]);
  }

  /* -------------------- Intraday modal -------------------- */
  void _showIntradayChartModal(BuildContext ctx, api_service.StockInfo s) {
    final ext = Theme.of(ctx).extension<AppThemeExtension>();

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // tutma çubuğu
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // başlık
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.ticker,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ext?.textPrimary ?? AppTheme.textPrimary,
                            )),
                        Text(s.name,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  ext?.textSecondary ?? AppTheme.textSecondary,
                            )),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${s.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ext?.textPrimary ?? AppTheme.textPrimary,
                            )),
                        StockPriceChange(
                          priceChange: s.priceChange,
                          percentChange: s.percentChange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // grafik
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IntradayChart(ticker: s.ticker),
                ),
              ),
              // butonlar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.candlestick_chart),
                        label: const Text('View Full Chart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              ext?.accentColor ?? AppTheme.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ext?.cardColor ?? AppTheme.cardColor,
                        foregroundColor:
                            ext?.textPrimary ?? AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /* -------------------- build -------------------- */
  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();

    // Temaya göre gradient renkleri al
    final bgGradientColors = ext?.gradientBackgroundColors ??
        [
          Theme.of(context).scaffoldBackgroundColor,
          Theme.of(context).scaffoldBackgroundColor,
        ];

    final textPrim = ext?.textPrimary ?? AppTheme.textPrimary;
    final textSec = ext?.textSecondary ?? AppTheme.textSecondary;
    final accent = ext?.accentColor ?? AppTheme.accentColor;
    final cardColor = ext?.cardColor ?? AppTheme.cardColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgGradientColors,
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          backgroundColor: cardColor,
          color: accent,
          child: CustomScrollView(
            slivers: [
              /* ---------- APP BAR ---------- */
              _buildAppBar(accent),
              /* ---------- SEARCH RESULTS ---------- */
              if (_isSearching || _searchResults.isNotEmpty)
                _buildSearchResults(cardColor, accent, textPrim, textSec),
              /* ---------- MARKET OVERVIEW ---------- */
              _buildMarketOverview(textPrim, accent),
              /* ---------- WATCHLIST HEADER/BODY ---------- */
              _watchlistHeader(textPrim),
              _watchlistBody(accent),
              /* ---------- FEATURE CARDS ---------- */
              _featureCards(textPrim),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(Color accent) {
    final ext = Theme.of(context).extension<AppThemeExtension>();

    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: accent),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.candlestick_chart, color: accent, size: 32),
          const SizedBox(width: 12),
          const GlowingText(
            'MODERN FINANCE',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        CircleAvatar(
          backgroundColor: ext?.cardColor ?? AppTheme.cardColor,
          radius: 20,
          child: IconButton(
            icon: Icon(Icons.person, color: accent),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
          child: SearchField(
            controller: _searchController,
            hintText: 'Search stocks, indices, ETFs...',
            onSubmitted: () => _performSearch(_searchController.text),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSearchResults(
      Color card, Color accent, Color txtPrim, Color txtSec) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isSearching
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: accent),
                ),
              )
            : Column(
                children: _searchResults
                    .map((r) => ListTile(
                          title: Text(r.symbol,
                              style: TextStyle(
                                  color: txtPrim, fontWeight: FontWeight.bold)),
                          subtitle:
                              Text(r.name, style: TextStyle(color: txtSec)),
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                            // TODO: Detay sayfasına yönlendir
                          },
                        ))
                    .toList(),
              ),
      ),
    );
  }

  SliverToBoxAdapter _buildMarketOverview(Color txtPrim, Color accent) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Market Overview',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: txtPrim)),
            ),
            _isLoadingIndices
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: accent),
                    ),
                  )
                : SizedBox(
                    height: 130,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      scrollDirection: Axis.horizontal,
                      itemCount: _marketIndices.length,
                      itemBuilder: (_, i) {
                        final m = _marketIndices[i];
                        return MarketIndexCard(
                          name: m.name,
                          value: m.value,
                          change: m.change,
                          percentChange: m.percentChange,
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _watchlistHeader(Color txtPrim) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Watchlist',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: txtPrim)),
            TextButton(onPressed: () {}, child: const Text('Edit')),
          ],
        ),
      ),
    );
  }

  Widget _watchlistBody(Color accent) {
    if (_isLoadingWatchlist) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CircularProgressIndicator(color: accent),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) {
          final s = _watchlistStocks[i];
          return StockListItem(
            ticker: s.ticker,
            name: s.name,
            price: s.price,
            priceChange: s.priceChange,
            percentChange: s.percentChange,
            chartData: s.chartData,
            onTap: () => _showIntradayChartModal(context, s),
          );
        },
        childCount: _watchlistStocks.length,
      ),
    );
  }

  SliverToBoxAdapter _featureCards(Color txtPrim) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Explore Features',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: txtPrim)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FeatureCard(
                    icon: Icons.filter_list,
                    title: 'Stock\nScreener',
                    description: 'Find stocks matching your criteria',
                    color: const Color(0xFF6200EA),
                    onTap: () {
                      Navigator.pushNamed(context, '/screener');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FeatureCard(
                    icon: Icons.candlestick_chart,
                    title: 'Advanced\nCharts',
                    description: 'Technical analysis tools',
                    color: const Color(0xFF00BFA5),
                    onTap: () {
                      Navigator.pushNamed(context, '/chart');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FeatureCard(
                    icon: Icons.account_balance,
                    title: 'Investment\nFunds',
                    description: 'Explore and analyze funds',
                    color: const Color(0xFF2E7D32),
                    onTap: () {
                      Navigator.pushNamed(context, '/funds');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FeatureCard(
                    icon: Icons.analytics,
                    title: 'Strategy\nBacktesting',
                    description: 'Test your trading strategies',
                    color: const Color(0xFFFF6D00),
                    onTap: () {
                      Navigator.pushNamed(context, '/backtest');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FeatureCard(
                    icon: Icons.slideshow,
                    title: 'Stock\nReels',
                    description: 'Quick stock insights in a swipe',
                    color: const Color(0xFFD50000),
                    onTap: () {
                      Navigator.pushNamed(context, '/reels');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FeatureCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Portfolio\nTracker',
                    description: 'Track your investments',
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      // Portfolio tab zaten mevcut navigation'da
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ====================================================================
///  MarketIndexCard
/// ====================================================================
class MarketIndexCard extends StatelessWidget {
  final String name;
  final double value;
  final double change;
  final double percentChange;

  const MarketIndexCard({
    Key? key,
    required this.name,
    required this.value,
    required this.change,
    required this.percentChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final txtPrim = ext?.textPrimary ?? AppTheme.textPrimary;
    final txtSec = ext?.textSecondary ?? AppTheme.textSecondary;
    final cardColor = ext?.cardColor ?? AppTheme.cardColor;
    final cardLight = ext?.cardColorLight ?? AppTheme.cardColorLight;
    final posColor = ext?.positiveColor ?? AppTheme.positiveColor;
    final negColor = ext?.negativeColor ?? AppTheme.negativeColor;
    final color = isPositive ? posColor : negColor;
    final sign = isPositive ? '+' : '';

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cardLight, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: txtSec, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              value.toStringAsFixed(value > 100
                  ? 2
                  : value > 10
                      ? 3
                      : 4),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: txtPrim, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: color.withOpacity(0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$sign${change.abs().toStringAsFixed(2)} '
                  '($sign${percentChange.abs().toStringAsFixed(2)}%)',
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ====================================================================
///  StockListItem
/// ====================================================================
class StockListItem extends StatelessWidget {
  final String ticker;
  final String name;
  final double price;
  final double priceChange;
  final double percentChange;
  final List<double> chartData;
  final VoidCallback onTap;

  const StockListItem({
    Key? key,
    required this.ticker,
    required this.name,
    required this.price,
    required this.priceChange,
    required this.percentChange,
    required this.chartData,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = priceChange >= 0;
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final txtPrim = ext?.textPrimary ?? AppTheme.textPrimary;
    final txtSec = ext?.textSecondary ?? AppTheme.textSecondary;
    final accent = ext?.accentColor ?? AppTheme.accentColor;
    final posColor = ext?.positiveColor ?? AppTheme.positiveColor;
    final negColor = ext?.negativeColor ?? AppTheme.negativeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: FuturisticCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            /* --- Ticker & Ad --- */
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticker,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: txtPrim)),
                  const SizedBox(height: 4),
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: txtSec)),
                ],
              ),
            ),
            /* --- Mini Chart --- */
            Expanded(
              flex: 2,
              child: chartData.length >= 2
                  ? MiniChart(
                      data: chartData,
                      isPositive: isPositive,
                      height: 40,
                      width: 80,
                      showGradient: true,
                    )
                  : Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isPositive
                              ? [
                                  posColor.withOpacity(0.2),
                                  posColor.withOpacity(0.1),
                                  Colors.transparent,
                                ]
                              : [
                                  negColor.withOpacity(0.2),
                                  negColor.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.show_chart, color: accent, size: 20),
                    ),
            ),
            /* --- Fiyat & Değişim --- */
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${price.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: txtPrim)),
                  const SizedBox(height: 4),
                  StockPriceChange(
                    priceChange: priceChange,
                    percentChange: percentChange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

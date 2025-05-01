// screens/stock_reels_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'dart:math' as math;

class StockReelsScreen extends StatefulWidget {
  const StockReelsScreen({Key? key}) : super(key: key);

  @override
  State<StockReelsScreen> createState() => _StockReelsScreenState();
}

class _StockReelsScreenState extends State<StockReelsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Sample stock data for reels
  final List<Map<String, dynamic>> _stockReels = [
    {
      'ticker': 'AAPL',
      'name': 'Apple Inc.',
      'price': 182.63,
      'change': 3.24,
      'percentChange': 1.81,
      'marketCap': '2.85T',
      'pe': 30.42,
      'volume': 74962145,
      'eps': 6.01,
      'dividend': '0.92 (0.50%)',
      'high52W': 198.23,
      'low52W': 124.17,
      'news': 'Apple announces new iPhone models with AI capabilities',
      'recommendation': 'BUY',
      'color': Colors.blue,
    },
    {
      'ticker': 'TSLA',
      'name': 'Tesla, Inc.',
      'price': 231.48,
      'change': 5.68,
      'percentChange': 2.52,
      'marketCap': '736.4B',
      'pe': 83.17,
      'volume': 108761234,
      'eps': 2.78,
      'dividend': '0.00 (0.00%)',
      'high52W': 299.29,
      'low52W': 152.31,
      'news':
          'Tesla exceeds quarterly delivery expectations with record numbers',
      'recommendation': 'HOLD',
      'color': Colors.red,
    },
    {
      'ticker': 'NVDA',
      'name': 'NVIDIA Corporation',
      'price': 495.22,
      'change': 12.35,
      'percentChange': 2.56,
      'marketCap': '1.22T',
      'pe': 75.64,
      'volume': 52487621,
      'eps': 6.55,
      'dividend': '0.16 (0.03%)',
      'high52W': 522.75,
      'low52W': 140.36,
      'news': 'NVIDIA unveils next-gen AI chips with 50% performance boost',
      'recommendation': 'STRONG BUY',
      'color': Colors.green,
    },
    {
      'ticker': 'AMZN',
      'name': 'Amazon.com, Inc.',
      'price': 174.36,
      'change': -0.87,
      'percentChange': -0.49,
      'marketCap': '1.79T',
      'pe': 60.24,
      'volume': 32547896,
      'eps': 2.90,
      'dividend': '0.00 (0.00%)',
      'high52W': 185.63,
      'low52W': 101.26,
      'news': 'Amazon expands AWS with new data centers in Asia Pacific region',
      'recommendation': 'BUY',
      'color': Colors.orange,
    },
    {
      'ticker': 'MSFT',
      'name': 'Microsoft Corporation',
      'price': 338.47,
      'change': -2.15,
      'percentChange': -0.63,
      'marketCap': '2.52T',
      'pe': 34.78,
      'volume': 25367418,
      'eps': 9.73,
      'dividend': '2.72 (0.80%)',
      'high52W': 369.84,
      'low52W': 242.71,
      'news': 'Microsoft launches new AI-powered Office 365 features',
      'recommendation': 'BUY',
      'color': Colors.purple,
    },
    {
      'ticker': 'META',
      'name': 'Meta Platforms, Inc.',
      'price': 474.32,
      'change': 8.76,
      'percentChange': 1.88,
      'marketCap': '1.22T',
      'pe': 32.56,
      'volume': 18436721,
      'eps': 14.57,
      'dividend': '0.00 (0.00%)',
      'high52W': 485.96,
      'low52W': 167.66,
      'news': 'Meta reports growing user engagement across platforms',
      'recommendation': 'BUY',
      'color': Colors.indigo,
    },
    {
      'ticker': 'NFLX',
      'name': 'Netflix, Inc.',
      'price': 591.65,
      'change': -3.42,
      'percentChange': -0.57,
      'marketCap': '258.3B',
      'pe': 51.89,
      'volume': 5832641,
      'eps': 11.40,
      'dividend': '0.00 (0.00%)',
      'high52W': 639.00,
      'low52W': 285.37,
      'news':
          'Netflix subscriber growth accelerates after password-sharing crackdown',
      'recommendation': 'HOLD',
      'color': Colors.deepOrange,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              Color(0xFF192138), // Slightly blueish dark
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.slideshow,
                      color: AppTheme.accentColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Stock Reels',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.filter_list,
                        color: AppTheme.accentColor,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.info, color: AppTheme.accentColor),
                      onPressed: () {
                        _showInfoDialog(context);
                      },
                    ),
                  ],
                ),
              ),

              // Main Content - Stock Reels
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _onPageChanged,
                  itemCount: _stockReels.length,
                  itemBuilder: (context, index) {
                    final stock = _stockReels[index];
                    return StockReelCard(
                      stock: stock,
                      index: index,
                      currentPage: _currentPage,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppTheme.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GlowingText(
                    'Stock Reels',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    glowRadius: 15,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Discover stocks by simply scrolling up and down. Get quick insights into company performance, key metrics, and latest news.',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildInfoItem(Icons.trending_up, 'Swipe up', 'Next'),
                      const SizedBox(width: 24),
                      _buildInfoItem(
                        Icons.trending_down,
                        'Swipe down',
                        'Previous',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildInfoItem(
                        Icons.favorite,
                        'Double tap',
                        'Add to favorites',
                      ),
                      const SizedBox(width: 24),
                      _buildInfoItem(
                        Icons.share,
                        'Tap share',
                        'Share stock info',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'GOT IT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.accentColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class StockReelCard extends StatefulWidget {
  final Map<String, dynamic> stock;
  final int index;
  final int currentPage;

  const StockReelCard({
    Key? key,
    required this.stock,
    required this.index,
    required this.currentPage,
  }) : super(key: key);

  @override
  State<StockReelCard> createState() => _StockReelCardState();
}

class _StockReelCardState extends State<StockReelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StockReelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPage == widget.index &&
        oldWidget.currentPage != widget.index) {
      _animationController.forward().then(
        (_) => _animationController.reverse(),
      );
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.stock['ticker']} added to favorites'),
          backgroundColor: AppTheme.accentColor,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPositive = widget.stock['change'] >= 0;
    final color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;

    return GestureDetector(
      onDoubleTap: _toggleFavorite,
      child: Container(
        height: size.height,
        width: size.width,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FuturisticCard(
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                // Chart Background with Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.stock['color'].withOpacity(0.6),
                        AppTheme.backgroundColor.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                      size: Size(size.width, size.height),
                      painter: ChartBackgroundPainter(
                        color: widget.stock['color'].withOpacity(0.3),
                      ),
                    ),
                  ),
                ),

                // Stock Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Section: Ticker and Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.stock['ticker'],
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      _isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color:
                                          _isFavorite
                                              ? Colors.red
                                              : AppTheme.textSecondary,
                                    ),
                                    onPressed: _toggleFavorite,
                                  ),
                                ],
                              ),
                              Text(
                                widget.stock['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${widget.stock['price']}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              StockPriceChange(
                                priceChange: widget.stock['change'],
                                percentChange: widget.stock['percentChange'],
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Chart Placeholder
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CustomPaint(
                              size: Size(size.width, 200),
                              painter: ChartPainter(
                                color: color,
                                stockIndex: widget.index,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Key Metrics
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Key Metrics Label
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Key Metrics',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRecommendationColor(
                                      widget.stock['recommendation'],
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    widget.stock['recommendation'],
                                    style: TextStyle(
                                      color: _getRecommendationColor(
                                        widget.stock['recommendation'],
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Metrics Grid
                            Expanded(
                              child: GridView.count(
                                crossAxisCount: 2,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _buildMetricItem(
                                    'Market Cap',
                                    widget.stock['marketCap'],
                                  ),
                                  _buildMetricItem(
                                    'P/E Ratio',
                                    widget.stock['pe'].toString(),
                                  ),
                                  _buildMetricItem(
                                    'Volume',
                                    _formatVolume(widget.stock['volume']),
                                  ),
                                  _buildMetricItem(
                                    'EPS',
                                    '\$${widget.stock['eps']}',
                                  ),
                                  _buildMetricItem(
                                    'Dividend',
                                    widget.stock['dividend'],
                                  ),
                                  _buildMetricItem(
                                    '52W High',
                                    '\$${widget.stock['high52W']}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // News Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.newspaper,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Latest News',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    widget.stock['news'],
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(
                            icon: Icons.analytics,
                            label: 'Analyze',
                            onTap: () {},
                          ),
                          _buildActionButton(
                            icon: Icons.candlestick_chart,
                            label: 'Chart',
                            onTap: () {},
                          ),
                          _buildActionButton(
                            icon: Icons.add_chart,
                            label: 'Add To',
                            onTap: () {},
                          ),
                          _buildActionButton(
                            icon: Icons.share,
                            label: 'Share',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Scroll Indicator
                Positioned(
                  right: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 50,
                            width: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Page Indicator
                Positioned(
                  left: 24,
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${widget.index + 1}/${_StockReelsScreenState()._stockReels.length}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.accentColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getRecommendationColor(String recommendation) {
    switch (recommendation) {
      case 'STRONG BUY':
        return const Color(0xFF00E676);
      case 'BUY':
        return AppTheme.positiveColor;
      case 'HOLD':
        return Colors.amber;
      case 'SELL':
        return AppTheme.negativeColor;
      case 'STRONG SELL':
        return const Color(0xFFFF1744);
      default:
        return AppTheme.textPrimary;
    }
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }
}

// Decorative Chart Painter for background
class ChartBackgroundPainter extends CustomPainter {
  final Color color;

  ChartBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    final path = Path();

    // Draw a sine wave line
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i < size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.5 + math.sin(i * 0.05) * 50 + math.cos(i * 0.03) * 50,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ChartBackgroundPainter oldDelegate) => false;
}

// Stock Chart Painter
class ChartPainter extends CustomPainter {
  final Color color;
  final int stockIndex;

  ChartPainter({required this.color, required this.stockIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    final fillPaint =
        Paint()
          ..color = color.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Generate random-ish but consistent points based on stockIndex as seed
    final random = math.Random(stockIndex);
    final List<double> points = List.generate(
      30,
      (i) => 0.5 + (random.nextDouble() - 0.5) * 0.5 + math.sin(i * 0.2) * 0.1,
    );

    // Create start point
    path.moveTo(0, size.height * (1 - points[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height * (1 - points[0]));

    // Create points along the path
    for (int i = 1; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height * (1 - points[i]);

      // Add some Bezier curve smoothing
      final prevX = size.width * ((i - 1) / (points.length - 1));
      final prevY = size.height * (1 - points[i - 1]);

      final controlX1 = prevX + (x - prevX) / 3;
      final controlX2 = prevX + (x - prevX) * 2 / 3;

      path.cubicTo(controlX1, prevY, controlX2, y, x, y);

      fillPath.cubicTo(controlX1, prevY, controlX2, y, x, y);
    }

    // Complete the fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    // Draw
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw price points
    for (int i = 0; i < points.length; i += 5) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height * (1 - points[i]);

      canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.white);

      canvas.drawCircle(Offset(x, y), 2, Paint()..color = color);
    }

    // Draw grid lines
    final gridPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Horizontal grid lines
    for (int i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid lines
    for (int i = 1; i < 6; i++) {
      final x = size.width * (i / 6);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) => false;
}

// screens/screener_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ScreenerScreen extends StatefulWidget {
  const ScreenerScreen({Key? key}) : super(key: key);

  @override
  State<ScreenerScreen> createState() => _ScreenerScreenState();
}

class _ScreenerScreenState extends State<ScreenerScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  String _selectedViewType = 'List';
  String _sortBy = 'Market Cap';

  // Filter values
  final List<String> _selectedSectors = [];
  RangeValues _marketCapRange = const RangeValues(0, 100);
  RangeValues _peRatioRange = const RangeValues(0, 100);
  RangeValues _priceRange = const RangeValues(0, 1000);
  RangeValues _volumeRange = const RangeValues(0, 10000000);

  // Sample data for the screener
  final List<Map<String, dynamic>> _stocks = [
    {
      'ticker': 'AAPL',
      'name': 'Apple Inc.',
      'sector': 'Technology',
      'price': 182.63,
      'change': 3.24,
      'percentChange': 1.81,
      'marketCap': 2850.5, // in billions
      'pe': 30.42,
      'volume': 74962145,
    },
    {
      'ticker': 'MSFT',
      'name': 'Microsoft Corporation',
      'sector': 'Technology',
      'price': 338.47,
      'change': -2.15,
      'percentChange': -0.63,
      'marketCap': 2520.1, // in billions
      'pe': 34.78,
      'volume': 25367418,
    },
    {
      'ticker': 'GOOGL',
      'name': 'Alphabet Inc.',
      'sector': 'Technology',
      'price': 142.57,
      'change': 1.42,
      'percentChange': 1.01,
      'marketCap': 1810.3, // in billions
      'pe': 25.13,
      'volume': 21456782,
    },
    {
      'ticker': 'AMZN',
      'name': 'Amazon.com, Inc.',
      'sector': 'Consumer Cyclical',
      'price': 174.36,
      'change': -0.87,
      'percentChange': -0.49,
      'marketCap': 1790.8, // in billions
      'pe': 60.24,
      'volume': 32547896,
    },
    {
      'ticker': 'TSLA',
      'name': 'Tesla, Inc.',
      'sector': 'Automotive',
      'price': 231.48,
      'change': 5.68,
      'percentChange': 2.52,
      'marketCap': 736.4, // in billions
      'pe': 83.17,
      'volume': 108761234,
    },
    {
      'ticker': 'META',
      'name': 'Meta Platforms, Inc.',
      'sector': 'Technology',
      'price': 474.32,
      'change': 8.76,
      'percentChange': 1.88,
      'marketCap': 1215.7, // in billions
      'pe': 32.56,
      'volume': 18436721,
    },
    {
      'ticker': 'NFLX',
      'name': 'Netflix, Inc.',
      'sector': 'Communication Services',
      'price': 591.65,
      'change': -3.42,
      'percentChange': -0.57,
      'marketCap': 258.3, // in billions
      'pe': 51.89,
      'volume': 5832641,
    },
    {
      'ticker': 'JPM',
      'name': 'JPMorgan Chase & Co.',
      'sector': 'Financial Services',
      'price': 183.27,
      'change': 2.13,
      'percentChange': 1.18,
      'marketCap': 530.6, // in billions
      'pe': 14.21,
      'volume': 12345632,
    },
    {
      'ticker': 'V',
      'name': 'Visa Inc.',
      'sector': 'Financial Services',
      'price': 273.54,
      'change': 0.86,
      'percentChange': 0.32,
      'marketCap': 560.2, // in billions
      'pe': 30.47,
      'volume': 7654318,
    },
    {
      'ticker': 'PG',
      'name': 'The Procter & Gamble Company',
      'sector': 'Consumer Defensive',
      'price': 162.83,
      'change': -0.43,
      'percentChange': -0.26,
      'marketCap': 384.1, // in billions
      'pe': 28.64,
      'volume': 6543217,
    },
  ];

  List<Map<String, dynamic>> get filteredStocks {
    return _stocks.where((stock) {
      // Apply sector filter
      if (_selectedSectors.isNotEmpty &&
          !_selectedSectors.contains(stock['sector'])) {
        return false;
      }

      // Apply market cap filter (in billions)
      if (stock['marketCap'] < _marketCapRange.start ||
          stock['marketCap'] > _marketCapRange.end) {
        return false;
      }

      // Apply P/E ratio filter
      if (stock['pe'] < _peRatioRange.start ||
          stock['pe'] > _peRatioRange.end) {
        return false;
      }

      // Apply price filter
      if (stock['price'] < _priceRange.start ||
          stock['price'] > _priceRange.end) {
        return false;
      }

      // Apply volume filter
      if (stock['volume'] < _volumeRange.start ||
          stock['volume'] > _volumeRange.end) {
        return false;
      }

      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        return stock['ticker'].toLowerCase().contains(query) ||
            stock['name'].toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  List<String> get allSectors {
    final sectors =
        _stocks.map((stock) => stock['sector'] as String).toSet().toList();
    sectors.sort();
    return sectors;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _toggleSector(String sector) {
    setState(() {
      if (_selectedSectors.contains(sector)) {
        _selectedSectors.remove(sector);
      } else {
        _selectedSectors.add(sector);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedSectors.clear();
      _marketCapRange = const RangeValues(0, 3000);
      _peRatioRange = const RangeValues(0, 100);
      _priceRange = const RangeValues(0, 1000);
      _volumeRange = const RangeValues(0, 150000000);
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
                      Icons.filter_list,
                      color: AppTheme.accentColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Stock Screener',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _showFilters ? Icons.filter_list_off : Icons.filter_alt,
                        color: AppTheme.accentColor,
                      ),
                      onPressed: _toggleFilters,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.save,
                        color: AppTheme.accentColor,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Search and View Type
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        controller: _searchController,
                        hintText: 'Search stocks...',
                        onChanged: (value) {
                          setState(() {});
                        },
                        onClear: () {
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _viewTypeButton(
                            icon: Icons.list,
                            isSelected: _selectedViewType == 'List',
                            onPressed: () {
                              setState(() {
                                _selectedViewType = 'List';
                              });
                            },
                          ),
                          _viewTypeButton(
                            icon: Icons.grid_view,
                            isSelected: _selectedViewType == 'Grid',
                            onPressed: () {
                              setState(() {
                                _selectedViewType = 'Grid';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filters
              if (_showFilters)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.restart_alt, size: 16),
                              label: const Text('Reset'),
                              onPressed: _resetFilters,
                            ),
                          ],
                        ),
                      ),

                      // Sectors
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          'Sectors',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: allSectors.map((sector) {
                            final isSelected =
                                _selectedSectors.contains(sector);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(sector),
                                selected: isSelected,
                                onSelected: (_) => _toggleSector(sector),
                                backgroundColor: AppTheme.backgroundColor,
                                selectedColor:
                                    AppTheme.accentColor.withOpacity(0.2),
                                checkmarkColor: AppTheme.accentColor,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppTheme.accentColor
                                      : AppTheme.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Market Cap Range
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Market Cap (Billion \$)', // Added backslash to escape the dollar sign
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${_marketCapRange.start.toInt()} - ${_marketCapRange.end.toInt()}',
                                  style: const TextStyle(
                                    color: AppTheme.accentColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            RangeSlider(
                              values: _marketCapRange,
                              min: 0,
                              max: 3000,
                              divisions: 30,
                              activeColor: AppTheme.accentColor,
                              inactiveColor:
                                  AppTheme.accentColor.withOpacity(0.2),
                              labels: RangeLabels(
                                '${_marketCapRange.start.toInt()}B',
                                '${_marketCapRange.end.toInt()}B',
                              ),
                              onChanged: (values) {
                                setState(() {
                                  _marketCapRange = values;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // P/E Ratio Range
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'P/E Ratio',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${_peRatioRange.start.toInt()} - ${_peRatioRange.end.toInt()}',
                                  style: const TextStyle(
                                    color: AppTheme.accentColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            RangeSlider(
                              values: _peRatioRange,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              activeColor: AppTheme.accentColor,
                              inactiveColor:
                                  AppTheme.accentColor.withOpacity(0.2),
                              labels: RangeLabels(
                                _peRatioRange.start.toInt().toString(),
                                _peRatioRange.end.toInt().toString(),
                              ),
                              onChanged: (values) {
                                setState(() {
                                  _peRatioRange = values;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // More filters button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('More Filters'),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),

              // Sort and Results Count
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredStocks.length} Results',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _sortBy,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: AppTheme.accentColor),
                      dropdownColor: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      underline: Container(
                        height: 1,
                        color: AppTheme.accentColor.withOpacity(0.3),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _sortBy = newValue!;
                        });
                      },
                      items: <String>[
                        'Market Cap',
                        'Price',
                        'Volume',
                        'P/E Ratio'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text('Sort by: $value'),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Stock List
              Expanded(
                child: _selectedViewType == 'List'
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredStocks.length,
                        itemBuilder: (context, index) {
                          final stock = filteredStocks[index];
                          return ScreenerListItem(
                            ticker: stock['ticker'],
                            name: stock['name'],
                            sector: stock['sector'],
                            price: stock['price'],
                            priceChange: stock['change'],
                            percentChange: stock['percentChange'],
                            marketCap: stock['marketCap'],
                            pe: stock['pe'],
                            volume: stock['volume'],
                            onTap: () {},
                          );
                        },
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredStocks.length,
                        itemBuilder: (context, index) {
                          final stock = filteredStocks[index];
                          return ScreenerGridItem(
                            ticker: stock['ticker'],
                            name: stock['name'],
                            sector: stock['sector'],
                            price: stock['price'],
                            priceChange: stock['change'],
                            percentChange: stock['percentChange'],
                            marketCap: stock['marketCap'],
                            onTap: () {},
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

  Widget _viewTypeButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}

class ScreenerListItem extends StatelessWidget {
  final String ticker;
  final String name;
  final String sector;
  final double price;
  final double priceChange;
  final double percentChange;
  final double marketCap;
  final double pe;
  final int volume;
  final VoidCallback onTap;

  const ScreenerListItem({
    Key? key,
    required this.ticker,
    required this.name,
    required this.sector,
    required this.price,
    required this.priceChange,
    required this.percentChange,
    required this.marketCap,
    required this.pe,
    required this.volume,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FuturisticCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticker, Name, and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticker,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StockPriceChange(
                      priceChange: priceChange,
                      percentChange: percentChange,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.backgroundColor),
            const SizedBox(height: 12),

            // Key Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metricColumn('Sector', sector),
                _metricColumn(
                    'Market Cap', '\$${marketCap.toStringAsFixed(1)}B'),
                _metricColumn('P/E Ratio', pe.toStringAsFixed(2)),
                _metricColumn('Volume', _formatVolume(volume)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
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

class ScreenerGridItem extends StatelessWidget {
  final String ticker;
  final String name;
  final String sector;
  final double price;
  final double priceChange;
  final double percentChange;
  final double marketCap;
  final VoidCallback onTap;

  const ScreenerGridItem({
    Key? key,
    required this.ticker,
    required this.name,
    required this.sector,
    required this.price,
    required this.priceChange,
    required this.percentChange,
    required this.marketCap,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = priceChange >= 0;
    final color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor;

    return FuturisticCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ticker,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sector,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Price Section
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                StockPriceChange(
                  priceChange: priceChange,
                  percentChange: percentChange,
                  compactMode: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Spacer(),

          // Market Cap
          Row(
            children: [
              const Text(
                'Market Cap: ',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '\$${marketCap.toStringAsFixed(1)}B',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

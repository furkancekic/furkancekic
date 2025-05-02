// screens/add_position_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/portfolio_service.dart';
import '../services/stock_api_service.dart';

class AddPositionScreen extends StatefulWidget {
  final String portfolioId;

  const AddPositionScreen({
    Key? key,
    required this.portfolioId,
  }) : super(key: key);

  @override
  State<AddPositionScreen> createState() => _AddPositionScreenState();
}

class _AddPositionScreenState extends State<AddPositionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tickerController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isAutoFetchingPrice = false;
  bool _isSearching = false;
  List<SearchResult> _searchResults = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Initialize date field
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Add listeners
    _tickerController.addListener(_onTickerChanged);
  }

  @override
  void dispose() {
    _tickerController.removeListener(_onTickerChanged);
    _tickerController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTickerChanged() {
    // Cancel any price fetching
    setState(() {
      _isAutoFetchingPrice = false;
    });

    // Perform search if ticker contains at least 2 characters
    final query = _tickerController.text.trim();
    if (query.length >= 2) {
      _performSearch(query);
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await StockApiService.searchStocks(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _selectTicker(String ticker, String name) {
    setState(() {
      _tickerController.text = ticker;
      _searchResults = [];
    });
    _fetchStockPrice(ticker);
  }

  Future<void> _fetchStockPrice(String ticker) async {
    setState(() {
      _isAutoFetchingPrice = true;
      _isLoading = true;
    });

    try {
      final stockInfo = await StockApiService.getStockInfo(ticker);
      if (mounted && _isAutoFetchingPrice) {
        setState(() {
          _priceController.text = stockInfo.price.toStringAsFixed(2);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Could not fetch current price. Please enter manually.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentColor,
              onPrimary: Colors.black,
              surface: AppTheme.cardColor,
              onSurface: AppTheme.textPrimary,
            ),
            dialogBackgroundColor: AppTheme.backgroundColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await PortfolioService.addPosition(
        portfolioId: widget.portfolioId,
        ticker: _tickerController.text.trim().toUpperCase(),
        quantity: double.parse(_quantityController.text.trim()),
        price: double.parse(_priceController.text.trim()),
        date: _selectedDate,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position added successfully'),
            backgroundColor: AppTheme.positiveColor,
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add position: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final textPrim = ext?.textPrimary ?? AppTheme.textPrimary;
    final accent = ext?.accentColor ?? AppTheme.accentColor;
    final cardColor = ext?.cardColor ?? AppTheme.cardColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Position',
          style: TextStyle(
            color: textPrim,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: accent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFF192138),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () =>
              FocusScope.of(context).unfocus(), // Dismiss keyboard on tap
          child: Stack(
            children: [
              // Main form
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Ticker Field
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrim,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Ticker input
                          Text(
                            'Ticker Symbol',
                            style: TextStyle(
                              fontSize: 14,
                              color: textPrim,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _tickerController,
                            style: TextStyle(color: textPrim),
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  AppTheme.backgroundColor.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Enter ticker symbol (e.g. AAPL)',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.5),
                              ),
                              suffixIcon: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: CircularProgressIndicator(
                                          color: accent,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ticker symbol is required';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              // Autocapitalize
                              final upperValue = value.toUpperCase();
                              if (value != upperValue) {
                                _tickerController.value = TextEditingValue(
                                  text: upperValue,
                                  selection: TextSelection.collapsed(
                                      offset: upperValue.length),
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          // Quantity input
                          Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: 14,
                              color: textPrim,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _quantityController,
                            style: TextStyle(color: textPrim),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,6}')),
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  AppTheme.backgroundColor.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Enter number of shares',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Quantity is required';
                              }
                              try {
                                final quantity = double.parse(value);
                                if (quantity <= 0) {
                                  return 'Quantity must be greater than zero';
                                }
                              } catch (e) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Purchase price
                          Text(
                            'Purchase Price (per share)',
                            style: TextStyle(
                              fontSize: 14,
                              color: textPrim,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceController,
                            style: TextStyle(color: textPrim),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  AppTheme.backgroundColor.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              prefixText: '\$ ',
                              prefixStyle: TextStyle(color: textPrim),
                              hintText: 'Enter purchase price',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Purchase price is required';
                              }
                              try {
                                final price = double.parse(value);
                                if (price <= 0) {
                                  return 'Price must be greater than zero';
                                }
                              } catch (e) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Transaction details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrim,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Purchase date
                          Text(
                            'Purchase Date',
                            style: TextStyle(
                              fontSize: 14,
                              color: textPrim,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectDate,
                            child: IgnorePointer(
                              child: TextFormField(
                                controller: _dateController,
                                style: TextStyle(color: textPrim),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      AppTheme.backgroundColor.withOpacity(0.3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.calendar_today,
                                    color: accent,
                                  ),
                                  hintStyle: TextStyle(
                                    color:
                                        AppTheme.textSecondary.withOpacity(0.5),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Purchase date is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Notes
                          Text(
                            'Notes (Optional)',
                            style: TextStyle(
                              fontSize: 14,
                              color: textPrim,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _notesController,
                            style: TextStyle(color: textPrim),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  AppTheme.backgroundColor.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Add notes about this position',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.5),
                              ),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Total investment calculator
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Investment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTotalInvestment(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Add button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: accent.withOpacity(0.5),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'ADD POSITION',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // Search results overlay
              if (_searchResults.isNotEmpty)
                Positioned(
                  top: 135, // Adjust based on ticker field position
                  left: 16,
                  right: 16,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          title: Text(
                            result.symbol,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            result.name,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () =>
                              _selectTicker(result.symbol, result.name),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalInvestment() {
    double quantity = 0;
    double price = 0;

    try {
      quantity = double.tryParse(_quantityController.text) ?? 0;
      price = double.tryParse(_priceController.text) ?? 0;
    } catch (_) {
      // Ignore parse errors for calculation
    }

    final totalInvestment = quantity * price;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$quantity shares × \$${price.toStringAsFixed(2)} =',
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          '\$${totalInvestment.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.accentColor,
          ),
        ),
      ],
    );
  }
}

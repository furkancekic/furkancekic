// screens/add_position_screen.dart - Enhanced version with debouncing
import 'dart:async'; // Add this import
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
  bool _isValidatingTicker = false;
  bool _isFetchingPrice = false;
  bool _isSearching = false;
  bool _useHistoricalPrice = true;

  // Debouncing variables
  Timer? _searchDebounceTimer;
  Timer? _validationDebounceTimer;
  Timer? _priceDebounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 800); // 800ms delay

  List<SearchResult> _searchResults = [];
  DateTime _selectedDate = DateTime.now();
  TickerValidationResult? _validationResult;
  PriceForDateResult? _priceResult;

  @override
  void initState() {
    super.initState();
    // Initialize date field
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Add listeners
    _tickerController.addListener(_onTickerChangedDebounced);
    _dateController.addListener(_onDateChanged);
  }

  @override
  void dispose() {
    // Cancel any pending timers
    _searchDebounceTimer?.cancel();
    _validationDebounceTimer?.cancel();
    _priceDebounceTimer?.cancel();
    
    _tickerController.removeListener(_onTickerChangedDebounced);
    _dateController.removeListener(_onDateChanged);
    _tickerController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTickerChangedDebounced() {
    final query = _tickerController.text.trim();
    
    // Cancel previous timers
    _searchDebounceTimer?.cancel();
    _validationDebounceTimer?.cancel();
    _priceDebounceTimer?.cancel();

    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _validationResult = null;
        _priceResult = null;
        _isSearching = false;
        _isValidatingTicker = false;
        _isFetchingPrice = false;
      });
      if (_useHistoricalPrice) {
        _priceController.clear();
      }
      return;
    }

    // Show loading indicators immediately
    setState(() {
      _isSearching = true;
      _isValidatingTicker = true;
    });

    // Set up debounced timers
    _searchDebounceTimer = Timer(_debounceDuration, () {
      if (mounted) {
        _performSearch(query);
      }
    });

    _validationDebounceTimer = Timer(_debounceDuration, () {
      if (mounted) {
        _validateTicker(query);
      }
    });
  }

  void _onDateChanged() {
    // Cancel previous timer
    _priceDebounceTimer?.cancel();
    
    if (_useHistoricalPrice && _validationResult?.isValid == true) {
      setState(() {
        _isFetchingPrice = true;
      });
      
      _priceDebounceTimer = Timer(_debounceDuration, () {
        if (mounted) {
          _fetchPriceForDate();
        }
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

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

  Future<void> _validateTicker(String ticker) async {
    if (ticker.isEmpty || !mounted) return;

    try {
      final result = await StockApiService.validateTicker(ticker);
      if (mounted) {
        setState(() {
          _validationResult = result;
          _isValidatingTicker = false;
        });

        if (result.isValid && _useHistoricalPrice) {
          // Start price fetching with a small delay
          setState(() {
            _isFetchingPrice = true;
          });
          
          _priceDebounceTimer = Timer(const Duration(milliseconds: 300), () {
            if (mounted) {
              _fetchPriceForDate();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationResult = TickerValidationResult(
            isValid: false,
            ticker: ticker,
            errorMessage: 'Error validating ticker: $e',
          );
          _isValidatingTicker = false;
        });
      }
    }
  }

  Future<void> _fetchPriceForDate() async {
    if (_validationResult?.isValid != true || !mounted) return;

    try {
      final result = await StockApiService.getPriceForDate(
        _validationResult!.ticker,
        _selectedDate,
      );

      if (mounted) {
        setState(() {
          _priceResult = result;
          _isFetchingPrice = false;
        });

        if (result.success && result.price != null) {
          _priceController.text = result.price!.toStringAsFixed(2);
        } else {
          _priceController.clear();
          if (result.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage!),
                backgroundColor: AppTheme.warningColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingPrice = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching price: $e'),
            backgroundColor: AppTheme.negativeColor,
          ),
        );
      }
    }
  }

  void _selectTicker(String ticker, String name) {
    // Cancel any pending timers
    _searchDebounceTimer?.cancel();
    _validationDebounceTimer?.cancel();
    _priceDebounceTimer?.cancel();

    setState(() {
      _tickerController.text = ticker;
      _searchResults = [];
      _isSearching = false;
      _isValidatingTicker = true; // Show loading for validation
    });
    
    // Immediately validate the selected ticker
    _validateTicker(ticker);
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

    // Additional validation for ticker
    if (_validationResult?.isValid != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid ticker symbol'),
          backgroundColor: AppTheme.negativeColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Determine price based on mode
      double? priceToSend;

      if (_useHistoricalPrice) {
        // In automatic mode, check if we have a fetched price
        if (_priceResult?.success == true && _priceResult?.price != null) {
          priceToSend = _priceResult!.price;
        } else {
          // If no historical price available, let server handle it (send null)
          priceToSend = null;
        }
      } else {
        // In manual mode, use the user-entered price
        if (_priceController.text.trim().isNotEmpty) {
          priceToSend = double.parse(_priceController.text.trim());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a purchase price'),
              backgroundColor: AppTheme.negativeColor,
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }

      await PortfolioService.addPosition(
        portfolioId: widget.portfolioId,
        ticker: _tickerController.text.trim().toUpperCase(),
        quantity: double.parse(_quantityController.text.trim()),
        price: priceToSend, // Can be null for historical price mode
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
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              // Main form
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Stock Information
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
                            style: TextStyle(fontSize: 14, color: textPrim),
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
                              suffixIcon: _isValidatingTicker
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
                                  : _validationResult?.isValid == true
                                      ? Icon(Icons.check_circle,
                                          color: AppTheme.positiveColor)
                                      : _validationResult?.isValid == false
                                          ? Icon(Icons.error,
                                              color: AppTheme.negativeColor)
                                          : null,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ticker symbol is required';
                              }
                              if (_validationResult?.isValid != true) {
                                return 'Invalid ticker symbol';
                              }
                              return null;
                            },
                            onChanged: (value) {
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

                          // Validation result display
                          if (_validationResult != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _validationResult!.isValid
                                    ? AppTheme.positiveColor.withOpacity(0.1)
                                    : AppTheme.negativeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _validationResult!.isValid
                                      ? AppTheme.positiveColor
                                      : AppTheme.negativeColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _validationResult!.isValid
                                        ? Icons.check
                                        : Icons.error,
                                    color: _validationResult!.isValid
                                        ? AppTheme.positiveColor
                                        : AppTheme.negativeColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _validationResult!.isValid
                                          ? '${_validationResult!.name} - ${_validationResult!.exchange}'
                                          : _validationResult!.errorMessage ??
                                              'Invalid ticker',
                                      style: TextStyle(
                                        color: _validationResult!.isValid
                                            ? AppTheme.positiveColor
                                            : AppTheme.negativeColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Quantity input
                          Text('Quantity',
                              style: TextStyle(fontSize: 14, color: textPrim)),
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Transaction Details
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
                          Text('Purchase Date',
                              style: TextStyle(fontSize: 14, color: textPrim)),
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
                                  suffixIcon:
                                      Icon(Icons.calendar_today, color: accent),
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

                          // Price mode toggle
                          Row(
                            children: [
                              Text('Price Mode',
                                  style:
                                      TextStyle(fontSize: 14, color: textPrim)),
                              const Spacer(),
                              Switch(
                                value: _useHistoricalPrice,
                                onChanged: (value) {
                                  setState(() {
                                    _useHistoricalPrice = value;
                                    if (value &&
                                        _validationResult?.isValid == true) {
                                      _fetchPriceForDate();
                                    } else {
                                      _priceController.clear();
                                      _priceResult = null;
                                    }
                                  });
                                },
                                activeColor: accent,
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            _useHistoricalPrice
                                ? 'Automatic: Fetch historical price for the selected date'
                                : 'Manual: Enter purchase price manually',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Purchase price
                          Row(
                            children: [
                              Text('Purchase Price (per share)',
                                  style:
                                      TextStyle(fontSize: 14, color: textPrim)),
                              if (_isFetchingPrice) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    color: accent,
                                    strokeWidth: 1.5,
                                  ),
                                ),
                              ],
                            ],
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
                            enabled: !_useHistoricalPrice ||
                                (_priceResult?.success != true),
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
                              hintText: _useHistoricalPrice
                                  ? 'Will be fetched automatically'
                                  : 'Enter purchase price',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.5),
                              ),
                              suffixIcon: _useHistoricalPrice &&
                                      _priceResult?.success == true
                                  ? Icon(Icons.auto_awesome,
                                      color: AppTheme.positiveColor)
                                  : null,
                            ),
                            validator: (value) {
                              if (!_useHistoricalPrice) {
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
                              }
                              return null;
                            },
                          ),

                          // Price result display
                          if (_priceResult != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _priceResult!.success
                                    ? AppTheme.positiveColor.withOpacity(0.1)
                                    : AppTheme.warningColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _priceResult!.success
                                      ? AppTheme.positiveColor
                                      : AppTheme.warningColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _priceResult!.success
                                        ? Icons.check
                                        : Icons.warning,
                                    color: _priceResult!.success
                                        ? AppTheme.positiveColor
                                        : AppTheme.warningColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _priceResult!.success
                                          ? 'Price fetched: ${_priceResult!.formattedPrice} for ${_priceResult!.date}'
                                          : _priceResult!.errorMessage ??
                                              'Could not fetch price',
                                      style: TextStyle(
                                        color: _priceResult!.success
                                            ? AppTheme.positiveColor
                                            : AppTheme.warningColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Notes
                          Text('Notes (Optional)',
                              style: TextStyle(fontSize: 14, color: textPrim)),
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
                    _buildTotalInvestmentCalculator(),

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
                  top: 135,
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
                            style:
                                const TextStyle(color: AppTheme.textSecondary),
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

              // Searching indicator overlay
              if (_isSearching && _searchResults.isEmpty)
                Positioned(
                  top: 135,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: accent,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Searching...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalInvestmentCalculator() {
    double quantity = 0;
    double price = 0;

    try {
      quantity = double.tryParse(_quantityController.text) ?? 0;
      price = double.tryParse(_priceController.text) ?? 0;
    } catch (_) {
      // Ignore parse errors for calculation
    }

    final totalInvestment = quantity * price;

    return Container(
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
          Row(
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
          ),
          if (_useHistoricalPrice &&
              _priceResult == null &&
              _validationResult?.isValid == true) ...[
            const SizedBox(height: 8),
            Text(
              'Price will be calculated automatically based on the selected date',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
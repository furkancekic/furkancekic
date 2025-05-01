import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/stock_api_service.dart';

class IntradayChart extends StatefulWidget {
  final String ticker;
  final double height;
  final double width;

  const IntradayChart({
    Key? key,
    required this.ticker,
    this.height = 150.0,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  State<IntradayChart> createState() => _IntradayChartState();
}

class _IntradayChartState extends State<IntradayChart> {
  List<Map<String, dynamic>> _chartData = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final data = await StockApiService.getIntradayChartData(widget.ticker);

      if (mounted) {
        setState(() {
          _chartData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      print('Error loading intraday chart data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ThemeExtension'dan renkleri al
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final cardColor = themeExtension?.cardColor ?? AppTheme.cardColor;
    final accentColor = themeExtension?.accentColor ?? AppTheme.accentColor;
    final textPrimary = themeExtension?.textPrimary ?? AppTheme.textPrimary;
    final textSecondary =
        themeExtension?.textSecondary ?? AppTheme.textSecondary;
    final positiveColor =
        themeExtension?.positiveColor ?? AppTheme.positiveColor;
    final negativeColor =
        themeExtension?.negativeColor ?? AppTheme.negativeColor;

    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: Center(
          child: CircularProgressIndicator(
            color: accentColor,
          ),
        ),
      );
    }

    if (_hasError || _chartData.isEmpty) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: Center(
          child: TextButton.icon(
            onPressed: _loadChartData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      );
    }

    // Calculate if the price trend is positive
    final firstPrice = _chartData.first['price'] as double;
    final lastPrice = _chartData.last['price'] as double;
    final isPositive = lastPrice >= firstPrice;

    // Determine line color based on trend
    final lineColor = isPositive ? positiveColor : negativeColor;

    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.ticker,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  lastPrice.toStringAsFixed(2),
                  style: TextStyle(
                    color: isPositive ? positiveColor : negativeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CustomPaint(
                size: Size(widget.width, widget.height - 50),
                painter: IntradayChartPainter(
                  data: _chartData,
                  lineColor: lineColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _chartData.first['time']
                      .toString()
                      .substring(11, 16), // Extract HH:MM
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  _chartData.last['time']
                      .toString()
                      .substring(11, 16), // Extract HH:MM
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
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

class IntradayChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color lineColor;

  IntradayChartPainter({
    required this.data,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) {
      return;
    }

    // Find min and max values for scaling
    double minValue = double.infinity;
    double maxValue = -double.infinity;

    for (var point in data) {
      final price = point['price'] as double;
      minValue = minValue > price ? price : minValue;
      maxValue = maxValue < price ? price : maxValue;
    }

    // Add a small buffer to min/max for better visualization
    final range = maxValue - minValue;
    minValue -= range * 0.05;
    maxValue += range * 0.05;

    // Ensure we have a range (avoid division by zero)
    if (maxValue - minValue < 0.000001) {
      maxValue = minValue + 1.0;
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = lineColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Calculate horizontal step size
    final double xStep = size.width / (data.length - 1);

    // Start path at the first point
    final double initialX = 0;
    final double initialY = size.height -
        ((data[0]['price'] as double) - minValue) /
            (maxValue - minValue) *
            size.height;

    path.moveTo(initialX, initialY);
    fillPath.moveTo(initialX, size.height);
    fillPath.lineTo(initialX, initialY);

    // Add points to the path
    for (int i = 1; i < data.length; i++) {
      final double x = xStep * i;
      final double y = size.height -
          ((data[i]['price'] as double) - minValue) /
              (maxValue - minValue) *
              size.height;
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    // Close fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw the fill first
    canvas.drawPath(fillPath, fillPaint);

    // Then draw the line
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(IntradayChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.lineColor != lineColor;
  }
}

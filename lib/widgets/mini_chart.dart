import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MiniChart extends StatelessWidget {
  final List<double> data;
  final bool isPositive;
  final double height;
  final double width;
  final bool showGradient;

  const MiniChart({
    Key? key,
    required this.data,
    required this.isPositive,
    this.height = 40,
    this.width = 80,
    this.showGradient = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If there's no data or only one point, return an empty container
    if (data.isEmpty || data.length < 2) {
      return SizedBox(height: height, width: width);
    }

    // ThemeExtension'dan renkleri al
    final themeExtension = Theme.of(context).extension<AppThemeExtension>();
    final lineColor = isPositive
        ? (themeExtension?.positiveColor ?? AppTheme.positiveColor)
        : (themeExtension?.negativeColor ?? AppTheme.negativeColor);

    return Container(
      height: height,
      width: width,
      decoration: showGradient
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  lineColor.withOpacity(0.25), // Adjusted opacity
                  lineColor.withOpacity(0.0),   // Fade to transparent
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: CustomPaint(
        size: Size(width, height),
        painter: ChartPainter(
          data: data,
          lineColor: lineColor,
        ),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  ChartPainter({
    required this.data,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) {
      return;
    }

    // Find min and max values for scaling
    double minValue = data.reduce((curr, next) => curr < next ? curr : next);
    double maxValue = data.reduce((curr, next) => curr > next ? curr : next);

    // Ensure we have a range (avoid division by zero)
    if (maxValue - minValue < 0.000001) {
      maxValue = minValue + 1.0;
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 // Changed from 2.0 to 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Calculate horizontal step size
    final double xStep = size.width / (data.length - 1);

    // Start path at the first point
    final double initialX = 0;
    final double initialY = size.height -
        (data[0] - minValue) / (maxValue - minValue) * size.height;
    path.moveTo(initialX, initialY);

    // Add points to the path
    for (int i = 1; i < data.length; i++) {
      final double x = xStep * i;
      final double y = size.height -
          (data[i] - minValue) / (maxValue - minValue) * size.height;
      path.lineTo(x, y);
    }

    // Draw the path
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.lineColor != lineColor;
  }
}

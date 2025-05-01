import 'package:flutter/material.dart';

class TechnicalIndicator {
  final String type;
  final String name;
  final Color color;
  final double width;
  final List<double> dashArray;

  const TechnicalIndicator({
    required this.type,
    required this.name,
    required this.color,
    this.width = 2,
    this.dashArray = const <double>[0, 0], // ← varsayılan
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
    };
  }
}

class MovingAverageIndicator {
  final String type; // SMA veya EMA
  final int period;
  final List<double> values;
  final List<DateTime> dates;

  MovingAverageIndicator({
    required this.type,
    required this.period,
    required this.values,
    required this.dates,
  });

  factory MovingAverageIndicator.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataPoints = json['data'] as List;
    final List<double> values = [];
    final List<DateTime> dates = [];

    for (var point in dataPoints) {
      values.add(point['value'].toDouble());
      dates.add(DateTime.parse(point['date']));
    }

    return MovingAverageIndicator(
      type: json['type'],
      period: json['period'],
      values: values,
      dates: dates,
    );
  }
}

class BollingerBands {
  final List<double> upper;
  final List<double> middle;
  final List<double> lower;
  final List<DateTime> dates;

  BollingerBands({
    required this.upper,
    required this.middle,
    required this.lower,
    required this.dates,
  });

  factory BollingerBands.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataPoints = json['data'] as List;
    final List<double> upper = [];
    final List<double> middle = [];
    final List<double> lower = [];
    final List<DateTime> dates = [];

    for (var point in dataPoints) {
      upper.add(point['upper'].toDouble());
      middle.add(point['middle'].toDouble());
      lower.add(point['lower'].toDouble());
      dates.add(DateTime.parse(point['date']));
    }

    return BollingerBands(
      upper: upper,
      middle: middle,
      lower: lower,
      dates: dates,
    );
  }
}

class RsiIndicator {
  final List<double> values;
  final List<DateTime> dates;

  RsiIndicator({
    required this.values,
    required this.dates,
  });

  factory RsiIndicator.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataPoints = json['data'] as List;
    final List<double> values = [];
    final List<DateTime> dates = [];

    for (var point in dataPoints) {
      values.add(point['value'].toDouble());
      dates.add(DateTime.parse(point['date']));
    }

    return RsiIndicator(
      values: values,
      dates: dates,
    );
  }
}

class MacdIndicator {
  final List<double> macdLine;
  final List<double> signalLine;
  final List<double> histogram;
  final List<DateTime> dates;

  MacdIndicator({
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
    required this.dates,
  });

  factory MacdIndicator.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataPoints = json['data'] as List;
    final List<double> macdLine = [];
    final List<double> signalLine = [];
    final List<double> histogram = [];
    final List<DateTime> dates = [];

    for (var point in dataPoints) {
      macdLine.add(point['macd'].toDouble());
      signalLine.add(point['signal'].toDouble());
      histogram.add(point['histogram'].toDouble());
      dates.add(DateTime.parse(point['date']));
    }

    return MacdIndicator(
      macdLine: macdLine,
      signalLine: signalLine,
      histogram: histogram,
      dates: dates,
    );
  }
}

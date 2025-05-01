class CandleData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  CandleData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory CandleData.fromJson(Map<String, dynamic> json) {
    return CandleData(
      date: DateTime.parse(json['Date']),
      open: json['Open'].toDouble(),
      high: json['High'].toDouble(),
      low: json['Low'].toDouble(),
      close: json['Close'].toDouble(),
      volume: json['Volume'] is int ? json['Volume'] : json['Volume'].toInt(),
    );
  }
}

// models/position.dart
import 'transaction.dart';

class Position {
  final String? id;
  final String ticker;
  final String? companyName;
  final double quantity;
  final double averagePrice;
  final double? currentPrice;
  final DateTime purchaseDate;
  final List<Transaction> transactions;
  List<double>? performanceData;
  final double? currentValue;
  final double? gainLoss;
  final double? gainLossPercent;
  final String? notes;

  Position({
    this.id,
    required this.ticker,
    this.companyName,
    required this.quantity,
    required this.averagePrice,
    this.currentPrice,
    required this.purchaseDate,
    this.transactions = const [],
    this.performanceData,
    this.currentValue,
    this.gainLoss,
    this.gainLossPercent,
    this.notes,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'],
      ticker: json['ticker'] ?? '',
      companyName: json['company_name'],
      quantity: json['quantity']?.toDouble() ?? 0.0,
      averagePrice: json['average_price']?.toDouble() ?? 0.0,
      currentPrice: json['current_price']?.toDouble(),
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : DateTime.now(),
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((transJson) => Transaction.fromJson(transJson))
              .toList()
          : [],
      performanceData: json['performance_data'] != null
          ? (json['performance_data'] as List)
              .map((p) => p == null ? 0.0 : double.parse(p.toString()))
              .toList()
          : null,
      currentValue: json['current_value']?.toDouble(),
      gainLoss: json['gain_loss']?.toDouble(),
      gainLossPercent: json['gain_loss_percent']?.toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ticker': ticker,
      if (companyName != null) 'company_name': companyName,
      'quantity': quantity,
      'average_price': averagePrice,
      if (currentPrice != null) 'current_price': currentPrice,
      'purchase_date': purchaseDate.toIso8601String(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      if (performanceData != null) 'performance_data': performanceData,
      if (currentValue != null) 'current_value': currentValue,
      if (gainLoss != null) 'gain_loss': gainLoss,
      if (gainLossPercent != null) 'gain_loss_percent': gainLossPercent,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

// models/transaction.dart
enum TransactionType {
  buy,
  sell,
  dividend,
  split,
}

class Transaction {
  final String? id;
  final TransactionType type;
  final double quantity;
  final double price;
  final DateTime date;
  final String? notes;

  Transaction({
    this.id,
    required this.type,
    required this.quantity,
    required this.price,
    required this.date,
    this.notes,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: _parseTransactionType(json['type']),
      quantity: json['quantity']?.toDouble() ?? 0.0,
      price: json['price']?.toDouble() ?? 0.0,
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'price': price,
      'date': date.toIso8601String(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  static TransactionType _parseTransactionType(String? typeStr) {
    if (typeStr == null) return TransactionType.buy;

    switch (typeStr.toLowerCase()) {
      case 'sell':
        return TransactionType.sell;
      case 'dividend':
        return TransactionType.dividend;
      case 'split':
        return TransactionType.split;
      case 'buy':
      default:
        return TransactionType.buy;
    }
  }
}

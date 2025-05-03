// models/portfolio.dart
import 'position.dart';

class Portfolio {
  final String? id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Position> positions;
  final double? totalValue;
  final double? totalGainLoss;
  final double? totalGainLossPercent;

  Portfolio({
    this.id,
    required this.name,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.positions = const [],
    this.totalValue,
    this.totalGainLoss,
    this.totalGainLossPercent,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      positions: json['positions'] != null
          ? (json['positions'] as List)
              .map((posJson) => Position.fromJson(posJson))
              .toList()
          : [],
      totalValue: json['total_value']?.toDouble(),
      totalGainLoss: json['total_gain_loss']?.toDouble(),
      totalGainLossPercent: json['total_gain_loss_percent']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'positions': positions.map((p) => p.toJson()).toList(),
      if (totalValue != null) 'total_value': totalValue,
      if (totalGainLoss != null) 'total_gain_loss': totalGainLoss,
      if (totalGainLossPercent != null)
        'total_gain_loss_percent': totalGainLossPercent,
    };
  }
}

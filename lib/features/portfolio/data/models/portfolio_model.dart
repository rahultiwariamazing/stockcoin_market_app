// File: lib/features/portfolio/data/models/portfolio_model.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

/// ✅ Portfolio Model
class PortfolioModel {

  final String id;
  final String name;
  final String symbol;
  final String image;
  final double price;
  final double quantity;
  final DateTime date;

  PortfolioModel({
    required this.id,
    required this.name,
    required this.symbol,
    required this.image,
    required this.price,
    required this.quantity,
    required this.date,
  });

  /// ✅ Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'image': image,
      'price': price,
      'quantity': quantity,
      'date': date.toIso8601String(),
    };
  }

  /// ✅ ✅ FIXED: Strong typing enforced
  factory PortfolioModel.fromMap(Map<String, dynamic> map) {
    return PortfolioModel(
      id: map['id'] as String,
      name: map['name'] as String,
      symbol: map['symbol'] as String,
      image: (map['image'] ?? '') as String,
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }
} 
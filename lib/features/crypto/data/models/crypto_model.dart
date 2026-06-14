// File: lib/features/crypto/data/models/crypto_model.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

// Model to map API response (object representation)

class CryptoModel {
  final String id;
  final String name;
  final String symbol;
  final String image;
  final double currentPrice;
  final double priceChangePercentage;

  CryptoModel({
    required this.id,
    required this.name,
    required this.symbol,
    required this.image,
    required this.currentPrice,
    required this.priceChangePercentage,
  });

  // ✅ Convert JSON → Object
  factory CryptoModel.fromJson(Map<String, dynamic> json) {
    return CryptoModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      image: json['image'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      priceChangePercentage:
          (json['price_change_percentage_24h'] ?? 0).toDouble(),
    );
  }
}

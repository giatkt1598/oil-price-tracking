import 'fuel_price.dart';

class FuelPriceSnapshot {
  const FuelPriceSnapshot({required this.updatedAt, required this.products});

  final DateTime updatedAt;
  final List<FuelPrice> products;

  DateTime get displayUpdatedAt {
    final time = updatedAt.toLocal();
    var hours = time.hour;
    var minutes = time.minute;
    if (minutes > 50) {
      hours++;
      if (hours > 24) {
        hours = 0;
      }
      minutes = 0;
    } else {
      minutes = minutes >= 45
          ? 45
          : minutes >= 30
          ? 30
          : minutes >= 15
          ? 15
          : 0;
    }
    return DateTime(time.year, time.month, time.day, hours, minutes);
  }

  factory FuelPriceSnapshot.fromJson(Map<String, dynamic> json) {
    final productsJson = json['products'];
    final products = productsJson is List
        ? productsJson
              .whereType<Map<String, dynamic>>()
              .map(FuelPrice.fromJson)
              .toList()
        : <FuelPrice>[];
    products.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return FuelPriceSnapshot(
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      products: products,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'products': products.map((price) => price.toJson()).toList(),
    };
  }
}

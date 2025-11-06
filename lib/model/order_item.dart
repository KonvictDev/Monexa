import 'package:hive/hive.dart';

part 'order_item.g.dart';

@HiveType(typeId: 2) // Unique typeId
class OrderItem extends HiveObject {
  @HiveField(0)
  late String productId;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double price;

  @HiveField(3)
  late int quantity;

  // --- NEW FIELD FOR CATEGORY ---
  @HiveField(4)
  late String category;
  // --- END NEW FIELD ---

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.category, // <-- ADD THIS
  });

  // --- NEW METHOD FOR FIRESTORE SYNC ---
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category, // <-- ADD THIS
      'subtotal': price * quantity,
    };
  }

  // lib/model/order_item.dart

// ... existing code ...

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      name: json['name'] as String,
      price: json['price'] as double,
      quantity: json['quantity'] as int,
      category: json['category'] as String? ?? 'Uncategorized', // <-- ADD THIS
    );
  }
}
// -------------------------------------
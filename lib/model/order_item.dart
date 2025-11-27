import 'package:hive/hive.dart';

part 'order_item.g.dart';

@HiveType(typeId: 2)
class OrderItem extends HiveObject {
  @HiveField(0)
  late String productId;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double price;

  @HiveField(3)
  late int quantity;

  @HiveField(4)
  late String category;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category,
      'subtotal': price * quantity,
    };
  }

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
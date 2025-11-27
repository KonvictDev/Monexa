import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double price;

  @HiveField(3)
  late String description;

  @HiveField(4)
  late String imagePath;

  @HiveField(5)
  late int quantity;

  @HiveField(6)
  String? thumbnailPath;

  @HiveField(7)
  String? imageCloudUrl;

  @HiveField(8)
  String? thumbnailCloudUrl;

  @HiveField(9)
  late String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    this.imagePath = '',
    this.quantity = 0,
    this.thumbnailPath,
    this.imageCloudUrl,
    this.thumbnailCloudUrl,
  });

  // --- NEW METHOD FOR FIRESTORE SYNC ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'quantity': quantity,
      'category': category,
      'imageCloudUrl': imageCloudUrl,
      'thumbnailCloudUrl': thumbnailCloudUrl,
      'localImagePath': imagePath,
      'localThumbnailPath': thumbnailPath,
      'lastSynced': FieldValue.serverTimestamp(),
    };
  }
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      price: (json['price'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      quantity: (json['quantity'] ?? 0).toInt(),
      category: json['category'] ?? 'General',
      imageCloudUrl: json['imageCloudUrl'],
      thumbnailCloudUrl: json['thumbnailCloudUrl'],
      imagePath: '',
      thumbnailPath: '',
    );
  }

// -------------------------------------
}
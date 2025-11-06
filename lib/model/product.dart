/** lib/model/product.dart */
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

  /** Path to the ORIGINAL full-size image on the local file system. */
  @HiveField(4)
  late String imagePath;

  @HiveField(5)
  late int quantity;

  /** Path to the smaller thumbnail image on the local file system. */
  @HiveField(6)
  String? thumbnailPath;

  /** NEW FIELD: URL of the ORIGINAL image stored in Firebase Storage. */
  @HiveField(7)
  String? imageCloudUrl;

  /** NEW FIELD: URL of the THUMBNAIL image stored in Firebase Storage. */
  @HiveField(8)
  String? thumbnailCloudUrl;

  // --- NEW FIELD FOR CATEGORY ---
  @HiveField(9)
  late String category;
  // --- END NEW FIELD ---

  /**
   * Creates a Product instance for local persistence.
   */
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category, // <-- ADD THIS
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
      'category': category, // <-- ADD THIS
      // When syncing, we prioritize the cloud URLs
      'imageCloudUrl': imageCloudUrl,
      'thumbnailCloudUrl': thumbnailCloudUrl,
      // We still send local paths for debugging/reference, but they aren't used by the cloud client
      'localImagePath': imagePath,
      'localThumbnailPath': thumbnailPath,
      'lastSynced': FieldValue.serverTimestamp(), // Use Firestore timestamp
    };
  }
// -------------------------------------
}
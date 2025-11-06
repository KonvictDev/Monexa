// lib/model/customer.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- ADD THIS

part 'customer.g.dart'; // We will generate this file

@HiveType(typeId: 4)
class Customer extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String phoneNumber;

  @HiveField(3)
  String email;

  @HiveField(4)
  String address;

  @HiveField(5)
  String tag; // Already added in previous step

  Customer({
    required this.id,
    required this.name,
    this.phoneNumber = '',
    this.email = '',
    this.address = '',
    this.tag = '',
  });

  // --- NEW METHOD FOR FIRESTORE SYNC (UPLOAD) ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'tag': tag,
      'lastSynced': FieldValue.serverTimestamp(),
    };
  }

  // --- NEW FACTORY FOR FIRESTORE RESTORE (DOWNLOAD) ---
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
    );
  }
}
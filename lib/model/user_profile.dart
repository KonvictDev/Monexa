import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String phoneNumber;
  String name;
  int? age;
  String email;
  String businessName;
  String businessAddress;
  String? gstin;

  // Subscription and Blocking Fields
  final bool isPro;
  final DateTime? proExpiry;
  final bool isBlocked;
  // ➡️ NEW FIELD: To store the SKU (e.g., 'monexa_pro_monthly')
  final String? lastSubscriptionId;

  UserProfile({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    this.age,
    required this.email,
    required this.businessName,
    required this.businessAddress,
    this.gstin,
    this.isPro = false,
    this.proExpiry,
    this.isBlocked = false,
    this.lastSubscriptionId,
  });

  // To save to Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': name,
      'age': age,
      'email': email,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'gstin': gstin,
      'lastUpdated': FieldValue.serverTimestamp(),
      'isBlocked':isBlocked,
    };
  }

  // To create from Firestore (MODIFIED and FIXED for TypeErrors)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      // ⚠️ FIX: Use ?? '' to safely handle null values for all required Strings
      uid: json['uid'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      name: json['name'] as String? ?? 'User', // Use a default placeholder name
      age: json['age'] as int?, // Nullable int is fine
      email: json['email'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      businessAddress: json['businessAddress'] as String? ?? '',
      gstin: json['gstin'] as String?, // Nullable String is fine

      // Map Subscription & Blocking Status (already safe with ?? false)
      isPro: json['isPro'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,

      // Convert Firestore Timestamp to Dart DateTime (already safe with ?.)
      proExpiry: (json['proExpiry'] as Timestamp?)?.toDate(),

      lastSubscriptionId: json['lastSubscriptionId'] as String?,
    );
  }
}
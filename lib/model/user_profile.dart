// lib/model/user_profile.dart

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

  // ➡️ NEW: Subscription and Blocking Fields
  final bool isPro;
  final DateTime? proExpiry;
  final bool isBlocked;
  // ⬅️ END NEW

  UserProfile({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    this.age,
    required this.email,
    required this.businessName,
    required this.businessAddress,
    this.gstin,
    // ➡️ Initialize new fields with safe defaults
    this.isPro = false,
    this.proExpiry,
    this.isBlocked = false,
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
      // We don't typically save isPro/isBlocked from the client,
      // but ensure other fields are included.
    };
  }

  // To create from Firestore (MODIFIED to include new fields)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'],
      phoneNumber: json['phoneNumber'],
      name: json['name'],
      age: json['age'] as int?,
      email: json['email'],
      businessName: json['businessName'],
      businessAddress: json['businessAddress'],
      gstin: json['gstin'] as String?,

      // ➡️ Map Subscription & Blocking Status
      isPro: json['isPro'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,

      // Convert Firestore Timestamp to Dart DateTime
      proExpiry: (json['proExpiry'] as Timestamp?)?.toDate(),
    );
  }
}
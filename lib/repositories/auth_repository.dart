// lib/repositories/auth_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_profile.dart'; // Import the new model

// Provider for the repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

// Provider to get the current auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore; // Kept private here

  AuthRepository(this._auth, this._firestore);

  // ➡️ NEW: Public Getter for Firestore instance (Needed by subscription_provider)
  FirebaseFirestore get firestoreInstance => _firestore;

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ➡️ NEW/FIXED: Helper function to map Firestore document to UserProfile
  UserProfile? mapUserProfile(DocumentSnapshot doc) {
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Get user profile from Firestore (using the helper)
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return mapUserProfile(doc);
  }

  // Check if a user profile exists
  Future<bool> doesProfileExist(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  // Create/Update user profile in Firestore
  Future<void> saveUserProfile(UserProfile profile) async {
    await _firestore
        .collection('users')
        .doc(profile.uid)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  // --- Phone Authentication ---

  Future<void> sendOtp({
    required String phoneNumber,
    required BuildContext context,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval (e.g., on Android)
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {
        // Called when auto-retrieval times out
      },
    );
  }

  Future<bool> verifyOtp({
    required String verificationId,
    required String userOtp,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: userOtp,
      );
      await _auth.signInWithCredential(credential);
      return true; // Sign in successful
    } catch (e) {
      return false; // Sign in failed
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
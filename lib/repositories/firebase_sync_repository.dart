import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive to resolve HiveObject

// 1. IMPORT YOUR LOCAL MODELS WITH AN ALIAS
import '../model/expense.dart' as local_model;
import '../model/order.dart' as local_model;
import '../model/product.dart' as local_model;
import '../model/customer.dart' as local_model; // <-- ADDED

import 'expense_repository.dart';
import 'order_repository.dart';
import 'product_repository.dart';
import 'auth_repository.dart';
import 'customer_repository.dart'; // <-- ADDED

// --- Providers ---
final firebaseSyncRepositoryProvider = Provider<FirebaseSyncRepository>((ref) {
  return FirebaseSyncRepository(
    ref.watch(productRepositoryProvider),
    ref.watch(orderRepositoryProvider),
    ref.watch(expenseRepositoryProvider),
    ref.watch(authRepositoryProvider),
    ref.watch(customerRepositoryProvider), // <-- ADDED
  );
});

// --- Repository Class ---
class FirebaseSyncRepository {
  final ProductRepository _productRepo;
  final OrderRepository _orderRepo;
  final ExpenseRepository _expenseRepo;
  final AuthRepository _authRepo;
  final CustomerRepository _customerRepo; // <-- ADDED
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  FirebaseSyncRepository(
      this._productRepo,
      this._orderRepo,
      this._expenseRepo,
      this._authRepo,
      this._customerRepo, // <-- ADDED
      );

  // --- CORE SYNC (UPLOAD) ---

  Future<void> syncAllDataToFirebase() async {
    final uid = _authRepo.currentUser?.uid;
    if (uid == null) {
      throw Exception('User is not signed in. Cannot sync.');
    }

    await _syncProducts(uid);

    // --- ADDED CUSTOMERS SYNC ---
    await _syncCollection<local_model.Customer>(
      uid: uid,
      data: _customerRepo.getAllCustomers(),
      collectionName: 'customers',
      getId: (c) => c.id,
    );
    // --- END ADDED ---

    await _syncCollection<local_model.Order>(
      uid: uid,
      data: _orderRepo.getAllOrders(),
      collectionName: 'orders',
      getId: (o) => o.id,
    );

    await _syncCollection<local_model.Expense>(
      uid: uid,
      data: _expenseRepo.getAllExpenses(),
      collectionName: 'expenses',
      getId: (e) => 'expense_${e.key}',
    );
  }

  // --- Image Upload Logic ---
  Future<void> _syncProducts(String uid) async {
    final products = _productRepo.getAllProducts();
    final collectionRef =
    _firestore.collection('users').doc(uid).collection('products');
    final batch = _firestore.batch();

    for (final product in products) {
      String? originalUrl = product.imageCloudUrl;
      String? thumbnailUrl = product.thumbnailCloudUrl;

      final storagePathPrefix = 'users/$uid/products/${product.id}';

      // 1. Check/Upload Original Image
      if ((originalUrl == null || originalUrl.isEmpty) && product.imagePath.isNotEmpty) {
        originalUrl = await _uploadImage(
          localPath: product.imagePath,
          storagePath: '$storagePathPrefix/original',
        );
        product.imageCloudUrl = originalUrl;
      }

      // 2. Check/Upload Thumbnail Image
      if ((thumbnailUrl == null || thumbnailUrl.isEmpty) && product.thumbnailPath != null && product.thumbnailPath!.isNotEmpty) {
        thumbnailUrl = await _uploadImage(
          localPath: product.thumbnailPath!,
          storagePath: '$storagePathPrefix/thumbnail',
        );
        product.thumbnailCloudUrl = thumbnailUrl;
      }

      final docRef = collectionRef.doc(product.id);
      await product.save();
      final itemMap = product.toJson();
      batch.set(docRef, itemMap, SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint('Successfully synchronized products: ${products.length} items.');
  }

  // Generic Upload Helper (Unchanged)
  Future<void> _syncCollection<T>({
    required String uid,
    required List<T> data,
    required String collectionName,
    required String Function(T) getId,
  }) async {
    final collectionRef =
    _firestore.collection('users').doc(uid).collection(collectionName);
    final batch = _firestore.batch();

    for (final item in data) {
      final itemMap = (item as dynamic).toJson() as Map<String, dynamic>;
      final docId = getId(item);
      final docRef = collectionRef.doc(docId);

      batch.set(docRef, itemMap, SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint('Successfully synchronized $collectionName: ${data.length} items.');
  }

  // Firebase Storage Upload Helper (Unchanged)
  Future<String?> _uploadImage({
    required String localPath,
    required String storagePath,
  }) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        debugPrint('Local file not found at $localPath');
        return null;
      }

      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image to $storagePath: $e');
      return null;
    }
  }

  // --- CORE RESTORE (DOWNLOAD) ---

  /// Downloads all user data from Firestore and replaces local Hive data.
  Future<void> restoreAllDataFromFirebase() async {
    final uid = _authRepo.currentUser?.uid;
    if (uid == null) {
      throw Exception('User is not signed in. Cannot restore data.');
    }

    // --- 1. Clear Local Data First (CRITICAL STEP) ---
    await _productRepo.clearAll();
    await _orderRepo.clearAll();
    await _expenseRepo.clearAll();
    await _customerRepo.clearAll(); // <-- ADDED CUSTOMERS CLEAR

    // --- 2. Download Products & Images ---
    await _downloadAndSaveProducts(uid);

    // --- 3. Download Customers ---
    await _downloadAndSaveCollection<local_model.Customer>(
      uid: uid,
      collectionName: 'customers',
      repo: _customerRepo,
      fromJson: local_model.Customer.fromJson,
      getId: (doc) {
        final data = doc.data();
        if (data == null) return null;
        return (data as Map<String, dynamic>)['id'] as String;
      },
    );
    // --- END ADDED ---

    // --- 4. Download Orders ---
    await _downloadAndSaveCollection<local_model.Order>(
      uid: uid,
      collectionName: 'orders',
      repo: _orderRepo,
      fromJson: local_model.Order.fromJson,
      getId: (doc) {
        final data = doc.data();
        if (data == null) return null;
        return (data as Map<String, dynamic>)['id'] as String;
      },
    );

    // --- 5. Download Expenses ---
    await _downloadAndSaveCollection<local_model.Expense>(
      uid: uid,
      collectionName: 'expenses',
      repo: _expenseRepo,
      fromJson: _expenseFromJson,
      getId: (doc) => null,
    );
  }

  // --- Helpers for Restore Logic ---

  // Helper to convert Expense Firestore Map back to Hive Model
  local_model.Expense _expenseFromJson(Map<String, dynamic> json) {
    return local_model.Expense(
      description: json['description'] as String,
      amount: json['amount'] as double,
      date: DateTime.parse(json['date'] as String),
    );
  }

  // Generic Download Helper (Handles Orders, Customers, and Expenses)
  // T extends HiveObject ensures compatibility with both local models
  Future<void> _downloadAndSaveCollection<T extends HiveObject>({
    required String uid,
    required String collectionName,
    required dynamic repo,
    required T Function(Map<String, dynamic>) fromJson,
    required String? Function(DocumentSnapshot) getId,
  }) async {
    final snapshot = await _firestore.collection('users').doc(uid).collection(collectionName).get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final item = fromJson(data);

      final docId = getId(doc);

      if (docId != null && docId.isNotEmpty) {
        if (repo is OrderRepository) {
          await repo.orderBox.put(docId, item as local_model.Order);
        }
        // --- ADDED CUSTOMER SAVE ---
        else if (repo is CustomerRepository) {
          await repo.customerBox.put(docId, item as local_model.Customer);
        }
        // --- END ADDED ---
      } else {
        if (repo is ExpenseRepository) {
          await repo.expenseBox.add(item as local_model.Expense);
        }
      }
    }
    debugPrint('Restored ${snapshot.docs.length} $collectionName.');
  }

  // Helper to get local directory (Unchanged)
  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Storage Download Helper (Unchanged)
  Future<String?> _downloadImageFile(String? url, String filename) async {
    if (url == null || url.isEmpty) return null;

    try {
      final appDir = await _getLocalPath();
      final localFile = File(p.join(appDir, 'synced_images', filename));

      await localFile.parent.create(recursive: true);

      final ref = _storage.refFromURL(url);

      await ref.writeToFile(localFile);

      return localFile.path;
    } catch (e) {
      debugPrint('Error downloading file from $url: $e');
      return null;
    }
  }

  // Product-specific Download (with Image Download Logic) (Updated for Category)
  Future<void> _downloadAndSaveProducts(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).collection('products').get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final originalUrl = data['imageCloudUrl'] as String?;
      final thumbnailUrl = data['thumbnailCloudUrl'] as String?;

      final originalFilename = '${data['id']}_original.jpg';
      final thumbnailFilename = '${data['id']}_thumb.jpg';

      // Download Images
      final localImagePath = await _downloadImageFile(originalUrl, originalFilename);
      final localThumbnailPath = await _downloadImageFile(thumbnailUrl, thumbnailFilename);

      // Map data to local Product model
      final product = local_model.Product(
        id: data['id'],
        name: data['name'],
        price: data['price'],
        description: data['description'],
        quantity: data['quantity'],

        // Ensure category is always handled for old/new schema
        category: data['category'] as String? ?? 'Uncategorized',

        imagePath: localImagePath ?? '',
        thumbnailPath: localThumbnailPath,

        imageCloudUrl: originalUrl,
        thumbnailCloudUrl: thumbnailUrl,
      );

      // FIX: Use the public getter instead of the private field
      await _productRepo.productBox.put(product.id, product);
    }
    debugPrint('Restored ${snapshot.docs.length} products.');
  }
}
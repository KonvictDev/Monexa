import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'order_item.dart';

part 'order.g.dart';

@HiveType(typeId: 1)
class Order extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String customerName;

  @HiveField(2)
  late List<OrderItem> items;

  @HiveField(3)
  late double totalAmount; // This is now the FINAL GRAND TOTAL (tax inclusive)

  @HiveField(4)
  late DateTime orderDate;

  @HiveField(5)
  late String comments;

  @HiveField(6)
  late String paymentMethod;

  @HiveField(7)
  late double subtotal; // The total *before* discounts

  @HiveField(8)
  late double discountAmount;

  @HiveField(9)
  late double taxRate;

  @HiveField(10)
  late double taxAmount;

  @HiveField(11)
  late String invoiceNumber;

  Order({
    required this.id,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.paymentMethod,
    this.comments = '',
    required this.subtotal,
    this.discountAmount = 0.0,
    required this.taxRate, // Added
    required this.taxAmount, // Added
    required this.invoiceNumber,
  });

  // --- NEW METHOD FOR FIRESTORE SYNC ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'orderDate': orderDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'comments': comments,
      // Map OrderItem list to a list of maps
      'items': items.map((i) => i.toJson()).toList(),
      'lastSynced': FieldValue.serverTimestamp(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      // You must handle nested items list conversion here:
      items: (json['items'] as List<dynamic>).map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList(),
      totalAmount: json['totalAmount'] as double,
      orderDate: DateTime.parse(json['orderDate'] as String),
      paymentMethod: json['paymentMethod'] as String,
      comments: json['comments'] as String? ?? '',
      subtotal: json['subtotal'] as double,
      discountAmount: json['discountAmount'] as double? ?? 0.0,
      taxRate: json['taxRate'] as double,
      taxAmount: json['taxAmount'] as double,
      invoiceNumber: json['invoiceNumber'] as String,
    );
  }
}
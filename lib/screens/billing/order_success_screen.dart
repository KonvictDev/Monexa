// lib/screens/order_success_screen.dart
import 'package:billing/services/receipt_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. IMPORT
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/order.dart';

// 2. CHANGE TO ConsumerWidget
class OrderSuccessScreen extends ConsumerWidget {
  final Order order;

  // 3. REMOVE MANUAL CREATION
  // final ReceiptService _receiptService = ReceiptService();

  const OrderSuccessScreen({super.key, required this.order});

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final buffer = StringBuffer();
    buffer.writeln("🧾 *Order Summary*");
    buffer.writeln("Inv: ${order.invoiceNumber}");
    buffer.writeln("----------------");

    for (var item in order.items) {
      buffer.writeln("${item.quantity} x ${item.name}");
    }

    buffer.writeln("----------------");
    buffer.writeln("Total: ₹${order.totalAmount.toStringAsFixed(2)}");
    buffer.writeln("Thank you! 😊");

    final text = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse("https://wa.me/?text=$text");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback if WhatsApp not installed
      Share.share(buffer.toString());
    }
  }

  // 4. ADD WidgetRef ref
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Successful'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              Text(
                'Order Placed!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('Print Receipt'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    // 5. READ THE SERVICE FROM PROVIDER
                    ref.read(receiptServiceProvider).printReceipt(order);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline_rounded), // Or WhatsApp icon asset
                  label: const Text('Share on WhatsApp'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _shareOnWhatsApp(context),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share Receipt'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    // 5. READ THE SERVICE FROM PROVIDER
                    final file = await ref.read(receiptServiceProvider).saveReceipt(order);
                    await Share.shareXFiles(
                      [XFile(file.path)],
                      text: 'Here is your receipt for order #${order.id}',
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                child: const Text('Done (New Order)'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
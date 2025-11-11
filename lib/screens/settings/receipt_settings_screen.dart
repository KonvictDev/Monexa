// lib/screens/settings/receipt_settings_screen.dart (MODIFIED - Gating Customization)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../repositories/settings_repository.dart';
import '../../utils/date_filter.dart';
import '../../utils/settings_utils.dart';
import '../../services/gating_service.dart'; // ➡️ Import Gating Service

class ReceiptSettingsScreen extends ConsumerStatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  ConsumerState<ReceiptSettingsScreen> createState() =>
      _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState
    extends ConsumerState<ReceiptSettingsScreen> {
  late TextEditingController _footerController;
  late TextEditingController _taxIdController;
  late bool _showTaxId;
  late bool _showDiscount;

  // --- DUMMY VALUES FOR PREVIEW ---
  final double _dummyDiscount = 10.00;
  final double _dummyTax = 14.50;
  // ---

  @override
  void initState() {
    super.initState();
    final settingsRepo = ref.read(settingsRepositoryProvider);
    _footerController = TextEditingController(
      text: settingsRepo.get('receiptFooter',
          defaultValue: 'Thank you for your business!'),
    );
    _taxIdController = TextEditingController(
      text: settingsRepo.get('businessTaxId', defaultValue: ''),
    );
    _showTaxId = settingsRepo.get('receiptShowTaxId', defaultValue: true);
    _showDiscount = settingsRepo.get('receiptShowDiscount', defaultValue: true);
  }

  @override
  void dispose() {
    _footerController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  void _showUpgradeModal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt Customization requires Monexa Pro.')),
    );
  }


  void _saveSettings() {
    // ➡️ GATING CHECK
    if (!ref.read(gatingServiceProvider).canAccessFeature(Feature.receiptCustomization)) {
      _showUpgradeModal();
      return;
    }

    final settingsRepo = ref.read(settingsRepositoryProvider);
    settingsRepo.put('receiptFooter', _footerController.text);
    settingsRepo.put('receiptShowTaxId', _showTaxId);
    settingsRepo.put('receiptShowDiscount', _showDiscount);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt Settings Saved!')),
    );
  }

  void _showReceiptPreview() {
    final String footer = _footerController.text;
    final String taxId = _taxIdController.text;
    final bool showTax = _showTaxId;
    final bool showDiscount = _showDiscount;
    final theme = Theme.of(context);

    final baseStyle = theme.textTheme.bodyMedium?.copyWith(fontSize: 10, color: Colors.black) ?? const TextStyle(fontSize: 10, color: Colors.black);
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Center(
                      child: Text('Receipt Preview', style: theme.textTheme.titleLarge),
                    ),
                    const SizedBox(height: 16),
                    // --- The Preview Card ---
                    Card(
                      elevation: 0,
                      color: Colors.white, // Simulate paper
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DefaultTextStyle(
                          style: baseStyle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- 1. Header (Center Aligned) ---
                              Center(
                                child: Text(
                                  'My Business Name',
                                  textAlign: TextAlign.center,
                                  style: boldStyle.copyWith(fontSize: 16),
                                ),
                              ),
                              Center(
                                child: Text(
                                  '123 Business Address, City',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (showTax && taxId.isNotEmpty)
                                Center(
                                  child: Text(
                                    taxId,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              const SizedBox(height: 5),
                              Center(
                                child: Text('RETAIL INVOICE', style: boldStyle.copyWith(fontSize: 12)),
                              ),
                              const SizedBox(height: 15),

                              // --- 2. Order Info (Left Aligned) ---
                              Text('Invoice No: INV-PREVIEW'),
                              Text('Date: ${DateFormat.yMd().add_jms().format(DateTime.now())}'),
                              Text('Customer: Customer Name'),
                              Text('Payment Mode: CASH'),

                              const SizedBox(height: 5),
                              const Divider(color: Colors.black, height: 1),

                              // --- 3. Items Table (5 Columns) ---
                              _buildPreviewTableHeader(style: boldStyle),
                              const Divider(color: Colors.black, height: 1),
                              _buildPreviewTableRow(sNo: '1', item: 'Sample Product 1', price: '₹120.00', qty: '1', amount: '₹120.00', style: baseStyle),
                              _buildPreviewTableRow(sNo: '2', item: 'Sample Product 2', price: '₹90.00', qty: '2', amount: '₹180.00', style: baseStyle),
                              const Divider(color: Colors.black, height: 1),
                              const SizedBox(height: 15),

                              // --- 4. Totals (Right Aligned) ---
                              Align(
                                alignment: Alignment.centerRight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildPreviewTotalRow('Subtotal', '₹300.00', style: baseStyle),
                                    if (showDiscount && _dummyDiscount > 0)
                                      _buildPreviewTotalRow('Discount', '-₹10.00', style: baseStyle),
                                    if (_dummyTax > 0)
                                      _buildPreviewTotalRow('GST (5.0%)', '+₹14.50', style: baseStyle),

                                    Container(
                                      height: 1,
                                      width: 120,
                                      color: Colors.black,
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                    ),

                                    _buildPreviewTotalRow('Grand Total', '₹304.50', style: boldStyle.copyWith(fontSize: 14)),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // --- 5. Footer (Center Aligned) ---
                              if (footer.isNotEmpty)
                                Center(
                                  child: Text(
                                    footer,
                                    textAlign: TextAlign.center,
                                    style: baseStyle.copyWith(fontStyle: FontStyle.italic, fontSize: 9),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewTableHeader({required TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('S.No', style: style)),
          Expanded(flex: 7, child: Text('Items', style: style)),
          Expanded(flex: 4, child: Text('Price', style: style, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('Qty', style: style, textAlign: TextAlign.right)),
          Expanded(flex: 4, child: Text('Amount', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildPreviewTableRow({
    required String sNo,
    required String item,
    required String price,
    required String qty,
    required String amount,
    required TextStyle? style,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(sNo, style: style)),
          Expanded(flex: 7, child: Text(item, style: style, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 4, child: Text(price, style: style, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text(qty, style: style, textAlign: TextAlign.right)),
          Expanded(flex: 4, child: Text(amount, style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildPreviewTotalRow(String title, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(title, style: style),
          const SizedBox(width: 20),
          Text(value, style: style, textAlign: TextAlign.right),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ➡️ Read Gating Service
    final canCustomize = ref.watch(gatingServiceProvider).canAccessFeature(Feature.receiptCustomization);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Customization'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_rounded),
            tooltip: 'Preview Receipt',
            onPressed: _showReceiptPreview,
          ),
          IconButton(
            icon: canCustomize ? const Icon(Icons.save_rounded) : const Icon(Icons.lock_outline), // ➡️ Visual indicator
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: "Receipt Display Options"),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Show GSTIN / Tax ID'),
                    subtitle: const Text(
                      'Displays your business tax number at the top (if provided).',
                    ),
                    value: _showTaxId,
                    onChanged: canCustomize ? (v) => setState(() => _showTaxId = v) : null, // ➡️ GATED
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Show Discount Line Item'),
                    subtitle: const Text(
                      'Shows the discount line on receipts (if discount > 0).',
                    ),
                    value: _showDiscount,
                    onChanged: canCustomize ? (v) => setState(() => _showDiscount = v) : null, // ➡️ GATED
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SectionHeader(title: "Footer Message"),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AbsorbPointer( // ➡️ Prevent input if locked
                  absorbing: !canCustomize,
                  child: buildSettingsTextField(
                    controller: _footerController,
                    label: 'Custom Footer Message',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                    onChanged: canCustomize ? (_) => setState(() {}) : null, // Only rebuild/track if unlocked
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: FilledButton.icon(
                icon: canCustomize ? const Icon(Icons.save_rounded) : const Icon(Icons.lock_outline),
                label: Text(canCustomize ? 'Save Settings' : 'Pro Required'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saveSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
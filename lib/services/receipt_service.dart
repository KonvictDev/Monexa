import 'dart:io';
import 'dart:typed_data';
import 'package:billing/model/order.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../repositories/settings_repository.dart';

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  final settingsRepo = ref.read(settingsRepositoryProvider);
  return ReceiptService(settingsRepo);
});

class ReceiptService {
  final SettingsRepository _settingsRepo;
  ReceiptService(this._settingsRepo);

  Future<Uint8List> generatePdfBytes(
      Order order, {
        // These optional params are used by the preview screen
        String? overrideFooter,
        bool? overrideShowTaxId,
        bool? overrideShowDiscount,
      }) async {
    // --- LOAD FONT DATA ---
    final fontData = await rootBundle.load("assets/fonts/Inter-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Inter-Bold.ttf");
    final italicFontData = await rootBundle.load("assets/fonts/Inter-Medium.ttf");

    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);
    final italicTtf = pw.Font.ttf(italicFontData);

    final theme = pw.ThemeData.withFont(
      base: ttf,
      bold: boldTtf,
      italic: italicTtf,
    );

    final pdf = pw.Document(theme: theme);

    // --- Load Data & Settings ---
    final String businessName = _settingsRepo.get('businessName', defaultValue: 'My Business');
    final String businessAddress = _settingsRepo.get('businessAddress', defaultValue: 'Business Address');
    final String taxId = _settingsRepo.get('businessTaxId', defaultValue: '');
    final String currencySymbol = _settingsRepo.get('currencySymbol', defaultValue: '₹');

    final String footerMessage = overrideFooter ?? _settingsRepo.get('receiptFooter', defaultValue: 'Thank you for your business!');
    final bool showTaxId = overrideShowTaxId ?? _settingsRepo.get('receiptShowTaxId', defaultValue: true);
    final bool showDiscount = overrideShowDiscount ?? _settingsRepo.get('receiptShowDiscount', defaultValue: true);
    // --- END LOAD ---

    final currencyFormat = NumberFormat.simpleCurrency(name: currencySymbol, decimalDigits: 2);
    final dateFormat = DateFormat.yMd().add_jms();
    const double smallGap = 5;
    const double largeGap = 15;

    final pw.TextStyle defaultBold = pw.TextStyle(fontWeight: pw.FontWeight.bold);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {

          final boldStyle = pw.Theme.of(context).header4 ?? defaultBold;
          final baseStyle = pw.Theme.of(context).defaultTextStyle;
          final italicStyle = pw.TextStyle(fontStyle: pw.FontStyle.italic);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- 1. Header (Center Aligned) ---
              pw.SizedBox(height: smallGap),
              pw.Center(
                child: pw.Text(businessName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
              if (businessAddress.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    businessAddress,
                    style: baseStyle?.copyWith(
                      fontSize: 7,
                      color: PdfColors.grey600, // ✅ Added grey color
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

              if (showTaxId && taxId.isNotEmpty)
                pw.Center(child: pw.Text(taxId, style: baseStyle?.copyWith(fontSize: 10))),

              pw.SizedBox(height: smallGap),
              pw.Center(
                child: pw.Text('RETAIL INVOICE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: largeGap),

              // --- 2. Order Info (Left Aligned) ---
              pw.Text('Invoice No: ${order.invoiceNumber}', style: pw.TextStyle(fontSize: 8)),
              pw.Text('Date: ${dateFormat.format(order.orderDate)}', style: pw.TextStyle(fontSize: 8)),
              pw.Text('Customer: ${order.customerName}', style: pw.TextStyle(fontSize: 8)),
              pw.Text('Payment Mode: ${order.paymentMethod.toUpperCase()}', style: pw.TextStyle(fontSize: 8)),

              pw.SizedBox(height: smallGap),

              // --- 3. Items Table (5 Columns) ---
              pw.Divider(
                color: PdfColors.black,
                thickness: 0.8, // ✅ controls how thick the line looks
                height: 5,      // ✅ controls vertical spacing around it
              ),
              _buildTableHeader(style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              // --- 3. Items Table (5 Columns) ---
              pw.Divider(
                color: PdfColors.black,
                thickness: 0.8, // ✅ controls how thick the line looks
                height: 5,      // ✅ controls vertical spacing around it
              ),

              ...List.generate(order.items.length, (index) {
                final item = order.items[index];
                final itemTotal = item.price * item.quantity;
                return _buildTableRow(
                  sNo: (index + 1).toString(),
                  item: item.name,
                  price: currencyFormat.format(item.price),
                  qty: item.quantity.toString(),
                  amount: currencyFormat.format(itemTotal),
                  style: pw.TextStyle(fontSize: 8),
                );
              }),

              pw.Divider(
                color: PdfColors.black,
                thickness: 0.5, // ✅ controls how thick the line looks
                height: 2,      // ✅ controls vertical spacing around it
              ),

              pw.SizedBox(height: 5),

              // --- 4. Totals (Right Aligned) ---
              // --- **** THIS IS THE FIX **** ---
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    _buildTotalRow('Subtotal', currencyFormat.format(order.subtotal), pw.TextStyle(fontSize: 8)),
                    if (showDiscount && order.discountAmount > 0)
                      _buildTotalRow('Discount', '- ${currencyFormat.format(order.discountAmount)}', pw.TextStyle(fontSize: 8)),
                    if (order.taxAmount > 0)
                      _buildTotalRow('GST (${order.taxRate.toStringAsFixed(1)}%)', '+ ${currencyFormat.format(order.taxAmount)}', pw.TextStyle(fontSize: 8)),


                    pw.Container(
                      width: 80,
                      child: pw.Divider(
                        color: PdfColors.black,
                        thickness: 0.5, // ✅ actual line thickness
                        height: 2,      // ✅ vertical spacing (distance above/below)
                      ),
                    ),


                    _buildTotalRow('Grand Total', currencyFormat.format(order.totalAmount), pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),

              // --- **** END FIX **** ---

              pw.SizedBox(height: largeGap * 2),

              // --- 5. Footer (Center Aligned) ---
              if (footerMessage.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    footerMessage,
                    style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.normal),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTableHeader({required pw.TextStyle style}) {
    // ... (This method is unchanged) ...
    return pw.Row(
      children: [
        pw.Expanded(flex: 2, child: pw.Text('S.No', style: style)),
        pw.Expanded(flex: 7, child: pw.Text('Items', style: style)),
        pw.Expanded(flex: 4, child: pw.Text('Price', style: style, textAlign: pw.TextAlign.right)),
        pw.Expanded(flex: 2, child: pw.Text('Qty', style: style, textAlign: pw.TextAlign.right)),
        pw.Expanded(flex: 4, child: pw.Text('Amount', style: style, textAlign: pw.TextAlign.right)),
      ],
    );
  }

  pw.Widget _buildTableRow({
    required String sNo,
    required String item,
    required String price,
    required String qty,
    required String amount,
    required pw.TextStyle? style,
  }) {
    // ... (This method is unchanged) ...
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 2, child: pw.Text(sNo, style: style)),
          pw.Expanded(flex: 7, child: pw.Text(item, style: style)),
          pw.Expanded(flex: 4, child: pw.Text(price, style: style, textAlign: pw.TextAlign.right)),
          pw.Expanded(flex: 2, child: pw.Text(qty, style: style, textAlign: pw.TextAlign.right)),
          pw.Expanded(flex: 4, child: pw.Text(amount, style: style, textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }

  // --- **** THIS IS THE FIX **** ---
  // (Removed fixed width, using MainAxisSize.min and SizedBox)
  pw.Widget _buildTotalRow(String title, String value, pw.TextStyle? style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(title, style: style),
          pw.SizedBox(width: 20),
          pw.Text(value, style: style, textAlign: pw.TextAlign.right),
        ],
      ),
    );
  }

  // --- **** END FIX **** ---

  Future<void> printReceipt(Order order) async {
    final bytes = await generatePdfBytes(order);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }

  Future<File> saveReceipt(Order order) async {
    final bytes = await generatePdfBytes(order);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/receipt_${order.id}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
}
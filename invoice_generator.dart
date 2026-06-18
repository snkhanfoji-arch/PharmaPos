import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale.dart';

class InvoiceGenerator {
  static Future<void> generateAndPrint({
    required Sale sale,
    required Map<String, String> settings,
    required String customHeader,
    required String customFooter,
  }) async {
    final pdf = pw.Document();

    final shopName = settings['shop_name'] ?? 'PharmaPOS Pro';
    final address = settings['address'] ?? '';
    final phone = settings['phone'] ?? '';
    final currencySymbol = settings['currency'] ?? '₨';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Classic POS receipt format
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            cross: pw.CrossAxisAlignment.start,
            children: [
              // Shop Header Block
              pw.Center(
                child: pw.Text(
                  shopName,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                ),
              ),
              if (address.isNotEmpty)
                pw.Center(
                  child: pw.Text(address, style: const pw.TextStyle(fontSize: 8)),
                ),
              if (phone.isNotEmpty)
                pw.Center(
                  child: pw.Text('Tel: $phone', style: const pw.TextStyle(fontSize: 8)),
                ),
              pw.Center(
                child: pw.Text(
                  '------------------------------------------',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),

              // Custom Header Text
              if (customHeader.isNotEmpty) ...[
                pw.Center(
                  child: pw.Text(
                    customHeader,
                    style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    '------------------------------------------',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],

              // Sale Metadata
              pw.Text('Bill ID: #${sale.id ?? 'TEMP'}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: ${sale.date}', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 5),

              // Divider
              pw.Text('------------------------------------------', style: const pw.TextStyle(fontSize: 8)),

              // Cart Items Header
              pw.Row(
                main: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text('Item Name', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Text('Qty x Price', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Container(width: 50, alignment: pw.Alignment.centerRight, child: pw.Text('Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.Text('------------------------------------------', style: const pw.TextStyle(fontSize: 8)),

              // Cart Items
              ...?sale.items?.map((item) {
                final rowTotal = item.qty * item.price;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  children: pw.Row(
                    main: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 8))),
                      pw.Text('${item.qty} x $currencySymbol${item.price.toStringAsFixed(1)}', style: const pw.TextStyle(fontSize: 8)),
                      pw.Container(
                        width: 50,
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text('$currencySymbol${rowTotal.toStringAsFixed(1)}', style: const pw.TextStyle(fontSize: 8)),
                      ),
                    ],
                  ),
                );
              }),

              pw.Text('------------------------------------------', style: const pw.TextStyle(fontSize: 8)),

              // Calculations Module
              pw.Row(
                main: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('$currencySymbol${sale.subtotal.toStringAsFixed(1)}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                main: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Discount (${sale.discountPercent.toStringAsFixed(1)}%):', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('-$currencySymbol${sale.discountAmount.toStringAsFixed(1)}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                main: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tax (${sale.taxPercent.toStringAsFixed(1)}%):', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('+$currencySymbol${sale.taxAmount.toStringAsFixed(1)}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Text('------------------------------------------', style: const pw.TextStyle(fontSize: 8)),

              // NET TOTAL
              pw.Row(
                main: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    '$currencySymbol${sale.total.toStringAsFixed(1)}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),

              pw.Text('------------------------------------------', style: const pw.TextStyle(fontSize: 8)),

              // Custom Footer Text
              if (customFooter.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    customFooter,
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    // Prints or opens standard preview system
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'invoice_pk_pos_${sale.id ?? 'draft'}.pdf',
    );
  }
}

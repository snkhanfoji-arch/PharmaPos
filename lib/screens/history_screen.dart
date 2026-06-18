import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/sale.dart';
import '../widgets/invoice_generator.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<Sale> _sales = [];
  bool _isLoading = true;
  Map<String, String> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadSalesHistory();
  }

  Future<void> _loadSalesHistory() async {
    setState(() => _isLoading = true);
    final list = await DBHelper.instance.getSalesHistory();
    final settings = await DBHelper.instance.getSettings();
    setState(() {
      _sales = list;
      _settings = settings;
      _isLoading = false;
    });
  }

  // Expansion panel or detail page for reprints
  void _showReprintDialog(Sale sale) {
    final headerEditController = TextEditingController(text: _settings['invoice_header'] ?? '');
    final footerEditController = TextEditingController(text: _settings['invoice_footer'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Reprint Receipt #${sale.id}'),
          content: SingleChildScrollView(
            child: Column(
              cross: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Customize header/footer specifically for this print copy:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                const Text('Header Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 4),
                TextField(
                  controller: headerEditController,
                  maxLines: 2,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Footer Disclaimer Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 4),
                TextField(
                  controller: footerEditController,
                  maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                await InvoiceGenerator.generateAndPrint(
                  sale: sale,
                  settings: _settings,
                  customHeader: headerEditController.text.trim(),
                  customFooter: footerEditController.text.trim(),
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('Confirm Reprint'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = _settings['currency'] ?? '₨';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Invoice Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Ledger',
            onPressed: _loadSalesHistory,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long, size: 64, color: Colors.black26),
                      const SizedBox(height: 12),
                      Text('No completed sale invoices logs found.', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _sales.length,
                  itemBuilder: (context, idx) {
                    final s = _sales[idx];
                    final itemNames = s.items?.map((item) => '${item.productName} (x${item.qty})').join(', ') ?? 'No items';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          foregroundColor: Colors.green,
                          child: const Icon(Icons.check_circle_outline),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bill #${s.id}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$currency${s.total.toStringAsFixed(1)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Date/Time: ${s.date}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            color: Colors.grey.shade50,
                            child: Column(
                              cross: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ITEMIZED MEDS RECEIPT:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo),
                                ),
                                const SizedBox(height: 8),
                                ...?s.items?.map((item) {
                                  final rowTotal = item.qty * item.price;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '- ${item.productName}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        Text(
                                          '${item.qty} x $currency${item.price.toStringAsFixed(1)} = $currency${rowTotal.toStringAsFixed(1)}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        )
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal:', style: TextStyle(fontSize: 12)),
                                    Text('$currency${s.subtotal.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Discount (${s.discountPercent}%):', style: const TextStyle(fontSize: 12)),
                                    Text('-$currency${s.discountAmount.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Tax (${s.taxPercent}%):', style: const TextStyle(fontSize: 12)),
                                    Text('+$currency${s.taxAmount.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _showReprintDialog(s),
                                      icon: const Icon(Icons.print, size: 16),
                                      label: const Text('Reprint Invoice'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                      ),
                                    ),
                                    Tooltip(
                                      message: '100% Offline SQLite database verified',
                                      child: Row(
                                        children: [
                                          Icon(Icons.offline_pin, size: 16, color: Colors.indigo.shade300),
                                          const SizedBox(width: 4),
                                          const Text('Local Record Saved', style: TextStyle(fontSize: 11, color: Colors.black45)),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

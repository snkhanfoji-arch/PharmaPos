import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../widgets/invoice_generator.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<Product> _allProducts = [];
  List<Product> _searchResult = [];
  final _searchController = TextEditingController();

  Map<String, String> _settings = {};

  // Cart Status (maps productId -> cart item properties)
  final Map<int, Map<String, dynamic>> _cart = {};

  double _discountPercent = 0.0;
  double _taxPercent = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBillingData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadBillingData() async {
    setState(() => _isLoading = true);
    final db = DBHelper.instance;
    final products = await db.getProducts();
    final settings = await db.getSettings();

    setState(() {
      _allProducts = products;
      // Filter out products with 0 qty to prevent adding empty inventory to cart
      _searchResult = products.where((p) => p.qty > 0).toList();
      _settings = settings;

      // Extract default discount/tax ratios from settings
      _discountPercent = double.tryParse(settings['discount_percentage'] ?? '0.0') ?? 0.0;
      _taxPercent = double.tryParse(settings['tax_percentage'] ?? '0.0') ?? 0.0;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchResult = _allProducts.where((p) {
        final match = p.name.toLowerCase().contains(query) || p.barcode.contains(query);
        return match && p.qty > 0;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Adding item to cart logic
  void _addToCart(Product p) {
    if (p.id == null) return;
    final pId = p.id!;

    setState(() {
      if (_cart.containsKey(pId)) {
        final currentQty = _cart[pId]!['qty'] as int;
        if (currentQty < p.qty) {
          _cart[pId]!['qty'] = currentQty + 1;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot add more. No remaining catalog inventory!'), backgroundColor: Colors.orange),
          );
        }
      } else {
        _cart[pId] = {
          'id': pId,
          'name': p.name,
          'price': p.salePrice,
          'qty': 1,
          'maxStock': p.qty,
        };
      }
    });
  }

  void _updateCartQty(int productId, int delta) {
    setState(() {
      if (!_cart.containsKey(productId)) return;
      final currentQty = _cart[productId]!['qty'] as int;
      final maxStock = _cart[productId]!['maxStock'] as int;
      final newQty = currentQty + delta;

      if (newQty <= 0) {
        _cart.remove(productId);
      } else if (newQty > maxStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exceeded maximum available store quantity!'), backgroundColor: Colors.orange),
        );
      } else {
        _cart[productId]!['qty'] = newQty;
      }
    });
  }

  // Calculate Subtotal, Tax, Discounts, total
  double _calculateSubtotal() {
    double total = 0.0;
    _cart.forEach((_, item) {
      final qty = item['qty'] as int;
      final price = item['price'] as double;
      total += qty * price;
    });
    return total;
  }

  double _calculateDiscountAmount(double subtotal) {
    return subtotal * (_discountPercent / 100);
  }

  double _calculateTaxAmount(double subtotalAfterDiscount) {
    return subtotalAfterDiscount * (_taxPercent / 100);
  }

  // Handles checkout: triggers payment dialogue and lets pharmacist override print texts
  Future<void> _handleCheckout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty! Select medicines first.'), backgroundColor: Colors.red),
      );
      return;
    }

    final subtotal = _calculateSubtotal();
    final discountAmount = _calculateDiscountAmount(subtotal);
    final taxableAmount = subtotal - discountAmount;
    final taxAmount = _calculateTaxAmount(taxableAmount);
    final netTotal = taxableAmount + taxAmount;

    // Controllers for invoice header/footer edit before printing
    final headerEditController = TextEditingController(text: _settings['invoice_header'] ?? '');
    final footerEditController = TextEditingController(text: _settings['invoice_footer'] ?? '');

    final bool? confirmReceipt = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          maxWidth: 500,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Publish Bill Record'),
          content: SingleChildScrollView(
            child: Column(
              cross: CrossAxisAlignment.start,
              children: [
                const Text('Review Invoice and edit print details below:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Divider(),
                const SizedBox(height: 8),
                Text('Total Items: ${_cart.length}', style: const TextStyle(fontSize: 12)),
                Text('Total Bill: ₨${netTotal.toStringAsFixed(1)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 16),
                const Text('Customize Print Header *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: headerEditController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Shop Header Caption Text...',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Customize Print Footer *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: footerEditController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Shop Footer / Warnings...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save & Print Invoice'),
            )
          ],
        );
      },
    );

    if (confirmReceipt == true) {
      setState(() => _isLoading = true);

      final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // 1. Map to models
      final List<SaleItem> listItems = [];
      _cart.forEach((pId, value) {
        listItems.add(SaleItem(
          productId: pId,
          productName: value['name'] as String,
          qty: value['qty'] as int,
          price: value['price'] as double,
        ));
      });

      final sale = Sale(
        date: dateStr,
        subtotal: subtotal,
        taxPercent: _taxPercent,
        taxAmount: taxAmount,
        discountPercent: _discountPercent,
        discountAmount: discountAmount,
        total: netTotal,
        items: listItems,
      );

      // 2. Commit transaction to local sqflite
      final saleId = await DBHelper.instance.createSale(sale, listItems);

      // Create complete sale object to pass to printer
      final finalizedSale = Sale(
        id: saleId,
        date: dateStr,
        subtotal: subtotal,
        taxPercent: _taxPercent,
        taxAmount: taxAmount,
        discountPercent: _discountPercent,
        discountAmount: discountAmount,
        total: netTotal,
        items: listItems,
      );

      // 3. Kickoff pdf generator with customs!
      await InvoiceGenerator.generateAndPrint(
        sale: finalizedSale,
        settings: _settings,
        customHeader: headerEditController.text.trim(),
        customFooter: footerEditController.text.trim(),
      );

      // Clear Cart and refresh
      _cart.clear();
      _searchController.clear();
      await _loadBillingData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = _settings['currency'] ?? '₨';
    final subtotal = _calculateSubtotal();
    final discountAmount = _calculateDiscountAmount(subtotal);
    final taxableAmount = subtotal - discountAmount;
    final taxAmount = _calculateTaxAmount(taxableAmount);
    final totalSum = taxableAmount + taxAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Checkout Terminal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_sharp),
            tooltip: 'Clear Cart',
            onPressed: () {
              setState(() {
                _cart.clear();
              });
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Dual layout for tablets vs single column for mobile screen width limits
                final isLargeScreen = constraints.maxWidth > 800;

                Widget buildProductSelectorPanel() {
                  return Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 1,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Click or type to search products...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _searchResult.isEmpty
                              ? const Center(child: Text('Empty stock logs.', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  itemCount: _searchResult.length,
                                  itemBuilder: (context, idx) {
                                    final p = _searchResult[idx];
                                    return ListTile(
                                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      subtitle: Text('Batch: ${p.batch} | Expire: ${p.expiry} | Stock: ${p.qty} left', style: const TextStyle(fontSize: 11)),
                                      trailing: ElevatedButton.icon(
                                        onPressed: () => _addToCart(p),
                                        icon: const Icon(Icons.add_shopping_cart, size: 14),
                                        label: Text('$currency${p.salePrice}'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          backgroundColor: Colors.indigo.shade50,
                                          foregroundColor: Colors.indigo,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        )
                      ],
                    ),
                  );
                }

                Widget buildCartPanel() {
                  return Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 1,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: Colors.indigo.shade50,
                          child: const Text(
                            'Active Invoice Items',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                        ),
                        Expanded(
                          child: _cart.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_cart_outlined, color: Colors.black26, size: 48),
                                      SizedBox(height: 8),
                                      Text('No medicines in cart', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _cart.length,
                                  itemBuilder: (context, index) {
                                    final itemKey = _cart.keys.elementAt(index);
                                    final item = _cart[itemKey]!;
                                    final lineTotal = (item['price'] as double) * (item['qty'] as int);

                                    return ListTile(
                                      title: Text(item['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      subtitle: Text('$currency${item['price']} x ${item['qty']}', style: const TextStyle(fontSize: 11)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.orange, size: 20),
                                            onPressed: () => _updateCartQty(itemKey, -1),
                                          ),
                                          Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, color: Colors.indigo, size: 20),
                                            onPressed: () => _updateCartQty(itemKey, 1),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 60,
                                            alignment: Alignment.centerRight,
                                            child: Text('$currency${lineTotal.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const Divider(),

                        // Subtotal and tax config items
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Cart Subtotal:', style: TextStyle(fontSize: 12)),
                              Text('$currency${subtotal.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                        // Discount Percentage Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Bill Discount (${_discountPercent.toStringAsFixed(0)}%):', style: const TextStyle(fontSize: 11)),
                              SizedBox(
                                width: 140,
                                child: Slider(
                                  value: _discountPercent,
                                  min: 0,
                                  max: 50,
                                  divisions: 10,
                                  label: '${_discountPercent.round()}%',
                                  onChanged: (val) {
                                    setState(() {
                                      _discountPercent = val;
                                    });
                                  },
                                ),
                              ),
                              Text('-$currency${discountAmount.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                            ],
                          ),
                        ),

                        // Tax Percentage Slider Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tax Percentage (${_taxPercent.toStringAsFixed(0)}%):', style: const TextStyle(fontSize: 11)),
                              SizedBox(
                                width: 140,
                                child: Slider(
                                  value: _taxPercent,
                                  min: 0,
                                  max: 30,
                                  divisions: 6,
                                  label: '${_taxPercent.round()}%',
                                  onChanged: (val) {
                                    setState(() {
                                      _taxPercent = val;
                                    });
                                  },
                                ),
                              ),
                              Text('+$currency${taxAmount.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                            ],
                          ),
                        ),

                        const Divider(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GRAND TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                '$currency${totalSum.toStringAsFixed(1)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _cart.isEmpty ? null : _handleCheckout,
                              icon: const Icon(Icons.receipt),
                              label: const Text('Checkout & Generate Invoice', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                }

                if (isLargeScreen) {
                  return Row(
                    children: [
                      Expanded(flex: 5, child: buildProductSelectorPanel()),
                      Expanded(flex: 5, child: buildCartPanel()),
                    ],
                  );
                } else {
                  return DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(icon: Icon(Icons.medication), text: 'Catalog Select'),
                            Tab(icon: Icon(Icons.shopping_cart), text: 'Receipt Items'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              buildProductSelectorPanel(),
                              buildCartPanel(),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }
              },
            ),
    );
  }
}

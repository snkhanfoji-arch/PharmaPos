import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  Map<String, String> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await DBHelper.instance.getProducts();
    final settings = await DBHelper.instance.getSettings();
    setState(() {
      _products = list;
      _filteredProducts = list;
      _settings = settings;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.barcode.contains(query) ||
            p.batch.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Show Add/Edit Dialog
  void _showFormDialog({Product? product}) {
    final isEdit = product != null;
    final formKey = GlobalKey<FormState>();

    // Input values
    String name = isEdit ? product.name : '';
    String batch = isEdit ? product.batch : '';
    String expiry = isEdit ? product.expiry : '';
    int qty = isEdit ? product.qty : 0;
    double purPrice = isEdit ? product.purchasePrice : 0.0;
    double salPrice = isEdit ? product.salePrice : 0.0;
    String barcode = isEdit ? product.barcode : '';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'Update Medication' : 'Register Medicine Capsule'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(labelText: 'Medicine Name *', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    onSaved: (v) => name = v!.trim(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: batch,
                          decoration: const InputDecoration(labelText: 'Batch Code *', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          onSaved: (v) => batch = v!.trim(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: expiry,
                          decoration: const InputDecoration(labelText: 'Expiry (YYYY-MM) *', placeholder: 'e.g. 2027-12', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          onSaved: (v) => expiry = v!.trim(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: qty.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qty (Pills/Boxes) *', border: OutlineInputBorder()),
                          validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid integer' : null,
                          onSaved: (v) => qty = int.parse(v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: barcode,
                          decoration: const InputDecoration(labelText: 'Barcode ID', border: OutlineInputBorder()),
                          onSaved: (v) => barcode = v?.trim() ?? '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: isEdit ? purPrice.toString() : '',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Cost Price (₨) *', border: OutlineInputBorder()),
                          validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid cost' : null,
                          onSaved: (v) => purPrice = double.parse(v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: isEdit ? salPrice.toString() : '',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Sale Price (₨) *', border: OutlineInputBorder()),
                          validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid price' : null,
                          onSaved: (v) => salPrice = double.parse(v!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  final p = Product(
                    id: isEdit ? product.id : null,
                    name: name,
                    batch: batch,
                    expiry: expiry,
                    qty: qty,
                    purchasePrice: purPrice,
                    salePrice: salPrice,
                    barcode: barcode,
                  );

                  if (isEdit) {
                    await DBHelper.instance.updateProduct(p);
                  } else {
                    await DBHelper.instance.insertProduct(p);
                  }

                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: Text(isEdit ? 'Update' : 'Register'),
            )
          ],
        );
      },
    );
  }

  // Delete product row with verification
  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Remove Product?'),
          content: const Text('Are you sure you want to delete this medicine record? This action cannot be revoked.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, Delete'),
            )
          ],
        );
      },
    );

    if (confirm == true) {
      await DBHelper.instance.deleteProduct(id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = _settings['currency'] ?? '₨';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Medicine',
            onPressed: () => _showFormDialog(),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Search Bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Name, Batch, or Barcode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),

                // Medicines list builder
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No matching products found.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _showFormDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Medicine'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, idx) {
                            final p = _filteredProducts[idx];
                            final isLowStock = p.qty < 10;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1.5,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isLowStock ? Colors.red.shade50 : Colors.indigo.shade50,
                                  foregroundColor: isLowStock ? Colors.red : Colors.indigo,
                                  child: const Icon(Icons.medication),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                    Text(
                                      '$currency${p.salePrice.toStringAsFixed(1)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Batch: ${p.batch} | Expiry: ${p.expiry}'),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          'Stock: ${p.qty}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isLowStock ? Colors.red : Colors.indigo,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('| Cost: $currency${p.purchasePrice} | Barcode: ${p.barcode.isNotEmpty ? p.barcode : "N/A"}', style: const TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                      onPressed: () => _showFormDialog(product: p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _deleteProduct(p.id!),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

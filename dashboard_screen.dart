import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/product.dart';
import '../models/sale.dart';
import 'products_screen.dart';
import 'billing_screen.dart';
import 'history_screen.dart';
import 'admin_login.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _todaySales = 0.0;
  int _totalProductsCount = 0;
  List<Product> _lowStockItems = [];
  Map<String, String> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final db = DBHelper.instance;

    // Load Settings
    final settings = await db.getSettings();

    // Load Products & Filter Low Stock
    final products = await db.getProducts();

    // Load Sales & Filter Today's sales
    final sales = await db.getSalesHistory();

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    double todaySalesSum = 0.0;

    for (var sale in sales) {
      if (sale.date.startsWith(todayStr)) {
        todaySalesSum += sale.total;
      }
    }

    final lowStock = products.where((p) => p.qty < 10).toList();

    setState(() {
      _settings = settings;
      _totalProductsCount = products.length;
      _lowStockItems = lowStock;
      _todaySales = todaySalesSum;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = _settings['currency'] ?? '₨';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_settings['shop_name'] ?? 'PharmaPOS Pro'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Dashboard',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.lock_person),
            tooltip: 'Admin Settings Panel',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
              ).then((_) => _loadDashboardData());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            cross: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Text(
                'Welcome, Pharmacy Pharmacist',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'POS Offline Engine is ready. Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // KPI Bento Grid cards of sales, total medicines and warnings
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 24) / 3;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildKPICard(
                        title: "Today's Sales",
                        value: '$currency${_todaySales.toStringAsFixed(1)}',
                        icon: Icons.monetization_on,
                        color: Colors.green,
                        width: itemWidth > 120 ? itemWidth : double.infinity,
                      ),
                      _buildKPICard(
                        title: "Total Medicines",
                        value: '$_totalProductsCount Items',
                        icon: Icons.medical_services,
                        color: Colors.indigo,
                        width: itemWidth > 120 ? itemWidth : double.infinity,
                      ),
                      _buildKPICard(
                        title: "Low Stock Items",
                        value: '${_lowStockItems.length} Warnings',
                        icon: Icons.warning_amber_rounded,
                        color: _lowStockItems.isNotEmpty ? Colors.red : Colors.grey,
                        width: itemWidth > 120 ? itemWidth : double.infinity,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Quick Launcher Controls
              const Text(
                'Core POS Workspaces',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, constraints) {
                final dWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildQuickLauncher(
                      label: "POS Billing Terminal",
                      sub: "Generate custom bills & receipt prints",
                      icon: Icons.point_of_sale,
                      color: Colors.indigo,
                      callback: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BillingScreen()),
                        ).then((_) => _loadDashboardData());
                      },
                      width: dWidth > 150 ? dWidth : double.infinity,
                    ),
                    _buildQuickLauncher(
                      label: "Medicine Database",
                      sub: "Register batches, costs, expiry & counts",
                      icon: Icons.inventory,
                      color: Colors.teal,
                      callback: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProductsScreen()),
                        ).then((_) => _loadDashboardData());
                      },
                      width: dWidth > 150 ? dWidth : double.infinity,
                    ),
                    _buildQuickLauncher(
                      label: "Receipt Ledger",
                      sub: "Trace invoice logs & execute reprints",
                      icon: Icons.receipt_long,
                      color: Colors.blueGrey,
                      callback: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SalesHistoryScreen()),
                        ).then((_) => _loadDashboardData());
                      },
                      width: dWidth > 150 ? dWidth : double.infinity,
                    ),
                    _buildQuickLauncher(
                      label: "Admin Settings",
                      sub: "Edit invoice headers & backup DB files",
                      icon: Icons.settings,
                      color: Colors.purple,
                      callback: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                        ).then((_) => _loadDashboardData());
                      },
                      width: dWidth > 150 ? dWidth : double.infinity,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),

              // Critical Stock Depletions Warn list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Critical Stock Expiries / Warning Lists',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                  ),
                  _lowStockItems.isNotEmpty
                      ? Tooltip(
                          message: 'Stock levels less than 10 units!',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                            child: const Text('LOW STOCK ALERT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        )
                      : const Text('All stocks normal', style: TextStyle(fontSize: 12, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 12),

              _lowStockItems.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 36),
                          SizedBox(height: 8),
                          Text('Awesome! No medication displays are understocked or depleted.', style: TextStyle(color: Colors.green, fontSize: 12), textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _lowStockItems.length,
                      itemBuilder: (context, idx) {
                        final p = _lowStockItems[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.shade100,
                              foregroundColor: Colors.red.shade700,
                              child: const Icon(Icons.dangerous),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('Batch: ${p.batch} | Expire: ${p.expiry}', style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              '${p.qty} left',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        cross: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            foregroundColor: color,
            radius: 18,
            child: Icon(icon, size: 18),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade900),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLauncher({
    required String label,
    required String sub,
    required IconData icon,
    required Color color,
    required VoidCallback callback,
    required double width,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: callback,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            color: Colors.white,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                foregroundColor: color,
                radius: 20,
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  cross: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}

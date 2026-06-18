import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currencyController = TextEditingController();
  final _taxController = TextEditingController();
  final _discountController = TextEditingController();
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  Map<String, String> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await DBHelper.instance.getSettings();
    setState(() {
      _settings = s;
      _shopNameController.text = s['shop_name'] ?? '';
      _addressController.text = s['address'] ?? '';
      _phoneController.text = s['phone'] ?? '';
      _currencyController.text = s['currency'] ?? '₨';
      _taxController.text = s['tax_percentage'] ?? '0.0';
      _discountController.text = s['discount_percentage'] ?? '0.0';
      _headerController.text = s['invoice_header'] ?? '';
      _footerController.text = s['invoice_footer'] ?? '';
      _adminEmailController.text = s['admin_email'] ?? 'random@gmail.com';
      _adminPasswordController.text = s['admin_password'] ?? 'random123';
      _isLoading = false;
    });
  }

  Future<void> _saveAllSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final helper = DBHelper.instance;

      await helper.updateSetting('shop_name', _shopNameController.text.trim());
      await helper.updateSetting('address', _addressController.text.trim());
      await helper.updateSetting('phone', _phoneController.text.trim());
      await helper.updateSetting('currency', _currencyController.text.trim());
      await helper.updateSetting('tax_percentage', _taxController.text.trim());
      await helper.updateSetting('discount_percentage', _discountController.text.trim());
      await helper.updateSetting('invoice_header', _headerController.text.trim());
      await helper.updateSetting('invoice_footer', _footerController.text.trim());
      await helper.updateSetting('admin_email', _adminEmailController.text.trim());
      await helper.updateSetting('admin_password', _adminPasswordController.text.trim());

      await _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All settings updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Database Backup Routine
  Future<void> _backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final sourceFile = File(p.join(dbPath, 'pharmapos_pro.db'));

      if (await sourceFile.exists()) {
        String? selectedDir = await FilePicker.platform.getDirectoryPath();
        if (selectedDir != null) {
          final backupFileName = 'pharmapos_backup_${DateTime.now().millisecondsSinceEpoch}.db';
          final targetFile = File(p.join(selectedDir, backupFileName));
          await sourceFile.copy(targetFile.path);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Database backed up to: ${targetFile.path}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        throw Exception("Source database file not found yet.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Database Restore Routine
  Future<void> _restoreDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result != null && result.files.single.path != null) {
        final selectedFilePath = result.files.single.path!;
        final dbPath = await getDatabasesPath();
        final targetPath = p.join(dbPath, 'pharmapos_pro.db');

        // Close old database connection of sqflite helper to avoid race conditions
        final db = await DBHelper.instance.database;
        await db.close();

        // Overwrite file
        await File(selectedFilePath).copy(targetPath);

        // Reload the database inside app
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database restored successfully! Re-connecting...'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadSettings();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PharmaPOS Pro Customization'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAllSettings,
            tooltip: 'Save Settings',
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Shop Details Section card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  cross: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pharmacy Identity',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _shopNameController,
                      decoration: const InputDecoration(
                        labelText: 'Shop Name',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Shop Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone/Telephone',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Financial parameters
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  cross: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Defaults',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _currencyController,
                            decoration: const InputDecoration(
                              labelText: 'Currency Symbol',
                              prefixIcon: Icon(Icons.money),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Currency symbol is required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _taxController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Default Tax (%)',
                              suffixText: '%',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _discountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Default Billing Discount (%)',
                        prefixIcon: Icon(Icons.percent),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Print template
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  cross: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Receipt Printing Configuration',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _headerController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Receipt Header Subtitle Lines',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _footerController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Receipt Footer Disclaimers / Text',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Admin configuration
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  cross: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Authentication Profiles',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adminEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Admin Login Email',
                        prefixIcon: Icon(Icons.alternate_email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adminPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Admin Password',
                        prefixIcon: Icon(Icons.password),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Backup Restore Section
            Card(
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  cross: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Backup & Restores (Offline DB)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Export entire relational schema containing products, items, and log records to local external storage, or upload copy of old SQLite files.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _backupDatabase,
                            icon: const Icon(Icons.backup),
                            label: const Text('Export .DB file'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _restoreDatabase,
                            icon: const Icon(Icons.restore_page),
                            label: const Text('Import .DB file'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.indigo),
                              foregroundColor: Colors.indigo,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveAllSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Form Customs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

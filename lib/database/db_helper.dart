import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pharmapos_pro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        batch TEXT NOT NULL,
        expiry TEXT NOT NULL,
        qty INTEGER NOT NULL,
        purchase_price REAL NOT NULL,
        sale_price REAL NOT NULL,
        barcode TEXT NOT NULL
      )
    ''');

    // 2. Sales table
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax_percent REAL NOT NULL,
        tax_amount REAL NOT NULL,
        discount_percent REAL NOT NULL,
        discount_amount REAL NOT NULL,
        total REAL NOT NULL
      )
    ''');

    // 3. Sale Items table
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        qty INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    // 4. Settings table (Key-Value)
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_name TEXT UNIQUE NOT NULL,
        val_value TEXT NOT NULL
      )
    ''');

    // Populate default settings
    final defaultSettings = {
      'shop_name': 'PharmaPOS Pro',
      'address': 'Kallara Chowk, Near City Care Hospital, PKR',
      'phone': '+92 300 1234567',
      'logo_path': '',
      'currency': '₨',
      'tax_percentage': '5.0',
      'discount_percentage': '10.0',
      'invoice_header': 'PHARMAPOS PRO - QUALITY MEDICINE',
      'invoice_footer': 'Medicines once sold can only be returned within 3 days with a valid bill and intact packaging.',
      'admin_email': 'random@gmail.com',
      'admin_password': 'random123',
    };

    for (var entry in defaultSettings.entries) {
      await db.insert('settings', {
        'key_name': entry.key,
        'val_value': entry.value,
      });
    }

    // Seed some initial products for convenience
    await db.insert('products', {
      'name': 'Panadol 500mg',
      'batch': 'B4281',
      'expiry': '2027-12',
      'qty': 150,
      'purchase_price': 1.5,
      'sale_price': 2.5,
      'barcode': '1234567890123'
    });
    await db.insert('products', {
      'name': 'Amoxil 250mg',
      'batch': 'AX992',
      'expiry': '2026-10',
      'qty': 80,
      'purchase_price': 12.0,
      'sale_price': 18.0,
      'barcode': '2345678901234'
    });
    await db.insert('products', {
      'name': 'Brufen Syrup',
      'batch': 'BF501',
      'expiry': '2025-08',
      'qty': 8, // Trigger low stock (< 10)
      'purchase_price': 45.0,
      'sale_price': 60.0,
      'barcode': '3456789012345'
    });
  }

  // Settings CRUD
  Future<Map<String, String>> getSettings() async {
    final db = await instance.database;
    final maps = await db.query('settings');
    final Map<String, String> result = {};
    for (var m in maps) {
      result[m['key_name'] as String] = m['val_value'] as String;
    }
    return result;
  }

  Future<int> updateSetting(String key, String val) async {
    final db = await instance.database;
    return await db.update(
      'settings',
      {'val_value': val},
      where: 'key_name = ?',
      whereArgs: [key],
    );
  }

  // Products CRUD
  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getProducts() async {
    final db = await instance.database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sales Handling
  Future<int> createSale(Sale sale, List<SaleItem> items) async {
    final db = await instance.database;
    int saleId = -1;

    await db.transaction((txn) async {
      // 1. Insert original sale
      saleId = await txn.insert('sales', sale.toMap());

      // 2. Insert items and update stock
      for (var item in items) {
        final Map<String, dynamic> itemMap = {
          'sale_id': saleId,
          'product_id': item.productId,
          'product_name': item.productName,
          'qty': item.qty,
          'price': item.price,
        };
        await txn.insert('sale_items', itemMap);

        // 3. Decrement Product Stock
        await txn.execute(
          'UPDATE products SET qty = qty - ? WHERE id = ?',
          [item.qty, item.productId],
        );
      }
    });

    return saleId;
  }

  Future<List<Sale>> getSalesHistory() async {
    final db = await instance.database;
    final saleMaps = await db.query('sales', orderBy: 'date DESC');
    final List<Sale> sales = [];

    for (var sm in saleMaps) {
      final saleId = sm['id'] as int;
      final itemMaps = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      final listItems = itemMaps.map((im) => SaleItem.fromMap(im)).toList();
      sales.add(Sale.fromMap(sm, items: listItems));
    }
    return sales;
  }
}

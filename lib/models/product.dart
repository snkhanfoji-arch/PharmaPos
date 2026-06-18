class Product {
  final int? id;
  final String name;
  final String batch;
  final String expiry;
  final int qty;
  final double purchasePrice;
  final double salePrice;
  final String barcode;

  Product({
    this.id,
    required this.name,
    required this.batch,
    required this.expiry,
    required this.qty,
    required this.purchasePrice,
    required this.salePrice,
    required this.barcode,
  });

  // Convert Product object to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'batch': batch,
      'expiry': expiry,
      'qty': qty,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'barcode': barcode,
    };
  }

  // Create Product object from map retrieved from database
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      batch: map['batch'] as String,
      expiry: map['expiry'] as String,
      qty: map['qty'] as int,
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      salePrice: (map['sale_price'] as num).toDouble(),
      barcode: map['barcode'] as String,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? batch,
    String? expiry,
    int? qty,
    double? purchasePrice,
    double? salePrice,
    String? barcode,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      batch: batch ?? this.batch,
      expiry: expiry ?? this.expiry,
      qty: qty ?? this.qty,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      barcode: barcode ?? this.barcode,
    );
  }
}

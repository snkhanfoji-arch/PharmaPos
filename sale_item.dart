class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final int qty;
  final double price; // Sale price of the product

  SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'qty': qty,
      'price': price,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      qty: map['qty'] as int,
      price: (map['price'] as num).toDouble(),
    );
  }
}

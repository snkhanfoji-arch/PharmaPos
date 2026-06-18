import 'sale_item.dart';

class Sale {
  final int? id;
  final String date; // YYYY-MM-DD HH:mm:ss
  final double subtotal;
  final double taxPercent;
  final double taxAmount;
  final double discountPercent;
  final double discountAmount;
  final double total;
  final List<SaleItem>? items;

  Sale({
    this.id,
    required this.date,
    required this.subtotal,
    required this.taxPercent,
    required this.taxAmount,
    required this.discountPercent,
    required this.discountAmount,
    required this.total,
    this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'subtotal': subtotal,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'total': total,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, {List<SaleItem>? items}) {
    return Sale(
      id: map['id'] as int?,
      date: map['date'] as String,
      subtotal: (map['subtotal'] as num).toDouble(),
      taxPercent: (map['tax_percent'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      discountPercent: (map['discount_percent'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      items: items,
    );
  }
}

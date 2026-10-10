import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  String get productId => product.id;
  double get unitCost => product.price;
  double get subtotal => product.price * quantity;
  
  double get taxAmount => subtotal * (product.taxPercentage / 100);

  double get total => subtotal + taxAmount;

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'productName': product.name,
      'barcode': product.barcode,
      'price': product.price,
      'weight': product.weight,
      'category': product.category,
      'imageUrl': product.imageUrl,
      'taxPercentage': product.taxPercentage,
      'quantity': quantity,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'total': total,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final taxRate = (map['tax_rate'] as num?)?.toDouble();
    final taxPercentage = (map['taxPercentage'] as num?)?.toDouble() ?? 
        (taxRate != null ? taxRate * 100.0 : 0.0);
    final price = (map['price'] ?? map['unit_price'] as num?)?.toDouble() ?? 0.0;

    final product = Product(
      id: map['productId'] ?? map['product_id'] ?? '',
      name: map['productName'] ?? map['product_name'] ?? map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      price: price,
      weight: map['weight'] ?? '',
      unit: map['unit'] ?? '',
      category: map['category'] ?? 'General',
      imageUrl: map['imageUrl'] ?? map['image_url'] ?? '',
      description: map['description'] ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 100,
      taxPercentage: taxPercentage,
      isAvailable: true,
    );

    return CartItem(
      product: product,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

import '../utils/constants.dart';
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
    final id = (map['productId'] ?? map['product_id'] ?? '').toString();
    final barcode = (map['barcode'] ?? '').toString();
    final parsedPrice = (map['price'] ?? map['unit_price'] ?? map['unitCost'] ?? map['unit_cost']);
    final rawPrice = parsedPrice is num ? parsedPrice.toDouble() : (double.tryParse(parsedPrice?.toString() ?? '') ?? 0.0);
    final price = rawPrice > 0
        ? rawPrice
        : AppConstants.getAuthoritativePrice(id.isNotEmpty ? id : barcode, rawPrice);

    final product = Product(
      id: id,
      name: map['productName'] ?? map['product_name'] ?? map['name'] ?? '',
      barcode: barcode,
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

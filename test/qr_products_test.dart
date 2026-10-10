import 'package:flutter_test/flutter_test.dart';
import 'package:flash_cart/providers/cart_provider.dart';
import 'package:flash_cart/services/product_service.dart';

void main() {
  group('10 Authoritative QR Products & Self-Checkout Billing Tests', () {
    late ProductService productService;
    late CartProvider cartProvider;

    setUp(() {
      productService = ProductService();
      cartProvider = CartProvider();
    });

    final expectedCatalogue = [
      {'id': 'P001', 'barcode': 'FLASHCART-P001', 'name': 'Maggi', 'price': 20.0},
      {'id': 'P002', 'barcode': 'FLASHCART-P002', 'name': 'Biscuit packets', 'price': 15.0},
      {'id': 'P003', 'barcode': 'FLASHCART-P003', 'name': 'Surf Excel', 'price': 70.0},
      {'id': 'P004', 'barcode': 'FLASHCART-P004', 'name': 'Stationery', 'price': 200.0},
      {'id': 'P005', 'barcode': 'FLASHCART-P005', 'name': 'College bag', 'price': 699.0},
      {'id': 'P006', 'barcode': 'FLASHCART-P006', 'name': 'Water bottle', 'price': 288.0},
      {'id': 'P007', 'barcode': 'FLASHCART-P007', 'name': 'Sonpapidi (sweet)', 'price': 154.0},
      {'id': 'P008', 'barcode': 'FLASHCART-P008', 'name': 'Paneer', 'price': 299.0},
      {'id': 'P009', 'barcode': 'FLASHCART-P009', 'name': 'Cool drinks', 'price': 40.0},
      {'id': 'P0010', 'barcode': 'FLASHCART-P0010', 'name': 'Lays packet', 'price': 50.0},
    ];

    test('1. All 10 QR codes look up correct product and authoritative price', () async {
      for (final item in expectedCatalogue) {
        final barcode = item['barcode'] as String;
        final expectedName = item['name'] as String;
        final expectedPrice = item['price'] as double;

        final product = await productService.getProductByBarcode(barcode);
        expect(product, isNotNull, reason: 'Product with barcode $barcode should exist');
        expect(product!.name, equals(expectedName));
        expect(product.price, equals(expectedPrice));
      }
    });

    test('2. Unknown QR code returns null and does not add phantom product', () async {
      final product = await productService.getProductByBarcode('UNKNOWN_CODE_999');
      expect(product, isNull);
    });

    test('3. Scanning items accumulates correctly and increments quantity on repeat scan', () async {
      // 1. Scan Maggi (₹20)
      final maggi = await productService.getProductByBarcode('FLASHCART-P001');
      expect(maggi, isNotNull);
      cartProvider.addProduct(maggi!);

      expect(cartProvider.itemCount, equals(1));
      expect(cartProvider.subtotal, equals(20.0));

      // 2. Repeat scan Maggi -> quantity becomes 2
      cartProvider.addProduct(maggi);
      expect(cartProvider.itemCount, equals(2));
      expect(cartProvider.items.length, equals(1)); // Still 1 unique item line
      expect(cartProvider.items.first.quantity, equals(2));
      expect(cartProvider.items.first.subtotal, equals(40.0));

      // 3. Scan Lays packet (₹50)
      final lays = await productService.getProductByBarcode('FLASHCART-P0010');
      expect(lays, isNotNull);
      cartProvider.addProduct(lays!);

      expect(cartProvider.itemCount, equals(3));
      expect(cartProvider.items.length, equals(2));
      expect(cartProvider.subtotal, equals(90.0)); // 2*20 + 1*50 = 90
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flash_cart/models/product.dart';
import 'package:flash_cart/providers/cart_provider.dart';

void main() {
  group('CartProvider Unit Tests', () {
    late CartProvider cart;
    late Product milk; // 0% GST
    late Product biscuits; // 5% GST
    late Product soap; // 18% GST

    setUp(() {
      cart = CartProvider();

      milk = const Product(
        id: 'p1',
        name: 'Amul Taaza Milk',
        barcode: '8901234567890',
        price: 68.0,
        weight: '1 L',
        unit: 'L',
        category: 'Dairy',
        imageUrl: '',
        description: 'Milk',
        stock: 50,
        taxPercentage: 0.0,
        isAvailable: true,
      );

      biscuits = const Product(
        id: 'p2',
        name: 'Parle-G Biscuits',
        barcode: '8901234567891',
        price: 20.0,
        weight: '250 g',
        unit: 'g',
        category: 'Biscuits',
        imageUrl: '',
        description: 'Biscuits',
        stock: 100,
        taxPercentage: 5.0,
        isAvailable: true,
      );

      soap = const Product(
        id: 'p3',
        name: 'Dove Soap',
        barcode: '8901234567892',
        price: 55.0,
        weight: '100 g',
        unit: 'g',
        category: 'Personal Care',
        imageUrl: '',
        description: 'Soap',
        stock: 40,
        taxPercentage: 18.0,
        isAvailable: true,
      );
    });

    test('1. Initial cart is empty with zero totals', () {
      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, equals(0));
      expect(cart.subtotal, equals(0.0));
      expect(cart.tax, equals(0.0));
      expect(cart.total, equals(0.0));
    });

    test('2. Adding items updates quantities without duplicate rows', () {
      cart.addProduct(milk, quantity: 2);
      expect(cart.items.length, equals(1));
      expect(cart.itemCount, equals(2));
      expect(cart.items.first.quantity, equals(2));

      // Adding milk again must increment quantity, not create a duplicate row
      cart.addProduct(milk, quantity: 1);
      expect(cart.items.length, equals(1));
      expect(cart.itemCount, equals(3));
      expect(cart.items.first.quantity, equals(3));
    });

    test('3. Subtotal calculation matches unit prices and quantities', () {
      cart.addProduct(milk, quantity: 2); // 68 * 2 = 136
      cart.addProduct(biscuits, quantity: 1); // 20 * 1 = 20
      cart.addProduct(soap, quantity: 1); // 55 * 1 = 55

      // Subtotal: 136 + 20 + 55 = 211
      expect(cart.subtotal, equals(211.0));
    });

    test('4. Tax calculation applies configured per-product tax rates', () {
      cart.addProduct(milk, quantity: 2); // 136 @ 0% = 0.0
      cart.addProduct(biscuits, quantity: 1); // 20 @ 5% = 1.0
      cart.addProduct(soap, quantity: 1); // 55 @ 18% = 9.90

      // Tax: 0.0 + 1.0 + 9.90 = 10.90
      expect(cart.tax, equals(10.90));
    });

    test('5. Grand total equals Subtotal + Tax - Discount', () {
      cart.addProduct(milk, quantity: 2); // 136
      cart.addProduct(biscuits, quantity: 1); // 20
      cart.addProduct(soap, quantity: 1); // 55

      // Total before discount: 211 + 10.90 = 221.90
      expect(cart.total, equals(221.90));

      // Apply ₹50 discount coupon
      final applied = cart.applyCoupon('FLASH50');
      expect(applied, isTrue);
      expect(cart.discount, equals(50.0));

      // Total after discount: 221.90 - 50 = 171.90
      expect(cart.total, equals(171.90));
    });

    test('6. Quantity updates: increase, decrease, decrease to zero removes item', () {
      cart.addProduct(biscuits, quantity: 2);
      expect(cart.items.first.quantity, equals(2));

      cart.increaseQuantity(biscuits.barcode);
      expect(cart.items.first.quantity, equals(3));

      cart.decreaseQuantity(biscuits.barcode);
      expect(cart.items.first.quantity, equals(2));

      cart.updateQuantity(biscuits.barcode, 0);
      expect(cart.isEmpty, isTrue);
    });

    test('7. Removing an item removes it from cart', () {
      cart.addProduct(milk);
      cart.addProduct(soap);
      expect(cart.items.length, equals(2));

      cart.removeItem(milk.barcode);
      expect(cart.items.length, equals(1));
      expect(cart.items.first.product.barcode, equals(soap.barcode));
    });

    test('8. Duplicate scan debouncing cooldown enforces delay', () {
      // First scan should be allowed
      expect(cart.canScanBarcode('8901234567890'), isTrue);

      // Immediate second scan of same barcode should be rejected
      expect(cart.canScanBarcode('8901234567890'), isFalse);

      // Different barcode should be allowed immediately
      expect(cart.canScanBarcode('8901234567891'), isTrue);
    });
  });
}

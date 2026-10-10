import 'package:flutter_test/flutter_test.dart';
import 'package:flash_cart/models/cart_item.dart';
import 'package:flash_cart/models/order.dart';
import 'package:flash_cart/models/product.dart';
import 'package:flash_cart/services/order_service.dart';
import 'package:flash_cart/services/product_service.dart';

void main() {
  group('Order & Staff Exit Verification Rules', () {
    late OrderService orderService;
    late ProductService productService;
    late OrderModel samplePaidOrder;
    late OrderModel sampleUnpaidOrder;

    setUp(() async {
      orderService = OrderService();
      productService = ProductService();

      const testProduct = Product(
        id: 'prod_8901234567890',
        name: 'Amul Taaza Toned Milk',
        barcode: '8901234567890',
        price: 68.0,
        weight: '1 L',
        unit: 'L',
        category: 'Dairy',
        imageUrl: '',
        description: 'Milk',
        stock: 100,
        taxPercentage: 0.0,
        isAvailable: true,
      );

      final item = CartItem(product: testProduct, quantity: 2);

      samplePaidOrder = OrderModel(
        orderId: 'FC_TEST_999901',
        userId: 'user_123',
        userName: 'Customer Test',
        userEmail: 'customer@test.com',
        items: [item],
        subtotal: 136.0,
        tax: 0.0,
        discount: 0.0,
        total: 136.0,
        paymentStatus: 'paid',
        paymentId: 'PAY_FC_TEST_01',
        orderStatus: 'paid',
        createdAt: DateTime.now(),
        exitVerified: false,
      );

      sampleUnpaidOrder = OrderModel(
        orderId: 'FC_TEST_999902',
        userId: 'user_123',
        userName: 'Customer Test',
        userEmail: 'customer@test.com',
        items: [item],
        subtotal: 136.0,
        tax: 0.0,
        discount: 0.0,
        total: 136.0,
        paymentStatus: 'pending',
        paymentId: '',
        orderStatus: 'created',
        createdAt: DateTime.now(),
        exitVerified: false,
      );

      await orderService.createOrder(samplePaidOrder);
      await orderService.createOrder(sampleUnpaidOrder);
    });

    test('1. Unknown product barcode returns null', () async {
      final product = await productService.getProductByBarcode('0000000000000');
      expect(product, isNull);
    });

    test('2. Known product barcode returns matching Product', () async {
      final product = await productService.getProductByBarcode('8901234567890');
      expect(product, isNotNull);
      expect(product!.name, contains('Amul Taaza'));
      expect(product.price, equals(68.0));
    });

    test('3. Verification on non-existent order returns INVALID ORDER', () async {
      final result = await orderService.verifyOrderExit(
        qrPayload: 'FC_DOES_NOT_EXIST',
        staffId: 'staff_guard_1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.title, equals('INVALID ORDER'));
    });

    test('4. Verification on UNPAID order rejects exit with PAYMENT UNPAID', () async {
      final result = await orderService.verifyOrderExit(
        qrPayload: sampleUnpaidOrder.orderId,
        staffId: 'staff_guard_1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.title, equals('PAYMENT UNPAID'));
    });

    test('5. Valid paid order verifies successfully and marks exitVerified = true', () async {
      final result = await orderService.verifyOrderExit(
        qrPayload: samplePaidOrder.orderId,
        staffId: 'staff_guard_1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.title, equals('PAYMENT VERIFIED — ORDER VALID'));

      // Check updated order state
      final updatedOrder = await orderService.getOrderById(samplePaidOrder.orderId);
      expect(updatedOrder, isNotNull);
      expect(updatedOrder!.exitVerified, isTrue);
      expect(updatedOrder.verifiedBy, equals('staff_guard_1'));
    });

    test('6. Re-scanning an already-verified order rejects exit with ALREADY VERIFIED', () async {
      final duplicateOrder = samplePaidOrder.copyWith(orderId: 'FC_TEST_DUP_001');
      await orderService.createOrder(duplicateOrder);

      // First verification succeeds
      final firstCheck = await orderService.verifyOrderExit(
        qrPayload: duplicateOrder.orderId,
        staffId: 'staff_guard_1',
      );
      expect(firstCheck.isSuccess, isTrue);

      // Second verification with the same QR must be blocked
      final secondCheck = await orderService.verifyOrderExit(
        qrPayload: duplicateOrder.orderId,
        staffId: 'staff_guard_2',
      );

      expect(secondCheck.isSuccess, isFalse);
      expect(secondCheck.title, equals('ALREADY VERIFIED'));
    });
  });
}

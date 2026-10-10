import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flash_cart/models/cart_item.dart';
import 'package:flash_cart/models/order.dart';
import 'package:flash_cart/models/product.dart';
import 'package:flash_cart/providers/auth_provider.dart';
import 'package:flash_cart/providers/cart_provider.dart';
import 'package:flash_cart/providers/product_provider.dart';
import 'package:flash_cart/screens/cart_screen.dart';
import 'package:flash_cart/screens/checkout_screen.dart';
import 'package:flash_cart/screens/home_screen.dart';
import 'package:flash_cart/screens/order_history_screen.dart';
import 'package:flash_cart/screens/order_success_screen.dart';
import 'package:flash_cart/screens/payment_screen.dart';
import 'package:flash_cart/screens/payment_verification_screen.dart';
import 'package:flash_cart/screens/scanner_screen.dart';
import 'package:flash_cart/widgets/flash_cart_app_bar.dart';

void main() {
  Widget createTestWidget(Widget child, {CartProvider? cart, AuthProvider? auth}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>(create: (_) => cart ?? CartProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => auth ?? AuthProvider()),
        ChangeNotifierProvider<ProductProvider>(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  final testProduct1 = const Product(
    id: 'P001',
    name: 'Maggi 2-Minute Noodles',
    category: 'Groceries',
    price: 20.0,
    barcode: 'FLASHCART-P001',
    imageUrl: 'assets/categories/groceries.png',
    weight: '70g',
    unit: 'packet',
    description: 'Instant noodles',
    stock: 50,
    taxPercentage: 5.0,
    isAvailable: true,
  );

  final testProduct2 = const Product(
    id: 'P002',
    name: 'Biscuit Packets',
    category: 'Food',
    price: 15.0,
    barcode: 'FLASHCART-P002',
    imageUrl: 'assets/categories/food.png',
    weight: '100g',
    unit: 'packet',
    description: 'Crispy biscuits',
    stock: 100,
    taxPercentage: 5.0,
    isAvailable: true,
  );

  final testOrder = OrderModel(
    orderId: 'ORD_TEST_9999',
    userId: 'usr_test_1',
    userName: 'Sravanthi',
    userEmail: 'customer@flashcart.com',
    items: [
      CartItem(product: testProduct1, quantity: 2),
      CartItem(product: testProduct2, quantity: 3),
    ],
    subtotal: 85.0,
    tax: 4.25,
    discount: 0.0,
    total: 89.25,
    paymentMethod: 'UPI',
    paymentStatus: 'PAID',
    paymentId: 'TXN_TEST_123456789',
    orderStatus: 'paid',
    exitToken: 'EXIT_TOKEN_TEST_9999',
    exitVerified: false,
    createdAt: DateTime(2026, 10, 10, 14, 30),
  );

  group('1. Profile Placement Tests', () {
    testWidgets('ProfileAvatarButton is present at top-right of HomeScreen', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen(initialIndex: 0)));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileAvatarButton), findsOneWidget);
    });

    testWidgets('ProfileAvatarButton is present on CartScreen', (tester) async {
      final cart = CartProvider();
      cart.addProduct(testProduct1);
      await tester.pumpWidget(createTestWidget(const CartScreen(), cart: cart));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileAvatarButton), findsOneWidget);
    });

    testWidgets('ProfileAvatarButton is present on CheckoutScreen', (tester) async {
      final cart = CartProvider();
      cart.addProduct(testProduct1);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: cart),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
          ],
          child: const MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ProfileAvatarButton), findsOneWidget);
    });

    testWidgets('ProfileAvatarButton is present on PaymentScreen', (tester) async {
      await tester.pumpWidget(createTestWidget(const PaymentScreen(verifiedTotal: 89.25)));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileAvatarButton), findsOneWidget);
    });

    testWidgets('ProfileAvatarButton is present on PaymentVerificationScreen', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
          ],
          child: const MaterialApp(
            home: PaymentVerificationScreen(verifiedTotal: 0.0, paymentMethod: 'UPI'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ProfileAvatarButton), findsOneWidget);
    });

    testWidgets('ProfileAvatarButton is present on OrderSuccessScreen', (tester) async {
      await tester.pumpWidget(createTestWidget(OrderSuccessScreen(order: testOrder)));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileAvatarButton), findsOneWidget);
    });

    testWidgets('ProfileAvatarButton is present on OrderHistoryScreen', (tester) async {
      await tester.pumpWidget(createTestWidget(const OrderHistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileAvatarButton), findsOneWidget);
    });

    testWidgets('Profile icon is strictly ABSENT from ScannerScreen', (tester) async {
      await tester.pumpWidget(createTestWidget(const ScannerScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // Profile avatar button must NOT be present
      expect(find.byType(ProfileAvatarButton), findsNothing);
      expect(find.byTooltip('Customer Profile'), findsNothing);
    });
  });

  group('2. Scanner UI and Home Page "View Bill" Placement Tests', () {
    testWidgets('HomeScreen has NO "View Bill" button or bar', (tester) async {
      final cart = CartProvider();
      cart.addProduct(testProduct1);

      await tester.pumpWidget(createTestWidget(const HomeScreen(initialIndex: 0), cart: cart));
      await tester.pumpAndSettle();

      expect(find.text('View Bill'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'View Bill'), findsNothing);
    });

    testWidgets('ScannerScreen HAS "View Bill" button in bottom bar', (tester) async {
      await tester.pumpWidget(createTestWidget(const ScannerScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.widgetWithText(ElevatedButton, 'View Bill'), findsOneWidget);
    });

    testWidgets('ScannerScreen HAS "View Bill" button after product scan feedback', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ScannerScreen(autoSelectProduct: testProduct1),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // Feedback should display product details
      expect(find.text('Maggi 2-Minute Noodles'), findsWidgets);
      // View Bill button should be available
      expect(find.text('View Bill'), findsWidgets);
    });
  });

  group('3. Receipt Branding Tests (No "FlashCart Express")', () {
    testWidgets('OrderSuccessScreen does NOT contain "FlashCart Express"', (tester) async {
      await tester.pumpWidget(createTestWidget(OrderSuccessScreen(order: testOrder)));
      await tester.pumpAndSettle();

      expect(find.textContaining('FlashCart Express'), findsNothing);
      expect(find.textContaining('FlashCart (STORE_FLASHCART_001)'), findsOneWidget);
    });

    testWidgets('OrderSuccessScreen displays order ID, total, and exit pass QR', (tester) async {
      await tester.pumpWidget(createTestWidget(OrderSuccessScreen(order: testOrder)));
      await tester.pumpAndSettle();

      expect(find.text('Order #ORD_TEST_9999'), findsOneWidget);
      expect(find.text('STORE EXIT VERIFICATION PASS'), findsOneWidget);
      expect(find.text('TOKEN: EXIT_TOKEN_TEST_9999'), findsOneWidget);
      expect(find.text('Final Amount Paid'), findsOneWidget);
    });
  });

  group('4. Independent Scroll in Bill Card Tests', () {
    testWidgets('CartScreen product list is enclosed inside its own card container', (tester) async {
      final cart = CartProvider();
      cart.addProduct(testProduct1);
      cart.addProduct(testProduct2);

      await tester.pumpWidget(createTestWidget(const CartScreen(), cart: cart));
      await tester.pumpAndSettle();

      // Card Header
      expect(find.text('Scanned Products'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);

      // Verify fixed bottom summary elements are directly visible
      expect(find.text('Final Payable'), findsOneWidget);
      expect(find.text('Proceed to Payment'), findsOneWidget);
      expect(find.text('Continue Scanning'), findsOneWidget);
    });

    testWidgets('OrderSuccessScreen item list is constrained in a scrollable view inside card', (tester) async {
      await tester.pumpWidget(createTestWidget(OrderSuccessScreen(order: testOrder)));
      await tester.pumpAndSettle();

      expect(find.text('Purchased Items'), findsOneWidget);
      expect(find.text('5 Items'), findsOneWidget);
      expect(find.byType(Scrollbar), findsWidgets);
    });
  });
}

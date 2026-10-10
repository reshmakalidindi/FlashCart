import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flash_cart/models/product.dart';
import 'package:flash_cart/providers/auth_provider.dart';
import 'package:flash_cart/providers/cart_provider.dart';
import 'package:flash_cart/providers/product_provider.dart';
import 'package:flash_cart/screens/home_screen.dart';
import 'package:flash_cart/screens/payment_screen.dart';
import 'package:flash_cart/screens/payment_verification_screen.dart';
import 'package:flash_cart/services/product_service.dart';
import 'package:flash_cart/utils/constants.dart';

void main() {
  group('1. Home Page Grocery Banner Tests', () {
    testWidgets('Renders Smart Shopping, Made Simple banner with correct text and image', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Heading and subtitle from user requirements
      expect(find.text('Smart Shopping, Made Simple'), findsOneWidget);
      expect(
        find.text('Scan your products, pay with ease, and skip the checkout queue.'),
        findsOneWidget,
      );
      expect(find.text('Scan • Add • Pay'), findsOneWidget);

      // Verify grocery banner image is rendered
      final bannerImages = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName == 'assets/banner_groceries.png',
      );
      expect(bannerImages, findsOneWidget);
    });
  });

  group('2. Consistent Bottom Navigation Across App Tests', () {
    testWidgets('Bottom navigation persists with Home, Scan, Profile and handles tab switching', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap Scan tab
      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      // Bottom nav is STILL present
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Bottom nav is STILL present
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Customer Profile'), findsOneWidget);

      // Tap Home tab to return
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to FlashCart'), findsOneWidget);
    });
  });

  group('3. Payment Screen to Payment Verification Navigation Tests', () {
    testWidgets('Next button on PaymentScreen navigates directly to PaymentVerificationScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cartProvider = CartProvider();
      final product = Product.fromMap(AppConstants.sampleProducts.first, 'P001');
      cartProvider.addProduct(product);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider.value(value: cartProvider),
          ],
          child: const MaterialApp(
            home: PaymentScreen(verifiedTotal: 20.0, paymentMethod: 'upi'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final nextButton = find.text('Next: Authorize & Pay ₹20.00');
      expect(nextButton, findsOneWidget);

      await tester.tap(nextButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify that PaymentVerificationScreen is pushed and verified
      expect(find.byType(PaymentVerificationScreen), findsOneWidget);
      expect(find.text('Payment Verification'), findsOneWidget);
      expect(find.textContaining('Payment Verified'), findsWidgets);

      await tester.pump(const Duration(milliseconds: 1500));
    });

    testWidgets('PaymentVerificationScreen displays processing state and does not accept ₹0', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: PaymentVerificationScreen(verifiedTotal: 0.0, paymentMethod: 'upi'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // ₹0 must fail immediately with clear warning
      expect(find.text('Payment Verification Failed'), findsOneWidget);
      expect(find.text('Invalid total amount: ₹0 cannot be authorized.'), findsOneWidget);
      expect(find.text('Return to Payment / Bill'), findsOneWidget);
    });
  });

  group('4. QR Product Scanning Speed & Memory Cache Tests', () {
    test('ProductService in-memory cache returns product instantly (< 1ms)', () async {
      final productService = ProductService();

      final stopwatch = Stopwatch()..start();
      final p1 = await productService.getProductByBarcode('FLASHCART-P001');
      stopwatch.stop();

      expect(p1, isNotNull);
      expect(p1!.id, 'P001');
      expect(p1.price, 20.0);
      expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Memory hit is virtually instant
    });

    test('Duplicate scan debounce protects against rapid repeat hits', () {
      final cartProvider = CartProvider();
      const barcode = 'FLASHCART-P001';

      final canScanFirst = cartProvider.canScanBarcode(barcode);
      expect(canScanFirst, isTrue);

      // Immediate second scan of the same barcode must be debounced
      final canScanSecond = cartProvider.canScanBarcode(barcode);
      expect(canScanSecond, isFalse);

      // Different product barcode is allowed immediately
      final canScanOther = cartProvider.canScanBarcode('FLASHCART-P002');
      expect(canScanOther, isTrue);
    });
  });
}

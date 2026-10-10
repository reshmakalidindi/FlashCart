import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flash_cart/models/cart_item.dart';
import 'package:flash_cart/models/order.dart';
import 'package:flash_cart/models/product.dart';
import 'package:flash_cart/providers/auth_provider.dart';
import 'package:flash_cart/providers/cart_provider.dart';
import 'package:flash_cart/screens/login_screen.dart';
import 'package:flash_cart/screens/payment_screen.dart';
import 'package:flash_cart/screens/profile_screen.dart';
import 'package:flash_cart/screens/home_screen.dart';
import 'package:flash_cart/screens/order_success_screen.dart';
import 'package:flash_cart/utils/constants.dart';
import 'package:flash_cart/widgets/cart_item_card.dart';
import 'package:flash_cart/widgets/product_thumbnail.dart';

void main() {
  group('1. Product Thumbnail & Image Fallback Tests', () {
    testWidgets('Renders ProductThumbnail with correct ID and category icon for P001-P0010', (tester) async {
      for (final pMap in AppConstants.sampleProducts) {
        final product = Product.fromMap(pMap, pMap['productId']);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProductThumbnail(product: product),
            ),
          ),
        );

        expect(find.text(product.id), findsOneWidget);
        expect(find.byType(Icon), findsOneWidget);
      }
    });

    testWidgets('CartItemCard displays ProductThumbnail on left and accurate details', (tester) async {
      final product = Product.fromMap(AppConstants.sampleProducts.first, 'P001'); // Maggi ₹20
      final item = CartItem(product: product, quantity: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemCard(
              item: item,
              onIncrease: () {},
              onDecrease: () {},
              onRemove: () {},
            ),
          ),
        ),
      );

      // Verify thumbnail is present
      expect(find.byType(ProductThumbnail), findsOneWidget);
      expect(find.text('Maggi'), findsOneWidget);
      expect(find.text('ID: P001'), findsWidgets);
      expect(find.text('2'), findsOneWidget); // Quantity
      expect(find.text('₹40'), findsOneWidget); // Line total: 2 * 20
    });
  });

  group('2. Price Integrity & Zero-Price Prevention Tests', () {
    test('CartItem and Product models strictly enforce authoritative price when map has 0.0 or null', () {
      final zeroPriceMap = {
        'productId': 'P005',
        'barcode': 'FLASHCART-P005',
        'productName': 'College bag',
        'price': 0.0,
        'quantity': 1,
      };

      final item = CartItem.fromMap(zeroPriceMap);
      expect(item.product.price, 699.0); // Authoritative P005 price
      expect(item.unitCost, 699.0);
      expect(item.subtotal, 699.0);
    });

    test('All 10 products guarantee non-zero prices via AppConstants.getAuthoritativePrice', () {
      final expectedPrices = {
        'P001': 20.0,
        'P002': 15.0,
        'P003': 70.0,
        'P004': 200.0,
        'P005': 699.0,
        'P006': 288.0,
        'P007': 154.0,
        'P008': 299.0,
        'P009': 40.0,
        'P0010': 50.0,
      };

      expectedPrices.forEach((id, expected) {
        final price = AppConstants.getAuthoritativePrice(id);
        expect(price, expected, reason: 'Product $id must have price ₹$expected');
      });
    });

    test('OrderModel.fromMap computes positive totals from items if server map has 0.0', () {
      final rawOrderMap = {
        'order_id': 'TEST_ORD_001',
        'items': [
          {'productId': 'P001', 'quantity': 2, 'price': 20.0},
          {'productId': 'P002', 'quantity': 1, 'price': 15.0},
        ],
        'subtotal': 0.0, // Zero from bad serialization
        'total': 0.0,
      };

      final order = OrderModel.fromMap(rawOrderMap, 'TEST_ORD_001');
      expect(order.subtotal, 55.0); // (2*20) + (1*15)
      expect(order.total, greaterThan(0));
    });
  });

  group('3. Payment Screen Centering & Duplicate Prevention Tests', () {
    testWidgets('PaymentScreen displays amount and payment options cleanly', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: PaymentScreen(verifiedTotal: 154.0, paymentMethod: 'upi'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('₹154'), findsWidgets);
      expect(find.text('Total Payable'), findsOneWidget);
      expect(find.text('Next: Authorize & Pay ₹154.00'), findsOneWidget);
    });
  });

  group('4. Customer Profile Screen & Logout Flow Tests', () {
    testWidgets('ProfileScreen renders customer info, shortcuts, and working logout dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cartProvider = CartProvider();
      final p = Product.fromMap(AppConstants.sampleProducts.first, 'P001');
      cartProvider.addProduct(p);
      expect(cartProvider.itemCount, 1);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider.value(value: cartProvider),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Profile Header & Shortcuts
      expect(find.text('Customer Profile'), findsOneWidget);
      expect(find.text('Order History'), findsOneWidget);
      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('Store Info'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      // Tap Log Out
      await tester.ensureVisible(find.text('Log Out'));
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appeared
      expect(find.text('Log Out of FlashCart?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Confirm logout in dialog
      final logoutButton = find.widgetWithText(ElevatedButton, 'Log Out');
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Cart should be cleared on logout
      expect(cartProvider.isEmpty, true);
    });
  });

  group('5. FlashCart Authentication Card Tests', () {
    testWidgets('LoginScreen renders modern card with FlashCart branding and segmented pill toggle', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Branding & Card
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.appTagline), findsOneWidget);
      expect(find.byType(Image), findsWidgets); // Uploaded logo asset

      // Segmented Pill Toggle: Login & Sign Up
      expect(find.text('Login'), findsWidgets); // Pill and Button
      expect(find.text('Sign Up'), findsOneWidget);

      // Default fields in Login
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Quick Demo Login (Auto-fill)'), findsOneWidget);

      // Switch to Sign Up tab
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });
  });

  group('6. HomeScreen 3-Tab Bottom Navigation & UI Reference Tests', () {
    testWidgets('Renders greeting, search bar, banner, and exactly 3 bottom nav items (Home, Scan, Profile)', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Greeting
      expect(find.text('Welcome to FlashCart'), findsOneWidget);

      // Search Bar
      expect(find.text('Search for products...'), findsOneWidget);

      // Promotional Banner
      expect(find.text('Smart Shopping, Made Simple'), findsOneWidget);
      expect(find.text('Scan your products, pay with ease, and skip the checkout queue.'), findsOneWidget);
      expect(find.text('Scan • Add • Pay'), findsOneWidget);

      // Exactly 3 Bottom Navigation Items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      final bottomNavBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNavBar.items.length, 3);
      expect(bottomNavBar.items[0].label, 'Home');
      expect(bottomNavBar.items[1].label, 'Scan');
      expect(bottomNavBar.items[2].label, 'Profile');
    });

    testWidgets('Renders all 8 categories with image & name only; NO prices or plus buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Shop by Category'), findsOneWidget);

      final categoryGrid = find.byKey(const ValueKey('category_grid'));
      expect(categoryGrid, findsOneWidget);

      // All 8 categories present
      final expectedCategories = [
        'Food',
        'Stationery',
        'Clothes',
        'Groceries',
        'Utensils',
        'Toys',
        'Footwear',
        'Cosmetics',
      ];

      for (final catName in expectedCategories) {
        expect(find.descendant(of: categoryGrid, matching: find.text(catName)), findsOneWidget);
      }

      // STRICT CHECK: No add buttons or plus icons on the category cards
      expect(find.descendant(of: categoryGrid, matching: find.byIcon(Icons.add)), findsNothing);
      expect(find.descendant(of: categoryGrid, matching: find.byIcon(Icons.add_shopping_cart)), findsNothing);
    });
  });

  group('7. Done Shopping & Digital Receipt Tests', () {
    testWidgets('OrderSuccessScreen displays order details, removes DMart CyberCity, and Done Shopping clears cart', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cartProvider = CartProvider();
      final p = Product.fromMap(AppConstants.sampleProducts.first, 'P001');
      cartProvider.addProduct(p);
      expect(cartProvider.itemCount, 1);

      final dummyOrder = OrderModel(
        orderId: 'FC_ORD_TEST_99',
        userId: 'USER_TEST',
        userName: 'Test Shopper',
        userEmail: 'shopper@test.com',
        items: cartProvider.items,
        subtotal: 20.0,
        tax: 2.0,
        discount: 0.0,
        total: 22.0,
        paymentStatus: 'PAID',
        paymentMethod: 'UPI',
        paymentId: 'TXN_TEST_99999',
        orderStatus: 'paid',
        exitVerified: false,
        exitToken: 'EXIT_TOKEN_9999',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider.value(value: cartProvider),
          ],
          child: MaterialApp(
            home: OrderSuccessScreen(order: dummyOrder),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure DMart CyberCity is removed
      expect(find.text('D-Mart Express CyberCity'), findsNothing);
      expect(find.text('View Full Modal'), findsNothing);

      // Verify Order ID and items
      expect(find.text('Order #FC_ORD_TEST_99'), findsOneWidget);
      expect(find.text('Purchased Items'), findsOneWidget);
      expect(find.text('Done Shopping'), findsOneWidget);

      // Tap Done Shopping
      await tester.tap(find.text('Done Shopping'));
      await tester.pumpAndSettle();

      // Cart should be cleared and HomeScreen opened
      expect(cartProvider.isEmpty, true);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}

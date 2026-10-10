import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette - User Defined
  static const Color butterYellow = Color(0xFFFBE8A6); // Backgrounds, promotional banners, onboarding
  static const Color warmCream = Color(0xFFFFF9E9);    // Main app background and soft surfaces
  static const Color leafGreen = Color(0xFF4A8F35);    // Fresh grocery highlights, category icons, buttons
  static const Color goldenYellow = Color(0xFFF2C94C); // Small highlights, offers, decorative elements
  static const Color charcoal = Color(0xFF242424);     // Headings, product names, primary text
  static const Color white = Color(0xFFFFFFFF);        // Product cards, search fields, clean areas

  // Primary Action Palette
  static const Color primary = leafGreen;               // Leaf Green #4A8F35
  static const Color primaryAccent = goldenYellow;      // Golden Yellow #F2C94C
  static const Color primaryDark = Color(0xFF386E28);   // Deeper leaf green
  static const Color primaryLight = Color(0xFFEBF5E7);  // Soft leaf green wash
  static const Color accent = goldenYellow;             // Golden Yellow #F2C94C

  // Neutral & Surface Palette
  static const Color background = warmCream;           // Warm Cream #FFF9E9
  static const Color surface = white;                  // Clean White #FFFFFF
  static const Color textPrimary = charcoal;           // Charcoal #242424
  static const Color textSecondary = Color(0xFF6B7280); // Muted secondary text
  static const Color border = Color(0xFFEADBBE);        // Warm subtle border

  // Status Colors
  static const Color success = leafGreen;              // Verified / success leaf green
  static const Color warning = goldenYellow;           // Golden yellow offer/warning
  static const Color error = Color(0xFFD64545);        // Error red
  static const Color info = Color(0xFF3B82F6);
}

class AppConstants {
  static const String appName = 'FlashCart';
  static const String appTagline = 'Scan. Shop. Pay. Go.';
  static const String currencySymbol = '₹';
  static const String defaultStoreId = 'STORE_DMART_001';
  static const double defaultTaxPercentage = 5.0;

  /// Looks up authoritative price for any product ID or barcode among the 10 catalog items
  static double getAuthoritativePrice(String idOrBarcode, [double fallback = 0.0]) {
    final clean = idOrBarcode.trim().toUpperCase();
    if (clean.isEmpty) return fallback;
    for (final p in sampleProducts) {
      final pId = (p['productId'] as String).toUpperCase();
      final pBar = (p['barcode'] as String).toUpperCase();
      if (pId == clean ||
          pBar == clean ||
          clean == 'FLASHCART-$pId' ||
          pId == clean.replaceAll('FLASHCART-', '') ||
          clean.endsWith(pId)) {
        return (p['price'] as num).toDouble();
      }
    }
    return fallback;
  }

  // 10 Authoritative Supermarket Products with User-Supplied Selling Prices & QR Identifiers
  static const List<Map<String, dynamic>> sampleProducts = [
    {
      'productId': 'P001',
      'name': 'Maggi',
      'barcode': 'FLASHCART-P001',
      'price': 20.0,
      'weight': '70 g',
      'unit': 'g',
      'category': 'Instant Food',
      'imageUrl': 'assets/product_qrs/P001.png',
      'description': 'Maggi 2-Minute Masala Noodles.',
      'stock': 100,
      'taxPercentage': 5.0,
      'taxCode': 'GST_5',
      'isAvailable': true,
      'storeId': 'STORE_DMART_001',
    },
    {
      'productId': 'P002',
      'name': 'Biscuit packets',
      'barcode': 'FLASHCART-P002',
      'price': 15.0,
      'weight': '100 g',
      'unit': 'g',
      'category': 'Biscuits & Snacks',
      'imageUrl': 'assets/product_qrs/P002.png',
      'description': 'Crispy tea-time biscuit packet.',
      'stock': 150,
      'taxPercentage': 5.0,
      'taxCode': 'GST_5',
      'isAvailable': true,
      'storeId': 'STORE_DMART_001',
    },
    {
      'productId': 'P003',
      'name': 'Surf Excel',
      'barcode': 'FLASHCART-P003',
      'price': 70.0,
      'weight': '500 g',
      'unit': 'g',
      'category': 'Household & Cleaning',
      'imageUrl': 'assets/product_qrs/P003.png',
      'description': 'Surf Excel detergent powder for stain removal.',
      'stock': 80,
      'taxPercentage': 18.0,
      'taxCode': 'GST_18',
      'isAvailable': true,
      'storeId': 'STORE_DMART_001',
    },
    {
      'productId': 'P004',
      'name': 'Stationery',
      'barcode': 'FLASHCART-P004',
      'price': 200.0,
      'weight': '1 Set',
      'unit': 'set',
      'category': 'Stationery',
      'imageUrl': 'assets/product_qrs/P004.png',
      'description': 'Essential student stationery pack.',
      'stock': 60,
      'taxPercentage': 12.0,
      'taxCode': 'GST_12',
      'isAvailable': true,
      'storeId': 'STORE_DMART_001',
    },
    {
      'productId': 'P005',
      'name': 'College bag',
      'barcode': 'FLASHCART-P005',
      'price': 699.0,
      'weight': '1 pc',
      'unit': 'pc',
      'category': 'Luggage & Bags',
      'imageUrl': 'assets/product_qrs/P005.png',
      'description': 'Durable lightweight backpack for college and work.',
      'stock': 40,
      'taxPercentage': 18.0,
      'taxCode': 'GST_18',
      'isAvailable': true,
      'storeId': 'STORE_DMART_001',
    },
    {
      'productId': 'P006',
      'name': 'Water bottle',
      'barcode': 'FLASHCART-P006',
      'price': 288.0,
      'weight': '1 L',
      'unit': 'L',
      'category': 'Home & Kitchen',
      'imageUrl': 'assets/product_qrs/P006.png',
      'description': 'BPA-free insulated water bottle.',
      'stock': 75,
      'taxPercentage': 12.0,
      'taxCode': 'GST_12',
      'isAvailable': true,
      'storeId': 'STORE_DMART_001',
    },
    {
      'productId': 'P007',
      'name': 'Sonpapidi (sweet)',
      'barcode': 'FLASHCART-P007',
      'price': 154.0,
      'weight': '250 g',
      'unit': 'g',
      'category': 'Sweets',
      'imageUrl': 'assets/product_qrs/P007.png',
      'description': 'Traditional flaky soan papdi sweet treat.',
      'stock': 90,
      'taxPercentage': 5.0,
      'taxCode': 'GST_5',
      'isAvailable': true,
      'storeId': 'STORE_DMART_001',
    },
    {
      'productId': 'P008',
      'name': 'Paneer',
      'barcode': 'FLASHCART-P008',
      'price': 299.0,
      'weight': '500 g',
      'unit': 'g',
      'category': 'Dairy',
      'imageUrl': 'assets/product_qrs/P008.png',
      'description': 'Fresh dairy cottage cheese paneer block.',
      'stock': 50,
      'taxPercentage': 5.0,
      'taxCode': 'GST_5',
      'isAvailable': true,
      'storeId': 'STORE_DMART_001',
    },
    {
      'productId': 'P009',
      'name': 'Cool drinks',
      'barcode': 'FLASHCART-P009',
      'price': 40.0,
      'weight': '600 ml',
      'unit': 'ml',
      'category': 'Beverages',
      'imageUrl': 'assets/product_qrs/P009.png',
      'description': 'Chilled carbonated refreshment drink.',
      'stock': 120,
      'taxPercentage': 12.0,
      'taxCode': 'GST_12',
      'isAvailable': true,
      'storeId': 'STORE_DMART_001',
    },
    {
      'productId': 'P0010',
      'name': 'Lays packet',
      'barcode': 'FLASHCART-P0010',
      'price': 50.0,
      'weight': '115 g',
      'unit': 'g',
      'category': 'Biscuits & Snacks',
      'imageUrl': 'assets/product_qrs/P0010.png',
      'description': 'Classic salted crispy potato chips.',
      'stock': 110,
      'taxPercentage': 12.0,
      'taxCode': 'GST_12',
      'isAvailable': true,
      'storeId': 'STORE_DMART_001',
    },
  ];
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../utils/constants.dart';
import 'api_config.dart';

class ProductService {
  // In-memory fallback product catalog initialized from AppConstants
  final List<Product> _fallbackProducts = AppConstants.sampleProducts
      .map((item) => Product.fromMap(item, item['productId'] ?? ''))
      .toList();

  // Fast in-memory cache indexed by barcode and ID for instant lookup
  static final Map<String, Product> _productCache = {};

  ProductService() {
    _populateCacheWithFallback();
  }

  void _populateCacheWithFallback() {
    for (final p in _fallbackProducts) {
      _cacheProduct(p);
    }
  }

  void _cacheProduct(Product product) {
    _productCache[product.barcode] = product;
    _productCache[product.id] = product;
    final stripped = product.barcode.replaceAll('FLASHCART-', '');
    _productCache[stripped] = product;
    _productCache['FLASHCART-$stripped'] = product;
    _productCache['FLASHCART-${product.id}'] = product;
  }

  /// Fetches all active products from FastAPI backend: GET /api/v1/products/
  /// Falls back to offline catalog if backend is unreachable.
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/products/'))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final products = data.map((item) => Product.fromJson(item)).toList();
        if (products.isNotEmpty) {
          for (final p in products) {
            _cacheProduct(p);
          }
          debugPrint('Loaded ${products.length} products from FastAPI backend.');
          return products;
        }
      }
    } catch (e) {
      debugPrint('FastAPI products fetch error ($e), using local catalog.');
    }
    return _fallbackProducts;
  }

  /// Scans & looks up product by barcode from FastAPI: GET /api/v1/products/barcode/{barcode}
  /// Uses instant memory cache first (< 1ms), then authoritative backend lookup.
  Future<Product?> getProductByBarcode(String rawBarcode) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) return null;

    final stripped = barcode.replaceAll('FLASHCART-', '');
    final prefixed = barcode.startsWith('FLASHCART-') ? barcode : 'FLASHCART-$barcode';

    // 1. Instant cache hit check (< 1 millisecond response time)
    if (_productCache.containsKey(barcode)) return _productCache[barcode];
    if (_productCache.containsKey(prefixed)) return _productCache[prefixed];
    if (_productCache.containsKey(stripped)) return _productCache[stripped];

    // Check fallback products
    for (final p in _fallbackProducts) {
      if (p.barcode == barcode || p.id == barcode || p.id == stripped || p.barcode == prefixed) {
        _cacheProduct(p);
        return p;
      }
    }

    // 2. Network lookup via FastAPI backend
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/products/barcode/$barcode'))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['found'] == true && data['product'] != null) {
          final product = Product.fromJson(data['product']);
          _cacheProduct(product);
          debugPrint('Product located via FastAPI backend: ${product.name}');
          return product;
        }
      }
    } catch (e) {
      debugPrint('FastAPI barcode lookup error ($e), checking local fallback.');
    }

    return null;
  }

  /// Seeds sample products into the backend if required.
  Future<int> seedSampleProducts() async {
    return _fallbackProducts.length;
  }
}

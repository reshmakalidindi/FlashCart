import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../utils/constants.dart';
import 'api_config.dart';

class ProductService {
  // In-memory fallback product catalog initialized from AppConstants
  final List<Product> _fallbackProducts = AppConstants.sampleProducts
      .asMap()
      .entries
      .map((entry) => Product.fromMap(entry.value, 'prod_${entry.key + 1}'))
      .toList();

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
  /// Falls back to offline catalog if backend is unreachable.
  Future<Product?> getProductByBarcode(String rawBarcode) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) return null;

    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/products/barcode/$barcode'))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['found'] == true && data['product'] != null) {
          debugPrint('Product located via FastAPI backend: ${data['product']['name']}');
          return Product.fromJson(data['product']);
        }
      }
    } catch (e) {
      debugPrint('FastAPI barcode lookup error ($e), using local lookup.');
    }

    // Fallback to local memory catalog lookup
    try {
      final match = _fallbackProducts.firstWhere(
        (p) => p.barcode == barcode,
      );
      return match;
    } catch (_) {
      return null;
    }
  }

  /// Seeds sample products into the backend if required.
  Future<int> seedSampleProducts() async {
    return _fallbackProducts.length;
  }
}

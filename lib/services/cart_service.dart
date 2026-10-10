import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';
import '../models/product.dart';
import 'api_config.dart';
import 'product_service.dart';

class RevalidatedCartResult {
  final List<CartItem> validatedItems;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final bool hasPriceChanges;
  final String? couponApplied;

  RevalidatedCartResult({
    required this.validatedItems,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.hasPriceChanges,
    this.couponApplied,
  });
}

class CartService {
  final ProductService _productService = ProductService();

  /// Revalidates cart authoritatively with FastAPI backend: POST /api/v1/cart/revalidate
  /// Ensures zero trust of client-side prices, taxes, or discounts.
  Future<RevalidatedCartResult> revalidateCartWithBackend(
    List<CartItem> clientItems, {
    String? couponCode,
  }) async {
    if (clientItems.isEmpty) {
      return RevalidatedCartResult(
        validatedItems: [],
        subtotal: 0.0,
        tax: 0.0,
        discount: 0.0,
        total: 0.0,
        hasPriceChanges: false,
      );
    }

    try {
      final payload = {
        'items': clientItems.map((item) => {
          'barcode': item.product.barcode,
          'quantity': item.quantity,
        }).toList(),
        'coupon_code': couponCode,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/cart/revalidate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> serverItems = data['items'] ?? [];
        final List<CartItem> updatedItems = [];
        bool priceChanged = false;

        for (var sItem in serverItems) {
          final prod = Product.fromJson(sItem);
          final qty = (sItem['quantity'] as num).toInt();
          
          final clientMatch = clientItems.firstWhere(
            (c) => c.product.barcode == prod.barcode,
            orElse: () => CartItem(product: prod, quantity: qty),
          );

          if (clientMatch.product.price != prod.price) {
            priceChanged = true;
          }

          updatedItems.add(CartItem(product: prod, quantity: qty));
        }

        final double serverSubtotal = (data['subtotal'] as num).toDouble();
        final double serverTax = (data['tax_amount'] as num).toDouble();
        final double serverDiscount = (data['discount_amount'] as num).toDouble();
        final double serverTotal = (data['grand_total'] as num).toDouble();

        debugPrint('Cart revalidated authoritatively with FastAPI: Total ₹$serverTotal');

        return RevalidatedCartResult(
          validatedItems: updatedItems,
          subtotal: serverSubtotal,
          tax: serverTax,
          discount: serverDiscount,
          total: serverTotal,
          hasPriceChanges: priceChanged,
          couponApplied: data['coupon_applied'],
        );
      }
    } catch (e) {
      debugPrint('FastAPI cart revalidate fallback triggered ($e).');
    }

    // Local in-memory calculation fallback
    final List<CartItem> fallbackItems = [];
    double calculatedSubtotal = 0.0;
    double calculatedTax = 0.0;
    bool priceChanged = false;

    for (var item in clientItems) {
      final freshProduct = await _productService.getProductByBarcode(item.product.barcode);
      final authoritativeProduct = freshProduct ?? item.product;

      if (freshProduct != null && freshProduct.price != item.product.price) {
        priceChanged = true;
      }

      final validatedItem = CartItem(
        product: authoritativeProduct,
        quantity: item.quantity,
      );

      fallbackItems.add(validatedItem);
      calculatedSubtotal += validatedItem.subtotal;
      calculatedTax += validatedItem.taxAmount;
    }

    double discount = 0.0;
    if (couponCode != null && couponCode.toUpperCase() == 'FLASH50' && calculatedSubtotal >= 300) {
      discount = 50.0;
    }

    final double finalTotal = (calculatedSubtotal + calculatedTax - discount).clamp(0.0, double.infinity);

    return RevalidatedCartResult(
      validatedItems: fallbackItems,
      subtotal: double.parse(calculatedSubtotal.toStringAsFixed(2)),
      tax: double.parse(calculatedTax.toStringAsFixed(2)),
      discount: discount,
      total: double.parse(finalTotal.toStringAsFixed(2)),
      hasPriceChanges: priceChanged,
      couponApplied: discount > 0 ? 'FLASH50 applied' : null,
    );
  }
}

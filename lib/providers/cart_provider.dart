import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();

  final List<CartItem> _items = [];
  double _discount = 0.0;
  String? _appliedCouponCode;
  bool _isRevalidating = false;
  bool _isProcessingPayment = false;
  String? _lastScannedBarcode;
  DateTime? _lastScanTime;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  bool get isRevalidating => _isRevalidating;
  bool get isProcessingPayment => _isProcessingPayment;
  String? get appliedCouponCode => _appliedCouponCode;

  double get subtotal {
    final s = _items.fold(0.0, (sum, item) => sum + item.subtotal);
    return double.parse(s.toStringAsFixed(2));
  }

  double get tax {
    final t = _items.fold(0.0, (sum, item) => sum + item.taxAmount);
    return double.parse(t.toStringAsFixed(2));
  }

  double get discount => double.parse(_discount.toStringAsFixed(2));

  double get total {
    final t = subtotal + tax - discount;
    return t < 0 ? 0.0 : double.parse(t.toStringAsFixed(2));
  }

  /// Debouncing check to prevent rapid repeat camera barcode hits (cooldown period of 2 seconds)
  bool canScanBarcode(String barcode) {
    final now = DateTime.now();
    if (_lastScannedBarcode == barcode && _lastScanTime != null) {
      final diff = now.difference(_lastScanTime!).inMilliseconds;
      if (diff < 2000) {
        return false; // Suppress duplicate scan within 2 seconds
      }
    }
    _lastScannedBarcode = barcode;
    _lastScanTime = now;
    return true;
  }

  void addProduct(Product product, {int quantity = 1}) {
    final index = _items.indexWhere((item) => item.product.barcode == product.barcode);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    _recalculateDiscounts();
    notifyListeners();
  }

  void updateQuantity(String barcode, int quantity) {
    final index = _items.indexWhere((item) => item.product.barcode == barcode);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      _recalculateDiscounts();
      notifyListeners();
    }
  }

  void increaseQuantity(String barcode) {
    final index = _items.indexWhere((item) => item.product.barcode == barcode);
    if (index >= 0) {
      _items[index].quantity++;
      _recalculateDiscounts();
      notifyListeners();
    }
  }

  void decreaseQuantity(String barcode) {
    final index = _items.indexWhere((item) => item.product.barcode == barcode);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      _recalculateDiscounts();
      notifyListeners();
    }
  }

  void removeItem(String barcode) {
    _items.removeWhere((item) => item.product.barcode == barcode);
    _recalculateDiscounts();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _discount = 0.0;
    _appliedCouponCode = null;
    _lastScannedBarcode = null;
    _lastScanTime = null;
    notifyListeners();
  }

  bool applyCoupon(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code == 'FLASH50') {
      _appliedCouponCode = 'FLASH50';
      _discount = 50.0;
      notifyListeners();
      return true;
    } else if (code == 'DMART10') {
      _appliedCouponCode = 'DMART10';
      _discount = subtotal * 0.10;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _discount = 0.0;
    notifyListeners();
  }

  void _recalculateDiscounts() {
    if (_appliedCouponCode == 'DMART10') {
      _discount = subtotal * 0.10;
    } else if (_items.isEmpty) {
      _discount = 0.0;
      _appliedCouponCode = null;
    }
  }

  /// Revalidates cart prices strictly against backend product database
  Future<RevalidatedCartResult> revalidateCart() async {
    _isRevalidating = true;
    notifyListeners();

    final result = await _cartService.revalidateCartWithBackend(
      _items,
      couponCode: _appliedCouponCode,
    );

    if (result.discount > 0) {
      _discount = result.discount;
    }

    _isRevalidating = false;
    notifyListeners();
    return result;
  }

  /// Process complete payment & order creation workflow
  Future<OrderModel?> processCheckoutAndPayment({
    required String userId,
    required String userName,
    required String userEmail,
    String paymentMethod = 'UPI',
  }) async {
    _isProcessingPayment = true;
    notifyListeners();

    try {
      // 1. Authoritative server-side price revalidation
      final revalidated = await _cartService.revalidateCartWithBackend(
        _items,
        couponCode: _appliedCouponCode,
      );

      // 2. Generate initial Order ID
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      // 3. Process Payment through isolated payment gateway
      final paymentResult = await _paymentService.executePayment(
        amount: revalidated.total,
        userEmail: userEmail,
        orderId: orderId,
      );

      if (!paymentResult.isSuccess) {
        throw Exception(paymentResult.errorMessage.isNotEmpty
            ? paymentResult.errorMessage
            : 'Payment failed. Please try again.');
      }

      // 4. Create complete Order object
      final newOrder = OrderModel(
        orderId: orderId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        items: revalidated.validatedItems,
        subtotal: revalidated.subtotal,
        tax: revalidated.tax,
        discount: revalidated.discount,
        total: revalidated.total,
        paymentStatus: 'paid',
        paymentId: paymentResult.paymentId,
        paymentMethod: paymentMethod,
        orderStatus: 'paid',
        createdAt: DateTime.now(),
        exitVerified: false,
      );

      // 5. Store order in backend
      final createdOrderId = await _orderService.createOrder(newOrder);
      final finalOrder = await _orderService.getOrderById(createdOrderId) ?? newOrder;

      // 6. Clear current cart
      clearCart();

      _isProcessingPayment = false;
      notifyListeners();
      return finalOrder;
    } catch (e) {
      _isProcessingPayment = false;
      notifyListeners();
      rethrow;
    }
  }
}

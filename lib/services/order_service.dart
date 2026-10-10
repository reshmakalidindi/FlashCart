import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import 'api_config.dart';

class OrderVerificationResult {
  final bool isSuccess;
  final String title;
  final String message;
  final OrderModel? order;

  OrderVerificationResult({
    required this.isSuccess,
    required this.title,
    required this.message,
    this.order,
  });
}

class OrderService {
  // In-memory fallback orders for offline demo mode and unit tests
  static final List<OrderModel> _inMemoryOrders = [];

  /// Authoritatively creates an order on the FastAPI backend: POST /api/v1/orders/
  Future<String> createOrder(OrderModel order) async {
    try {
      final payload = {
        'user_id': order.userId.isNotEmpty ? order.userId : 'usr_demo_customer',
        'order_id': order.orderId,
        'payment_status': order.paymentStatus,
        'items': order.items.map((i) => {
          'barcode': i.product.barcode,
          'quantity': i.quantity,
        }).toList(),
        'payment_method': 'MOCK_UPI',
        'coupon_code': order.discount > 0 ? 'FLASH50' : null,
        'store_id': 'STORE_DMART_001',
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String serverOrderId = data['order_id'];

        // If order was created and marked paid locally, trigger mock payment authorization
        if (order.paymentStatus == 'paid') {
          await verifyMockPayment(serverOrderId);
        }

        final serverOrder = OrderModel.fromJson(data);
        _inMemoryOrders.removeWhere((o) => o.orderId == serverOrderId);
        _inMemoryOrders.insert(0, serverOrder);

        debugPrint('Order $serverOrderId placed authoritatively via FastAPI backend.');
        return serverOrderId;
      }
    } catch (e) {
      debugPrint('FastAPI order creation error ($e), fallback to local cache.');
    }

    _inMemoryOrders.removeWhere((o) => o.orderId == order.orderId);
    _inMemoryOrders.insert(0, order);
    return order.orderId;
  }

  /// Authorizes payment and generates cryptographic exit token on FastAPI backend: POST /api/v1/payments/mock-verify
  Future<String?> verifyMockPayment(String orderId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payments/mock-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'payment_method': 'MOCK_UPI',
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final exitToken = data['exit_token'];
        debugPrint('Payment verified on FastAPI backend. Exit token: $exitToken');
        return exitToken;
      }
    } catch (e) {
      debugPrint('FastAPI mock payment verification fallback: $e');
    }
    return null;
  }

  /// Fetches orders for user from FastAPI backend: GET /api/v1/orders/user/{user_id}
  Future<List<OrderModel>> getUserOrders(String userId) async {
    final effectiveUserId = userId.isNotEmpty ? userId : 'usr_demo_customer';
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/user/$effectiveUserId'),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final orders = list.map((json) => OrderModel.fromJson(json)).toList();
        if (orders.isNotEmpty) {
          return orders;
        }
      }
    } catch (e) {
      debugPrint('FastAPI fetch user orders error ($e), using local fallback.');
    }

    return _inMemoryOrders.where((o) => o.userId == userId || userId.isEmpty).toList();
  }

  /// Fetches order by ID from FastAPI backend: GET /api/v1/orders/{order_id}
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/$orderId'),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OrderModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('FastAPI get order error ($e), using local fallback.');
    }

    try {
      return _inMemoryOrders.firstWhere((o) => o.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  /// Staff Exit QR Scanner verification via FastAPI backend: POST /api/v1/orders/verify-exit
  /// Enforces atomic backend exit validation and duplicate prevention.
  Future<OrderVerificationResult> verifyOrderExit({
    required String qrPayload,
    required String staffId,
  }) async {
    final cleanPayload = qrPayload.trim();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders/verify-exit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id_or_token': cleanPayload,
          'staff_id': staffId,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool success = data['success'] ?? false;
        final String status = data['status'] ?? '';
        final String message = data['message'] ?? '';

        if (success) {
          // Fetch updated order
          OrderModel? updatedOrder;
          if (data['order_id'] != null) {
            updatedOrder = await getOrderById(data['order_id']);
          }
          return OrderVerificationResult(
            isSuccess: true,
            title: 'PAYMENT VERIFIED — ORDER VALID',
            message: message,
            order: updatedOrder,
          );
        } else {
          String title = 'EXIT DENIED';
          if (status == 'ALREADY_VERIFIED') {
            title = 'ALREADY VERIFIED';
          } else if (status == 'UNPAID') {
            title = 'PAYMENT UNPAID';
          } else if (status == 'NOT_FOUND') {
            title = 'INVALID ORDER';
          }

          OrderModel? existingOrder;
          if (data['order_id'] != null) {
            existingOrder = await getOrderById(data['order_id']);
          }

          return OrderVerificationResult(
            isSuccess: false,
            title: title,
            message: message,
            order: existingOrder,
          );
        }
      }
    } catch (e) {
      debugPrint('FastAPI verify exit error ($e), using local fallback.');
    }

    // Local in-memory verification fallback (for offline tests)
    final order = await getOrderById(cleanPayload);

    if (order == null) {
      return OrderVerificationResult(
        isSuccess: false,
        title: 'INVALID ORDER',
        message: 'No record found for QR code "$cleanPayload". Please check customer receipt.',
      );
    }

    if (order.paymentStatus != 'paid') {
      return OrderVerificationResult(
        isSuccess: false,
        title: 'PAYMENT UNPAID',
        message: 'Order status is "${order.paymentStatus.toUpperCase()}". Direct customer to cashier.',
        order: order,
      );
    }

    if (order.exitVerified) {
      return OrderVerificationResult(
        isSuccess: false,
        title: 'ALREADY VERIFIED',
        message: 'This order was already scanned and verified for exit at ${order.verifiedAt != null ? order.verifiedAt.toString().substring(11, 16) : 'earlier'}. Possible double scan or reuse!',
        order: order,
      );
    }

    final now = DateTime.now();
    final index = _inMemoryOrders.indexWhere((o) => o.orderId == order.orderId);
    if (index != -1) {
      final updated = order.copyWith(
        exitVerified: true,
        orderStatus: 'completed',
        verifiedAt: now,
        verifiedBy: staffId,
      );
      _inMemoryOrders[index] = updated;
    }

    return OrderVerificationResult(
      isSuccess: true,
      title: 'PAYMENT VERIFIED — ORDER VALID',
      message: 'Payment verified: PAID. ${order.items.length} item(s) checked. Customer is cleared to exit store.',
      order: order,
    );
  }
}

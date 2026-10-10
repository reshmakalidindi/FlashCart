import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

enum PaymentMethod { mockUpi, mockCard, razorpay }

class PaymentResult {
  final bool isSuccess;
  final String paymentId;
  final String errorMessage;
  final DateTime timestamp;

  PaymentResult({
    required this.isSuccess,
    required this.paymentId,
    this.errorMessage = '',
    required this.timestamp,
  });
}

abstract class PaymentGateway {
  Future<PaymentResult> processPayment({
    required double verifiedAmount,
    required String userEmail,
    required String orderId,
  });
}

class MockPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentResult> processPayment({
    required double verifiedAmount,
    required String userEmail,
    required String orderId,
  }) async {
    debugPrint('Processing payment of ₹$verifiedAmount for order $orderId...');
    // Simulate real bank network processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate realistic Payment ID
    final randomDigits = Random().nextInt(899999) + 100000;
    final paymentId = 'PAY_FC_$randomDigits';

    return PaymentResult(
      isSuccess: true,
      paymentId: paymentId,
      timestamp: DateTime.now(),
    );
  }
}

class PaymentService {
  final PaymentGateway _gateway;

  PaymentService({PaymentGateway? gateway})
      : _gateway = gateway ?? MockPaymentGateway();

  Future<PaymentResult> executePayment({
    required double amount,
    required String userEmail,
    required String orderId,
  }) async {
    try {
      return await _gateway.processPayment(
        verifiedAmount: amount,
        userEmail: userEmail,
        orderId: orderId,
      );
    } catch (e) {
      return PaymentResult(
        isSuccess: false,
        paymentId: '',
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }
}

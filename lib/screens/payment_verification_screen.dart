import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import '../widgets/price_text.dart';
import '../widgets/primary_button.dart';
import '../widgets/flash_cart_app_bar.dart';
import 'order_success_screen.dart';

enum VerificationStep {
  processing,
  success,
  failed,
}

class PaymentVerificationScreen extends StatefulWidget {
  final double verifiedTotal;
  final String paymentMethod;

  const PaymentVerificationScreen({
    super.key,
    required this.verifiedTotal,
    required this.paymentMethod,
  });

  @override
  State<PaymentVerificationScreen> createState() => _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  VerificationStep _currentStep = VerificationStep.processing;
  String? _errorMessage;
  OrderModel? _confirmedOrder;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Automatically initiate payment authorization & verification on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeVerification();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _executeVerification() async {
    if (_currentStep == VerificationStep.processing && _confirmedOrder != null) return;

    if (widget.verifiedTotal <= 0) {
      if (mounted) {
        setState(() {
          _currentStep = VerificationStep.failed;
          _errorMessage = 'Invalid total amount: ₹0 cannot be authorized.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _currentStep = VerificationStep.processing;
        _errorMessage = null;
      });
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    try {
      final order = await cartProvider.processCheckoutAndPayment(
        userId: authProvider.user?.uid ?? 'usr_demo_customer',
        userName: authProvider.user?.displayName ?? 'Customer',
        userEmail: authProvider.user?.email ?? 'customer@flashcart.com',
        paymentMethod: widget.paymentMethod,
      );

      if (_isDisposed || !mounted) return;

      if (order != null) {
        setState(() {
          _confirmedOrder = order;
          _currentStep = VerificationStep.success;
        });

        // Allow user to see authoritative verification success before receipt transition
        await Future.delayed(const Duration(milliseconds: 1400));

        if (mounted && !_isDisposed) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderSuccessScreen(order: order),
            ),
          );
        }
      } else {
        throw Exception('Order could not be confirmed by the server.');
      }
    } catch (e) {
      if (_isDisposed || !mounted) return;
      setState(() {
        _currentStep = VerificationStep.failed;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep != VerificationStep.processing,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: FlashCartAppBar(
          titleText: 'Payment Verification',
          automaticallyImplyLeading: _currentStep != VerificationStep.processing,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Center(
              child: _buildCurrentStateView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStateView() {
    switch (_currentStep) {
      case VerificationStep.processing:
        return _buildProcessingView();
      case VerificationStep.success:
        return _buildSuccessView();
      case VerificationStep.failed:
        return _buildFailedView();
    }
  }

  Widget _buildProcessingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Verifying Payment with Store Server...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Authoritatively confirming transaction and checking store ledger. Please do not close or navigate away.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Verifying ₹${widget.verifiedTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Method: ${widget.paymentMethod}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_circle_rounded,
              size: 68,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Payment Verified & Authorized!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Transaction confirmed by store server. Generating your official digital exit receipt...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        PriceText(
          amount: widget.verifiedTotal,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildFailedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.error_outline_rounded,
              size: 58,
              color: AppColors.error,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Payment Verification Failed',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage ?? 'Unable to complete authoritative verification. Your cart items are preserved.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.error,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Amount retained: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              PriceText(
                amount: widget.verifiedTotal,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Retry Payment Verification',
          icon: Icons.refresh_rounded,
          onPressed: _executeVerification,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Return to Payment / Bill'),
        ),
      ],
    );
  }
}

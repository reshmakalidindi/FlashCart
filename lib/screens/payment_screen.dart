import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import '../widgets/price_text.dart';
import '../widgets/primary_button.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double verifiedTotal;
  final String paymentMethod; // upi, net_banking, card

  const PaymentScreen({
    super.key,
    required this.verifiedTotal,
    this.paymentMethod = 'upi',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  bool _isProcessing = false;
  bool _isSuccess = false;
  late String _currentMethod;
  String? _selectedBank = 'HDFC Bank';
  String? _selectedUpiApp = 'Google Pay';

  @override
  void initState() {
    super.initState();
    _currentMethod = widget.paymentMethod;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Authorizes payment authoritatively via FastAPI backend
  Future<void> _processPaymentAuthorization({bool simulateFailure = false}) async {
    if (simulateFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment Declined: Simulated bank rejection / insufficient funds. Bill retained.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _isSuccess = false;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    try {
      final order = await cartProvider.processCheckoutAndPayment(
        userId: authProvider.user?.uid ?? 'usr_demo_customer',
        userName: authProvider.user?.displayName ?? 'Customer',
        userEmail: authProvider.user?.email ?? 'customer@flashcart.com',
        paymentMethod: _currentMethod == 'upi'
            ? 'UPI ($_selectedUpiApp)'
            : _currentMethod == 'net_banking'
                ? 'Net Banking ($_selectedBank)'
                : 'Credit/Debit Card',
      );

      if (order != null && mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => OrderSuccessScreen(order: order),
            ),
            (route) => route.isFirst,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildMethodSpecificUI() {
    if (_currentMethod == 'upi') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select UPI App or Provider',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Google Pay', 'PhonePe', 'Paytm', 'BHIM'].map((app) {
              final isSel = _selectedUpiApp == app;
              return ChoiceChip(
                label: Text(app, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                selected: isSel,
                selectedColor: AppColors.primaryLight,
                onSelected: (val) => setState(() => _selectedUpiApp = app),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'VPA / UPI ID',
              hintText: 'shopper@upi',
              prefixIcon: Icon(Icons.alternate_email, size: 18),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      );
    } else if (_currentMethod == 'net_banking') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Banks',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['HDFC Bank', 'ICICI Bank', 'SBI', 'Axis Bank', 'Kotak'].map((bank) {
              final isSel = _selectedBank == bank;
              return ChoiceChip(
                label: Text(bank, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                selected: isSel,
                selectedColor: AppColors.primaryLight,
                onSelected: (val) => setState(() => _selectedBank = bank),
              );
            }).toList(),
          ),
        ],
      );
    } else {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mock Card Details (No real cards stored)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          SizedBox(height: 10),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '4532 •••• •••• 8892',
              prefixIcon: Icon(Icons.credit_card),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Expiry',
                    hintText: '12/28',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '•••',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_isSuccess) ...[
              const SizedBox(height: 60),
              const Icon(
                Icons.check_circle_rounded,
                size: 96,
                color: AppColors.success,
              ),
              const SizedBox(height: 20),
              const Text(
                'Payment Verified & Authorized!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generating your official exit QR receipt...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ] else if (_isProcessing) ...[
              const SizedBox(height: 80),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Processing & Verifying Payment...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Contacting FastAPI banking gateway for authoritative order creation',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ] else ...[
              // Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: const Text(
                        'TEST GATEWAY SIMULATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.deepOrange,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Total Amount Payable',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    PriceText(
                      amount: widget.verifiedTotal,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: AppColors.success),
                        SizedBox(width: 6),
                        Text(
                          '256-Bit SSL Encrypted • No PIN/Card credentials stored',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Payment Method Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _currentMethod == 'upi'
                              ? Icons.account_balance_wallet_outlined
                              : _currentMethod == 'net_banking'
                                  ? Icons.account_balance_outlined
                                  : Icons.credit_card,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Method: ${_currentMethod.replaceAll('_', ' ').toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildMethodSpecificUI(),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Authorize Payment Button
              PrimaryButton(
                label: 'Authorize & Pay ₹${widget.verifiedTotal.toStringAsFixed(2)}',
                icon: Icons.check_circle_outline,
                height: 54,
                onPressed: () => _processPaymentAuthorization(simulateFailure: false),
              ),

              const SizedBox(height: 12),

              // Test Failure Simulation (As required by instructions)
              OutlinedButton.icon(
                onPressed: () => _processPaymentAuthorization(simulateFailure: true),
                icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                label: const Text('Simulate Failed Transaction (Test Error Handling)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel & Return to Bill', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

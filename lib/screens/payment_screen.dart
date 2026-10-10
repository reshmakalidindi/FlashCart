import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/price_text.dart';
import '../widgets/primary_button.dart';
import '../widgets/flash_cart_app_bar.dart';
import 'payment_verification_screen.dart';

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

class _PaymentScreenState extends State<PaymentScreen> {
  late String _currentMethod;
  String? _selectedBank = 'HDFC Bank';
  String? _selectedUpiApp = 'Google Pay';

  @override
  void initState() {
    super.initState();
    _currentMethod = widget.paymentMethod;
  }

  /// Navigates to the authoritative PaymentVerificationScreen
  void _navigateToVerification() {
    if (widget.verifiedTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot pay ₹0: Bill total must be greater than zero.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final methodDescription = _currentMethod == 'upi'
        ? 'UPI ($_selectedUpiApp)'
        : _currentMethod == 'net_banking'
            ? 'Net Banking ($_selectedBank)'
            : 'Credit/Debit Card';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentVerificationScreen(
          verifiedTotal: widget.verifiedTotal,
          paymentMethod: methodDescription,
        ),
      ),
    );
  }

  Widget _buildMethodSpecificUI() {
    if (_currentMethod == 'upi') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select UPI App or Provider',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Google Pay', 'PhonePe', 'Paytm', 'BHIM'].map((app) {
              final isSel = _selectedUpiApp == app;
              return ChoiceChip(
                label: Text(app, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w600 : FontWeight.w400)),
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
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['HDFC Bank', 'ICICI Bank', 'SBI', 'Axis Bank', 'Kotak'].map((bank) {
              final isSel = _selectedBank == bank;
              return ChoiceChip(
                label: Text(bank, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w600 : FontWeight.w400)),
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
      appBar: const FlashCartAppBar(
        titleText: 'Payment',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'SELF-CHECKOUT PAYMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
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
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PriceText(
                    amount: widget.verifiedTotal,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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
                        '256-Bit SSL Encrypted • Authoritative Backend Pricing',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
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
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMethodSpecificUI(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Prominent Total Amount Display above Payment Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Payable',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Authoritatively verified by store server',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  PriceText(
                    amount: widget.verifiedTotal,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Next / Proceed to Verification Button
            PrimaryButton(
              label: 'Next: Authorize & Pay ₹${widget.verifiedTotal.toStringAsFixed(2)}',
              icon: Icons.arrow_forward_rounded,
              height: 54,
              onPressed: _navigateToVerification,
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel & Return to Bill', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

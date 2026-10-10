import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/cart_service.dart';
import '../utils/constants.dart';
import '../widgets/price_text.dart';
import '../widgets/primary_button.dart';
import '../widgets/flash_cart_app_bar.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  RevalidatedCartResult? _revalidatedResult;
  bool _isRevalidating = true;
  String _selectedPaymentMethod = 'mock_upi'; // mock_upi, mock_card, razorpay

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _performBackendPriceRevalidation();
      }
    });
  }

  Future<void> _performBackendPriceRevalidation() async {
    setState(() => _isRevalidating = true);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final result = await cartProvider.revalidateCart();

    if (mounted) {
      setState(() {
        _revalidatedResult = result;
        _isRevalidating = false;
      });

      if (result.hasPriceChanges) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Product prices were updated from store database for accuracy.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (cartProvider.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text('Your cart is empty. Add items before checking out.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Shopping'),
              ),
            ],
          ),
        ),
      );
    }

    final subtotal = _revalidatedResult?.subtotal ?? cartProvider.subtotal;
    final tax = _revalidatedResult?.tax ?? cartProvider.tax;
    final discount = _revalidatedResult?.discount ?? cartProvider.discount;
    final total = _revalidatedResult?.total ?? cartProvider.total;
    final items = _revalidatedResult?.validatedItems ?? cartProvider.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FlashCartAppBar(
        titleText: 'Payment',
      ),
      body: _isRevalidating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Revalidating store catalog prices with backend database...',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store & User Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.storefront_rounded, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'FlashCart Self-Checkout',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Customer: ${authProvider.user?.displayName ?? 'Shopper'} (${authProvider.user?.email ?? 'customer@flashcart.com'})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bill Breakdown
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Items Subtotal'),
                              PriceText(amount: subtotal),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Applicable Taxes (GST)'),
                              PriceText(amount: tax),
                            ],
                          ),
                          if (discount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Discounts / Promo', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w400)),
                                Text('- ₹${discount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL AMOUNT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              PriceText(
                                amount: total,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Payment Method Selection
                  const Text(
                    'Select Payment Mode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option 1: UPI
                  _buildPaymentOption(
                    id: 'upi',
                    title: 'UPI (Google Pay / PhonePe / Paytm / BHIM)',
                    subtitle: 'Instant QR & UPI Intent Payment',
                    icon: Icons.account_balance_wallet_outlined,
                    badge: 'POPULAR',
                  ),

                  const SizedBox(height: 8),

                  // Option 2: Net Banking
                  _buildPaymentOption(
                    id: 'net_banking',
                    title: 'Net Banking',
                    subtitle: 'HDFC, ICICI, SBI, Axis, Kotak and 50+ Banks',
                    icon: Icons.account_balance_outlined,
                    badge: 'BANKING',
                  ),

                  const SizedBox(height: 8),

                  // Option 3: Credit/Debit Card
                  _buildPaymentOption(
                    id: 'card',
                    title: 'Credit / Debit Card',
                    subtitle: 'Visa, Mastercard, RuPay & Diners Club',
                    icon: Icons.credit_card,
                    badge: 'CARDS',
                  ),

                  const SizedBox(height: 28),

                  // Proceed to Payment Action
                  PrimaryButton(
                    label: 'Proceed to Payment (₹${total.toStringAsFixed(0)})',
                    icon: Icons.lock_outline,
                    onPressed: () {
                      if (items.any((item) => item.product.price <= 0) || total <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Cannot proceed: Invalid item prices or zero total.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            verifiedTotal: total,
                            paymentMethod: _selectedPaymentMethod,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badge == 'DEV MOCK' ? AppColors.primaryLight : AppColors.butterYellow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: badge == 'DEV MOCK' ? AppColors.primaryDark : AppColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}

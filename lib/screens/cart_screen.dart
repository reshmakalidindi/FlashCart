import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/empty_cart.dart';
import '../widgets/price_text.dart';
import '../widgets/primary_button.dart';
import '../widgets/flash_cart_app_bar.dart';
import 'checkout_screen.dart';
import 'scanner_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _handleApplyCoupon(CartProvider cartProvider) {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    final success = cartProvider.applyCoupon(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '🎉 Coupon "$code" applied successfully!'
              : 'Invalid coupon code. Try "FLASH50" (orders over ₹300) or "DMART10".',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
    _couponController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FlashCartAppBar(
        titleText: 'Current Bill (${cartProvider.itemCount} items)',
        actions: [
          if (!cartProvider.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Clear Bill',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Current Bill?'),
                    content: const Text('Are you sure you want to remove all scanned items from your bill?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        onPressed: () {
                          cartProvider.clearCart();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Clear Bill'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartProvider.isEmpty
          ? EmptyCartWidget(
              onStartScanning: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ScannerScreen()),
                );
              },
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Scanned Products Dedicated Card Container (Independently Scrollable)
                Flexible(
                  fit: FlexFit.loose,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card Header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Scanned Products',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${cartProvider.itemCount} items',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, thickness: 1, color: AppColors.border),

                            // Independently Scrollable List Inside Card
                            Flexible(
                              fit: FlexFit.loose,
                              child: Scrollbar(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.all(12),
                                  itemCount: cartProvider.items.length,
                                  separatorBuilder: (_, index) => const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final item = cartProvider.items[index];
                                    return CartItemCard(
                                      item: item,
                                      onIncrease: () => cartProvider.increaseQuantity(item.product.barcode),
                                      onDecrease: () => cartProvider.decreaseQuantity(item.product.barcode),
                                      onRemove: () => cartProvider.removeItem(item.product.barcode),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bill Summary Breakdown
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Coupon Code Input / Applied Badge
                      if (cartProvider.appliedCouponCode == null)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: TextField(
                                  controller: _couponController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    hintText: 'Enter Coupon (try FLASH50)',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.check, size: 18, color: AppColors.primary),
                                      onPressed: () => _handleApplyCoupon(cartProvider),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.success),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '🎉 Coupon Applied: ${cartProvider.appliedCouponCode}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                                onPressed: cartProvider.removeCoupon,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Item Count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Items Scanned', style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            '${cartProvider.itemCount} units',
                            style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary)),
                          PriceText(
                            amount: cartProvider.subtotal,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Taxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Configured GST Taxes', style: TextStyle(color: AppColors.textSecondary)),
                          PriceText(
                            amount: cartProvider.tax,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                          ),
                        ],
                      ),

                      // Discounts
                      if (cartProvider.discount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Coupon Discount', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w500)),
                            Text(
                              '- ₹${cartProvider.discount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success),
                            ),
                          ],
                        ),
                      ],

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(thickness: 1, color: AppColors.border),
                      ),

                      // Final Amount Payable
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Final Payable',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Authoritatively verified by store server',
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          PriceText(
                            amount: cartProvider.total,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Two Primary Actions: Continue Scanning & Proceed to Payment
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                              label: const Text('Continue Scanning'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Proceed to Payment',
                              icon: Icons.lock_outline,
                              onPressed: cartProvider.isEmpty
                                  ? null
                                  : () {
                                      final hasInvalidPrice = cartProvider.items.any((item) => item.product.price <= 0);
                                      if (hasInvalidPrice) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('⚠️ Cannot proceed: One or more scanned items have an invalid price.'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                        return;
                                      }
                                      if (cartProvider.total <= 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('⚠️ Bill total must be greater than ₹0 to proceed.'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                        return;
                                      }
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

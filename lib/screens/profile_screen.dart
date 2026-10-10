import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool showAppBar;

  const ProfileScreen({
    super.key,
    this.showAppBar = true,
  });

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text('Log Out of FlashCart?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out? Your active self-checkout cart will be cleared and your session will end safely.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();

              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final cartProvider = Provider.of<CartProvider>(context, listen: false);

              // 1. Clear cart state so next user starts completely fresh
              cartProvider.clearCart();

              // 2. Clear authentication session
              await authProvider.logout();

              // 3. Navigate back to LoginScreen and prevent back navigation
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Methods',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildPaymentTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Unified Payments Interface (UPI)',
              subtitle: 'Google Pay, PhonePe, Paytm (shopper@upi)',
              isDefault: true,
            ),
            const SizedBox(height: 10),
            _buildPaymentTile(
              icon: Icons.credit_card_outlined,
              title: 'Saved Cards',
              subtitle: 'HDFC Bank Visa ending •••• 8892',
              isDefault: false,
            ),
            const SizedBox(height: 10),
            _buildPaymentTile(
              icon: Icons.account_balance_outlined,
              title: 'Net Banking',
              subtitle: 'HDFC, ICICI, SBI & 50+ Banks',
              isDefault: false,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: const Text('Add Payment Method'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('UPI / Cards are dynamically verified during self-checkout payment.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPaymentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDefault,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDefault ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDefault ? AppColors.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isDefault ? AppColors.primary : AppColors.textSecondary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'DEFAULT',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _showStoreInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.storefront_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Supermarket Store Info',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Store Name:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('FlashCart Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Store ID:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('STORE_FLASHCART_001', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active Checkout:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('FlashCart Lane 01', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Store Hours:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('7:00 AM – 11:00 PM Daily', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Security exit guards will scan your QR code receipt before exiting.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final displayName = user?.displayName.isNotEmpty == true ? user!.displayName : 'Customer Shopper';
    final email = user?.email.isNotEmpty == true ? user!.email : 'customer@flashcart.com';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showAppBar
          ? AppBar(
              title: const Text('Customer Profile'),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Centered Customer Profile Card (matching UI reference image)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Circular Profile Avatar with Warm Burnt-Orange Ring
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryAccent, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Customer Email
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Role Badge Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          authProvider.isStaff ? Icons.shield_rounded : Icons.verified_user_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          authProvider.isStaff ? 'Store Staff / Security' : 'Verified Shopper',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Profile Actions & Shortcuts Section
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                  // 1. Order History
                  _buildMenuTile(
                    icon: Icons.receipt_long_rounded,
                    iconBg: AppColors.primaryLight,
                    iconColor: AppColors.primary,
                    title: 'Order History',
                    subtitle: 'Past digital receipts & verified exit QR passes',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 64, color: AppColors.border),

                  // 2. Payment Methods
                  _buildMenuTile(
                    icon: Icons.credit_card_rounded,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: AppColors.success,
                    title: 'Payment Methods',
                    subtitle: 'UPI, saved cards & banking preferences',
                    onTap: () => _showPaymentMethodsModal(context),
                  ),
                  const Divider(height: 1, indent: 64, color: AppColors.border),

                  // 3. Supermarket Store Info
                  _buildMenuTile(
                    icon: Icons.storefront_rounded,
                    iconBg: const Color(0xFFE1F5FE),
                    iconColor: const Color(0xFF0288D1),
                    title: 'Store Info',
                    subtitle: 'FlashCart Store (STORE_FLASHCART_001)',
                    onTap: () => _showStoreInfoModal(context),
                  ),
                  const Divider(height: 1, indent: 64, color: AppColors.border),

                  // 4. Working Logout Option
                  _buildMenuTile(
                    icon: Icons.logout_rounded,
                    iconBg: const Color(0xFFFFEBEE),
                    iconColor: AppColors.error,
                    title: 'Log Out',
                    subtitle: 'End session and clear shopping cart',
                    titleColor: AppColors.error,
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                ],
              ),
            ),
          ),

            const SizedBox(height: 30),

            // App Version Footer
            const Text(
              'FlashCart Supermarket Self-Checkout • v2.0\nScan. Shop. Pay. Go.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}

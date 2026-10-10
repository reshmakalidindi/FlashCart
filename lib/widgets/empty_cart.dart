import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'primary_button.dart';

class EmptyCartWidget extends StatelessWidget {
  final VoidCallback onStartScanning;

  const EmptyCartWidget({
    super.key,
    required this.onStartScanning,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan product barcodes while walking down supermarket aisles to build your self-checkout cart.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Scan First Product',
              icon: Icons.qr_code_scanner,
              onPressed: onStartScanning,
            ),
          ],
        ),
      ),
    );
  }
}

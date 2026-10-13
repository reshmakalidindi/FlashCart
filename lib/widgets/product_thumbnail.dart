import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../utils/constants.dart';

/// A clean, responsive product thumbnail component that displays either a product photograph
/// (from local assets or network source) or a category-appropriate styled visual badge,
/// cleanly distinguishing photos from QR codes.
class ProductThumbnail extends StatelessWidget {
  final Product product;
  final double size;
  final double borderRadius;
  final bool preferPhoto;

  const ProductThumbnail({
    super.key,
    required this.product,
    this.size = 72,
    this.borderRadius = 14,
    this.preferPhoto = true,
  });

  static String? _getAssetPhotoPath(String id, String rawImageUrl) {
    if (rawImageUrl.startsWith('assets/') &&
        !rawImageUrl.contains('product_qrs')) {
      return rawImageUrl;
    }
    return null;
  }

  static ({IconData icon, Color bg, Color iconColor}) _getCategoryVisuals(String id, String category) {
    final cleanId = id.toUpperCase();
    if (cleanId.contains('P0010') || cleanId.contains('P010')) {
      return (
        icon: Icons.fastfood_rounded,
        bg: const Color(0xFFFFF9C4),
        iconColor: const Color(0xFFE65100),
      );
    } else if (cleanId.contains('P001')) {
      return (
        icon: Icons.ramen_dining_rounded,
        bg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFE65100),
      );
    } else if (cleanId.contains('P002')) {
      return (
        icon: Icons.cookie_rounded,
        bg: const Color(0xFFFFF8E1),
        iconColor: const Color(0xFFF57F17),
      );
    } else if (cleanId.contains('P003')) {
      return (
        icon: Icons.local_laundry_service_rounded,
        bg: const Color(0xFFE1F5FE),
        iconColor: const Color(0xFF0288D1),
      );
    } else if (cleanId.contains('P004')) {
      return (
        icon: Icons.draw_rounded,
        bg: const Color(0xFFEDE7F6),
        iconColor: const Color(0xFF512DA8),
      );
    } else if (cleanId.contains('P005')) {
      return (
        icon: Icons.backpack_rounded,
        bg: const Color(0xFFE0F2F1),
        iconColor: const Color(0xFF00796B),
      );
    } else if (cleanId.contains('P006')) {
      return (
        icon: Icons.water_drop_rounded,
        bg: const Color(0xFFE0F7FA),
        iconColor: const Color(0xFF0097A7),
      );
    } else if (cleanId.contains('P007')) {
      return (
        icon: Icons.cake_rounded,
        bg: const Color(0xFFFCE4EC),
        iconColor: const Color(0xFFC2185B),
      );
    } else if (cleanId.contains('P008')) {
      return (
        icon: Icons.egg_alt_rounded,
        bg: const Color(0xFFFFFDE7),
        iconColor: const Color(0xFFFBC02D),
      );
    } else if (cleanId.contains('P009')) {
      return (
        icon: Icons.local_bar_rounded,
        bg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFD32F2F),
      );
    }

    // Fallback based on category
    final catLower = category.toLowerCase();
    if (catLower.contains('instant') || catLower.contains('food')) {
      return (
        icon: Icons.lunch_dining_rounded,
        bg: const Color(0xFFFFF3E0),
        iconColor: AppColors.primary,
      );
    } else if (catLower.contains('snack') || catLower.contains('biscuit')) {
      return (
        icon: Icons.cookie_rounded,
        bg: const Color(0xFFFFF8E1),
        iconColor: const Color(0xFFF57F17),
      );
    } else if (catLower.contains('beverage') || catLower.contains('drink')) {
      return (
        icon: Icons.emoji_food_beverage_rounded,
        bg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFD32F2F),
      );
    } else if (catLower.contains('dairy')) {
      return (
        icon: Icons.egg_alt_rounded,
        bg: const Color(0xFFFFFDE7),
        iconColor: const Color(0xFFFBC02D),
      );
    } else if (catLower.contains('clean') || catLower.contains('house')) {
      return (
        icon: Icons.cleaning_services_rounded,
        bg: const Color(0xFFE1F5FE),
        iconColor: const Color(0xFF0288D1),
      );
    }

    return (
      icon: Icons.shopping_bag_outlined,
      bg: AppColors.primaryLight,
      iconColor: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNetworkUrl = product.imageUrl.startsWith('http://') || product.imageUrl.startsWith('https://');
    final assetPath = _getAssetPhotoPath(product.id, product.imageUrl);
    final visuals = _getCategoryVisuals(product.id, product.category);

    Widget imageContent;

    if (preferPhoto && assetPath != null) {
      imageContent = Padding(
        padding: const EdgeInsets.all(4.0),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) => _buildPlaceholder(visuals),
        ),
      );
    } else if (preferPhoto && hasNetworkUrl) {
      imageContent = Padding(
        padding: const EdgeInsets.all(4.0),
        child: Image.network(
          product.imageUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) => _buildPlaceholder(visuals),
        ),
      );
    } else {
      imageContent = _buildPlaceholder(visuals);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        padding: const EdgeInsets.all(4),
        child: Center(child: imageContent),
      ),
    );
  }

  Widget _buildPlaceholder(({IconData icon, Color bg, Color iconColor}) visuals) {
    return Container(
      decoration: BoxDecoration(
        color: visuals.bg,
        borderRadius: BorderRadius.circular(borderRadius - 4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            visuals.icon,
            size: size * 0.44,
            color: visuals.iconColor,
          ),
          Positioned(
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                product.id.isNotEmpty ? product.id : 'ITEM',
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: visuals.iconColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

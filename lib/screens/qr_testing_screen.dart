import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../utils/constants.dart';
import '../widgets/price_text.dart';
import 'cart_screen.dart';

class QrTestingProduct {
  final String id;
  final String name;
  final String qrCode;
  final String qrImage;
  final double price;
  final String category;
  final String weight;

  const QrTestingProduct({
    required this.id,
    required this.name,
    required this.qrCode,
    required this.qrImage,
    required this.price,
    required this.category,
    required this.weight,
  });
}

class QrTestingScreen extends StatelessWidget {
  const QrTestingScreen({super.key});

  static const List<QrTestingProduct> testProducts = [
    QrTestingProduct(
      id: 'P001',
      name: 'Maggi',
      qrCode: 'FLASHCART-P001',
      qrImage: 'P001.png',
      price: 20.0,
      category: 'Instant Food',
      weight: '70 g',
    ),
    QrTestingProduct(
      id: 'P002',
      name: 'Biscuit packets',
      qrCode: 'FLASHCART-P002',
      qrImage: 'P002.png',
      price: 15.0,
      category: 'Biscuits & Snacks',
      weight: '100 g',
    ),
    QrTestingProduct(
      id: 'P003',
      name: 'Surf Excel',
      qrCode: 'FLASHCART-P003',
      qrImage: 'P003.png',
      price: 70.0,
      category: 'Household & Cleaning',
      weight: '500 g',
    ),
    QrTestingProduct(
      id: 'P004',
      name: 'Stationery',
      qrCode: 'FLASHCART-P004',
      qrImage: 'P004.png',
      price: 200.0,
      category: 'Stationery',
      weight: '1 Set',
    ),
    QrTestingProduct(
      id: 'P005',
      name: 'College bag',
      qrCode: 'FLASHCART-P005',
      qrImage: 'P005.png',
      price: 699.0,
      category: 'Luggage & Bags',
      weight: '1 pc',
    ),
    QrTestingProduct(
      id: 'P006',
      name: 'Water bottle',
      qrCode: 'FLASHCART-P006',
      qrImage: 'P006.png',
      price: 288.0,
      category: 'Home & Kitchen',
      weight: '1 L',
    ),
    QrTestingProduct(
      id: 'P007',
      name: 'Sonpapidi (sweet)',
      qrCode: 'FLASHCART-P007',
      qrImage: 'P007.png',
      price: 154.0,
      category: 'Sweets',
      weight: '250 g',
    ),
    QrTestingProduct(
      id: 'P008',
      name: 'Paneer',
      qrCode: 'FLASHCART-P008',
      qrImage: 'P008.png',
      price: 299.0,
      category: 'Dairy',
      weight: '500 g',
    ),
    QrTestingProduct(
      id: 'P009',
      name: 'Cool drinks',
      qrCode: 'FLASHCART-P009',
      qrImage: 'P009.png',
      price: 40.0,
      category: 'Beverages',
      weight: '600 ml',
    ),
    QrTestingProduct(
      id: 'P0010',
      name: 'Lays packet',
      qrCode: 'FLASHCART-P0010',
      qrImage: 'P0010.png',
      price: 50.0,
      category: 'Biscuits & Snacks',
      weight: '115 g',
    ),
  ];

  void _showExpandedQr(BuildContext context, QrTestingProduct item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${item.id} • ${item.qrCode}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/product_qrs/${item.qrImage}',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              PriceText(
                amount: item.price,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Simulate Scan Into Bill'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _simulateScan(context, item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _simulateScan(BuildContext context, QrTestingProduct item) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Fetch authoritative product from backend
    Product? product = await productProvider.scanProductBarcode(item.qrCode);
    product ??= await productProvider.scanProductBarcode(item.id);

    if (product != null) {
      cartProvider.addProduct(product);
      if (context.mounted) {
        final count = cartProvider.items.firstWhere((i) => i.productId == product!.id || i.product.barcode == product.barcode).quantity;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${product.name} (Qty: $count) • ₹${product.price.toStringAsFixed(2)}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to locate ${item.id} on backend.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('QR Product Test Bench'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'View Current Bill',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
          if (cartProvider.itemCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 16),
              child: Text(
                '(${cartProvider.itemCount})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primaryLight,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primaryDark, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '10 Authoritative QR Products. Tap QR to enlarge for scanning, or tap "+ Add" to simulate barcode read.',
                    style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),

          // 10 Products Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: testProducts.length,
              itemBuilder: (context, index) {
                final item = testProducts[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showExpandedQr(context, item),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Product ID badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.id,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                item.weight,
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // QR Image
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/product_qrs/${item.qrImage}',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Product Name
                          Text(
                            item.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),

                          // Database Price
                          PriceText(
                            amount: item.price,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Add button
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: AppColors.primaryLight,
                                foregroundColor: AppColors.primaryDark,
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.add_shopping_cart, size: 14),
                              label: const Text('Add to Bill', style: TextStyle(fontSize: 11)),
                              onPressed: () => _simulateScan(context, item),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: cartProvider.itemCount > 0
          ? Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.receipt_long),
                label: Text(
                  'View Current Bill (${cartProvider.itemCount} items • ₹${cartProvider.total.toStringAsFixed(2)})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
            )
          : null,
    );
  }
}

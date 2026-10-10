import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../utils/constants.dart';
import '../widgets/price_text.dart';
import 'cart_screen.dart';
import 'login_screen.dart';

class ScannerScreen extends StatefulWidget {
  final Product? autoSelectProduct;

  const ScannerScreen({
    super.key,
    this.autoSelectProduct,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.qrCode,
    ],
  );

  final TextEditingController _manualBarcodeController = TextEditingController();
  bool _isProcessingScan = false;
  bool _torchOn = false;
  Product? _lastAddedProduct;
  int _lastAddedQuantity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.autoSelectProduct != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addProductDirectly(widget.autoSelectProduct!);
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualBarcodeController.dispose();
    super.dispose();
  }

  /// Handles barcode detection from camera or manual entry
  Future<void> _handleBarcode(String rawBarcode) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty || _isProcessingScan) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // 1. Debounce rapid repeat camera hits (2 second cooldown for identical barcode)
    if (!cartProvider.canScanBarcode(barcode)) {
      return;
    }

    setState(() {
      _isProcessingScan = true;
      _lastAddedProduct = null;
    });

    try {
      // 2. Fetch authoritative product from FastAPI backend
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final product = await productProvider.scanProductBarcode(barcode);

      if (!mounted) return;

      if (product != null) {
        // 3. Automatically add product to current bill (increments if already present)
        _addProductDirectly(product);
      } else {
        // 4. Never invent or silently accept unknown barcode
        _showNotFoundDialog(barcode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error checking barcode: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isProcessingScan = false);
      }
    }
  }

  void _addProductDirectly(Product product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addProduct(product);

    final cartItem = cartProvider.items.firstWhere(
      (item) => item.product.barcode == product.barcode,
    );

    setState(() {
      _isProcessingScan = false;
      _lastAddedProduct = product;
      _lastAddedQuantity = cartItem.quantity;
    });

    // Short success notification
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Added ${product.name} (Qty: ${cartItem.quantity})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.error),
        title: const Text('Product Not Found'),
        content: Text(
          'Barcode "$barcode" was not recognized in the supermarket database.\n\nPlease check the barcode or request assistance from store staff.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isProcessingScan = false);
            },
            child: const Text('Scan Next Product'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isProcessingScan = false);
      }
    });
  }

  void _showManualBarcodeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Product Barcode Manually',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualBarcodeController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. 8901234567890',
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
                  onPressed: () {
                    final code = _manualBarcodeController.text;
                    _manualBarcodeController.clear();
                    Navigator.of(ctx).pop();
                    _handleBarcode(code);
                  },
                ),
              ),
              onSubmitted: (code) {
                _manualBarcodeController.clear();
                Navigator.of(ctx).pop();
                _handleBarcode(code);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Or pick a sample supermarket product to test:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.local_drink, size: 16, color: AppColors.primary),
                  label: const Text('Amul Milk (₹68)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('8901234567890');
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.cookie, size: 16, color: AppColors.primary),
                  label: const Text('Parle-G (₹20)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('8901234567891');
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.soap, size: 16, color: AppColors.primary),
                  label: const Text('Dove Soap (₹55)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('8901234567892');
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.local_grocery_store, size: 16, color: AppColors.primary),
                  label: const Text('Tata Salt (₹28)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('8901234567894');
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.ramen_dining, size: 16, color: AppColors.primary),
                  label: const Text('Maggi (₹56)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('8901234567896');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Products'),
        actions: [
          // Torch toggle
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Torch',
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          // Manual barcode input
          IconButton(
            icon: const Icon(Icons.keyboard_alt_outlined),
            tooltip: 'Enter Barcode Manually',
            onPressed: _showManualBarcodeSheet,
          ),
          // Cart Icon with Badge
          Stack(
            alignment: Alignment.center,
            children: [
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
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${cartProvider.itemCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Logout menu
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Live Camera Scanner
          MobileScanner(
            controller: _scannerController,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.no_photography_outlined, size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text(
                        'Camera Unavailable or Permission Denied',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You can still shop by entering product barcodes manually.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _showManualBarcodeSheet,
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Enter Barcode Manually'),
                      ),
                    ],
                  ),
                ),
              );
            },
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (var barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleBarcode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Scanning Reticle Target
          Center(
            child: Container(
              width: 270,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white, width: 3), left: BorderSide(color: Colors.white, width: 3)),
                    )),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white, width: 3), right: BorderSide(color: Colors.white, width: 3)),
                    )),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white, width: 3), left: BorderSide(color: Colors.white, width: 3)),
                    )),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white, width: 3), right: BorderSide(color: Colors.white, width: 3)),
                    )),
                  ),
                ],
              ),
            ),
          ),

          // Instructions Strip
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: AppColors.accent, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Scan product barcode to automatically add to bill',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Just-Added Product Notification Card (With "Scan Next Product" & "View Bill")
          if (_lastAddedProduct != null)
            Positioned(
              bottom: cartProvider.isEmpty ? 24 : 88,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lastAddedProduct!.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '₹${_lastAddedProduct!.price.toStringAsFixed(2)} • In Bill: $_lastAddedQuantity',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          PriceText(
                            amount: _lastAddedProduct!.price * _lastAddedQuantity,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _lastAddedProduct = null);
                              },
                              icon: const Icon(Icons.qr_code_scanner, size: 16),
                              label: const Text('Scan Next Product'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                );
                              },
                              icon: const Icon(Icons.receipt_long, size: 16),
                              label: const Text('View Bill'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Persistent Bottom Bill Bar
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton.outlined(
                    onPressed: _showManualBarcodeSheet,
                    icon: const Icon(Icons.keyboard, color: AppColors.primary),
                    tooltip: 'Manual Barcode Entry',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Current Bill (${cartProvider.itemCount} items)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        PriceText(
                          amount: cartProvider.total,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: cartProvider.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay when looking up product
          if (_isProcessingScan)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Looking up Product in Store Catalog...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

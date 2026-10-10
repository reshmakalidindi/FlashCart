import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../utils/constants.dart';
import '../widgets/price_text.dart';
import 'cart_screen.dart';
import 'qr_testing_screen.dart';

class ScannerScreen extends StatefulWidget {
  final Product? autoSelectProduct;

  final bool isActive;
  final bool showAppBar;

  const ScannerScreen({
    super.key,
    this.autoSelectProduct,
    this.isActive = true,
    this.showAppBar = true,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;

  final TextEditingController _manualBarcodeController = TextEditingController();
  bool _isProcessingScan = false;
  bool _torchOn = false;
  Product? _lastAddedProduct;
  int _lastAddedQuantity = 1;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      autoStart: widget.isActive,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      returnImage: false,
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
      ],
    );

    if (widget.autoSelectProduct != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addProductDirectly(widget.autoSelectProduct!);
      });
    }
  }

  @override
  void didUpdateWidget(covariant ScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _scannerController.start();
      } else {
        _scannerController.stop();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive) return;
    if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _feedbackTimer?.cancel();
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

    // Auto-dismiss the scanned product feedback after 2.5 seconds to allow continuous scanning
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _lastAddedProduct = null);
      }
    });

    // Short prompt success notification with name, price and quantity
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Added ${product.name} (₹${product.price.toStringAsFixed(0)}) • Qty: ${cartItem.quantity}',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Or pick an authoritative test product:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.qr_code_2, size: 16),
                  label: const Text('QR Test Bench', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QrTestingScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Text('P001', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  label: const Text('Maggi (₹20)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('FLASHCART-P001');
                  },
                ),
                ActionChip(
                  avatar: const Text('P002', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  label: const Text('Biscuits (₹15)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('FLASHCART-P002');
                  },
                ),
                ActionChip(
                  avatar: const Text('P003', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  label: const Text('Surf Excel (₹70)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('FLASHCART-P003');
                  },
                ),
                ActionChip(
                  avatar: const Text('P004', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  label: const Text('Stationery (₹200)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('FLASHCART-P004');
                  },
                ),
                ActionChip(
                  avatar: const Text('P005', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  label: const Text('College bag (₹699)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('FLASHCART-P005');
                  },
                ),
                ActionChip(
                  avatar: const Text('P006', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  label: const Text('Water bottle (₹288)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('FLASHCART-P006');
                  },
                ),
                ActionChip(
                  avatar: const Text('P007', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  label: const Text('Sonpapidi (₹154)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('FLASHCART-P007');
                  },
                ),
                ActionChip(
                  avatar: const Text('P008', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  label: const Text('Paneer (₹299)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('FLASHCART-P008');
                  },
                ),
                ActionChip(
                  avatar: const Text('P009', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  label: const Text('Cool drinks (₹40)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('FLASHCART-P009');
                  },
                ),
                ActionChip(
                  avatar: const Text('P0010', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  label: const Text('Lays packet (₹50)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleBarcode('FLASHCART-P0010');
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text('Scan Products'),
              actions: [
                // QR Test Bench screen shortcut
                IconButton(
                  icon: const Icon(Icons.qr_code_2),
                  tooltip: 'QR Test Bench',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QrTestingScreen()),
                    );
                  },
                ),
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
              ],
            )
          : null,
      body: Stack(
        children: [
          // Live Camera Scanner
          MobileScanner(
            controller: _scannerController,
            errorBuilder: (context, error, child) {
              final isPermissionDenied = error.errorCode == MobileScannerErrorCode.permissionDenied;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPermissionDenied ? Icons.lock_outline_rounded : Icons.no_photography_outlined,
                        size: 64,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPermissionDenied ? 'Camera Permission Required' : 'Camera Unavailable',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPermissionDenied
                            ? 'Please allow camera permission so FlashCart can scan barcodes from product shelves.'
                            : 'Unable to connect to the camera on this device. You can still scan items manually.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _scannerController.start(),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Retry Camera'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textPrimary,
                            ),
                            onPressed: _showManualBarcodeSheet,
                            icon: const Icon(Icons.keyboard, size: 18),
                            label: const Text('Manual Barcode'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const QrTestingScreen()),
                              );
                            },
                            icon: const Icon(Icons.qr_code, size: 18),
                            label: const Text('Test QR Bench'),
                          ),
                        ],
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

          // Fast Product Lookup HUD
          if (_isProcessingScan)
            Positioned(
              top: 76,
              left: 40,
              right: 40,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Looking up product...',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Instant Non-blocking Product Feedback Toast (No "View Bill" button)
          if (_lastAddedProduct != null)
            Positioned(
              bottom: 84,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _lastAddedProduct!.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_lastAddedProduct!.price.toStringAsFixed(2)} • In Bill: $_lastAddedQuantity',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    PriceText(
                      amount: _lastAddedProduct!.price * _lastAddedQuantity,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Bill',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward, size: 12, color: AppColors.primaryDark),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Persistent Bottom Bill Bar with View Bill Button
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
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Bill', style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 16),
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

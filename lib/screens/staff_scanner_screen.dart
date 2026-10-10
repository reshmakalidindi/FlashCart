import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/order_service.dart';
import '../utils/constants.dart';
import '../widgets/price_text.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

class StaffScannerScreen extends StatefulWidget {
  const StaffScannerScreen({super.key});

  @override
  State<StaffScannerScreen> createState() => _StaffScannerScreenState();
}

class _StaffScannerScreenState extends State<StaffScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );
  final TextEditingController _manualOrderIdController = TextEditingController();
  final OrderService _orderService = OrderService();

  bool _isProcessing = false;
  OrderVerificationResult? _lastResult;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualOrderIdController.dispose();
    super.dispose();
  }

  Future<void> _processVerification(String qrPayload) async {
    if (_isProcessing || qrPayload.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _lastResult = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final staffId = authProvider.user?.uid ?? 'staff_guard';

    final result = await _orderService.verifyOrderExit(
      qrPayload: qrPayload,
      staffId: staffId,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _lastResult = result;
      });
    }
  }

  void _showManualInputSheet() {
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
              'Staff Manual Verification Input',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualOrderIdController,
              decoration: InputDecoration(
                hintText: 'Enter Customer Order # (e.g. FC123456)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.verified, color: AppColors.primary),
                  onPressed: () {
                    final code = _manualOrderIdController.text;
                    Navigator.of(ctx).pop();
                    _processVerification(code);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Verify Order ID',
              onPressed: () {
                final code = _manualOrderIdController.text;
                Navigator.of(ctx).pop();
                _processVerification(code);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isStaff) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Restricted')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person_outlined, size: 72, color: AppColors.error),
                const SizedBox(height: 18),
                const Text(
                  'Staff Permissions Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Only authorized store security guards and cashiers can access the exit verification scanner.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Return to Shopper Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.security, color: AppColors.accent, size: 22),
            SizedBox(width: 8),
            Text('Staff Exit Verification'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Manual Order ID Entry',
            onPressed: _showManualInputSheet,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
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
          // Scanner Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (var b in barcodes) {
                if (b.rawValue != null && !_isProcessing && _lastResult == null) {
                  _processVerification(b.rawValue!);
                  break;
                }
              }
            },
          ),

          // Scanner Overlay Frame
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _lastResult == null
                      ? AppColors.accent
                      : (_lastResult!.isSuccess ? AppColors.success : AppColors.error),
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 64,
                  color: Colors.white38,
                ),
              ),
            ),
          ),

          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Scan customer\'s exit QR code on their screen',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Manual Entry trigger floating button
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: ElevatedButton.icon(
              onPressed: _showManualInputSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.edit_note, color: AppColors.primary),
              label: const Text(
                'Type Customer Order ID Manually',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.accent),
                    SizedBox(height: 16),
                    Text(
                      'Verifying Order Payment in Database...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Verification Result Sheet Modal Overlay
          if (_lastResult != null)
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _lastResult!.isSuccess ? Icons.check_circle : Icons.cancel,
                          size: 72,
                          color: _lastResult!.isSuccess ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _lastResult!.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _lastResult!.isSuccess ? AppColors.success : AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _lastResult!.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        if (_lastResult!.order != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Order #'),
                                    Text(_lastResult!.order!.orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Items Checked'),
                                    Text('${_lastResult!.order!.items.length} items', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Paid'),
                                    PriceText(amount: _lastResult!.order!.total, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Scan Next Customer',
                          color: _lastResult!.isSuccess ? AppColors.primary : AppColors.error,
                          onPressed: () {
                            setState(() => _lastResult = null);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

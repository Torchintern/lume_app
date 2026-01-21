import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'payment_amount_screen.dart';

class QrScannerScreen extends StatefulWidget {
  final int regId;

  const QrScannerScreen({
    super.key,
    required this.regId,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  final ImagePicker _picker = ImagePicker();

  bool torchOn = false;
  bool scanned = false; // prevents multiple scans

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ================= PICK IMAGE & SCAN =================
  Future<void> _pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    await controller.analyzeImage(image.path);
  }

  // ================= PARSE UPI QR =================
  Map<String, String?> _parseUpiQr(String raw) {
    try {
      final uri = Uri.parse(raw);
      if (uri.scheme != "upi") return {};

      return {
        "upiId": uri.queryParameters["pa"],
        "name": uri.queryParameters["pn"],
        "amount": uri.queryParameters["am"], // optional
      };
    } catch (_) {
      return {};
    }
  }

  // ================= HANDLE QR RESULT =================
  void _handleQrResult(String qrValue) {
    if (scanned) return;

    final parsed = _parseUpiQr(qrValue);
    final upiId = parsed["upiId"];

    if (upiId == null || upiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid UPI QR"),
        ),
      );
      return;
    }

    scanned = true;

    final payeeName =
        parsed["name"] != null && parsed["name"]!.isNotEmpty
            ? parsed["name"]!
            : "UPI Payment";

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentAmountScreen(
          regId: widget.regId,
          payee: upiId,  //ONLY UPI ID
          payeeName: payeeName,      // Parsed name
          isWalletTransfer: false, // Wallet → UPI
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ================= CAMERA SCANNER =================
            MobileScanner(
              controller: controller,
              onDetect: (BarcodeCapture capture) {
                if (capture.barcodes.isEmpty) return;

                final String? value =
                    capture.barcodes.first.rawValue;

                if (value != null && mounted) {
                  _handleQrResult(value);
                }
              },
            ),

            // ================= TOP BAR =================
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  Row(
                    children: [
                      // Torch
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: Icon(
                            torchOn
                                ? Icons.flash_on
                                : Icons.flash_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            controller.toggleTorch();
                            setState(() {
                              torchOn = !torchOn;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Gallery
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(
                            Icons.photo,
                            color: Colors.white,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ================= SCAN FRAME =================
            Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: CustomPaint(
                  painter: _ScanFramePainter(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= WHITE CORNER FRAME =================
class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const c = 26.0;

    // Top-left
    canvas.drawLine(Offset(0, c), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(c, 0), paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - c, 0), Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, c), paint);

    // Bottom-left
    canvas.drawLine(
        Offset(0, size.height - c),
        Offset(0, size.height),
        paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(c, size.height), paint);

    // Bottom-right
    canvas.drawLine(
        Offset(size.width - c, size.height),
        Offset(size.width, size.height),
        paint);
    canvas.drawLine(
        Offset(size.width, size.height - c),
        Offset(size.width, size.height),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

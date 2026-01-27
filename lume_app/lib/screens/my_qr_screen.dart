import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class MyQrScreen extends StatefulWidget {
  final String name;
  final String upiId;
  final bool walletActive;
  final String? profileImageUrl;

  const MyQrScreen({
    super.key,
    required this.name,
    required this.upiId,
    required this.walletActive,
    this.profileImageUrl,
  });

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  final GlobalKey qrKey = GlobalKey();
  final TextEditingController amountCtrl = TextEditingController();

  bool amountQrGenerated = false;
  String generatedAmount = "";

  @override
  void initState() {
    super.initState();
    _resetQrState();
  }

  void _resetQrState() {
    amountQrGenerated = false;
    generatedAmount = "";
    amountCtrl.clear();
  }

  String get initials {
    final parts = widget.name.trim().split(" ");
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return widget.name.substring(0, 1).toUpperCase();
  }

  String get upiUri {
    final encodedName = Uri.encodeComponent(widget.name);

    if (amountQrGenerated && generatedAmount.isNotEmpty) {
      return "upi://pay?"
          "pa=${widget.upiId}"
          "&pn=$encodedName"
          "&am=$generatedAmount"
          "&cu=INR";
    }

    return "upi://pay?"
        "pa=${widget.upiId}"
        "&pn=$encodedName"
        "&cu=INR";
  }

  // ================= AMOUNT DIALOG =================
  Future<void> showAmountDialog() async {
    amountCtrl.clear();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          content: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter amount",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "₹",
                      style: TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: amountCtrl,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "0",
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (amountCtrl.text.isEmpty ||
                    double.tryParse(amountCtrl.text) == null) {
                  return;
                }

                setState(() {
                  generatedAmount = amountCtrl.text;
                  amountQrGenerated = true;
                });

                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _requestPermission() async {
    if (await Permission.photos.isGranted ||
        await Permission.photos.request().isGranted) {
      return true;
    }
    if (await Permission.storage.isGranted ||
        await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  // ================= RESULT DIALOG =================
  void _showResultDialog(String message, {bool success = true}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              size: 48,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ================= DOWNLOAD QR =================
  Future<void> downloadQr(BuildContext context) async {
    try {
      final hasPermission = await _requestPermission();
      if (!hasPermission) return;

      final boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      final pngBytes = byteData!.buffer.asUint8List();
      final directory = Directory(
        "/storage/emulated/0/Pictures/LUME",
      );

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File(
        "${directory.path}/LUME_QR_${DateTime.now().millisecondsSinceEpoch}.png",
      );

      await file.writeAsBytes(pngBytes);

      if (!context.mounted) return;
      _showResultDialog("QR code saved to gallery");
    } catch (_) {
      if (!context.mounted) return;
      _showResultDialog("Failed to save QR code", success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text("My QR Code"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: widget.walletActive
            ? [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => Share.share(
                    "${widget.name}\n${widget.upiId}\n\nPay via UPI:\n$upiUri",
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.currency_rupee),
                  onPressed: showAmountDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => downloadQr(context),
                ),
              ]
            : [],
      ),
      body: widget.walletActive
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.upiId,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 36),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 12),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            RepaintBoundary(
                              key: qrKey,
                              child: QrImageView(
                                data: upiUri,
                                size: 260,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFFE8ECFF),
                              backgroundImage: widget.profileImageUrl != null &&
                                      widget.profileImageUrl!.isNotEmpty
                                  ? NetworkImage(widget.profileImageUrl!)
                                  : null,
                              child: widget.profileImageUrl == null ||
                                      widget.profileImageUrl!.isEmpty
                                  ? Text(
                                      initials,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF4C6EF5),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                        if (amountQrGenerated && generatedAmount.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            "₹ $generatedAmount",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  "Powered by LUME",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      "Wallet is inactive",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Complete Aadhaar verification to activate your wallet.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

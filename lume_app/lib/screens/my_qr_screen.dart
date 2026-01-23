import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MyQrScreen extends StatefulWidget {
  final String name;
  final String upiId;
  final bool walletActive;

  const MyQrScreen({
    super.key,
    required this.name,
    required this.upiId,
    required this.walletActive,
  });

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  final GlobalKey qrKey = GlobalKey();
  final TextEditingController amountCtrl = TextEditingController();
  File? profileImage;
  bool amountQrGenerated = false;
  String generatedAmount = "";

  @override
  void initState() {
    super.initState();
    _resetQrState();
    _loadProfileImage();
  }

  void _resetQrState() {
    amountQrGenerated = false;
    generatedAmount = "";
    amountCtrl.clear();
  }

  Future<void> _loadProfileImage() async {
  final prefs = await SharedPreferences.getInstance();
  final path = prefs.getString("profile_image_path");

  if (path != null) {
    final file = File(path);
    if (await file.exists()) {
      setState(() {
        profileImage = file;
      });
    }
  }
}


  // ================= USER INITIALS =================
  String get initials {
    final parts = widget.name.trim().split(" ");
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return widget.name.substring(0, 1).toUpperCase();
  }

  // ================= UPI URI =================
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
          content: Column(
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

  // ================= PERMISSION =================
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

      final directory = await getExternalStorageDirectory();
      final file = File(
        "${directory!.path}/LUME_QR_${DateTime.now().millisecondsSinceEpoch}.png",
      );

      await file.writeAsBytes(pngBytes);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR saved to gallery")),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save QR")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

      // ================= BODY =================
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

                // ================= QR CARD =================
                Center(
                  child:Container(
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
                              backgroundImage: profileImage != null
                                  ? FileImage(profileImage!)
                                  : null,
                              child: profileImage == null
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

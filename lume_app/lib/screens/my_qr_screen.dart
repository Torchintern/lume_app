import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';


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
  final TextEditingController amountCtrl = TextEditingController();
  Color selectedBgColor = const Color(0xFFE86A6A); 
  Color savedBgColor = const Color(0xFFE86A6A);
  bool showSaveButton = false;
  final List<Color> bgColors = [
    Color(0xFFE86A6A),
    Color(0xFFEF5350),
    Color(0xFFEC407A),
    Color(0xFFAB47BC),
    Color(0xFF7E57C2),
    Color(0xFF5C6BC0),
    Color(0xFF42A5F5),
    Color(0xFF26A69A),
    Color(0xFF66BB6A),
    Color(0xFFFFA726),
  ];
  final GlobalKey shareQrKey = GlobalKey();
  bool amountQrGenerated = false;
  String generatedAmount = "";
  bool copied = false;
  bool showSavedAnimation = false;
  bool isSharingMode = false;
 

 @override
  void initState() {
    super.initState();
    _resetQrState();
     loadSavedColor();
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

  Future<void> saveColorToPrefs(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("qr_bg_color", color.value);
  }


Future<void> loadSavedColor() async {
    final prefs = await SharedPreferences.getInstance();

    final colorValue = prefs.getInt("qr_bg_color");

    if (colorValue != null) {
      setState(() {
        savedBgColor = Color(colorValue);
        selectedBgColor = Color(colorValue);
      });
    }
  }

  // === copy ====
  Future<void> handleCopy() async {
  await Clipboard.setData(
    ClipboardData(text: widget.upiId),
  );

  setState(() => copied = true);

  Future.delayed(const Duration(seconds: 2), () {
    if (mounted) {
      setState(() => copied = false);
    }
  });
}


  // ===== ShareQR ==========
 Future<void> shareQrImage() async {
  try {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Center(
          child: RepaintBoundary(
            key: shareQrKey,
            child: buildShareCard(),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Wait for render frame
    await Future.delayed(const Duration(milliseconds: 300));

    final boundary =
        shareQrKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3);

    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    final pngBytes = byteData!.buffer.asUint8List();

    final file = File("${Directory.systemTemp.path}/qr_share.png");

    await file.writeAsBytes(pngBytes);

    entry.remove();

    await Share.shareXFiles([XFile(file.path)]);
  } catch (e) {
    _showResultDialog("Share failed", success: false);
  }
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
  // Background Color
  Widget buildColorPicker() {
  return Container(
    padding: const EdgeInsets.all(20),
    child: Wrap(
      spacing: 14,
      runSpacing: 14,
      children: bgColors.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedBgColor = color;
              showSaveButton = selectedBgColor != savedBgColor;
            });
            Navigator.pop(context);
          },
          child: CircleAvatar(
            radius: 24,
            backgroundColor: color,
            child: selectedBgColor == color
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    ),
  );
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

    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Center(
          child: RepaintBoundary(
            key: shareQrKey,
            child: buildShareCard(),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    await Future.delayed(const Duration(milliseconds: 300));

    final boundary =
        shareQrKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3);

    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    final pngBytes = byteData!.buffer.asUint8List();

    final file = File(
      "${Directory.systemTemp.path}/qr_download.png",
    );

    await file.writeAsBytes(pngBytes);

    /// Save to Gallery
    await GallerySaver.saveImage(file.path);

    entry.remove();

    if (!context.mounted) return;
    _showResultDialog("QR saved to gallery");

  } catch (e) {
    _showResultDialog("Failed to save QR", success: false);
  }
}


  // share screen
  Widget buildShareCard() {
  return Container(
    color: Colors.white, 
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [

 Text(
  widget.name,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  ),
),




        const SizedBox(height: 24),

        Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selectedBgColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Image.asset("assets/images/upi.png", height: 28),

              const SizedBox(height: 20),

              Container(
                width: 260,
                height: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
  alignment: Alignment.center,
  children: [

    QrImageView(
      data: upiUri,
      size: 228,
      backgroundColor: Colors.transparent,
    ),
    CircleAvatar(
  radius: 26,
  backgroundColor: Colors.white,
  child: CircleAvatar(
    radius: 24,
    backgroundImage: widget.profileImageUrl != null &&
            widget.profileImageUrl!.isNotEmpty
        ? NetworkImage(widget.profileImageUrl!)
        : null,
    child: widget.profileImageUrl == null ||
            widget.profileImageUrl!.isEmpty
        ? Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          )
        : null,
  ),
),

  ],
),

              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
child: Center(
  child: Text(
    widget.upiId,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: Colors.black,
    ),
  ),
),




              ),

              if (amountQrGenerated) ...[
                const SizedBox(height: 12),
                Text(
                  "₹ $generatedAmount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
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
                  
                Stack(
  alignment: Alignment.topCenter,
  children: [

    /// MAIN QR CONTENT
    RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 36),

          Center(
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: selectedBgColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [

    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        if (!isSharingMode)
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => buildColorPicker(),
              );
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Image.asset(
                "assets/images/star.png",
                width: 16,
              ),
            ),
          )
        else
          const SizedBox(width: 36),

        /// UPI LOGO
        Image.asset(
          "assets/images/upi.png",
          height: 28,
        ),

        if (!isSharingMode)
          GestureDetector(
            onTap: shareQrImage,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Image.asset(
                "assets/images/share.png",
                width: 16,
              ),
            ),
          )
        else
          const SizedBox(width: 36),
      ],
    ),

    const SizedBox(height: 20),

    /// ===== QR BOX =====
    Container(
      width: 260,
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2).withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
  alignment: Alignment.center,
  children: [

    /// QR IMAGE
    QrImageView(
      data: upiUri,
      size: 228,
      backgroundColor: Colors.transparent,
    ),

    /// PROFILE IMAGE CENTER
    CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.black,
        backgroundImage:
            widget.profileImageUrl != null &&
                    widget.profileImageUrl!.isNotEmpty
                ? NetworkImage(widget.profileImageUrl!)
                : null,
        child: widget.profileImageUrl == null ||
                widget.profileImageUrl!.isEmpty
            ? Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    ),
  ],
),

    ),

    const SizedBox(height: 18),

    /// ===== UPI ID BOX =====
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.upiId,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!isSharingMode) ...[
            const SizedBox(width: 10),
  GestureDetector(
  onTap: handleCopy,
  child: AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    child: copied
        ? const Icon(
            Icons.check_circle,  
            key: ValueKey("tick"),
            color: Colors.green,
            size: 22,
          )
        : const Icon(
            Icons.copy,
            key: ValueKey("copy"),
            size: 20,
          ),
  ),
)


          ]
        ],
      ),
    ),

    if (amountQrGenerated) ...[
      const SizedBox(height: 12),
      Text(
        "₹ $generatedAmount",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ],
),

            ),
          ),
        ],
      ),
    ),
  

  ],
),
          
                  const SizedBox(height: 18),  
                  
                if (showSaveButton)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          savedBgColor = selectedBgColor;
                          showSaveButton = false;
                          showSavedAnimation = true;
                        });

                        saveColorToPrefs(selectedBgColor);

                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() {
                              showSavedAnimation = false;
                            });
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: showSavedAnimation
                        ? Container(
                            key: const ValueKey("saved"),
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "Saved",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(),
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

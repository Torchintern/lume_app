import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pin_verify_screen.dart';
import 'payment_result_screen.dart';
import 'pin_settings_screen.dart';
import '../widgets/create_upi_dialog.dart';

class PaymentAmountScreen extends StatefulWidget {
  final int regId;
  final String payee;        // UPI ID or mobile
  final String payeeName;    // detected name
  final bool isWalletTransfer;
  final String? profileImage;


  const PaymentAmountScreen({
    super.key,
    required this.regId,
    required this.payee,
    required this.payeeName,
    required this.isWalletTransfer,
    this.profileImage, 
  });

  @override
  State<PaymentAmountScreen> createState() =>
      _PaymentAmountScreenState();
}

class _PaymentAmountScreenState
    extends State<PaymentAmountScreen> {
  String amountText = "";
  double balance = 0.0;
  bool loadingBalance = true;
  bool paying = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final b = await ApiService.getWalletBalance(widget.regId);
      if (!mounted) return;
      setState(() {
        balance = b;
        loadingBalance = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        balance = 0.0;
        loadingBalance = false;
      });
    }
  }

  double get amount =>
      amountText.isEmpty ? 0.0 : double.tryParse(amountText) ?? 0.0;

  void _addDigit(String d) {
    if (d == "." && amountText.contains(".")) return;
    setState(() => amountText += d);
  }

  void _removeDigit() {
    if (amountText.isNotEmpty) {
      setState(() {
        amountText =
            amountText.substring(0, amountText.length - 1);
      });
    }
  }

  bool get canPay =>
      amount > 0 &&
      !paying &&
      !loadingBalance &&
      amount <= balance &&
      widget.payee.isNotEmpty &&
      (widget.payee.contains("@") || widget.payee.length == 10);

  Future<bool> _ensureUpiCreated() async {
    try {
      final details =
          await ApiService.getStudentDetails(widget.regId);
      final upiId = details["upi_id"];

      if (upiId == null || upiId.isEmpty) {
        await showCreateUpiDialog(
          context: context,
          regId: widget.regId,
          onSuccess: () {},
        );
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onPayPressed() async {
    final hasUpi = await _ensureUpiCreated();
    if (!hasUpi) return;

    final status =
        await ApiService.getPinStatus(widget.regId);
    final bool walletPinSet = status["wallet"] == true;

    if (!walletPinSet) {
      _showWalletPinRequiredDialog();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinVerifyScreen(
          regId: widget.regId,
          type: "wallet",
          onVerified: _executePayment,
          amount: amount,
        ),
      ),
    );
  }

 Future<void> _executePayment() async {
  if (!canPay) return;

  setState(() => paying = true);
  String status = "failed";

  Map<String, dynamic>? res;   // ⭐ MOVE HERE (OUTSIDE TRY)

  try {

    if (!widget.payee.contains("@")) {

      res = await ApiService.walletToWalletTransfer(
        senderRegId: widget.regId,
        receiverMobile: widget.payee,
        amount: amount,
      );

    } else {

      res = await ApiService.payViaUpi(
        widget.regId,
        widget.payee,
        amount,
        widget.payeeName,
      );

    }

    status = res != null ? "success" : "failed";

  } catch (_) {
    status = "failed";
  }

  if (!mounted) return;
  setState(() => paying = false);

  final details = await ApiService.getStudentDetails(widget.regId);

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => PaymentResultScreen(
        amount: amount,
        status: status,
        direction: "debit",

        payeeName: widget.payeeName.isNotEmpty
            ? widget.payeeName
            : widget.payee,

        payee: widget.payee,
        isWallet: !widget.payee.contains("@"),
        regId: widget.regId,
        fullName: details["full_name"] ?? "",
        mobile: details["mobile"] ?? "",
        upiId: details["upi_id"],
        walletStatus: details["wallet_status"] ?? "inactive",
        aadhaarVerified: details["aadhaar_verified"] ?? 0,
        panVerified: details["pan_verified"] ?? 0,

        earnedPoints: res?["earned_points"], 
        rewardToken: res?["reward_token"],
      ),
    ),
  );
}


  void _showWalletPinRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Wallet PIN not set",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          "Please set your Wallet PIN to continue payments.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PinSettingsScreen(
                    regId: widget.regId,
                    forceSetup: true,
                  ),
                ),
              );
            },
            child: const Text("Go to Wallet PIN"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isUpi = widget.payee.contains("@");

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ================= TOP (SCROLLABLE) =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "₹${amountText.isEmpty ? "0" : amountText}",
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ================= PAYEE PROFILE =================
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isWalletTransfer
                              ? Colors.green
                              : Colors.blue,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            (widget.profileImage != null &&
                                    widget.profileImage!.isNotEmpty)
                                ? NetworkImage(widget.profileImage!)
                                : null,
                        child: (widget.profileImage == null ||
                                widget.profileImage!.isEmpty)
                            ? Text(
                                widget.payeeName.isNotEmpty
                                    ? widget.payeeName
                                        .trim()
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : "U",
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      widget.payeeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text(
                      widget.payee,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isUpi ? "UPI Payment" : "Lume Wallet",
                      style: TextStyle(
                        fontSize: 12,
                        color: isUpi ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= KEYPAD (FIXED) =================
            _Keypad(
              onDigit: _addDigit,
              onBackspace: _removeDigit,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canPay ? _onPayPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canPay ? const Color(0xFF4C6EF5) : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: paying
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Pay",
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= KEYPAD =================
class _Keypad extends StatelessWidget {
  final Function(String) onDigit;
  final VoidCallback onBackspace;

  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    Widget key(String t, {VoidCallback? onTap}) {
      return GestureDetector(
        onTap: onTap ?? () => onDigit(t),
        child: SizedBox(
          width: 80,
          height: 60,
          child: Center(
            child: Text(
              t,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:
              ["1", "2", "3"].map((e) => key(e)).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:
              ["4", "5", "6"].map((e) => key(e)).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:
              ["7", "8", "9"].map((e) => key(e)).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            key("."),
            key("0"),
            key("<", onTap: onBackspace),
          ],
        ),
      ],
    );
  }
}

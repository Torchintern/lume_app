import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pin_verify_screen.dart';
import 'payment_result_screen.dart';
import 'pin_settings_screen.dart';

class PaymentAmountScreen extends StatefulWidget {
  final int regId;
  final String payee;
  final String payeeName;
  final bool isWalletTransfer;

  const PaymentAmountScreen({
    super.key,
    required this.regId,
    required this.payee,
    required this.payeeName,
    required this.isWalletTransfer,
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

  // ================= LOAD BALANCE =================
  Future<void> _loadBalance() async {
    try {
      final b =
          await ApiService.getWalletBalance(widget.regId);
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

  // ================= AMOUNT INPUT =================
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
      (widget.payee.contains("@") ||
          widget.payee.length == 10);

  // ================= PAY BUTTON ENTRY =================
  Future<void> _onPayPressed() async {
    final status =
        await ApiService.getPinStatus(widget.regId);
    final bool walletPinSet = status["wallet"] == true;

    if (!walletPinSet) {
      _showWalletPinRequiredDialog();
      return;
    }

    _startPaymentFlow();
  }

  // ================= PIN VERIFY =================
  Future<void> _startPaymentFlow() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinVerifyScreen(
          regId: widget.regId,
          type: "wallet",
          onVerified: _executePayment,
        ),
      ),
    );
  }

  // ================= EXECUTE PAYMENT =================
  Future<void> _executePayment() async {
    if (!canPay) return;

    setState(() => paying = true);

    String status = "failed";

    try {
      final bool isUpiPayment =
          widget.payee.contains("@");
      bool ok = false;

      if (isUpiPayment) {
        ok = await ApiService.payViaUpi(
          widget.regId,
          widget.payee,
          amount,
        );
      } else {
        ok = await ApiService.walletToWalletTransfer(
          senderRegId: widget.regId,
          receiverMobile: widget.payee,
          amount: amount,
        );
      }

      status = ok ? "success" : "failed";
    } catch (_) {
      status = "failed";
    }

    if (!mounted) return;

    setState(() => paying = false);

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
        ),
      ),
    );
  }

  // ================= WALLET PIN REQUIRED DIALOG =================
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
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

            const SizedBox(height: 10),

            Column(
              children: [
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
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.payee.contains("@")
                        ? "UPI Payment"
                        : "Lume Wallet",
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.payee.contains("@")
                          ? Colors.blue
                          : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            _Keypad(
              onDigit: _addDigit,
              onBackspace: _removeDigit,
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canPay ? _onPayPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canPay
                        ? const Color(0xFF4C6EF5)
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
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
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
          children:
              ["1", "2", "3"].map((e) => key(e)).toList(),
        ),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
          children:
              ["4", "5", "6"].map((e) => key(e)).toList(),
        ),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
          children:
              ["7", "8", "9"].map((e) => key(e)).toList(),
        ),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
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

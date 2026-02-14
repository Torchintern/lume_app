import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../dashboard_screen.dart';

class CardPaymentOtpScreen extends StatefulWidget {
  final int txnId;
  final bool saveCard;
  final Map<String, dynamic> cardData;

  final int regId;
  final String fullName;
  final String mobile;
  final String? upiId;
  final String walletStatus;
  final int aadhaarVerified;
  final int panVerified;

  const CardPaymentOtpScreen({
    super.key,
    required this.txnId,
    required this.saveCard,
    required this.cardData,
    required this.regId,
    required this.fullName,
    required this.mobile,
    required this.upiId,
    required this.walletStatus,
    required this.aadhaarVerified,
    required this.panVerified,
  });

  @override
  State<CardPaymentOtpScreen> createState() => _CardPaymentOtpScreenState();
}

class _CardPaymentOtpScreenState extends State<CardPaymentOtpScreen> {
  final TextEditingController otpController = TextEditingController();
  bool loading = false;

  // ================= RESEND STATE =================
  Timer? _timer;
  int _secondsLeft = 60;
  bool showResentMessage = false;

  bool get canResend => _secondsLeft == 0;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _secondsLeft = 60;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  // ================= VERIFY OTP =================
  Future<void> _verifyOtp() async {
    if (otpController.text.trim().length < 4) {
      _showResultDialog(
        success: false,
        message: "Please enter a valid OTP",
      );
      return;
    }

    setState(() => loading = true);

    bool success = false;

    try {
      final result = await ApiService.verifyAddMoney(
        txnId: widget.txnId,
        otp: otpController.text.trim(),
        saveCard: widget.saveCard,
        cardData: widget.cardData,
        regId: widget.regId,
      ).timeout(const Duration(seconds: 20));

      if (result == "success" || result == true) {
        success = true;
      }
    } catch (_) {
      success = false;
    }

    if (!mounted) return;
    setState(() => loading = false);

    _showResultDialog(
      success: success,
      message: success ? "Payment successful" : "Payment failed",
    );
  }

  // ================= CANCEL PAYMENT =================
  Future<void> _cancelPayment() async {
    await ApiService.cancelAddMoney(widget.txnId);

    _showResultDialog(
      success: false,
      message: "Payment cancelled",
    );
  }

  // ================= RESEND OTP =================
  void _resendOtp() {
    otpController.clear();
    showResentMessage = true;
    _startResendTimer();
    setState(() {});
  }

  // ================= RESULT DIALOG =================
  void _showResultDialog({
    required bool success,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.cancel,
                size: 72,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C6EF5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DashboardScreen(
                          regId: widget.regId,
                          fullName: widget.fullName,
                          mobile: widget.mobile,
                          upiId: widget.upiId,
                          walletStatus: widget.walletStatus,
                          aadhaarVerified: widget.aadhaarVerified,
                          panVerified: widget.panVerified,
                          initialTab: "wallet",
                        ),
                      ),
                      (_) => false,
                    );
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "OTP Verification",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancelPayment,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Enter OTP sent to your registered mobile number",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // ================= OTP FIELD =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                obscuringCharacter: "●",
                onChanged: (_) {
                  if (showResentMessage) {
                    setState(() => showResentMessage = false);
                  }
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter OTP",
                  counterText: "",
                ),
              ),
            ),

            if (showResentMessage)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "OTP resent successfully",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: canResend ? _resendOtp : null,
              child: Text(
                canResend
                    ? "Resend OTP"
                    : "Resend OTP in 00:${_secondsLeft.toString().padLeft(2, '0')}",
                style: TextStyle(
                  color:
                      canResend ? const Color(0xFF4C6EF5) : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Spacer(),

            // ================= DASHBOARD STYLE BUTTONS =================
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4C6EF5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: _cancelPayment,
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4C6EF5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C6EF5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: loading ? null : _verifyOtp,
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Verify & Pay",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

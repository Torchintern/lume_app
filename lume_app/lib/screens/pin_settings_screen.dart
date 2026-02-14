import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/otp_bottom_sheet.dart';
import '../widgets/primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinSettingsScreen extends StatefulWidget {
  final int regId;
  final bool forceSetup;
  final String initialTab; 

  const PinSettingsScreen({
    super.key,
    required this.regId,
    this.forceSetup = false,
    this.initialTab = "wallet",
  });

  @override
  State<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

class _PinSettingsScreenState extends State<PinSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool walletHasPin = false;
  bool cardHasPin = false;

  bool walletOtpVerified = false;
  bool cardOtpVerified = false;

  bool loading = true;

  @override
  void initState() {
    super.initState();
   _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == "card" ? 1 : 0,
    );
    _loadPinStatus();
  }

  // ================= LOAD PIN STATUS =================
  Future<void> _loadPinStatus() async {
    try {
      final status = await ApiService.getPinStatus(widget.regId);
      if (!mounted) return;

      setState(() {
      walletHasPin = status["wallet_pin_set"] == true;
      cardHasPin = status["card_pin_set"] == true;
      loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        walletHasPin = false;
        cardHasPin = false;
        loading = false;
      });
    }
  }

  // ================= OTP FLOW =================
  Future<void> _openOtpSheet(bool isWallet) async {
    await ApiService.sendPinResetOtp(regId: widget.regId);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return OTPBottomSheet(
          otpSentMessage: "OTP sent to your registered mobile number",
          onVerify: (otp) async {
            await ApiService.verifyPinResetOtp(otp: otp);
            if (!mounted) return;

            setState(() {
              if (isWallet) {
                walletOtpVerified = true;
              } else {
                cardOtpVerified = true;
              }
            });
          },
        );
      },
    );
  }

  // ================= SAVE PIN =================
  Future<void> _savePin(bool isWallet, String pin) async {
    final success = await ApiService.setPin(
      regId: widget.regId,
      type: isWallet ? "wallet" : "card",
      pin: pin,
    );

    if (!mounted) return;

    if (!success) {
      _showResultDialog(
        success: false,
        message: "Unable to update PIN. Please try again.",
      );
      return;
    }

    if (isWallet) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("wallet_pin_set", true);
    }

    setState(() {
      if (isWallet) {
        walletHasPin = true;
        walletOtpVerified = false;
      } else {
        cardHasPin = true;
        cardOtpVerified = false;
      }
    });

    _showResultDialog(
      success: true,
      message: "Your PIN has been updated successfully.",
    );
  }

  // ================= RESULT DIALOG =================
  void _showResultDialog({
    required bool success,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: success ? Colors.green : Colors.red,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              success ? "PIN Updated" : "Action Failed",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context, true); // return to dashboard
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async => !widget.forceSetup,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: !widget.forceSetup,
          title: Text(
            widget.forceSetup ? "Set PIN" : "PIN Settings",
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Wallet"),
              Tab(text: "Card"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _PinFlow(
              hasPin: walletHasPin,
              otpVerified: walletOtpVerified,
              onForgotPin: () => _openOtpSheet(true),
              onSave: (pin) => _savePin(true, pin),
            ),
            _PinFlow(
              hasPin: cardHasPin,
              otpVerified: cardOtpVerified,
              onForgotPin: () => _openOtpSheet(false),
              onSave: (pin) => _savePin(false, pin),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= PIN FLOW =================
class _PinFlow extends StatefulWidget {
  final bool hasPin;
  final bool otpVerified;
  final VoidCallback onForgotPin;
  final Function(String) onSave;

  const _PinFlow({
    required this.hasPin,
    required this.otpVerified,
    required this.onForgotPin,
    required this.onSave,
  });

  @override
  State<_PinFlow> createState() => _PinFlowState();
}

class _PinFlowState extends State<_PinFlow> {
  String pin = "";
  String confirmPin = "";
  bool confirmStep = false;

  bool get canEnterPin => !widget.hasPin || widget.otpVerified;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            confirmStep ? "Re-enter PIN" : "Create 4-digit PIN",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (widget.hasPin && !widget.otpVerified)
            TextButton(
              onPressed: widget.onForgotPin,
              child: const Text("Change / Forgot PIN"),
            ),

          const SizedBox(height: 24),

          _dots(confirmStep ? confirmPin.length : pin.length),

          const SizedBox(height: 24),

          _keypad(),

          const SizedBox(height: 24),

          PrimaryButton(
            text: confirmStep ? "Set PIN" : "Confirm",
            enabled: confirmStep ? confirmPin.length == 4 : pin.length == 4,
            onPressed: () {
              if (!confirmStep) {
                setState(() => confirmStep = true);
                return;
              }

              if (pin != confirmPin) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text("PIN Mismatch"),
                    content: const Text(
                      "The PINs you entered do not match. Please try again.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
                setState(() => confirmPin = "");
                return;
              }

              widget.onSave(pin);
            },
          ),
        ],
      ),
    );
  }

  Widget _dots(int filled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (i) => Container(
          margin: const EdgeInsets.all(6),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled ? Colors.blue : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _keypad() {
    const keys = [
      ["1", "2", "3"],
      ["4", "5", "6"],
      ["7", "8", "9"],
      ["", "0", "⌫"],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 64);

            return Padding(
              padding: const EdgeInsets.all(8),
              child: InkWell(
                onTap: () {
                  if (!canEnterPin) return;

                  setState(() {
                    if (k == "⌫") {
                      if (confirmStep && confirmPin.isNotEmpty) {
                        confirmPin =
                            confirmPin.substring(0, confirmPin.length - 1);
                      } else if (!confirmStep && pin.isNotEmpty) {
                        pin = pin.substring(0, pin.length - 1);
                      }
                    } else {
                      if (!confirmStep && pin.length < 4) {
                        pin += k;
                      } else if (confirmStep && confirmPin.length < 4) {
                        confirmPin += k;
                      }
                    }
                  });
                },
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: Text(
                    k,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

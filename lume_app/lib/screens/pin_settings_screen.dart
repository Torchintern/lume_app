import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/otp_bottom_sheet.dart';
import '../widgets/primary_button.dart';

class PinSettingsScreen extends StatefulWidget {
  final int regId;

  const PinSettingsScreen({
    super.key,
    required this.regId,
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
    _tabController = TabController(length: 2, vsync: this);
    _loadPinStatus();
  }

  // ================= LOAD PIN STATUS =================
  Future<void> _loadPinStatus() async {
    try {
      final status = await ApiService.getPinStatus(widget.regId);
      if (!mounted) return;

      setState(() {
        walletHasPin = status["wallet"] ?? false;
        cardHasPin = status["card"] ?? false;
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

  // ================= OTP BOTTOM SHEET =================
  void _openOtpSheet(bool isWallet) {
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
            // OTPBottomSheet handles validation UI
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

    if (success) {
      setState(() {
        if (isWallet) {
          walletHasPin = true;
          walletOtpVerified = false;
        } else {
          cardHasPin = true;
          cardOtpVerified = false;
        }
      });

      _showSuccessDialog();
    } else {
      _showErrorDialog("Failed to set PIN. Please try again.");
    }
  }

  // ================= SUCCESS DIALOG =================
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 56),
            SizedBox(height: 16),
            Text(
              "PIN set successfully",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // 🔄 Refresh PIN status
              await _loadPinStatus();

              // 🔁 Clear navigation stack → go back to dashboard
              if (mounted) {
                Navigator.of(context)
                    .popUntil((route) => route.isFirst);
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Set PIN"),
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

          _keypad(
            onKey: (v) {
              if (!canEnterPin) return;

              setState(() {
                if (!confirmStep && pin.length < 4) {
                  pin += v;
                } else if (confirmStep && confirmPin.length < 4) {
                  confirmPin += v;
                }
              });
            },
            onDelete: () {
              setState(() {
                if (confirmStep && confirmPin.isNotEmpty) {
                  confirmPin =
                      confirmPin.substring(0, confirmPin.length - 1);
                } else if (!confirmStep && pin.isNotEmpty) {
                  pin = pin.substring(0, pin.length - 1);
                }
              });
            },
          ),

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
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                    title: const Text("PIN Mismatch"),
                    content:
                        const Text("Entered PINs do not match."),
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
            color: i < filled
                ? Colors.blue
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _keypad({
    required Function(String) onKey,
    required VoidCallback onDelete,
  }) {
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
                onTap: k == "⌫" ? onDelete : () => onKey(k),
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

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pin_settings_screen.dart';

class PinVerifyScreen extends StatefulWidget {
  final int regId;
  final String type; // wallet | card
  final VoidCallback onVerified;

  const PinVerifyScreen({
    super.key,
    required this.regId,
    required this.type,
    required this.onVerified,
  });

  @override
  State<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends State<PinVerifyScreen> {
  static const int pinLength = 4;

  String enteredPin = "";
  String? error;
  bool locked = false;
  bool verifying = false;

  // ================= PIN INPUT =================

  void _onKeyTap(String value) {
    if (locked || verifying) return;
    if (enteredPin.length >= pinLength) return;

    setState(() {
      enteredPin += value;
      error = null;
    });

    if (enteredPin.length == pinLength) {
      _verify();
    }
  }

  void _onDelete() {
    if (locked || verifying) return;
    if (enteredPin.isEmpty) return;

    setState(() {
      enteredPin =
          enteredPin.substring(0, enteredPin.length - 1);
    });
  }

  // ================= VERIFY =================

  Future<void> _verify() async {
    if (enteredPin.length != pinLength) {
      setState(() {
        error = "Enter 4-digit PIN";
      });
      return;
    }

    setState(() {
      verifying = true;
      error = null;
    });

    final res = await ApiService.verifyPin(
      regId: widget.regId,
      type: widget.type,
      pin: enteredPin,
    );

    setState(() {
      verifying = false;
    });

    if (res["statusCode"] == 200) {
      widget.onVerified();
      Navigator.pop(context);
      return;
    }

    if (res["locked"] == true ||
        res["message"] == "WALLET_PIN_LOCKED" ||
        res["message"] == "CARD_PIN_LOCKED") {
      setState(() {
        locked = true;
        error = "PIN locked. Reset required.";
      });
      return;
    }

    if (res["message"] == "INVALID_PIN") {
      setState(() {
        enteredPin = "";
        error =
            "Wrong PIN. Attempts left: ${res["attemptsLeft"]}";
      });
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ===== TITLE =====
            const Text(
              "Enter PIN",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 32),

            // ===== PIN DOTS =====
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pinLength, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < enteredPin.length
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // ===== ERROR =====
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ===== FORGOT PIN =====
            if (!locked)
              GestureDetector(
                onTap: () async {
                  await Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PinSettingsScreen(regId: widget.regId),
                    ),
                  );

                  if (mounted) {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  }
                },
                child: const Text(
                  "Forgot PIN",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const Spacer(),

            // ===== RESET PIN (LOCKED) =====
            if (locked)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () async {
                      await Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PinSettingsScreen(regId: widget.regId),
                        ),
                      );

                      if (mounted) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    },
                    child: const Text("Reset PIN"),
                  ),
                ),
              ),

            if (!locked) _buildKeypad(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ================= KEYPAD =================

  Widget _buildKeypad() {
    return Column(
      children: [
        _keypadRow(["1", "2", "3"]),
        _keypadRow(["4", "5", "6"]),
        _keypadRow(["7", "8", "9"]),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80),
            _keyButton("0"),
            _iconButton(Icons.backspace_outlined, _onDelete),
          ],
        ),
      ],
    );
  }

  Widget _keypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map(_keyButton).toList(),
    );
  }

  Widget _keyButton(String value) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: () => _onKeyTap(value),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
          ),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

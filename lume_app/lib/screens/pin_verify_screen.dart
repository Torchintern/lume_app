import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'pin_settings_screen.dart';

class PinVerifyScreen extends StatefulWidget {
  final int regId;
  final String type; // wallet | card
  final VoidCallback? onVerified; // Amount is REQUIRED to enforce ₹10,000 biometric limit
  final double? amount;

  const PinVerifyScreen({
    super.key,
    required this.regId,
    required this.type,
    this.onVerified,
    this.amount,
  });

  @override
  State<PinVerifyScreen> createState() => _PinVerifyScreenState();
}
class _PinVerifyScreenState extends State<PinVerifyScreen> {
  static const int pinLength = 4;
  static const int maxAttempts = 3;
  final LocalAuthentication _auth = LocalAuthentication();
  String enteredPin = "";
  String? error;
  bool locked = false;
  bool verifying = false;
  int attemptsLeft = maxAttempts;
  bool showBiometric = false;
  String get _biometricKey => "biometric_payment_${widget.regId}";

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  // ================= LOAD BIOMETRIC PREF =================
  Future<void> _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool(_biometricKey) ?? false;

    bool supported = false;
    try {
      supported = await _auth.canCheckBiometrics &&
          await _auth.isDeviceSupported();
    } catch (_) {
      supported = false;
    }

    /// ₹10,000 LIMIT
    final bool withinLimit =
        widget.amount == null || widget.amount! <= 10000;

    if (!mounted) return;

    setState(() {
      showBiometric =
          biometricEnabled && supported && withinLimit;
    });
  }

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

  // ================= VERIFY PIN =================
  Future<void> _verify() async {
    if (enteredPin.length != pinLength) return;

    setState(() {
      verifying = true;
      error = null;
    });

    final res = await ApiService.verifyPin(
      regId: widget.regId,
      type: widget.type,
      pin: enteredPin,
    );

    if (!mounted) return;

    setState(() {
      verifying = false;
    });

    if (res["message"] == "PIN_VERIFIED") {
      widget.onVerified?.call();
      Navigator.pop(context, true);
      return;
    }

    if (res["message"] == "WALLET_PIN_LOCKED" ||
        res["message"] == "CARD_PIN_LOCKED") {
      setState(() {
        locked = true;
        error = "PIN locked. Reset required.";
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PinSettingsScreen(
            regId: widget.regId,
            forceSetup: true,
          ),
        ),
      );
      return;
    }

    if (res["message"] == "INVALID_PIN") {
      setState(() {
        enteredPin = "";
        attemptsLeft = res["attempts_left"] ?? attemptsLeft - 1;
        error =
            "Wrong PIN. Attempts left: $attemptsLeft";
      });

      if (attemptsLeft <= 0) {
        setState(() {
          locked = true;
          error = "PIN locked. Reset required.";
        });
      }
      return;
    }

    setState(() {
      enteredPin = "";
      error = "PIN verification failed. Try again.";
    });
  }

  // ================= BIOMETRIC VERIFY =================
  Future<void> _verifyWithBiometric() async {
    if (!showBiometric || verifying || locked) return;

    try {
      final success = await _auth.authenticate(
        localizedReason: "Authenticate to continue",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (success && mounted) {
        widget.onVerified?.call();
        Navigator.pop(context, true);
      }
    } catch (_) {
      // silent fail → PIN fallback
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < enteredPin.length
                        ? const Color(0xFF4C6EF5)
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // ===== ERROR =====
            if (error != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
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
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PinSettingsScreen(
                        regId: widget.regId,
                        forceSetup: true,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Forgot PIN",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4C6EF5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const Spacer(),

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
            showBiometric
                ? _iconButton(
                    Icons.fingerprint,
                    _verifyWithBiometric,
                  )
                : const SizedBox(width: 88),
            _keyButton("0"),
            _iconButton(
              Icons.backspace_outlined,
              _onDelete,
            ),
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

  Widget _iconButton(
      IconData icon, VoidCallback onTap) {
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
          child: Icon(
            icon,
            size: 22,
            color: const Color(0xFF4C6EF5),
          ),
        ),
      ),
    );
  }
}

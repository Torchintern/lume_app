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
  final TextEditingController pinController = TextEditingController();

  String? error;
  bool locked = false;
  bool verifying = false;

  Future<void> _verify() async {
    if (pinController.text.length != 4) {
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
      pin: pinController.text,
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
        error =
            "Wrong PIN. Attempts left: ${res["attemptsLeft"]}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.type.toUpperCase()} PIN"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter PIN",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: pinController,
              maxLength: 4,
              keyboardType: TextInputType.number,
              obscureText: true,
              enabled: !locked,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "****",
              ),
            ),

            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 24),

            if (!locked)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: verifying ? null : _verify,
                  child: verifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Verify"),
                ),
              ),

            if (locked)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PinSettingsScreen(
                          regId: widget.regId,
                        ),
                      ),
                    );
                  },
                  child: const Text("Reset PIN"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

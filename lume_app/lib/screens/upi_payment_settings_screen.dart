import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '/widgets/create_upi_dialog.dart';

class UpiPaymentSettingsScreen extends StatefulWidget {
  final String? upiId;
  final String mobile;
  final int regId;

  const UpiPaymentSettingsScreen({
    super.key,
    required this.upiId,
    required this.mobile,
    required this.regId,
  });

  @override
  State<UpiPaymentSettingsScreen> createState() =>
      _UpiPaymentSettingsScreenState();
}

class _UpiPaymentSettingsScreenState
    extends State<UpiPaymentSettingsScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

  bool biometricEnabled = false;
  bool biometricSupported = false;
  bool upiCopied = false;
  bool _biometricProcessing = false;
  String get _biometricKey => "biometric_payment_${widget.regId}";

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _loadBiometricSetting();
  }

  // ================= CHECK BIOMETRIC SUPPORT =================
  Future<void> _checkBiometricSupport() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!mounted) return;
      setState(() {
        biometricSupported = canCheck && isSupported;
      });
    } catch (_) {
      biometricSupported = false;
    }
  }

  // ================= LOAD SAVED SETTING (PER USER) =================
  Future<void> _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      biometricEnabled = prefs.getBool(_biometricKey) ?? false;
    });
  }

  // ================= HANDLE BIOMETRIC TOGGLE =================
  Future<void> _handleBiometricToggle(bool enable) async {
    if (!biometricSupported || _biometricProcessing) return;

    final prefs = await SharedPreferences.getInstance();

    // DISABLE
    if (!enable) {
      await prefs.setBool(_biometricKey, false);
      if (!mounted) return;
      setState(() {
        biometricEnabled = false;
      });
      return;
    }

    // ENABLE (needs biometric)
    setState(() {
      _biometricProcessing = true;
    });

    bool success = false;

    try {
      success = await _auth.authenticate(
        localizedReason:
            "Confirm fingerprint to enable biometric payments",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      success = false;
    }

    if (!mounted) return;

    if (success) {
      await prefs.setBool(_biometricKey, true);
      setState(() {
        biometricEnabled = true;
      });
    }

    setState(() {
      _biometricProcessing = false;
    });
  }

  // ================= COPY UPI =================
  void _copyUpiId() async {
    await Clipboard.setData(
      ClipboardData(text: widget.upiId ?? ""),
    );

    setState(() => upiCopied = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => upiCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text("UPI & Payment Settings"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ================= ACCOUNT CARD =================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 12),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8ECFF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.account_balance,
                              color: Color(0xFF4C6EF5),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "LUME Bank",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ================= UPI ID =================
                      Row(
                        children: [
                          const Text(
                            "UPI ID : ",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: (widget.upiId == null ||
                                    widget.upiId!.isEmpty)
                                ? GestureDetector(
                                    onTap: () => showCreateUpiDialog(
                                      context: context,
                                      regId: widget.regId,
                                      onSuccess: () {
                                        Navigator.pop(context, true);
                                      },
                                    ),
                                    child: const Text(
                                      "+ Create UPI ID",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFF4C6EF5),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : Text(
                                    widget.upiId!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          if (widget.upiId != null &&
                              widget.upiId!.isNotEmpty)
                            GestureDetector(
                              onTap: _copyUpiId,
                              child: Icon(
                                upiCopied
                                    ? Icons.check_circle
                                    : Icons.copy,
                                size: 18,
                                color: upiCopied
                                    ? Colors.green
                                    : const Color(0xFF4C6EF5),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ================= UPI NUMBER =================
                      Row(
                        children: [
                          const Text(
                            "UPI Number : ",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.mobile,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= BIOMETRIC CARD =================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 12),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: biometricSupported
                                  ? const Color(0xFFE8ECFF)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.fingerprint,
                              color: biometricSupported
                                  ? const Color(0xFF4C6EF5)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Pay with biometric",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Switch(
                            value: biometricEnabled,
                            activeColor: const Color(0xFF4C6EF5),
                            onChanged: biometricSupported &&
                                    !_biometricProcessing
                                ? (v) => _handleBiometricToggle(v)
                                : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        biometricSupported
                            ? "Payments upto ₹10,000 using fingerprint.\nNo PIN required."
                            : "Biometric authentication is not available on this device.",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              "Powered by LUME",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

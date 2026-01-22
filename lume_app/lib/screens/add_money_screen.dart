import 'package:flutter/material.dart';
import 'my_qr_screen.dart';
import 'select_payment_method_screen.dart';

class AddMoneyScreen extends StatefulWidget {
  final int regId;
  final String fullName;
  final String mobile;
  final String upiId;
  final String walletStatus;
  final int aadhaarVerified;
  final int panVerified;

  const AddMoneyScreen({
    super.key,
    required this.regId,
    required this.fullName,
    required this.mobile,
    required this.upiId,
    required this.walletStatus,
    required this.aadhaarVerified,
    required this.panVerified,
  });

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  String amountText = "";

  // ================= AMOUNT INPUT =================
  void _addDigit(String d) {
    if (d == "." && amountText.contains(".")) return;
    setState(() {
      amountText += d;
    });
  }

  void _removeDigit() {
    if (amountText.isNotEmpty) {
      setState(() {
        amountText = amountText.substring(0, amountText.length - 1);
      });
    }
  }

  void _quickAdd(int v) {
    final current = double.tryParse(amountText) ?? 0;
    setState(() {
      amountText = (current + v).toStringAsFixed(0);
    });
  }

  bool get _isValidAmount {
    final amount = double.tryParse(amountText);
    return amount != null && amount > 0;
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
        leading: const BackButton(),
        title: const Text(
          "Add Money",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyQrScreen(
                    name: widget.fullName,
                    upiId: widget.upiId,
                    walletActive: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 30),
          const Text("Add", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),

          Text(
            "₹${amountText.isEmpty ? "0" : amountText}",
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4C6EF5),
            ),
          ),

          const SizedBox(height: 30),

          // ================= QUICK AMOUNTS =================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuickAmount("+ ₹50", () => _quickAdd(50)),
              const SizedBox(width: 10),
              _QuickAmount("+ ₹100", () => _quickAdd(100)),
              const SizedBox(width: 10),
              _QuickAmount("+ ₹500", () => _quickAdd(500)),
            ],
          ),

          const Spacer(),

          // ================= KEYPAD =================
          _Keypad(
            onDigit: _addDigit,
            onBackspace: _removeDigit,
          ),

          const SizedBox(height: 20),

          // ================= CONTINUE BUTTON =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C6EF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: !_isValidAmount
                    ? null
                    : () {
                        final amount =
                            double.tryParse(amountText) ?? 0;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectPaymentMethodScreen(
                              regId: widget.regId,
                              amount: amount,
                              fullName: widget.fullName,
                              mobile: widget.mobile,
                              upiId: widget.upiId,
                              walletStatus: widget.walletStatus,
                              aadhaarVerified: widget.aadhaarVerified,
                              panVerified: widget.panVerified,
                            ),
                          ),
                        );
                      },
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= QUICK AMOUNT =================
class _QuickAmount extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmount(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4C6EF5),
            fontWeight: FontWeight.w600,
          ),
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
          width: 100,
          height: 60,
          child: Center(
            child: Text(
              t,
              style: const TextStyle(
                fontSize: 26,
                color: Colors.black,
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
          children: ["1", "2", "3"].map((e) => key(e)).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ["4", "5", "6"].map((e) => key(e)).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ["7", "8", "9"].map((e) => key(e)).toList(),
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

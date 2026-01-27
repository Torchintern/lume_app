import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';

class PaymentResultScreen extends StatelessWidget {
  final double amount;
  final String status; // success | failed | pending
  final String payeeName; // NAME from backend / runtime
  final String payee; // UPI ID / Mobile
  final bool isWallet;

  /// debit | credit | topup
  final String direction;

  final String? createdAt;

  const PaymentResultScreen({
    super.key,
    required this.amount,
    required this.status,
    required this.payeeName,
    required this.payee,
    required this.isWallet,
    this.direction = "debit",
    this.createdAt,
  });

  // ================= LOTTIE =================
  String get lottieFile {
    switch (status) {
      case "success":
        return "assets/lottie/success.json";
      case "pending":
        return "assets/lottie/pending.json";
      default:
        return "assets/lottie/failed.json";
    }
  }

  // ================= STATUS COLOR =================
  Color get statusColor {
    switch (status) {
      case "success":
        return Colors.green;
      case "pending":
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  // ================= STATUS TEXT =================
  String get statusText {
    if (status == "pending") return "Payment Pending";
    if (status == "failed") return "Payment Failed";

    if (direction == "credit") return "Payment Received";
    if (direction == "topup") return "Wallet Top-Up Successful";

    return "Payment Successful";
  }

  // ================= DATE FORMAT =================
  String get formattedTime {
    final DateTime d =
        DateTime.tryParse(createdAt ?? "") ?? DateTime.now();

    return "${d.day.toString().padLeft(2, '0')} "
        "${_month(d.month)} "
        "${d.year}, "
        "${d.hour % 12 == 0 ? 12 : d.hour % 12}:"
        "${d.minute.toString().padLeft(2, '0')} "
        "${d.hour >= 12 ? "PM" : "AM"}";
  }

  String _month(int m) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[m - 1];
  }

  // ================= DISPLAY NAME (FINAL & CORRECT) =================
  String get displayName {
    if (payeeName.trim().isNotEmpty) {
      return payeeName.trim();
    }
    return payee.isNotEmpty ? payee : "Unknown";
  }

  // ================= PAYMENT TYPE =================
  bool get _effectiveIsWallet =>
      isWallet && !payee.contains("@");

  String get paymentTypeText =>
      _effectiveIsWallet ? "Wallet" : "UPI";

  String get _idLabel =>
      _effectiveIsWallet ? "Mobile" : "UPI";

  // ================= SHARE =================
  void _sharePayment() {
    final String directionText =
        direction == "credit" ? "Received from" : "Paid to";

    final String message = """
Lume Payment Receipt

Amount: ₹${amount.toStringAsFixed(2)}
Status: $statusText
Payment Type: $paymentTypeText
$directionText: $displayName
Date: $formattedTime
""";

    Share.share(message.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bool isTopup = direction == "topup";
    final bool showSplit =
        direction == "debit" || direction == "topup";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            SizedBox(
              height: 180,
              child: Lottie.asset(
                lottieFile,
                repeat: true,
                animate: true,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              statusText,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "₹${amount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),

            const SizedBox(height: 30),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  if (isTopup) ...[
                    _row("Type", "Wallet Top-Up"),
                    _row("Payment Method", paymentTypeText),
                  ] else if (direction == "credit") ...[
                    _row("From", displayName),
                    _row("From $_idLabel", payee.isNotEmpty ? payee : "-"),
                    _row("Payment Method", paymentTypeText),
                  ] else ...[
                    _row("To", displayName),
                    _row("To $_idLabel", payee.isNotEmpty ? payee : "-"),
                    _row("Payment Method", paymentTypeText),
                  ],
                  _row("Time", formattedTime),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sharePayment,
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (showSplit)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.call_split),
                        label: const Text("Split"),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C6EF5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Done",
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

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: const TextStyle(color: Colors.grey),
          ),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

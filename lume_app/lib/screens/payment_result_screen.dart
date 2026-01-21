import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PaymentResultScreen extends StatelessWidget {
  final double amount;
  final String status; // success | failed | pending
  final String payeeName;
  final String payee;
  final bool isWallet;

  /// OPTIONAL → credit (received) | debit (paid)
  final String direction;

  /// OPTIONAL → timestamp (from history or live)
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
    DateTime d;

    if (createdAt != null) {
      d = DateTime.tryParse(createdAt!) ?? DateTime.now();
    } else {
      d = DateTime.now();
    }

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
String get displayName {
  if (payeeName.isNotEmpty && !payeeName.contains("@")) {
    return payeeName;
  }
  if (payee.isNotEmpty) {
    return payee;
  }
  return "Unknown";
}

  @override
  Widget build(BuildContext context) {
    final bool isTopup = direction == "topup";


    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // ================= ANIMATION =================
            SizedBox(
              height: 180,
              child: Lottie.asset(
                lottieFile,
                repeat: true,
                animate: true,
              ),
            ),

            const SizedBox(height: 8),

            // ================= STATUS =================
            Text(
              statusText,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),

            const SizedBox(height: 10),

            // ================= AMOUNT =================
            Text(
              "₹${amount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            // ================= STATUS TAG =================
            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),

            const SizedBox(height: 30),

       // ================= DETAILS =================
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

      // ---------- WALLET TOP-UP ----------
      if (isTopup) ...[
        _row("Type", "Wallet Top-Up"),
      ]

      // ---------- RECEIVED ----------
      else if (direction == "credit") ...[
  _row("From", displayName),
_row("From UPI / Mobile", payee.isNotEmpty ? payee : "Unknown"),
_row(
  "Type",
  payee.contains("@") ? "UPI" : "Wallet",
),

]
      // ---------- PAID ----------
      else ...[
        _row("To", displayName),
_row("To UPI / Mobile", payee.isNotEmpty ? payee : "-"),
_row(
  "Type",
  payee.contains("@") ? "UPI" : "Wallet",
),

      ],

      _row("Time", formattedTime),
    ],
  ),
),


            const Spacer(),

            // ================= ACTIONS =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                    ),
                  ),
                  const SizedBox(width: 12),
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

            // ================= DONE =================
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);

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

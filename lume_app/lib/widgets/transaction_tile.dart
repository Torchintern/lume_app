import 'package:flutter/material.dart';
import '../screens/payment_result_screen.dart';

class TransactionTile extends StatelessWidget {
  final dynamic txn;

  const TransactionTile({
    super.key,
    required this.txn,
  });

  @override
  Widget build(BuildContext context) {
    final String direction = txn["direction"]; // debit | credit | topup
    final bool isIncoming = direction == "credit";
    final bool isTopup = direction == "topup";

    Color amountColor;
    IconData icon;

    if (isTopup) {
      amountColor = Colors.blue;
      icon = Icons.account_balance_wallet;
    } else if (isIncoming) {
      amountColor = Colors.green;
      icon = Icons.arrow_downward;
    } else {
      amountColor = Colors.red;
      icon = Icons.arrow_upward;
    }

    Color statusColor;
    switch (txn["status"]) {
      case "success":
        statusColor = Colors.green;
        break;
      case "failed":
        statusColor = Colors.red;
        break;
      case "pending":
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentResultScreen(
              amount: (txn["amount"] as num).toDouble(),
              status: txn["status"],
              direction: txn["direction"],
              payeeName: txn["counterparty_name"] ?? "-",
              payee: txn["counterparty_upi"] ?? "-",
              isWallet: txn["payment_type"] == "Wallet",
              createdAt: txn["created_at"],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: amountColor),
            const SizedBox(width: 12),

            // ================= LEFT SIDE =================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 TITLE
                  Text(
                    txn["title"] ?? "Transaction",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 🔹 DATE (EXACT FORMAT)
                  Text(
                    _formatDate(txn["created_at"]),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // ================= RIGHT SIDE =================
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _amountText(txn),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  txn["status_text"] ?? "",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  String _amountText(dynamic txn) {
    final double amount = double.parse(txn["amount"].toString());
    final String direction = txn["direction"];

    if (direction == "credit" || direction == "topup") {
      return "+₹${amount.toStringAsFixed(2)}";
    }
    return "-₹${amount.toStringAsFixed(2)}";
  }

  String _formatDate(String? raw) {
    if (raw == null) return "";
    final d = DateTime.tryParse(raw);
    if (d == null) return "";

    return "${d.day.toString().padLeft(2, '0')} "
        "${_month(d.month)} ${d.year}, "
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
}

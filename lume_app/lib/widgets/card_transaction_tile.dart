import 'package:flutter/material.dart';

class CardTransactionTile extends StatelessWidget {
  final dynamic txn;

  const CardTransactionTile({
    super.key,
    required this.txn,
  });

  @override
  Widget build(BuildContext context) {
    // ===== SAFE EXTRACTION =====
    final double amount =
        double.tryParse(txn["amount"]?.toString() ?? "0") ?? 0.0;

    final String merchant =
        (txn["merchant_name"] ?? "Unknown").toString();

    final String status =
        (txn["status"] ?? "pending").toString();

    final String txnType =
        (txn["txn_type"] ?? "").toString();

    final String createdAt =
        txn["created_at"]?.toString() ?? "";

    // ===== UI LOGIC =====
    Color amountColor = Colors.red;
    IconData icon = Icons.credit_card;
    if (txnType != "spend") {
      return const SizedBox.shrink();
    }

    if (status == "failed") {
      amountColor = Colors.grey;
    }


    return Container(
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
        children: [
          Icon(icon, color: amountColor),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return "";
    final d = DateTime.tryParse(raw);
    if (d == null) return "";

    return "${d.day.toString().padLeft(2, '0')} "
        "${_month(d.month)} ${d.year}";
  }

  String _month(int m) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[m - 1];
  }
}

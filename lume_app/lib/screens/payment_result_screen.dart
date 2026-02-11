import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/split_people_sheet.dart';


class PaymentResultScreen extends StatelessWidget {
  final double amount;
  final String status; // success | failed | pending
  final String payeeName; // NAME from backend / runtime
  final String payee; // UPI ID / Mobile
  final bool isWallet;
  final int regId;
  final String direction;
  final String? createdAt;
  final String fullName;
  final String mobile;
  final String? upiId;
  final String walletStatus;
  final int aadhaarVerified;
  final int panVerified;
  final String? customTitle;
  final String? note;
  final String? paymentMethod;
  final DateTime? txnTime;
  final int? earnedPoints;

  const PaymentResultScreen({
  super.key,
  required this.amount,
  required this.status,
  required this.payeeName,
  required this.payee,
  required this.isWallet,
  required this.regId,
  required this.fullName,
  required this.mobile,
  required this.upiId,
  required this.walletStatus,
  required this.aadhaarVerified,
  required this.panVerified,
  this.direction = "debit",
  this.createdAt,
  this.customTitle,
  this.note,
  this.paymentMethod,
  this.txnTime,
  this.earnedPoints,



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
    if (customTitle != null) return customTitle!;

    if (status == "pending") return "Payment Pending";
    if (status == "failed") return "Payment Failed";

    if (direction == "credit") return "Payment Received";
    if (direction == "topup") return "Wallet Top-Up Successful";

    return "Payment Successful";
  }


  // ================= DATE FORMAT =================
  String get formattedTime {
  final DateTime d =
      txnTime ??
      DateTime.tryParse(createdAt ?? "") ??
      DateTime.now();

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
    paymentMethod ?? (_effectiveIsWallet ? "Wallet" : "UPI");

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
    direction == "debit" &&
    status == "success" &&
    fullName.isNotEmpty;


    return Scaffold(
  backgroundColor: const Color(0xFFF7F8FC),
  appBar: AppBar(
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.black,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.pop(context);
      },
    ),
  ),

  body: SafeArea(
     child: SingleChildScrollView(
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

            if (status == "success" &&
            earnedPoints != null &&
            earnedPoints! > 0) ...[
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/tier/points.png",
                  height: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "+$earnedPoints Tier Points Earned",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],


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

                    if (note != null && note!.isNotEmpty)
                      _row("Note", note!),

                    _row("To $_idLabel", payee.isNotEmpty ? payee : "-"),
                    _row("Payment Method", paymentTypeText),
                  ],
                  _row("Time", formattedTime),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                        onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (_) => SplitPeopleSheet(
                                totalAmount: amount,
                                creatorRegId: regId,

                                fullName: fullName,
                                mobile: mobile,
                                upiId: upiId,
                                walletStatus: walletStatus,
                                aadhaarVerified: aadhaarVerified,
                                panVerified: panVerified,

                                preSelectedUsers: isWallet
                                    ? [
                                        {
                                          "reg_id": null,
                                          "name": displayName,
                                          "identifier": payee,
                                          "profile_image": null,
                                        }
                                      ]
                                    : null,
                              ),
                            );
                          },
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

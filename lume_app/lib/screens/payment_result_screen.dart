import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/split_people_sheet.dart';
import '../widgets/cashback_dragger.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class PaymentResultScreen extends StatefulWidget {
  final double amount;
  final String status;
  final String payeeName;
  final String payee;
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
  final String? rewardToken;
  

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
    this.rewardToken,

  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  double? cashbackReceived;
  String? pendingRewardToken;
  String? revealedRewardType;
  bool rewardRevealed = false;
  String? revealedRewardValue;
  bool isClaiming = false;


  @override
  void initState() {
    super.initState();
    pendingRewardToken = widget.rewardToken;
  }


  // ================= LOTTIE =================
  String get lottieFile {
    switch (widget.status) {
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
    switch (widget.status) {
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
    if (widget.customTitle != null) return widget.customTitle!;

    if (widget.status == "pending") return "Payment Pending";
    if (widget.status == "failed") return "Payment Failed";

    if (widget.direction == "credit") return "Payment Received";
    if (widget.direction == "topup") return "Wallet Top-Up Successful";

    return "Payment Successful";
  }

  // ================= DATE FORMAT =================
  String get formattedTime {
    final DateTime d = widget.txnTime ??
        DateTime.tryParse(widget.createdAt ?? "") ??
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
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[m - 1];
  }

  // ================= DISPLAY NAME =================
  String get displayName {
    if (widget.payeeName.trim().isNotEmpty) {
      return widget.payeeName.trim();
    }
    return widget.payee.isNotEmpty ? widget.payee : "Unknown";
  }

  // ================= PAYMENT TYPE =================
  bool get _effectiveIsWallet =>
      widget.isWallet && !widget.payee.contains("@");

  String get paymentTypeText =>
      widget.paymentMethod ?? (_effectiveIsWallet ? "Wallet" : "UPI");

  String get _idLabel => _effectiveIsWallet ? "Mobile" : "UPI";

  // ================= SHARE =================
  void _sharePayment() {
    final String directionText =
        widget.direction == "credit" ? "Received from" : "Paid to";

    final String message = """
Lume Payment Receipt

Amount: ₹${widget.amount.toStringAsFixed(2)}
Status: $statusText
Payment Type: $paymentTypeText
$directionText: $displayName
Date: $formattedTime
""";

    Share.share(message.trim());
  }


  // ================= CASHBACK SHEET =================
void _openCashbackSheet() {

  showModalBottomSheet(
    context: context,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setSheetState) {

          Future<void> claim() async {

            if (pendingRewardToken == null || isClaiming) return;

            setSheetState(() => isClaiming = true);

            final res = await ApiService.revealReward(
              token: pendingRewardToken!,
            );

            if (res == null) {
              setSheetState(() => isClaiming = false);
              return;
            }

            final type = res["type"];
            final value = res["value"];

            setState(() {
              rewardRevealed = true;
              revealedRewardType = type;
              revealedRewardValue = value.toString();
              pendingRewardToken = null;

              if (type == "cashback") {
                cashbackReceived =
                    double.tryParse(value.toString()) ?? 0;
              }
            });

            setSheetState(() => isClaiming = false);

            final dashboard =
                context.findAncestorStateOfType<DashboardScreenState>();

            await dashboard?.refreshWalletNow();
            await dashboard?.refreshStudentState();
            await dashboard?.loadUnreadCount();
          }

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FC),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// ===== DRAG HANDLE =====
                Container(
                  height: 5,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 20),

                /// ===== TITLE =====
                const Text(
                  "Your Reward",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                /// ===== BEFORE CLAIM =====
                if (!rewardRevealed && pendingRewardToken != null) ...[
                  _rewardPlaceholderCard(),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isClaiming ? null : claim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C6EF5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isClaiming
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Reveal Reward",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ]

                /// ===== AFTER CLAIM =====
                else ...[
                  _rewardResultCard(),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C6EF5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Done"),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}
Widget _rewardPlaceholderCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.05),
          blurRadius: 12,
        ),
      ],
    ),
    child: Column(
      children: const [
        Icon(Icons.card_giftcard, size: 48, color: Color(0xFF4C6EF5)),
        SizedBox(height: 12),
        Text(
          "Tap Reveal to see your reward 🎁",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}


Widget _rewardResultCard() {

  final icon = revealedRewardType == "cashback"
      ? Icons.currency_rupee
      : revealedRewardType == "coupon"
          ? Icons.confirmation_number
          : Icons.card_giftcard;

  final title = revealedRewardType == "cashback"
      ? "Cashback Won"
      : revealedRewardType == "coupon"
          ? "Coupon Unlocked"
          : "Voucher Unlocked";

  final valueText = revealedRewardType == "cashback"
      ? "₹${cashbackReceived?.toStringAsFixed(2)}"
      : revealedRewardValue ?? "";

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.05),
          blurRadius: 12,
        ),
      ],
    ),
    child: Column(
      children: [

        Icon(icon, size: 48, color: const Color(0xFF4C6EF5)),

        const SizedBox(height: 14),

        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        if (valueText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4C6EF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              valueText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final bool isTopup = widget.direction == "topup";

    final bool showSplit = widget.direction == "debit" &&
        widget.status == "success" &&
        widget.fullName.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),

              SizedBox(
                height: 180,
                child: Lottie.asset(lottieFile),
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
                "₹${widget.amount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                widget.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),

              if (widget.status == "success" &&
                  widget.earnedPoints != null &&
                  widget.earnedPoints! > 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/tier/points.png", height: 20),
                      const SizedBox(width: 8),
                      Text(
                        "+${widget.earnedPoints} Tier Points Earned",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],

              /// Cashback Dragger
              if (widget.status == "success" &&
   (pendingRewardToken != null || cashbackReceived != null || revealedRewardType != null)) ...[
                const SizedBox(height: 16),
                CashbackDragger(
                  onOpen: _openCashbackSheet,
                  rewardAmount: cashbackReceived,
                  rewardType: revealedRewardType,
                ),
              ],

              const SizedBox(height: 30),

              /// DETAILS CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10)
                  ],
                ),
                child: Column(
                  children: [
                    if (isTopup) ...[
                      _row("Type", "Wallet Top-Up"),
                      _row("Payment Method", paymentTypeText),
                    ] else if (widget.direction == "credit") ...[
                      _row("From", displayName),
                      _row("From $_idLabel",
                          widget.payee.isNotEmpty ? widget.payee : "-"),
                      _row("Payment Method", paymentTypeText),
                    ] else ...[
                      _row("To", displayName),
                      if (widget.note != null && widget.note!.isNotEmpty)
                        _row("Note", widget.note!),
                      _row("To $_idLabel",
                          widget.payee.isNotEmpty ? widget.payee : "-"),
                      _row("Payment Method", paymentTypeText),
                    ],
                    _row("Time", formattedTime),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// SHARE + SPLIT
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
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (_) => SplitPeopleSheet(
                                totalAmount: widget.amount,
                                creatorRegId: widget.regId,
                                fullName: widget.fullName,
                                mobile: widget.mobile,
                                upiId: widget.upiId,
                                walletStatus: widget.walletStatus,
                                aadhaarVerified: widget.aadhaarVerified,
                                panVerified: widget.panVerified,
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

              /// DONE BUTTON
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C6EF5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child:
                        const Text("Done", style: TextStyle(fontSize: 18)),
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
          Text(k, style: const TextStyle(color: Colors.grey)),
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

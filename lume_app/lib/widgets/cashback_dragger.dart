import 'package:flutter/material.dart';

class CashbackDragger extends StatefulWidget {
  final VoidCallback? onOpen;
  final double? rewardAmount;
  final String? rewardType;

  const CashbackDragger({
  super.key,
  this.onOpen,
  this.rewardAmount,
  this.rewardType,
});


  @override
  State<CashbackDragger> createState() => _CashbackDraggerState();
}

class _CashbackDraggerState extends State<CashbackDragger> {
  double drag = 0;


  @override
  Widget build(BuildContext context) {
    final bool rewardReceived =
    widget.rewardAmount != null || widget.rewardType != null;

    return GestureDetector(
      onHorizontalDragUpdate: rewardReceived
          ? null
          : (d) {
              setState(() {
                drag += d.delta.dx;
                drag = drag.clamp(0, 120);
              });
            },
      onHorizontalDragEnd: rewardReceived
          ? null
          : (_) {
              if (drag > 80) {
                widget.onOpen?.call();
              }
              setState(() => drag = 0);
            },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E), // Soft Black (Not Deep Black)
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: rewardReceived
                ? const Color(0xFFFFD54F)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            /// Reward Coin / Icon
            Container(
              height: 52,
              width: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFD54F),
                    Color(0xFFFFA000),
                  ],
                ),
              ),
             child: Icon(
              rewardReceived
                  ? (widget.rewardType == "coupon"
                      ? Icons.confirmation_number
                      : widget.rewardType == "voucher"
                          ? Icons.card_giftcard
                          : Icons.check)
                  : Icons.card_giftcard,
                color: Colors.black,
              ),
            ),

            const SizedBox(width: 14),

            /// Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rewardReceived
                    ? (widget.rewardType == "coupon"
                        ? "Coupon Unlocked"
                        : widget.rewardType == "voucher"
                            ? "Voucher Unlocked"
                            : "Cashback Received")
                    : "Weeha!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rewardReceived
                    ? (widget.rewardType == "coupon"
                        ? "Coupon added to your rewards"
                        : widget.rewardType == "voucher"
                            ? "Voucher added to your rewards"
                            : "₹${widget.rewardAmount!.toStringAsFixed(2)} added to wallet")
                    : "A Surprise is waiting",

                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            /// Drag Capsule
            if (!rewardReceived)
              Container(
                height: 44,
                width: 120,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Stack(
                  children: [
                    /// Arrows
                    const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.chevron_right,
                              color: Colors.white54),
                          Icon(Icons.chevron_right,
                              color: Colors.white54),
                          Icon(Icons.chevron_right,
                              color: Colors.white54),
                        ],
                      ),
                    ),

                    /// Draggable Circle
                    Positioned(
                      left: drag,
                      top: 4,
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFD54F),
                              Color(0xFFFFA000),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

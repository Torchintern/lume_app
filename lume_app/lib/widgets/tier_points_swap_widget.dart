import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/tier_assets.dart';

class TierPointsSwapWidget extends StatefulWidget {
  final int rewardPoints;
  final String tier;

  const TierPointsSwapWidget({
    super.key,
    required this.rewardPoints,
    required this.tier,
  });

  @override
  State<TierPointsSwapWidget> createState() =>
      _TierPointsSwapWidgetState();
}

class _TierPointsSwapWidgetState
    extends State<TierPointsSwapWidget> {

  bool showRemaining = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        showRemaining = !showRemaining;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  int get remainingToNextTier {
    final p = widget.rewardPoints;

    if (p < 401) return 401 - p;
    if (p < 901) return 901 - p;
    if (p < 1501) return 1501 - p;
    return 0;
  }

  String get nextTier {
    final p = widget.rewardPoints;

    if (p < 401) return "gold";
    if (p < 901) return "platinum";
    if (p < 1501) return "diamond";
    return "diamond";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),

        child: showRemaining && remainingToNextTier > 0

            // ================= SWAP VIEW =================
            ? Row(
                key: const ValueKey("remaining"),
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// NEXT TIER BADGE (BIGGER)
                  Image.asset(
                    getTierAsset(nextTier),
                    height: 28,
                  ),

                  const SizedBox(width: 8),

                  /// REMAINING NUMBER
                  Text(
                    remainingToNextTier.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(width: 5),

                  /// POINTS ICON
                  Image.asset(
                    "assets/tier/points.png",
                    height: 20,
                  ),

                  const SizedBox(width: 6),

                  const Text(
                    "left",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )

            // ================= NORMAL VIEW =================
            : Row(
                key: const ValueKey("current"),
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// CURRENT POINTS NUMBER
                  Text(
                    widget.rewardPoints.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(width: 6),

                  /// POINTS ICON
                  Image.asset(
                    "assets/tier/points.png",
                    height: 22,
                  ),
                ],
              ),
      ),
    );
  }
}

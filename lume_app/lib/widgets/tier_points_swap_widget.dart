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
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),

        child: showRemaining && remainingToNextTier > 0
            ? Row(
                key: const ValueKey("remaining"),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    getTierAsset(nextTier),
                    height: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$remainingToNextTier pts left",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                key: const ValueKey("current"),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    getTierAsset(widget.tier),
                    height: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.rewardPoints} pts",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

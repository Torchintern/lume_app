import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/tier_assets.dart';

class TierPointsSwapWidget extends StatefulWidget {
  final int rewardPoints;
  final String tier;

  /// ===== REWARD MODE SUPPORT =====
  final String? rewardToken;
  final String? rewardType;
  final dynamic rewardValue;
  final Future<void> Function()? onDragComplete;
  final bool locked;

  const TierPointsSwapWidget({
    super.key,
    required this.rewardPoints,
    required this.tier,
    this.rewardToken,
    this.rewardType,
    this.rewardValue,
    this.onDragComplete,
    this.locked = false,
  });

  @override
  State<TierPointsSwapWidget> createState() =>
      _TierPointsSwapWidgetState();
}

class _TierPointsSwapWidgetState
    extends State<TierPointsSwapWidget> {

  bool showRemaining = false;
  Timer? timer;

  /// DRAG STATE
  double dragProgress = 0;
  bool completed = false;

  bool get isRewardMode => widget.tier == "reward";

  @override
  void initState() {
    super.initState();

    /// Only run timer for tier mode
    if (!isRewardMode) {
      timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        setState(() {
          showRemaining = !showRemaining;
        });
      });
    }
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

  /// ================= REWARD VIEW =================
  Widget buildRewardView() {

    final maxDrag = MediaQuery.of(context).size.width * 0.35;

    return Container(
      height: 90,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [

          /// TEXT
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.locked && !completed) ...[
                  const Text(
                    "MYSTERY REWARD",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Drag to reveal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]
                else ...[
                  Text(
                    widget.rewardType?.toUpperCase() ?? "REWARD",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (widget.rewardValue ?? "").toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          /// DRAG TRACK BACKGROUND
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: maxDrag,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          /// DRAG BUTTON
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(

              onHorizontalDragUpdate: (details) {
                if (completed || widget.locked == false) return;

                setState(() {
                  dragProgress += details.delta.dx;
                  dragProgress = dragProgress.clamp(0.0, maxDrag);
                });
              },

              onHorizontalDragEnd: (_) async {

                if (dragProgress >= maxDrag * 0.9 && !completed) {

                  setState(() {
                    completed = true;
                  });

                  if (widget.onDragComplete != null) {
                    await widget.onDragComplete!();
                  }

                  await Future.delayed(const Duration(milliseconds: 400));

                  if (mounted) {
                    setState(() {
                      dragProgress = 0;
                    });
                  }

                } else {
                  setState(() {
                    dragProgress = 0;
                  });
                }
              },

              child: Transform.translate(
                offset: Offset(dragProgress, 0),
                child: Container(
                  width: 72,
                  decoration: BoxDecoration(
                    color: completed
                        ? Colors.green
                        : const Color(0xFF4C6EF5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    completed
                        ? Icons.check
                        : Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= TIER VIEW =================
  Widget buildTierView() {
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

            /// REMAINING VIEW
            ? Row(
                key: const ValueKey("remaining"),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    getTierAsset(nextTier),
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    remainingToNextTier.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
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

            /// CURRENT VIEW
            : Row(
                key: const ValueKey("current"),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.rewardPoints.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    "assets/tier/points.png",
                    height: 22,
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isRewardMode) {
      return buildRewardView();
    }
    return buildTierView();
  }
}

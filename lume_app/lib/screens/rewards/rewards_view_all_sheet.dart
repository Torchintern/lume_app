import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/cashback_dragger.dart';
import '../dashboard_screen.dart';

class RewardsViewAllSheet extends StatefulWidget {
  final ScrollController scrollController;
  final int regId;

  const RewardsViewAllSheet({
    super.key,
    required this.scrollController,
    required this.regId,
  });

  @override
  State<RewardsViewAllSheet> createState() => _RewardsViewAllSheetState();
}

class _RewardsViewAllSheetState extends State<RewardsViewAllSheet> {

  List rewards = [];
  bool loading = true;

  /// token -> reveal data
  Map<String, Map<String, dynamic>> revealedRewards = {};

  @override
  void initState() {
    super.initState();
    loadRewards();
  }

  // ================= LOAD =================
  Future<void> loadRewards() async {
    try {
      final data = await ApiService.getPendingDragRewards(widget.regId);

      if (!mounted) return;

      setState(() {
        rewards = List.from(data);
        loading = false;
      });

    } catch (e) {
      print("Rewards load error = $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  // ================= REVEAL =================
  Future<void> revealReward(String token) async {

    /// prevent double reveal
    if (revealedRewards.containsKey(token)) return;

    final res = await ApiService.revealReward(
      token: token,
      regId: widget.regId,
    );

    if (res == null) return;

    /// ===== INSTANT UI UPDATE =====
    setState(() {
      revealedRewards[token] = Map<String, dynamic>.from(res);

      /// remove from pending immediately
      rewards.removeWhere((r) => r["reward_token"] == token);
    });

    /// ===== DASHBOARD SYNC =====
    final dashboard =
        context.findAncestorStateOfType<DashboardScreenState>();

    await dashboard?.refreshAllCounts();
    await dashboard?.loadUnrevealedRewardsCount();

    /// ===== FINAL BACKEND SYNC =====
    await loadRewards();
  }

  // ================= RESULT CARD =================
  Widget rewardResultCard(Map<String, dynamic> data) {

    final type = data["type"];
    final value = data["value"];

    final icon = type == "cashback"
        ? Icons.currency_rupee
        : type == "coupon"
            ? Icons.confirmation_number
            : Icons.card_giftcard;

    final title = type == "cashback"
        ? "Cashback Won"
        : type == "coupon"
            ? "Coupon Unlocked"
            : "Voucher Unlocked";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFF4C6EF5)),
          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            type == "cashback" ? "₹$value" : value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      children: [

        const Text(
          "My Rewards",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        if (rewards.isEmpty && revealedRewards.isEmpty)
          const Center(child: Text("No pending rewards")),

        /// ===== SHOW REVEALED FIRST =====
        ...revealedRewards.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: rewardResultCard(entry.value),
          );
        }),

        /// ===== THEN SHOW PENDING =====
        ...rewards.map((r) {

          final token = r["reward_token"];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CashbackDragger(
              onOpen: () => revealReward(token),
            ),
          );
        }),
      ],
    );
  }
}

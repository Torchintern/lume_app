import 'package:flutter/material.dart';
import '../widgets/lume_flip_card.dart';

class CardBenefitsScreen extends StatefulWidget {
  final String maskedNumber;

  const CardBenefitsScreen({
    super.key,
    required this.maskedNumber,
  });

  @override
  State<CardBenefitsScreen> createState() => _CardBenefitsScreenState();
}

class _CardBenefitsScreenState extends State<CardBenefitsScreen>
    with SingleTickerProviderStateMixin {
  int selectedTab = 0;

  Widget _pillTabs() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFE9ECF5),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        _tabButton("Features", 0),
        _tabButton("Fees & charges", 1),
      ],
    ),
  );
}

Widget _tabButton(String text, int index) {
  final bool active = selectedTab == index;

  return Expanded(
    child: GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4C6EF5) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF4C6EF5).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Card benefits"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Column(
        children: [
          /// ===== FLIP CARD =====
          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LumeVerticalFlipCard(),
          ),

          const SizedBox(height: 10),

          const Text(
            "Tap card to flip",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),




          const SizedBox(height: 16),

          /// ===== TAB CONTENT =====
          const SizedBox(height: 14),
          _pillTabs(),

          const SizedBox(height: 18),

          Expanded(
            child: selectedTab == 0
                ? _buildFeaturesTab()
                : _buildFeesTab(),
          ),

        ],
      ),
    );
  }

  /// ================= FEATURES TAB =================
  Widget _buildFeaturesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: const [

        _BenefitTile(
          icon: Icons.smartphone,
          title: "Transact digitally",
          subtitle: "Use your card virtually through the app",
        ),

        _BenefitTile(
          icon: Icons.security,
          title: "Enhanced security",
          subtitle: "Chip-enabled protection for safe transactions",
        ),

        _BenefitTile(
          icon: Icons.lock,
          title: "Instant lock control",
          subtitle: "Lock or unlock your card anytime",
        ),

        _BenefitTile(
          icon: Icons.notifications_active,
          title: "Real-time alerts",
          subtitle: "Get notified instantly for every transaction",
        ),
      ],
    );
  }

  /// ================= FEES TAB =================
  Widget _buildFeesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: const [

        _FeeTile(
          title: "Card issuance fee",
          value: "No Charge",
        ),

        _FeeTile(
          title: "Annual maintenance",
          value: "No Charge",
        ),

        _FeeTile(
          title: "Card replacement",
          value: "₹149",
        ),

        _FeeTile(
          title: "ATM withdrawal",
          value: "₹29 Per txn (3 free / month)",
        ),
      ],
    );
  }
}

/// ================= BENEFIT TILE =================
class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        )
      ],

      ),
      child: Row(
        children: [

          Container(
            height: 46,
            width: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFE8ECFF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(0xFF4C6EF5)),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// ================= FEE TILE =================
class _FeeTile extends StatelessWidget {
  final String title;
  final String value;

  const _FeeTile({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4C6EF5),
            ),
          ),
        ],
      ),
    );
  }
}

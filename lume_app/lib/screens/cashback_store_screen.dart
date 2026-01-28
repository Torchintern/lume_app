import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lume_app/screens/rewards/my_vouchers_screen.dart';
import 'package:lume_app/screens/rewards/brand_vouchers_screen.dart';

class CashbackStoreScreen extends StatefulWidget {
  const CashbackStoreScreen({super.key});

  @override
  State<CashbackStoreScreen> createState() => _CashbackStoreScreenState();
}

class _CashbackStoreScreenState extends State<CashbackStoreScreen> {
  final ScrollController _scrollController = ScrollController();
 final PageController _promoController =
    PageController(viewportFraction: 0.9, initialPage: 1000);

  bool _collapsed = false;
  int _currentPromo = 1000;
  Timer? _promoTimer;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.offset > 120 && !_collapsed) {
        setState(() => _collapsed = true);
      } else if (_scrollController.offset <= 120 && _collapsed) {
        setState(() => _collapsed = false);
      }
    });

    _promoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!_promoController.hasClients) return;

        _currentPromo++;

        _promoController.animateToPage(
          _currentPromo,
          duration: const Duration(milliseconds: 999),
          curve: Curves.easeInOut,
        );
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _promoController.dispose();
    _promoTimer?.cancel();
    super.dispose();
  }
  void _openHowItWorksSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 20),

            // Icon
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFE8ECFF),
              child: const Icon(
                Icons.card_giftcard,
                size: 34,
                color: Color(0xFF4C6EF5),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              "How it works",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            _HowStep(
              number: "1",
              text: "Buy vouchers from your favourite brands",
            ),

            const SizedBox(height: 14),

            _HowStep(
              number: "2",
              text: "Get instant cashback in your wallet",
            ),

            const SizedBox(height: 14),

            _HowStep(
              number: "3",
              text: "Redeem vouchers on brand apps or websites",
            ),

            const SizedBox(height: 28),

            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Center(
                  child: Text(
                    "Explore Vouchers",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ================= APP BAR =================
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFFF7F8FC),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: AnimatedOpacity(
                opacity: _collapsed ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Text(
                  "Cashback Store",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              actions: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _collapsed
                      ? IconButton(
                          key: const ValueKey("icon"),
                          icon: const Icon(
                            Icons.confirmation_number_outlined,
                            color: Color(0xFF4C6EF5),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyVouchersScreen(),
                              ),
                            );
                          },
                        )
                      : Padding(
                          key: const ValueKey("text"),
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyVouchersScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 6),
                                ],
                              ),
                              child: const Text(
                                "My Vouchers",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),

            // ================= HEADER TITLE =================
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    "Cashback Store",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C6EF5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _openHowItWorksSheet,
                    child: const Text(
                      "How does it work?",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ================= PROMO (AUTO SCROLL) =================
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: PageView.builder(
                controller: _promoController,
                itemBuilder: (context, index) {
                  final promos = [
                    const _PromoCard(
                      brand: "Zomato",
                      offer: "11.75% cashback",
                      bgColor: Color(0xFFFFEEF1),
                    ),
                    const _PromoCard(
                      brand: "Amazon",
                      offer: "12% cashback",
                      bgColor: Color(0xFFEFF4FF),
                    ),
                    const _PromoCard(
                      brand: "Steam",
                      offer: "15% cashback",
                      bgColor: Color(0xFFEFFAF6),
                    ),
                  ];
                  return promos[index % promos.length];
                },
              ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ================= STICKY SEARCH =================
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchHeaderDelegate(),
            ),

            // ================= STICKY CATEGORIES =================
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryHeaderDelegate(),
            ),

            // ================= TRENDING TITLE =================
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  "Trending now",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ================= TRENDING GRID =================
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate(
                  const [
                    _TrendingTile("Valorant", "1.2% back"),
                    _TrendingTile("Apple", "5% back"),
                    _TrendingTile("Play Store", "2.5% back"),
                    _TrendingTile("Game Pass", "25% back"),
                    _TrendingTile("Amazon", "12% back"),
                    _TrendingTile("McDonald's", "11% back"),
                    _TrendingTile("Westside", "9% back"),
                    _TrendingTile("AJIO", "4% back"),
                    _TrendingTile("Tata CLiQ", "5% back"),
                    _TrendingTile("Nykaa", "4% back"),
                    _TrendingTile("Zomato", "1.75% back"),
                    _TrendingTile("BookMyShow", "3% back"),
                    _TrendingTile("Steam", "15% back"),
                    _TrendingTile("PVR", "12% back"),
                    _TrendingTile("Domino's", "6% back"),
                  ],
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.9,
                ),
              ),
            ),

            // ================= VIEW ALL =================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 36),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BrandVouchersScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFFFC107),
                        width: 1.6,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "View All Vouchers",
                        style: TextStyle(
                          color: Color(0xFFFFC107),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= STICKY SEARCH =================
class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 70;
  @override
  double get maxExtent => 70;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF7F8FC),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 10),
            Text(
              "Search by brand or category",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_) => false;
}

// ================= STICKY CATEGORIES =================
class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 96;
  @override
  double get maxExtent => 96;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF7F8FC),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: const [
          _Category(Icons.grid_view, "View All"),
          _Category(Icons.shopping_bag, "Shopping"),
          _Category(Icons.sports_esports, "Gaming"),
          _Category(Icons.fastfood, "Food"),
          _Category(Icons.movie, "Movies"),
          _Category(Icons.spa, "Self-Care"),
          _Category(Icons.flight_takeoff, "Travel"),
          _Category(Icons.devices, "Electronics"),
          _Category(Icons.checkroom, "Fashion"),
          _Category(Icons.subscriptions, "Subscriptions"),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_) => false;
}

// ================= COMPONENTS =================
class _PromoCard extends StatelessWidget {
  final String brand;
  final String offer;
  final Color bgColor;

  const _PromoCard({
    required this.brand,
    required this.offer,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipPath(
        clipper: _TicketClipper(),
        child: Container(
          height: 120,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: bgColor,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              // ================= BRAND =================
              Text(
                brand.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF4C6EF5),
                  letterSpacing: 1,
                ),
              ),

              const Spacer(),

              // ================= OFFER =================
              Text(
                offer,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ====== Ticket design ================
class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double radius = 12;

    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height / 2 - radius);
    path.arcToPoint(
      Offset(size.width, size.height / 2 + radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height / 2 + radius);
    path.arcToPoint(
      Offset(0, size.height / 2 - radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class _Category extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Category(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (label == "View All") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BrandVouchersScreen(),
            ),
          );
        }
      },
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFE8ECFF),
              child: Icon(
                icon,
                color: const Color(0xFF4C6EF5),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _TrendingTile extends StatelessWidget {
  final String title;
  final String badge;

  const _TrendingTile(this.title, this.badge);

    Color get brandColor {
    switch (title) {
      case "Valorant":
        return const Color(0xFFB81E28);

      case "Apple":
        return const Color(0xFF0A2540);

      case "Play Store":
        return const Color(0xFF1E8E3E);

      case "Game Pass":
        return const Color(0xFF107C10);

      case "Amazon":
        return const Color(0xFFCC3A00);

      case "McDonald's":
        return const Color(0xFFFFBC0D);

      case "Westside":
        return const Color(0xFF1C1C1C);

      case "AJIO":
        return const Color(0xFFB0006D);

      case "Tata CLiQ":
        return const Color(0xFF6A1B9A);

      case "Nykaa":
        return const Color(0xFFE80071);

      case "Zomato":
        return const Color(0xFF7A1020);

      case "BookMyShow":
        return const Color(0xFFC62828);

      case "Steam":
        return const Color(0xFF171A21);

      case "PVR":
        return const Color(0xFF0033A0);

      case "Domino's":
        return const Color(0xFFFF9800);

      default:
        return const Color(0xFF4C6EF5);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          badge,
          style: const TextStyle(
            color: Color(0xFF1DB954),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _HowStep extends StatelessWidget {
  final String number;
  final String text;

  const _HowStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFC107),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

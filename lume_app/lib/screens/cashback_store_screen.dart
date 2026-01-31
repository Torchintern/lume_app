import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lume_app/screens/rewards/my_vouchers_screen.dart';
import 'package:lume_app/screens/rewards/brand_vouchers_screen.dart';
import 'category_cashback_screen.dart';
import '../data/cashback_data.dart';
import 'package:flutter/rendering.dart';
import '../widgets/brand_cashback_card.dart';

class PromoBrand {
  final String logo;
  final String offer;
  final Color bgColor;

  const PromoBrand({
    required this.logo,
    required this.offer,
    required this.bgColor,
  });
}

class CashbackStoreScreen extends StatefulWidget {
  const CashbackStoreScreen({super.key});

  @override
  State<CashbackStoreScreen> createState() => _CashbackStoreScreenState();
}

class _CashbackStoreScreenState extends State<CashbackStoreScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final PageController _promoController =
      PageController(viewportFraction: 0.9, initialPage: 1000);

  bool _isUserInteracting = false;
  bool _collapsed = false;
  int _currentPromo = 1000;
  Timer? _promoTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _startPromoTimer();
    WidgetsBinding.instance.addObserver(this);

    _scrollController.addListener(() {
      if (_scrollController.offset > 120 && !_collapsed) {
        setState(() => _collapsed = true);
      } else if (_scrollController.offset <= 120 && _collapsed) {
        setState(() => _collapsed = false);
      }
    });
  }

  void _startPromoTimer() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_promoController.hasClients || _isUserInteracting) return;
      _currentPromo++;
      _promoController.animateToPage(
        _currentPromo,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _promoController.dispose();
    _promoTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _promoTimer?.cancel();
    }
    if (state == AppLifecycleState.resumed) {
      _startPromoTimer();
    }
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
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const _HowStep(
                number: "1",
                text: "Buy vouchers from your favourite brands",
              ),
              const SizedBox(height: 14),
              const _HowStep(
                number: "2",
                text: "Get instant cashback in your wallet",
              ),
              const SizedBox(height: 14),
              const _HowStep(
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
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
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
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 6),
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

            SliverToBoxAdapter(
              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  if (notification.direction == ScrollDirection.idle) {
                    _isUserInteracting = false;
                  } else {
                    _isUserInteracting = true;
                  }
                  return false;
                },
                child: SizedBox(
                  height: 120,
                  child: PageView.builder(
                    key: const PageStorageKey('promo_carousel'),
                    controller: _promoController,
                    onPageChanged: (index) {
                      _currentPromo = index;
                    },
                    itemBuilder: (context, index) {
                      final promos = [
                      const PromoBrand(
                        logo: "assets/brands/zomato.png",
                        offer: "15% cashback",
                        bgColor: Color(0xFFFFEBEE),
                      ),
                      const PromoBrand(
                      logo: "assets/brands/amazon.png",
                      offer: "12% cashback",
                      bgColor: Color(0xFFF2F2F2), 
                    ),
                    const PromoBrand(
                      logo: "assets/brands/steam.png",
                      offer: "8% cashback",
                      bgColor: Color(0xFFE6F0FF), 
                    ),

                    ];
                    return _PromoCard(promo: promos[index % promos.length]);
                    },
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchHeaderDelegate(),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryHeaderDelegate(),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  "Trending now",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final brand = trendingBrands[index];
                    return BrandCashbackCard(brand: brand);
                  },
                  childCount: trendingBrands.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.9,
                ),
              ),
            ),
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF7F8FC),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cashbackCategories.length,
        itemBuilder: (context, index) {
          final category = cashbackCategories[index];
          return GestureDetector(
            onTap: () {
              if (category.title == "View All") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BrandVouchersScreen(),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryCashbackScreen(
                    title: category.title,
                    icon: category.icon,
                    brands: category.brands,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFE8ECFF),
                    child: Icon(
                      category.icon,
                      color: const Color(0xFF4C6EF5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(category.title,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_) => false;
}

// ================= COMPONENTS =================
class _PromoCard extends StatelessWidget {
  final PromoBrand promo;

  const _PromoCard({required this.promo});

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
            color: promo.bgColor,
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                promo.logo,
                height: 36,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              Text(
                promo.offer,
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


// ====== Ticket design ======
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

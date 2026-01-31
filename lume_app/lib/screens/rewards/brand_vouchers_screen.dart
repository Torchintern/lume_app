import 'package:flutter/material.dart';

class BrandVouchersScreen extends StatelessWidget {
  const BrandVouchersScreen({super.key});

  static final Map<String, List<_Voucher>> vouchers = {
    "A": [
      _Voucher("assets/brands/armani.png", "12% back"),
      _Voucher("assets/brands/amazon.png", "12% back"),
      _Voucher("assets/brands/apple.png", "15% back"),
    ],
    "B": [
      _Voucher("assets/brands/bookmyshow.png", "10% back"),
    ],
    "C": [
      _Voucher("assets/brands/croma.png", "6% back"),
    ],
    "F": [
      _Voucher("assets/brands/flipkart.png", "12% back"),
    ],
    "G": [
      _Voucher("assets/brands/goibibo.png", "8% back"),
    ],
    "J": [
      _Voucher("assets/brands/jackjones.png", "10% back"),
    ],
    "M": [
      _Voucher("assets/brands/mmt.png", "10% back"),
      _Voucher("assets/brands/mcdonalds.png", "18% back"),
    ],
    "N": [
      _Voucher("assets/brands/netflix.png", "5% back"),
    ],
    "P": [
      _Voucher("assets/brands/pvr.png", "15% back"),
      _Voucher("assets/brands/prime.png", "6% back"),
    ],
    "R": [
      _Voucher("assets/brands/reliance.png", "5% back"),
    ],
    "S": [
      _Voucher("assets/brands/steam.png", "8% back"),
      _Voucher("assets/brands/swiggy.png", "12% back"),
      _Voucher("assets/brands/spotify.png", "7% back"),
    ],
    "U": [
      _Voucher("assets/brands/urbancompany.png", "8% back"),
    ],
    "V": [
      _Voucher("assets/brands/valorant.png", "10% back"),
    ],
    "W": [
      _Voucher("assets/brands/wildcraft.png", "7% back"),
    ],
    "X": [
      _Voucher("assets/brands/gamepass.png", "8% back"),
    ],
    "Z": [
      _Voucher("assets/brands/zomato.png", "15% back"),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.search, color: Colors.black),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Column(
            children: const [
              Icon(
                Icons.card_giftcard,
                size: 56,
                color: Color(0xFF4C6EF5),
              ),
              SizedBox(height: 12),
              Text(
                "Brand Vouchers",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...vouchers.entries.map(
            (entry) => _VoucherSection(
              letter: entry.key,
              vouchers: entry.value,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= SECTION =================
class _VoucherSection extends StatelessWidget {
  final String letter;
  final List<_Voucher> vouchers;

  const _VoucherSection({
    required this.letter,
    required this.vouchers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          letter,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vouchers.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (_, i) {
            return _VoucherTile(voucher: vouchers[i]);
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ================= VOUCHER TILE =================
class _VoucherTile extends StatelessWidget {
  final _Voucher voucher;

  const _VoucherTile({required this.voucher});

 Color _backgroundFromLogo() {
  final logo = voucher.logo.toLowerCase();

  // Shopping
  if (logo.contains('amazon')) return Colors.white;
  if (logo.contains('flipkart')) return const Color(0xFF2874F0);
  if (logo.contains('armani')) return Colors.white;

  // Gaming
  if (logo.contains('valorant')) return const Color(0xFF1C1C1C);
  if (logo.contains('steam')) return const Color(0xFF171A21);
  if (logo.contains('gamepass')) return Colors.white;

  // Food
  if (logo.contains('zomato')) return const Color(0xFFE23744);
  if (logo.contains('swiggy')) return Colors.white;
  if (logo.contains('mcdonalds')) return const Color(0xFF000000);

  // Movies
  if (logo.contains('bookmyshow')) return const Color(0xFFC62828);
  if (logo.contains('pvr')) return Colors.black;

  // Self-care
  if (logo.contains('urbancompany')) return Colors.white;

  // Travel
  if (logo.contains('mmt')) return const Color(0xFFE53935);
  if (logo.contains('goibibo')) return Colors.white;

  // Electronics
  if (logo.contains('croma')) return Colors.white;
  if (logo.contains('reliance')) return Colors.white;
  if (logo.contains('apple')) return Colors.white;

  // Fashion
  if (logo.contains('jackjones')) return Colors.white;
  if (logo.contains('wildcraft')) return Colors.white;

  // Subscriptions
  if (logo.contains('netflix')) return Colors.black;
  if (logo.contains('spotify')) return const Color(0xFF1DB954);
  if (logo.contains('prime')) return Colors.white;

  // Default fallback
  return const Color(0xFF2C2C2C);
}



  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _backgroundFromLogo(),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
            child: Center(
              child: Image.asset(
                voucher.logo,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          voucher.offer,
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

// ================= DATA MODEL =================
class _Voucher {
  final String logo;
  final String offer;

  const _Voucher(this.logo, this.offer);
}

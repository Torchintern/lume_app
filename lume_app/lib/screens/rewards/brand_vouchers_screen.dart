import 'package:flutter/material.dart';

class BrandVouchersScreen extends StatelessWidget {
  const BrandVouchersScreen({super.key});

  static final Map<String, List<_Voucher>> vouchers = {
    "A": [
      _Voucher("AJIO", "4% back", Color(0xFFB0006D)),
      _Voucher("Amazon", "Win 1x", Color(0xFFCC3A00)),
      _Voucher("Amazon Prime", "12% back", Color(0xFF1F3C4F)),
      _Voucher("Apple", "5% back", Color(0xFF0A2540)),
      _Voucher("Armani Exchange", "12% back", Color(0xFF2D2A2A)),
      _Voucher("Arrow", "7% back", Color(0xFF2F4F6F)),
    ],
    "B": [
      _Voucher("BookMyShow", "3% back", Color(0xFFC62828)),
    ],
    "D": [
      _Voucher("Domino's", "6% back", Color(0xFFFF9800)),
    ],
    "Z": [
      _Voucher("Zomato", "1.75% back", Color(0xFF7A1020)),
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
          // ================= HEADER =================
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

          // ================= VOUCHERS =================
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: voucher.color,
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
                  voucher.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
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
  final String name;
  final String offer;
  final Color color;

  const _Voucher(this.name, this.offer, this.color);
}

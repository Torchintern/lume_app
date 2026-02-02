import 'package:flutter/material.dart';
import '../models/brand_cashback.dart';

class BrandCashbackCard extends StatelessWidget {
  final BrandCashback brand;

  const BrandCashbackCard({
    super.key,
    required this.brand,
  });

  // ================= BACKGROUND COLOR =================
  Color get brandColor {
    final logo = brand.logo.toLowerCase();

    // Shopping
    if (logo.contains('amazon')) return Colors.white;
    if (logo.contains('flipkart')) return const Color(0xFF2874F0);
    if (logo.contains('armani')) return Colors.white;

    // Gaming
    if (logo.contains('valorant')) return const Color(0xFF1C1C1C);
    if (logo.contains('steam')) return const Color(0xFF171A21);
    if (logo.contains('gamepass')) return Colors.white;
    if (logo.contains('apple')) return Colors.white;
    if (logo.contains('playstore')) return Colors.white;
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
    

    // Fashion
    if (logo.contains('jackjones')) return Colors.white;
    if (logo.contains('wildcraft')) return Colors.white;

    // Subscriptions
    if (logo.contains('netflix')) return Colors.black;
    if (logo.contains('spotify')) return const Color(0xFF1DB954);
    if (logo.contains('prime')) return Colors.white;
    return const Color(0xFF2C2C2C);
  }

  // ================= LOGO SIZE =================
  double get logoSize {
    final logo = brand.logo.toLowerCase();

    if (logo.contains('zomato')) return 50;
    if (logo.contains('swiggy')) return 50;
    if (logo.contains('urbancompany')) return 50;
    if (logo.contains('valorant')) return 52;
    if (logo.contains('reliance')) return 62;
    if (logo.contains('netflix')) return 20;
    if (logo.contains('croma')) return 20;
    if (logo.contains('prime')) return 20;
    if (logo.contains('jackjones')) return 15;
    return 32;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ================= BRAND CARD =================
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: brandColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Image.asset(
            brand.logo,
            height: logoSize,
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 6),

        // ================= CASHBACK =================
        Text(
          brand.cashback,
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

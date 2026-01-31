import 'package:flutter/material.dart';
import 'package:lume_app/models/brand_cashback.dart';
import 'package:lume_app/widgets/brand_cashback_card.dart';

class CategoryCashbackScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<BrandCashback> brands;

  const CategoryCashbackScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.brands,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FC),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 16),

          // ================= CATEGORY ICON =================
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE8ECFF),
            child: Icon(
              icon,
              size: 36,
              color: const Color(0xFF4C6EF5),
            ),
          ),

          const SizedBox(height: 12),

          // ================= TITLE =================
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4C6EF5),
            ),
          ),

          const SizedBox(height: 24),

          // ================= BRAND GRID =================
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.9,
              ),
              itemCount: brands.length,
              itemBuilder: (_, i) {
                return BrandCashbackCard(
                  brand: brands[i],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

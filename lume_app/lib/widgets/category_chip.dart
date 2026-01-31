import 'package:flutter/material.dart';
import '../models/cashback_category.dart';
import '../screens/category_cashback_screen.dart';

class CategoryChip extends StatelessWidget {
  final CashbackCategory category;

  const CategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
              backgroundColor: Colors.deepPurple.shade100,
              child: Icon(category.icon, color: Colors.deepPurple),
            ),
            const SizedBox(height: 6),
            Text(
              category.title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

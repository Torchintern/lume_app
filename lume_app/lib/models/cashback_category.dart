import 'package:flutter/material.dart';
import 'brand_cashback.dart';

class CashbackCategory {
  final String title;
  final IconData icon;
  final List<BrandCashback> brands;

  CashbackCategory({
    required this.title,
    required this.icon,
    required this.brands,
  });
}

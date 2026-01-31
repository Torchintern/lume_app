import 'package:flutter/material.dart';
import '../models/brand_cashback.dart';
import '../models/cashback_category.dart';

// category for vouchers
final List<CashbackCategory> cashbackCategories = [

  CashbackCategory(
    title: "View All",
    icon: Icons.grid_view,
    brands: [],
  ),

  CashbackCategory(
    title: "Shopping",
    icon: Icons.shopping_bag,
    brands: [
      BrandCashback(logo: "assets/brands/armani.png", cashback: "12% back"),
      BrandCashback(logo: "assets/brands/amazon.png", cashback: "12% back"),
      BrandCashback(logo: "assets/brands/flipkart.png", cashback: "12% back"),
    ],
  ),

  CashbackCategory(
    title: "Gaming",
    icon: Icons.sports_esports,
    brands: [
      BrandCashback(logo: "assets/brands/valorant.png", cashback: "10% back"),
      BrandCashback(logo: "assets/brands/steam.png", cashback: "8% back"),
      BrandCashback(logo: "assets/brands/gamepass.png", cashback: "8% back"),
    ],
  ),

  CashbackCategory(
    title: "Food",
    icon: Icons.fastfood,
    brands: [
      BrandCashback(logo: "assets/brands/zomato.png", cashback: "15% back"),
      BrandCashback(logo: "assets/brands/swiggy.png", cashback: "12% back"),
      BrandCashback(logo: "assets/brands/mcdonalds.png", cashback: "18% back"),
    ],
  ),

  CashbackCategory(
    title: "Movies",
    icon: Icons.movie,
    brands: [
      BrandCashback(logo: "assets/brands/bookmyshow.png", cashback: "10% back"),
      BrandCashback(logo: "assets/brands/pvr.png", cashback: "15% back"),
    ],
  ),

  CashbackCategory(
    title: "Self-Care",
    icon: Icons.spa,
    brands: [
      BrandCashback(logo: "assets/brands/urbancompany.png", cashback: "8% back"),
    ],
  ),

  CashbackCategory(
    title: "Travel",
    icon: Icons.flight_takeoff,
    brands: [
      BrandCashback(logo: "assets/brands/mmt.png", cashback: "10% back"),
      BrandCashback(logo: "assets/brands/goibibo.png", cashback: "8% back"),
    ],
  ),

  CashbackCategory(
    title: "Electronics",
    icon: Icons.devices,
    brands: [
      BrandCashback(logo: "assets/brands/croma.png", cashback: "6% back"),
      BrandCashback(logo: "assets/brands/reliance.png", cashback: "5% back"),
      BrandCashback(logo: "assets/brands/apple.png", cashback: "15% back"),
    ],
  ),

  CashbackCategory(
    title: "Fashion",
    icon: Icons.checkroom,
    brands: [
      BrandCashback(logo: "assets/brands/jackjones.png", cashback: "10% back"),
      BrandCashback(logo: "assets/brands/wildcraft.png", cashback: "7% back"),
    ],
  ),

  CashbackCategory(
    title: "Subscriptions",
    icon: Icons.subscriptions,
    brands: [
      BrandCashback(logo: "assets/brands/netflix.png", cashback: "5% back"),
      BrandCashback(logo: "assets/brands/spotify.png", cashback: "7% back"),
      BrandCashback(logo: "assets/brands/prime.png", cashback: "6% back"),
    ],
  ),
];
// Trending Tile
final List<BrandCashback> trendingBrands = [
  BrandCashback(
    logo: "assets/brands/amazon.png",
    cashback: "12% back",
  ),
  BrandCashback(
    logo: "assets/brands/zomato.png",
    cashback: "15% back",
  ),
  BrandCashback(
    logo: "assets/brands/steam.png",
    cashback: "8% back",
  ),
  BrandCashback(
    logo: "assets/brands/apple.png",
    cashback: "15% back",
  ),
  BrandCashback(
    logo: "assets/brands/bookmyshow.png",
    cashback: "10% back",
  ),
];

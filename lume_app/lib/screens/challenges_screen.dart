import 'package:flutter/material.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF8FA3AD),
        leading: const BackButton(color: Colors.white),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "Learn more",
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ===== TOP PLATINUM HEADER =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: const BoxDecoration(
              color: Color(0xFF8FA3AD),
            ),
            child: Column(
              children: const [
                Icon(Icons.diamond, color: Colors.white70, size: 60),
                SizedBox(height: 16),
                Text(
                  "Lume Platinum",
                  style: TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "until March 31, 2026",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          /// ===== POINTS SECTION =====
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Jan 1 - Mar 31",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "44 points",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// ===== PROGRESS BAR =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 44 / 200, // progress ratio
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("0"),
                    Row(
                      children: [
                        Icon(Icons.diamond, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text("200"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

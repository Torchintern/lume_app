import 'package:flutter/material.dart';

class LiquidKycProgressBar extends StatelessWidget {
  final double progress; // 0 → 1

  const LiquidKycProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),

        // ===== METALLIC BACKGROUND =====
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),

      child: Stack(
        children: [

          // ===== FILL =====
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),

                  // ===== BLUE LIQUID GRADIENT =====
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF90CAF9),   
                      Color(0xFF4C6EF5),   
                      Color(0xFF1A3ED8),  
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),

          // ===== GLOSS OVERLAY =====
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.55),
                      Colors.transparent,
                      Colors.white.withOpacity(0.15),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // ===== PERCENT TEXT =====
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

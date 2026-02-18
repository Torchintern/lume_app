import 'package:flutter/material.dart';

class LumeVerticalFlipCard extends StatefulWidget {
  const LumeVerticalFlipCard({super.key});

  @override
  State<LumeVerticalFlipCard> createState() => _LumeVerticalFlipCardState();
}

class _LumeVerticalFlipCardState extends State<LumeVerticalFlipCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isFront = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
    child: GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {

          final angle = _animation.value * 3.1416;
          final isBack = _animation.value > 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.1416),
                    child: _buildBackCard(),
                  )
                : _buildFrontCard(),
          );
        },
      ),
    ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      height: 340,
      width: 210,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4C6EF5),
            Color(0xFF7A95FF),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C6EF5).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          "LUME",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      height: 340,
      width: 210,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2A),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          Container(height: 50, color: Colors.black),
          const SizedBox(height: 24),
          Row(
            children: const [
              Spacer(),
              Padding(
                padding: EdgeInsets.only(right: 18),
                child: Text("***",
                    style: TextStyle(
                        color: Colors.black,
                        backgroundColor: Colors.white,
                        fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

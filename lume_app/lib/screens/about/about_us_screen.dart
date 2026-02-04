import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Us"),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Lume is built to make campus payments, rewards, and student "
          "finance seamless and secure.\n\n"
          "Our mission is to simplify everyday payments while rewarding "
          "students for smart spending.",
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Privacy Policy",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Text(
          "We respect your privacy.\n\n"
          "Your personal and financial information is securely stored "
          "and shared only with verified lending partners for loan processing.\n\n"
          "We do not sell, rent, or misuse your data under any circumstances.",
          style: TextStyle(height: 1.6),
        ),
      ),
    );
  }
}

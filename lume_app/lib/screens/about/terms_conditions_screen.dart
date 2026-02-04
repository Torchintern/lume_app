import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Text(
          "By using LUME, you agree to provide accurate information.\n\n"
          "Loan approvals, processing timelines, interest rates, and fees "
          "are subject to partner bank policies and eligibility criteria.\n\n"
          "LUME does not guarantee loan approval and is not responsible "
          "for decisions made by lending partners.",
          style: TextStyle(height: 1.6),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CashWonScreen extends StatefulWidget {
  final int regId;

  const CashWonScreen({super.key, required this.regId});

  @override
  State<CashWonScreen> createState() => _CashWonScreenState();
}

class _CashWonScreenState extends State<CashWonScreen> {
  bool loading = true;
  List<dynamic> cashList = [];
  double totalCashWon = 0;


  @override
  void initState() {
    super.initState();
    _loadCashWon();
  }

  Future<void> _loadCashWon() async {
    try {
      final data = await ApiService.getCashWon(widget.regId);

      double total = 0;
      for (final c in data) {
        total += double.tryParse(c["amount"].toString()) ?? 0;
      }

      if (!mounted) return;
      setState(() {
        cashList = data;
        totalCashWon = total;
        loading = false;
      });
    } catch (e) {
      loading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cash Won"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : cashList.isEmpty
              ? const Center(child: Text("No cashback earned yet"))
              : Column(
                  children: [
                    /// TOTAL CARD
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4C6EF5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Total Cashback Earned",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹${totalCashWon.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// LIST
                    Expanded(
                      child: ListView.builder(
                        itemCount: cashList.length,
                        itemBuilder: (_, i) {
                          final item = cashList[i];

                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE8ECFF),
                              child: Icon(Icons.currency_rupee),
                            ),
                            title: Text(
                              "₹${item["amount"] ?? 0} Cashback",
                            ),
                            subtitle: const Text("Cashback Reward"),
                            trailing: Text(
                              item["created_at"]?.toString().substring(0, 10) ?? "",
                              style: const TextStyle(fontSize: 12),
                            ),
                          );

                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

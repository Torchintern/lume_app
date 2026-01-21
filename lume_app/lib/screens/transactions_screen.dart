import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  final int regId;

  const TransactionsScreen({
    super.key,
    required this.regId,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> transactions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final data =
          await ApiService.getTransactionHistory(widget.regId);
      if (!mounted) return;
      setState(() {
        transactions = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        transactions = [];
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text("Transactions"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Wallet"),
            Tab(text: "Card"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ================= WALLET TRANSACTIONS =================
          loading
              ? const Center(child: CircularProgressIndicator())
              : transactions.isEmpty
                  ? const Center(
                      child: Text(
                        "No transactions found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (_, i) {
                        return TransactionTile(
                          txn: transactions[i],
                        );
                      },
                    ),

          // ================= CARD TRANSACTIONS =================
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.credit_card,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 12),
                Text(
                  "Coming Soon",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

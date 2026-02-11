import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:lume_app/screens/cashback_store_screen.dart';

class MyVouchersScreen extends StatefulWidget {
  const MyVouchersScreen({super.key});

  @override
  State<MyVouchersScreen> createState() => _MyVouchersScreenState();
}

class _MyVouchersScreenState extends State<MyVouchersScreen> {

  bool loading = true;
  List<dynamic> vouchers = [];

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      final regId = ApiService.currentUserRegId;

      if (regId == null) {
        setState(() => loading = false);
        return;
      }

      final data = await ApiService.getVouchers(regId);

      if (!mounted) return;

      setState(() {
        vouchers = data;
        loading = false;
      });

    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Vouchers",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : vouchers.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vouchers.length,
                  itemBuilder: (_, i) {

                    final v = vouchers[i];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Row(
                        children: [

                          const CircleAvatar(
                            backgroundColor: Color(0xFFE8ECFF),
                            child: Icon(
                              Icons.card_giftcard,
                              color: Color(0xFF4C6EF5),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v["voucher_code"] ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  v["status"] ?? "",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Text(
                            _formatDate(v["created_at"]),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return "";
    final dt = DateTime.tryParse(iso);
    if (dt == null) return "";
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}

// ================= EMPTY STATE =================
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: Color(0xFF4C6EF5),
            ),

            const SizedBox(height: 16),

            const Text(
              "No vouchers available",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Start earning vouchers by making payments",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 28),

            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CashbackStoreScreen(),
                  ),
                );
              },
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF4C6EF5),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Center(
                  child: Text(
                    "Get Vouchers",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

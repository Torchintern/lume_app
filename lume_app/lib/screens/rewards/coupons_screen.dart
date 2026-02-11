import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CouponsScreen extends StatefulWidget {
  final int regId;

  const CouponsScreen({super.key, required this.regId});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  bool loading = true;
  List<dynamic> coupons = [];

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    try {
      final data = await ApiService.getCoupons(widget.regId);

      if (!mounted) return;
      setState(() {
        coupons = data;
        loading = false;
      });
    } catch (e) {
      loading = false;
      setState(() {});
    }
  }

  Color _statusColor(String status) {
    if (status == "used") return Colors.grey;
    if (status == "expired") return Colors.red;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Coupons"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : coupons.isEmpty
              ? const Center(child: Text("No coupons available"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: coupons.length,
                  itemBuilder: (_, i) {
                    final c = coupons[i];
                    final status =
                        (c["status"] ?? "active").toString().toLowerCase();

                    return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c["coupon_code"] ?? "Coupon",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Transaction #${c["txn_id"] ?? ""}",
                          style: const TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Received: ${c["created_at"]?.toString().substring(0, 10) ?? "-"}",
                              style: const TextStyle(fontSize: 12),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  },
                ),
    );
  }
}

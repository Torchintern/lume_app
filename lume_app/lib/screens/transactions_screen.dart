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

  List<dynamic> allTransactions = [];
  List<dynamic> filteredTransactions = [];
  bool loading = true;
  // ================= SEARCH STATE =================
  final TextEditingController _walletSearchController =
      TextEditingController();
  final TextEditingController _cardSearchController =
      TextEditingController();

  String walletSearchQuery = "";
  String cardSearchQuery = "";

  // ================= FILTER STATE =================
  DateTime? fromMonth;
  DateTime? toMonth;
  String statusFilter = 'All';

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
        allTransactions = data;
        filteredTransactions = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        allTransactions = [];
        filteredTransactions = [];
        loading = false;
      });
    }
  }

  @override
  void dispose() {
  _tabController.dispose();
  _walletSearchController.dispose();
  _cardSearchController.dispose();
  super.dispose();
  }

  // ================= SORT + GROUP =================
  Map<String, List<dynamic>> _groupByMonthSorted(
      List<dynamic> txns) {
    final List<dynamic> sorted = List.from(txns);

    sorted.sort((a, b) {
      final da = DateTime.parse(a["created_at"]);
      final db = DateTime.parse(b["created_at"]);
      return db.compareTo(da);
    });

    final Map<String, List<dynamic>> grouped = {};

    for (var t in sorted) {
      final date = DateTime.parse(t["created_at"]);
      final key = "${_monthName(date.month)}, ${date.year}";
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(t);
    }

    return grouped;
  }

  String _monthName(int m) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[m - 1];
  }

  // ================= FILTER LOGIC =================
 void _applyFilters({bool isWallet = true}) {
  List<dynamic> temp = List.from(allTransactions);

  // ===== DATE FILTER (DAY LEVEL) =====
  if (fromMonth != null && toMonth != null) {
    final startDate = DateTime(
      fromMonth!.year,
      fromMonth!.month,
      fromMonth!.day,
    );

    final endDate = DateTime(
      toMonth!.year,
      toMonth!.month,
      toMonth!.day,
      23,
      59,
      59,
    );

    temp = temp.where((t) {
      final d = DateTime.parse(t["created_at"]);
      return !d.isBefore(startDate) && !d.isAfter(endDate);
    }).toList();
  }

  // ===== STATUS FILTER =====
  if (statusFilter != 'All') {
    temp = temp.where((t) =>
        t["status"].toString().toLowerCase() ==
        statusFilter.toLowerCase()).toList();
  }

  // ===== SEARCH FILTER =====
  final q = (isWallet ? walletSearchQuery : cardSearchQuery)
      .toLowerCase();

  if (q.isNotEmpty) {
    temp = temp.where((t) {
      return t.values.any(
        (v) => v.toString().toLowerCase().contains(q),
      );
    }).toList();
  }

  setState(() {
    filteredTransactions = temp;
  });
}


  // ================= FILTER HEADER (UPDATED) =================
  Widget _filterHeader() {
    final String timeLabel =
      (fromMonth != null && toMonth != null)
          ? "${fromMonth!.day} ${_monthShort(fromMonth!.month)} ${fromMonth!.year} - "
            "${toMonth!.day} ${_monthShort(toMonth!.month)} ${toMonth!.year}"
          : "Time";

    final String statusLabel =
        statusFilter == 'All' ? "Status" : _capitalize(statusFilter);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterChip(timeLabel, _openTimeSheet,
              isActive: fromMonth != null),
          const SizedBox(width: 12),
          _filterChip(statusLabel, _openStatusSheet,
              isActive: statusFilter != 'All'),
        ],
      ),
    );
  }
  Widget _searchBar({
  required TextEditingController controller,
  required ValueChanged<String> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Search by amount, reference, status...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

  Widget _filterChip(String label, VoidCallback onTap,
      {bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey.shade400,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.blue : Colors.black,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
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
          Column(
          children: [
            _filterHeader(),
            _searchBar(
              controller: _walletSearchController,
              onChanged: (v) {
                walletSearchQuery = v;
                _applyFilters(isWallet: true);
              },
            ),
            Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTransactions.isEmpty
                        ? const Center(
                            child: Text(
                              "No transactions found",
                              style:
                                  TextStyle(color: Colors.grey),
                            ),
                          )
                        : _buildTransactionList(),
              ),
            ],
          ),
          Column(
          children: [
            _filterHeader(),
            _searchBar(
              controller: _cardSearchController,
              onChanged: (v) {
                cardSearchQuery = v;
                _applyFilters(isWallet: false);
              },
            ),
            const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.credit_card,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        "Coming Soon",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TRANSACTION LIST =================
  Widget _buildTransactionList() {
    final grouped =
        _groupByMonthSorted(filteredTransactions);

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ...entry.value.map(
              (txn) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                child: TransactionTile(txn: txn),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ================= TIME BOTTOM SHEET =================
  void _openTimeSheet() {
    DateTime tempFrom = fromMonth ?? DateTime.now();
    DateTime tempTo = toMonth ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select date range",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _rangeButton(
                    "From",
                    "${_monthShort(tempFrom.month)}, ${tempFrom.year}",
                    () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempFrom,
                        firstDate: DateTime(2018),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModal(() => tempFrom = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _rangeButton(
                    "To",
                    "${_monthShort(tempTo.month)}, ${tempTo.year}",
                    () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempTo,
                        firstDate: DateTime(2018),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModal(() => tempTo = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  _applyButton(() {
                    setState(() {
                      fromMonth = tempFrom;
                      toMonth = tempTo;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _rangeButton(
      String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Text("$label: $value"),
      ),
    );
  }

  // ================= STATUS BOTTOM SHEET =================
  void _openStatusSheet() {
    String tempStatus = statusFilter;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Payment Status",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  ...["success", "pending", "failed"].map(
                    (s) => ListTile(
                      title: Text(_capitalize(s)),
                      trailing: Radio<String>(
                        value: s,
                        groupValue: tempStatus,
                        onChanged: (v) =>
                            setModal(() => tempStatus = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _applyButton(() {
                    setState(() => statusFilter = tempStatus);
                    _applyFilters();
                    Navigator.pop(context);
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _applyButton(VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: onTap,
        child: const Text(
          "Apply",
          style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _monthShort(int m) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[m - 1];
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

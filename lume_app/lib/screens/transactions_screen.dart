import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/card_transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  final int regId;
  final String initialTab;  

  const TransactionsScreen({
    super.key,
    required this.regId,
    this.initialTab = "wallet",  
  });


  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> filteredTransactions = [];
  List<dynamic> walletTransactions = [];
  List<dynamic> cardTransactions = [];

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
  _tabController.addListener(() {
      if (mounted) setState(() {});
    });


  if (widget.initialTab == "card") {
    _tabController.index = 1;
    _loadCardTransactions();
  } else {
    _tabController.index = 0;
    _loadWalletTransactions();
  }

 _tabController.addListener(() {
  if (_tabController.index != _tabController.previousIndex) {

    // Reset filters when switching
    fromMonth = null;
    toMonth = null;
    statusFilter = "All";

    _walletSearchController.clear();
    _cardSearchController.clear();

    walletSearchQuery = "";
    cardSearchQuery = "";

    if (_tabController.index == 0) {
      _loadWalletTransactions();
    } else {
      _loadCardTransactions();
    }
  }
});

}



Future<void> _loadWalletTransactions() async {
  setState(() => loading = true);

  try {
    final data =
        await ApiService.getTransactionHistory(widget.regId);

    if (!mounted) return;

    setState(() {
      walletTransactions = data;
      filteredTransactions = data;
      loading = false;
    });

  } catch (_) {
    if (!mounted) return;

    setState(() {
      walletTransactions = [];
      filteredTransactions = [];
      loading = false;
    });
  }
}

Future<void> _loadCardTransactions() async {
  setState(() => loading = true);

  try {
    final data =
        await ApiService.getCardTransactions(widget.regId);

    if (!mounted) return;

    setState(() {
      cardTransactions = data;
      filteredTransactions = data;
      loading = false;
    });

  } catch (_) {
    if (!mounted) return;

    setState(() {
      cardTransactions = [];
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
List<dynamic> temp = List.from(
      isWallet ? walletTransactions : cardTransactions
    );

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
    borderRadius: BorderRadius.circular(22),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFE8ECFF)   // active bg
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? const Color(0xFF4C6EF5)
                  : Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: isActive
                ? const Color(0xFF4C6EF5)
                : Colors.black54,
          ),
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
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),

      body: Column(
   children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            height: 46,
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: EdgeInsets.zero,
              indicator: BoxDecoration(
                color: const Color(0xFF4C6EF5),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(child: Center(child: Text("Wallet"))),
                Tab(child: Center(child: Text("Card"))),
              ],
            ),
          ),
        ),
      ),
    ),

    Expanded(
      child: TabBarView(
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

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTransactions.isEmpty
                      ? const Center(
                          child: Text(
                            "No transactions Found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : _buildTransactionList(),
            ),

          ],
        )

        ],
      ),
    ),
   ]
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _tabController.index == 1
                  ? CardTransactionTile(
                      txn: txn,
                    )
                  : TransactionTile(
                      txn: txn,
                      regId: widget.regId,
                    ),
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
                  Row(
                  children: [

                    /// CLEAR BUTTON
                    Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        setState(() {
                          fromMonth = null;
                          toMonth = null;
                        });

                        _applyFilters(isWallet: _tabController.index == 0);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Clear",
                          style: TextStyle(
                            color: Color(0xFF4C6EF5),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),


                    const SizedBox(width: 12),

                    /// APPLY BUTTON
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            fromMonth = tempFrom;
                            toMonth = tempTo;
                          });

                          _applyFilters(
                            isWallet: _tabController.index == 0,
                          );

                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Apply",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

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
                  Row(
                  children: [

                    /// CLEAR BUTTON
                    Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        setState(() {
                          fromMonth = null;
                          toMonth = null;
                        });

                        _applyFilters(isWallet: _tabController.index == 0);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Clear",
                          style: TextStyle(
                            color: Color(0xFF4C6EF5),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),


                    const SizedBox(width: 12),

                    /// APPLY BUTTON
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            statusFilter = tempStatus;
                          });

                          _applyFilters(
                            isWallet: _tabController.index == 0,
                          );

                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Apply",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                ],
              ),
            );
          },
        );
      },
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

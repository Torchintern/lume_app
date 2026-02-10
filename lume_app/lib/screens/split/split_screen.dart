import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '/widgets/dashboard_status_dialog.dart';
import '/screens/dashboard_screen.dart';

class SplitScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedUsers;
  final double totalAmount;
  final int creatorRegId;
  final String fullName;
  final String mobile;
  final String? upiId;
  final String walletStatus;
  final int aadhaarVerified;
  final int panVerified;


 const SplitScreen({
  super.key,
  required this.selectedUsers,
  required this.totalAmount,
  required this.creatorRegId,
  required this.fullName,
  required this.mobile,
  required this.upiId,
  required this.walletStatus,
  required this.aadhaarVerified,
  required this.panVerified,
});

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}


class _SplitScreenState extends State<SplitScreen>
    with SingleTickerProviderStateMixin {

  late TabController tabController;
  Set<int> selectedIndexes = {};

  late List<TextEditingController> amountControllers;
  late List<TextEditingController> percentControllers;
  late List<int> shares;
  late List<TextEditingController> shareControllers;
  static const double minSplitAmount = 1.0;

  bool loading = false;

  late TextEditingController amountController;
  final TextEditingController noteController = TextEditingController();

  
  double get totalAmount =>
      double.tryParse(amountController.text) ?? 0;
  
  String get splitType {
  switch (tabController.index) {
    case 0:
      return "equal";     
    case 1:
      return "exact";     
    case 2:
      return "shares";    
    case 3:
      return "percent"; 
    default:
      return "equal";
  }
}



  String formatAmount(String value) {
  if (value.isEmpty) return "";

  final num? parsed = num.tryParse(value);
  if (parsed == null) return value;

  // remove trailing .00
  if (parsed == parsed.toInt()) {
    return parsed.toInt().toString();
  }

  // remove trailing zero like 10.50 -> 10.5
  return parsed.toString();
}

 List<double> _roundAndFixTotal(
  List<double> values,
  double total,
) {
  List<double> rounded =
      values.map((e) => double.parse(e.toStringAsFixed(2))).toList();

  // ===== Ensure minimum ₹1 for selected users =====
  for (int i in selectedIndexes) {
    if (rounded[i] < minSplitAmount) {
      rounded[i] = minSplitAmount;
    }
  }

  // ===== Recalculate sum only for selected =====
  double sum = 0;
  for (int i = 0; i < rounded.length; i++) {
  if (selectedIndexes.contains(i)) {
    sum += rounded[i];
  } else {
    rounded[i] = 0;
  }
}


  double diff = double.parse((total - sum).toStringAsFixed(2));

  if (diff.abs() >= 0.01 && selectedIndexes.isNotEmpty) {

    // adjust highest value splitter
    int index = selectedIndexes.first;
    double maxVal = 0;

    for (int i in selectedIndexes) {
      if (rounded[i] > maxVal) {
        maxVal = rounded[i];
        index = i;
      }
    }

    rounded[index] =
        double.parse((rounded[index] + diff).toStringAsFixed(2));

    if (rounded[index] < minSplitAmount) {
      rounded[index] = minSplitAmount;
    }
  }

  return rounded;
}



double get enteredTotal {
  double sum = 0;

  for (var c in amountControllers) {
    sum += double.tryParse(c.text) ?? 0;
  }

  return sum;
}

double get remainingAmount {
  if (enteredTotal == 0) return totalAmount;

return double.parse(
  (totalAmount - enteredTotal).toStringAsFixed(2),
);

}

double get enteredPercentTotal {

  double sum = 0;

  for (int i in selectedIndexes) {
    sum += double.tryParse(percentControllers[i].text) ?? 0;
  }

  return sum;
}

double get remainingPercent {
  return double.parse(
    (100 - enteredPercentTotal).toStringAsFixed(2),
  );
}



 @override
void initState() {
  super.initState();

  tabController = TabController(length: 4, vsync: this);

  amountController = TextEditingController(
    text: widget.totalAmount.toStringAsFixed(2),
  );

  amountControllers = List.generate(
  widget.selectedUsers.length,
  (_) => TextEditingController(),
);

percentControllers = List.generate(
  widget.selectedUsers.length,
  (_) => TextEditingController(),
);


  shares = List.generate(
    widget.selectedUsers.length,
    (_) => 1,
  );
   tabController.addListener(() {

  if (tabController.indexIsChanging) return;

  if (tabController.index == 1) {
    _clearManualAmounts();
  } else {
    _recalcByTab();
  }
});


  shareControllers = List.generate(
  widget.selectedUsers.length,
  (i) => TextEditingController(text: shares[i].toString()),
);

  selectedIndexes =
      Set.from(List.generate(widget.selectedUsers.length, (i) => i));

  _recalcEvenSplit(); 
}


  // ================= SPLIT CALCULATIONS =================

 void _recalcEvenSplit() {
  if (totalAmount < selectedIndexes.length * minSplitAmount) {
  Future.microtask(() {
  showMessageDialog(
    title: "Amount Too Small",
    message: "Total too small for minimum ₹1 per splitter",
    isError: true,
  );
});

  return;
}

  if (selectedIndexes.isEmpty || totalAmount <= 0) return;

  final selectedCount = selectedIndexes.length;
  if (selectedCount == 0) return;

  double per = totalAmount / selectedCount;

  if (per < minSplitAmount) per = minSplitAmount;

  List<double> values = List.generate(
    amountControllers.length,
    (i) => selectedIndexes.contains(i) ? per : 0,
  );

  values = _roundAndFixTotal(values, totalAmount);

  for (int i = 0; i < values.length; i++) {
    amountControllers[i].text =
        values[i] == 0 ? "" : values[i] == values[i].toInt()
    ? values[i].toInt().toString()
    : values[i].toString()
;
  }

  setState(() {});
}


  void _clearManualAmounts() {
  for (int i = 0; i < amountControllers.length; i++) {
    if (selectedIndexes.contains(i)) {
      amountControllers[i].clear();
    }
  }
  setState(() {});
}



void toggleUser(int index) {
  setState(() {

    bool wasSelected = selectedIndexes.contains(index);

    if (wasSelected) {
      selectedIndexes.remove(index);
      amountControllers[index].clear();
      percentControllers[index].clear();
      shares[index] = 0;
    } else {
      selectedIndexes.add(index);
      shares[index] = 1;
    }

    _recalcByTab();
  });
}





void _recalcByTab() {

  if (tabController.index == 0) {
    _recalcEvenSplit();
  }

  if (tabController.index == 1) {
}


  if (tabController.index == 2) {
    _recalcShares();
  }

  if (tabController.index == 3) {
    _recalcPercent();
  }
}



 void _recalcShares() {

  int totalShares = 0;
  if (totalAmount < selectedIndexes.length * minSplitAmount) return;
  for (int i in selectedIndexes) {
    totalShares += shares[i];
  }

  if (totalShares == 0) return;

  List<double> values = List.generate(
    amountControllers.length,
    (i) {
      if (!selectedIndexes.contains(i)) return 0;
      return totalAmount * shares[i] / totalShares;
    },
  );



values = _roundAndFixTotal(values, totalAmount);



  for (int i = 0; i < values.length; i++) {
    amountControllers[i].text =
        values[i] == 0 ? "" : values[i] == values[i].toInt()
    ? values[i].toInt().toString()
    : values[i].toString()
;
  }
  for (int i = 0; i < shares.length; i++) {
  shareControllers[i].text = shares[i].toString();
}


  setState(() {});
}


void _recalcPercent() {

  double totalPercent = enteredPercentTotal;

  // ===== HARD LIMIT =====
  if (totalPercent > 100) {
    Future.microtask(() {
  showMessageDialog(
    title: "Invalid Percent",
    message: "Total percent cannot exceed 100%",
    isError: true,
  );
});

    return;
  }

  List<double> values = List.generate(
    amountControllers.length,
    (i) {
      if (!selectedIndexes.contains(i)) return 0;

      final percent =
          double.tryParse(percentControllers[i].text) ?? 0;

      return totalAmount * percent / 100;
    },
  );
  values = _roundAndFixTotal(values, totalAmount);

  for (int i = 0; i < values.length; i++) {
    amountControllers[i].text =
        values[i] == 0 ? "" : formatAmount(values[i].toString());
  }

  setState(() {});
}


List<double> normalizeAmounts(List<double> amounts, double total) {
  double sum = amounts.fold(0, (a, b) => a + b);

  double diff = total - sum;

  if (diff.abs() > 0.001) {
    int maxIndex = 0;

    for (int i = 1; i < amounts.length; i++) {
      if (amounts[i] > amounts[maxIndex]) {
        maxIndex = i;
      }
    }

    amounts[maxIndex] += diff;
  }

  return amounts
      .map((e) => double.parse(e.toStringAsFixed(2)))
      .toList();
}



  // ================= API =================

  Future createSplit() async {
    try {
      setState(() => loading = true);
      // ===== CREATOR STATUS CHECK =====
      if (widget.aadhaarVerified != 1) {
        await showMessageDialog(
          title: "KYC Required",
          message: "Complete Aadhaar verification before creating split",
          isError: true,
        );
        setState(() => loading = false);
        return;
      }

      if (widget.walletStatus != "active") {
        await showMessageDialog(
          title: "Wallet Inactive",
          message: "Activate wallet before creating split",
          isError: true,
        );
        setState(() => loading = false);
        return;
      }

      if (tabController.index == 1) {

  for (int i in selectedIndexes) {

    double val =
        double.tryParse(amountControllers[i].text) ?? 0;

    if (val < minSplitAmount) {

      await showMessageDialog(
  title: "Invalid Split",
  message: "Each splitter must have at least ₹1",
  isError: true,
);


      setState(() => loading = false);
      return;
    }
  }

  if (remainingAmount.abs() >= 0.01) {
    await showMessageDialog(
  title: "Amount Mismatch",
  message: "Total must match split amount",
  isError: true,
);


    setState(() => loading = false);
    return;
  }
}

// ===== GLOBAL MIN ₹1 VALIDATION =====
for (int i in selectedIndexes) {

  double val =
      double.tryParse(amountControllers[i].text) ?? 0;

  if (val < minSplitAmount) {

   await showMessageDialog(
  title: "Invalid Split",
  message: "Each splitter must have at least ₹1",
  isError: true,
);


    setState(() => loading = false);
    return;
  }
}

  final List<int> regIds = [];
final List<double> rawAmounts = [];

for (int i = 0; i < widget.selectedUsers.length; i++) {
  if (selectedIndexes.contains(i)) {
    final id = widget.selectedUsers[i]["reg_id"];

    if (id == null) {
      throw Exception("User reg_id null at index $i");
    }

    regIds.add(int.parse(id.toString()));
    rawAmounts.add(
      double.tryParse(amountControllers[i].text) ?? 0,
    );
  }
}

final amounts = normalizeAmounts(rawAmounts, totalAmount);




  await ApiService.createSplit(
  creatorRegId: widget.creatorRegId,
  memberRegIds: regIds,
  totalAmount: totalAmount,
  note: noteController.text,
  individualAmounts: amounts,
  splitType: splitType,
);


      if (!mounted) return;

     await showDialog(
  context: context,
  builder: (_) => const DashboardStatusDialog(
    type: StatusDialogType.success,
    title: "Split Created",
    message: "Split request sent successfully",
  ),
);
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (_) => DashboardScreen(
      regId: widget.creatorRegId,
      fullName: "",       
      mobile: "",        
      upiId: null,
      walletStatus: "active",
      aadhaarVerified: 1,
      panVerified: 1,
      initialTab: "pay",
    ),
  ),
  (route) => false,
);

    }  catch (e) {
  print("CREATE SPLIT ERROR: $e");

  if (mounted) {
    await showMessageDialog(
      title: "Split Failed",
      message: "Unable to create split. Please try again.",
      isError: true,
    );
  }
}

 finally {
      if (mounted) setState(() => loading = false);
    }
  }

Future<void> showMessageDialog({
  required String title,
  required String message,
  bool isError = false,
}) async {
  if (!mounted) return;

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FC),
        foregroundColor: Colors.black,
        title: const Text("Split Payment"),
      ),

      body: Column(
        children: [
          // ===== MEMBER STATUS WARNING =====
          if (widget.selectedUsers.any((u) =>
              u["aadhaar_verified"] == 0 ||
              u["wallet_active"] == 0))
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Some members may not be able to pay (KYC / Wallet issue)",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),


          // ===== AMOUNT =====
          const SizedBox(height: 10),

          const Text(
            "Enter amount to split",
            style: TextStyle(color: Colors.grey),
          ),

          SizedBox(
            width: 180,
            child: TextField(
              controller: amountController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixText: "₹ ",
              ),
  onChanged: (_) {
  if (tabController.index == 0) {
    _recalcEvenSplit();
  }

  if (tabController.index == 2) {
    _recalcShares();
  }

  if (tabController.index == 3) {
    _recalcPercent();
  }
},


            ),
          ),

          // ===== NOTE =====
          TextField(
            controller: noteController,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: "What's this for?",
              border: InputBorder.none,
            ),
          ),

          const SizedBox(height: 6),

          if (tabController.index == 3)
  _buildPercentRemainingIndicator()
else
  _buildRemainingIndicator(),


          const SizedBox(height: 10),

          // ===== TABS =====
          TabBar(
            controller: tabController,
            labelColor: const Color(0xFF4C6EF5),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.people)),
              Tab(text: "123"),
              Tab(icon: Icon(Icons.pie_chart_outline)),
              Tab(text: "%"),
            ],
          ),

          const SizedBox(height: 10),

          // ===== LIST =====
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _buildList(mode: "even"),
                _buildList(mode: "amount"),
                _buildList(mode: "shares"),
                _buildList(mode: "percent"),
              ],
            ),
          ),

          // ===== BUTTON =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C6EF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
         onPressed: loading ||
(
  tabController.index == 3
      ? remainingPercent.abs() >= 0.01
      : remainingAmount.abs() >= 0.01
)
    ? null
    : createSplit,

                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Send Request",
                        style: TextStyle(fontSize: 17),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }


 Widget _buildRemainingIndicator() {

  if (remainingAmount.abs() < 0.01) {
    return const Text(
      "Split Complete ✓",
      style: TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  if (remainingAmount > 0) {
    return Text(
      "₹${remainingAmount.toStringAsFixed(2)} left to split",
      style: const TextStyle(
        color: Colors.orange,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  return Text(
    "Exceeded by ₹${remainingAmount.abs().toStringAsFixed(2)}",
    style: const TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.w600,
    ),
  );
}


  // ================= LIST BUILDER =================

  Widget _buildList({required String mode}) {

    return ListView.builder(
      itemCount: widget.selectedUsers.length,
      itemBuilder: (_, i) {

        final user = widget.selectedUsers[i];

        return ListTile(
  dense: true,
  leading: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
     Checkbox(
  value: selectedIndexes.contains(i),
  onChanged: (_) => toggleUser(i),
),


     CircleAvatar(
  radius: 22,
  backgroundColor: Colors.grey.shade200,
  backgroundImage: (user["profile_image"] != null &&
          user["profile_image"].toString().isNotEmpty)
      ? NetworkImage(user["profile_image"])
      : null,
  child: (user["profile_image"] == null ||
          user["profile_image"].toString().isEmpty)
      ? Text(
          (user["name"] ?? "U")[0].toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        )
      : null,
),

    ],
  ),
  title: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
  user["name"] ?? "",
  style: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
  ),
),


    if (mode == "shares" || mode == "percent")
  if (mode == "shares" ||
      (mode == "percent" &&
          percentControllers[i].text.isNotEmpty))
    Text(
      amountControllers[i].text.isEmpty
          ? "₹ 0"
          : "₹ ${formatAmount(amountControllers[i].text)}",
      style: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
      ),
    ),

  ],
),

  trailing: _buildTrailing(mode, i),
);

      },
    );
  }





  Widget _buildTrailing(String mode, int i) {

  if (mode == "even") {
    return Text(
      "₹ ${formatAmount(amountControllers[i].text.isEmpty ? "0" : amountControllers[i].text)}",
      style: const TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 18,
),
    );
  }

 if (mode == "amount") {
  return SizedBox(
    width: 90,
    child: TextField(
  controller: amountControllers[i],
  enabled: selectedIndexes.contains(i),
  keyboardType: TextInputType.number,
  textAlign: TextAlign.end,

  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  ),

  decoration: InputDecoration(
    prefixText: "₹ ",
    hintText: "0",

    border: amountControllers[i].text.isEmpty
        ? const UnderlineInputBorder()
        : InputBorder.none,

    enabledBorder: amountControllers[i].text.isEmpty
        ? const UnderlineInputBorder()
        : InputBorder.none,

    focusedBorder: amountControllers[i].text.isEmpty
        ? const UnderlineInputBorder()
        : InputBorder.none,
  ),

  onChanged: (_) {
  Future.microtask(() {
    if (mounted) setState(() {});
  });
},
),
  );
}


if (mode == "shares") {
  final enabled = selectedIndexes.contains(i);

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [

      IconButton(
        icon: const Icon(Icons.remove),
        onPressed: enabled && shares[i] > 1
            ? () {
                shares[i]--;
                shareControllers[i].text = shares[i].toString();
                _recalcShares();
              }
            : null,
      ),

      SizedBox(
        width: 40,
        child: TextField(
          controller: shareControllers[i],
          enabled: enabled,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          onChanged: (v) {
            final val = int.tryParse(v);
            if (val != null && val > 0) {
              shares[i] = val;
              _recalcShares();
            }
          },
        ),
      ),

      IconButton(
        icon: const Icon(Icons.add),
        onPressed: enabled
            ? () {
                shares[i]++;
                shareControllers[i].text = shares[i].toString();
                _recalcShares();
              }
            : null,
      ),
    ],
  );
}



if (mode == "percent") {
  return SizedBox(
    width: 90,
    child: TextField(
      controller: percentControllers[i],
      enabled: selectedIndexes.contains(i),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.end,
    decoration: InputDecoration(
  prefixText: "₹ ",
  suffixText: "%",
  hintText: "0",

  border: percentControllers[i].text.isEmpty
      ? const UnderlineInputBorder()
      : InputBorder.none,

  enabledBorder: percentControllers[i].text.isEmpty
      ? const UnderlineInputBorder()
      : InputBorder.none,

  focusedBorder: percentControllers[i].text.isEmpty
      ? const UnderlineInputBorder()
      : InputBorder.none,
),




      onChanged: (v) {
  _recalcPercent();
  Future.microtask(() => setState(() {}));
},
    ),
  );
}


  return const SizedBox();
}



Widget _buildPercentRemainingIndicator() {

  if (remainingPercent.abs() < 0.01) {
    return const Text(
      "Percent Split Complete ✓",
      style: TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  if (remainingPercent > 0) {
    return Text(
      "${remainingPercent.toStringAsFixed(0)}% left to assign",
      style: const TextStyle(
        color: Colors.orange,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  return Text(
    "Exceeded by ${remainingPercent.abs().toStringAsFixed(0)}%",
    style: const TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.w600,
    ),
  );
}


}

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '/screens/split/split_screen.dart';

class SplitPeopleSheet extends StatefulWidget {
  final double totalAmount;
  final int creatorRegId;
  final String fullName;
  final String mobile;
  final String? upiId;
  final String walletStatus;
  final int aadhaarVerified;
  final int panVerified;
  final List<Map<String, dynamic>>? preSelectedUsers;


 const SplitPeopleSheet({
  super.key,
  required this.totalAmount,
  required this.creatorRegId,
  required this.fullName,
  required this.mobile,
  required this.upiId,
  required this.walletStatus,
  required this.aadhaarVerified,
  required this.panVerified,
  this.preSelectedUsers,
});


  @override
  State<SplitPeopleSheet> createState() => _SplitPeopleSheetState();
}

class _SplitPeopleSheetState extends State<SplitPeopleSheet> {

  List<Map<String, dynamic>> users = [];
  Map<dynamic, Map<String, dynamic>> memberStatusMap = {};
  Set<String> selectedMobiles = {};
  Map<String, Map<String, dynamic>> selectedUsersMap = {};
  String? creatorMobile;
  String? creatorName;
  String? creatorProfileImage;



  bool loading = false;
  final TextEditingController searchController = TextEditingController();

@override
void initState() {
  super.initState();

  creatorMobile = ApiService.currentUserMobile;
  creatorName = ApiService.currentUserName;
  creatorProfileImage = ApiService.currentUserProfileImage;

  if (creatorMobile != null) {
    selectedMobiles.add(creatorMobile!);

    selectedUsersMap[creatorMobile!] = {
      "name": creatorName,
      "identifier": creatorMobile,
      "profile_image": creatorProfileImage,
      "reg_id": widget.creatorRegId,
    };
  }
  if (widget.preSelectedUsers != null) {
    for (var user in widget.preSelectedUsers!) {
      final mobile = user["identifier"];

      if (mobile == null) continue;
      if (mobile == creatorMobile) continue;

      selectedMobiles.add(mobile);

      if (user["reg_id"] == null) continue;

      selectedUsersMap[mobile] = {
        "reg_id": user["reg_id"],
        "name": user["name"],
        "identifier": user["identifier"],
        "profile_image": user["profile_image"],
      };

    }
  }

}

// Show Dialog msgs
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


  // ================= SEARCH =================
 Future<void> search(String q) async {
  if (q.length < 3) {
    setState(() => users = []);
    return;
  }

  setState(() => loading = true);

  try {
    final res = await ApiService.searchLumeUserByMobile(q);
    final list = List<Map<String, dynamic>>.from(res)
    .where((u) => u["reg_id"] != null)
    .toList();

    for (var u in list) {
      final regId = u["reg_id"];
      if (regId != null) {
        try {
          final status = await ApiService.getSplitMemberStatus(regId);
          memberStatusMap[regId] = status;
        } catch (_) {}
      }
    }

    setState(() {
      users = list;
    });

  } catch (_) {
    setState(() => users = []);
  }

  setState(() => loading = false);
}



  // ================= SELECT USER =================
void toggleUser(Map<String, dynamic> user) {

  final mobile = user["identifier"];
  print("SELECTED USER DATA: $user");

  setState(() {

    if (selectedMobiles.contains(mobile)) {

      selectedMobiles.remove(mobile);
      selectedUsersMap.remove(mobile);

    } else {

      final regId = user["reg_id"];

      if (regId == null) {
        showMessageDialog(
          title: "Invalid User",
          message: "This user cannot be added to split",
          isError: true,
        );
        return;
      }

      selectedMobiles.add(mobile);

      selectedUsersMap[mobile] = {
        "reg_id": regId,
        "name": user["name"],
        "identifier": user["identifier"],
        "profile_image": user["profile_image"],
        "aadhaar_verified": memberStatusMap[regId] != null
            ? memberStatusMap[regId]!["aadhaar_verified"]
            : 1,
        "wallet_active": memberStatusMap[regId] != null
            ? memberStatusMap[regId]!["wallet_active"]
            : 1,
      };
    }
  });
}



// to ee selected users
Widget _buildSelectedUsersChips() {
  if (selectedUsersMap.isEmpty) return const SizedBox();

  return SizedBox(
    height: 70,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: selectedUsersMap.values.map((u) {

        final mobile = u["identifier"];

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Stack(
            children: [

              Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        u["profile_image"] != null &&
                        u["profile_image"].toString().isNotEmpty
                            ? NetworkImage(u["profile_image"])
                            : null,
                    child: (u["profile_image"] == null ||
                            u["profile_image"].toString().isEmpty)
                        ? Text(
                            (u["name"] ?? "U")[0].toUpperCase(),
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    u["name"] ?? "",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),

              // REMOVE BUTTON
              if (true)
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedMobiles.remove(mobile);
                        selectedUsersMap.remove(mobile);
                      });
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}


  // ================= NAVIGATION =================
 void goToSplitScreen() {

  if (selectedUsersMap.values.any((u) => u["reg_id"] == null)) {

    showMessageDialog(
      title: "Invalid Selection",
      message: "Some users are invalid. Please reselect.",
      isError: true,
    );

    return;
  }

  Navigator.pop(context);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SplitScreen(
        selectedUsers: selectedUsersMap.values.toList(),
        totalAmount: widget.totalAmount,
        creatorRegId: widget.creatorRegId,
        fullName: widget.fullName,
        mobile: widget.mobile,
        upiId: widget.upiId,
        walletStatus: widget.walletStatus,
        aadhaarVerified: widget.aadhaarVerified,
        panVerified: widget.panVerified,
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {

    return SafeArea(
  child: Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.max,
      children: [

        // Handle
        Container(
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          "Split Payment",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 4),

        Text(
          "Select people to split ₹${widget.totalAmount.toStringAsFixed(2)}",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),

        const SizedBox(height: 18),

        _buildSelectedUsersChips(),

        const SizedBox(height: 12),

        TextField(
          controller: searchController,
          keyboardType: TextInputType.phone,
          onChanged: search,
          decoration: InputDecoration(
            hintText: "Search mobile number",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 14),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: _buildUserList(),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed:
                selectedMobiles.isEmpty ? null : goToSplitScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C6EF5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              selectedMobiles.isEmpty
                  ? "Add People"
                  : "Add (${selectedMobiles.where((m) => m != creatorMobile).length})",
            ),
          ),
        ),
      ],
    ),
  ),
);

  }

  // ================= USER LIST BUILDER =================
  Widget _buildUserList() {

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty && searchController.text.length >= 3) {
      return const Center(
        child: Text(
          "No Lume users found",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (_, i) {

        final u = users[i];
        final mobile = u["identifier"];
        final regId = u["reg_id"];
        final status = memberStatusMap[regId];
        final aadhaarOk = status?["aadhaar_verified"] ?? true;
        final walletOk = status?["wallet_active"] ?? true;
        final isSel = selectedMobiles.contains(mobile);

        return ListTile(
          onTap: () => toggleUser(u),

          leading: CircleAvatar(
  backgroundColor: isSel
      ? const Color(0xFF4C6EF5).withOpacity(0.15)
      : Colors.grey.shade200,

  backgroundImage:
      u["profile_image"] != null &&
      u["profile_image"].toString().isNotEmpty
          ? NetworkImage(u["profile_image"])
          : null,

  child: (u["profile_image"] == null ||
          u["profile_image"].toString().isEmpty)
      ? Text(
          (u["name"] ?? "U")[0].toUpperCase(),
        )
      : null,
),



          title: Text(
            u["name"] ?? "Unknown",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(mobile),

    if (!aadhaarOk)
      const Text(
        "KYC Pending",
        style: TextStyle(color: Colors.red, fontSize: 11),
      ),

    if (!walletOk)
      const Text(
        "Wallet Inactive",
        style: TextStyle(color: Colors.orange, fontSize: 11),
      ),
  ],
),


          trailing: Checkbox(
  value: isSel,
  activeColor: const Color(0xFF4C6EF5),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(6),
  ),
  onChanged: (_) => toggleUser(u),
),

        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'student_details_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import '../services/api_service.dart';
import 'qr_scanner_screen.dart';
import 'payment_amount_screen.dart';
import 'add_money_screen.dart';
import 'package:flutter/services.dart';
import 'my_qr_screen.dart';
import 'transactions_screen.dart';
import 'package:lume_app/widgets/transaction_tile.dart';
import 'pin_settings_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'upi_payment_settings_screen.dart';
import 'pin_verify_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int regId;
  final String fullName;
  final String mobile;
  final String? upiId;
  final String walletStatus;
  final int aadhaarVerified;
  final int panVerified;
  final String initialTab;
  const DashboardScreen({
    super.key,
    required this.regId,
    required this.fullName,
    required this.mobile,
    required this.upiId,
    required this.walletStatus,
    required this.aadhaarVerified,
    required this.panVerified,
    this.initialTab = "pay",
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 2;
  int unreadCount = 0;
  bool aadhaarVerified = false;
  bool panVerified = false;
  String walletStatus = "inactive";
  double kycProgress = 0.0;
  bool isKycCompleted = false;
  String? upiId;
  String? userName;
  File? profileImage;
  String? profileImageUrl;


  // ================= USER HELPERS =================
  String get initials {
    if (widget.fullName.trim().isEmpty) return "XO";
    final parts = widget.fullName.trim().split(" ");
    return parts.length >= 2
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : widget.fullName.substring(0, 2).toUpperCase();
  }
void logout() {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}


  Future<void> _loadProfileData() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    userName = prefs.getString("user_name") ?? widget.fullName;
    final imagePath = prefs.getString("profile_image_path");
    if (imagePath != null) {
      profileImage = File(imagePath);
    }
  });
}
Future<void> _pickImage(ImageSource source) async {
  final picker = ImagePicker();

  final picked = await picker.pickImage(
    source: source,
    imageQuality: 80,
  );

  if (picked != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("profile_image_path", picked.path);

    setState(() {
      profileImage = File(picked.path);
    });
  }
}

Future<void> _pickProfileImage() async {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // Drag handle
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
            "Change Profile Picture",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFF4C6EF5)),
            title: const Text("Take photo"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),

          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFF4C6EF5)),
            title: const Text("Choose from gallery"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}


Future<void> _loadUnreadCount() async {
  try {
    unreadCount =
        await ApiService.getUnreadNotificationCount(widget.regId);
    if (!mounted) return;
    setState(() {});
  } catch (_) {
  }
}
@override
void initState() {
  super.initState();
  if (widget.initialTab == "wallet") {
    currentIndex = 1;
  } else if (widget.initialTab == "card") {
    currentIndex = 0;
  } else {
    currentIndex = 2; 
  }
  _loadUnreadCount();
  _refreshStudentState();
  _loadProfileData();
}
// Pin status check
Future<void> openWalletPinFlow() async {
  final status = await ApiService.getPinStatus(widget.regId);
  final bool walletPinSet = status["wallet"] == true;

  if (!walletPinSet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PinSettingsScreen(
          regId: widget.regId,
          forceSetup: true,
        ),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PinVerifyScreen(
        regId: widget.regId,
        type: "wallet",
        onVerified: () {},
      ),
    ),
  );
}


// Refresh student state
Future<void> _refreshStudentState() async {
  try {
    final data = await ApiService.getStudentDetails(widget.regId);
    if (!mounted) return;

    setState(() {
      aadhaarVerified = data["aadhaar_verified"] == 1;
      panVerified = data["pan_verified"] == 1;

      walletStatus = data["wallet_status"] ?? "inactive";
      upiId = data["upi_id"];

      final percent =
          (data["kyc_completion_percent"] ?? 0).toDouble();
      kycProgress = percent / 100;
      isKycCompleted = kycProgress == 1.0;
    });
  } catch (_) {
    // silent fail
  }
}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
  onWillPop: () async {
    return false; 
  },
  child: Scaffold(

      backgroundColor: const Color(0xFFF7F8FC),

      // ================= DRAWER =================
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFE8ECFF),
                          backgroundImage: profileImage != null
                              ? FileImage(profileImage!)
                              : null,
                          child: profileImage == null
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4C6EF5),
                                  ),
                                )
                              : null,
                        ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        height: 22,
                        width: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Color(0xFF4C6EF5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                userName ?? widget.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.mobile,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                upiId ?? "No UPI ID",
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(height: 40),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("My Details"),
                onTap: () async {
                    Navigator.of(context).pop();

                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentDetailsScreen(regId: widget.regId),
                      ),
                    );

                    if (updated == true) {
                      _refreshStudentState();
                    }
                  },
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text("UPI & Payment Settings"),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UpiPaymentSettingsScreen(
                        upiId: upiId ?? "",
                        mobile: widget.mobile,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: logout,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // ================= BODY =================
      body: SafeArea(
  child: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ================= TOP ROW =================
        Row(
          children: [
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE8ECFF),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C6EF5),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, size: 26),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );

                    // refresh badge count when returning
                    _loadUnreadCount();
                  },
                ),

                // BADGE
                if (unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? "9+" : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ================= TAB CONTENT =================
        if (currentIndex == 1)
         _WalletView(
  regId: widget.regId,
  walletStatus: walletStatus,
  fullName: widget.fullName,
  upiId: upiId ?? "",
  mobile: widget.mobile,
  aadhaarVerified: widget.aadhaarVerified,
  panVerified: widget.panVerified,
  onNewCredit: _loadUnreadCount,
)

        else
          _PayView(
            regId: widget.regId,
            kycProgress: kycProgress,
            isKycCompleted: isKycCompleted,
            onKycUpdated: _refreshStudentState,
          ),
      ],
    ),
  ),
),


      // ================= BOTTOM NAV =================
      bottomNavigationBar: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) {
            setState(() => currentIndex = i);
          },
          selectedItemColor: const Color(0xFF4C6EF5),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card),
              label: "Card",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: "Wallet",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code),
              label: "Pay",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: "Rewards",
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ================= PAY VIEW =================
class _PayView extends StatefulWidget {
  final int regId;
  final double kycProgress;
  final bool isKycCompleted;
  final VoidCallback onKycUpdated;
  
  const _PayView({
    required this.regId,
    required this.kycProgress,
    required this.isKycCompleted,
    required this.onKycUpdated,
  });

  @override
  State<_PayView> createState() => _PayViewState();
}

class _PayViewState extends State<_PayView> {
  double balance = 0.0;
  bool loading = true;
  bool showBalance = false;
  final TextEditingController upiController = TextEditingController();
  List<dynamic> paySuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }
bool isInternalUpi(String v) =>
    v.toLowerCase().endsWith("@lumepay");

bool isExternalUpi(String v) =>
    v.contains("@") && !isInternalUpi(v);
bool isMobile(String v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v);
bool isUpi(String v) => v.contains('@');

void openPayment(Map to, bool isWallet) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PaymentAmountScreen(
        regId: widget.regId,
        payee: to["identifier"],
        payeeName: to["name"],
        isWalletTransfer: isWallet,
      ),
    ),
  );

  if (result == true) {
    upiController.clear(); 
    paySuggestions.clear();
    setState(() {});
  }
}



  Future<void> _loadBalance() async {
    try {
      final b = await ApiService.getWalletBalance(widget.regId);
      if (!mounted) return;
      setState(() {
        balance = b;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        balance = 0.0;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
       // ================= BALANCE CARD =================
Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 10),
    ],
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Balance",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            loading
                ? "Loading..."
                : showBalance
                    ? "₹ ${balance.toStringAsFixed(2)}"
                    : "₹ ••••••",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      //EYE TOGGLE
      IconButton(
        icon: Icon(
          showBalance ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey.shade700,
        ),
        onPressed: () {
          setState(() {
            showBalance = !showBalance;
          });
        },
      ),
    ],
  ),
),
const SizedBox(height: 16),


        // ================= TAP & PAY =================
GestureDetector(
  onTap: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
  regId: widget.regId,
),
      ),
    );

    if (result != null) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PaymentAmountScreen(
        regId: widget.regId,
        payee: result,
        payeeName: "QR Payment",
        isWalletTransfer: false,
      ),
    ),
  );
}

  },
  child: Container(
    height: 130,
    decoration: BoxDecoration(
      color: const Color(0xFF4C6EF5),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Center(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.touch_app, color: Color(0xFF4C6EF5)),
            SizedBox(width: 8),
            Text(
              "Tap & Pay",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),

const SizedBox(height: 22),

        // ================= PAY UPI FIELD =================
Container(
  padding: const EdgeInsets.symmetric(horizontal: 14),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.grey.shade400),
  ),
  child: Column(
    children: [
      Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: upiController,
              decoration: const InputDecoration(
                hintText: "Pay UPI ID or mobile number",
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.done,
              onChanged: (value) async {
  // Mobile number → wallet user
  if (isMobile(value)) {
    paySuggestions =
        await ApiService.searchLumeUserByMobile(value);
  }

  // Internal UPI → wallet user
  else if (isInternalUpi(value)) {
    paySuggestions =
        await ApiService.searchLumeUserByUpi(value);
  }

  // External UPI → local suggestion
  else if (isExternalUpi(value)) {
    paySuggestions = [
      {
        "name": value,
        "identifier": value,
        "isWallet": false,
      }
    ];
  }

  else {
    paySuggestions = [];
  }

  setState(() {});
},
              onSubmitted: (value) {
                  if (paySuggestions.isNotEmpty) {
                    final s = paySuggestions.first;
                    openPayment(
  {
    "name": s["name"],
    "identifier": s["identifier"],
  },
  s["identifier"].toString().endsWith("@lumepay"),
);
                  }
                },
            ),
          ),
        ],
      ),

      // ================= SUGGESTIONS =================
      if (paySuggestions.isNotEmpty)
        ListView.builder(
          shrinkWrap: true,
          itemCount: paySuggestions.length,
          itemBuilder: (_, i) {
            final s = paySuggestions[i];
            return ListTile(
              leading: CircleAvatar(
                  backgroundColor:
                      (s["isWallet"] ?? true)
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                  child: Icon(
                    (s["isWallet"] ?? true)
                        ? Icons.person
                        : Icons.account_balance,
                    color:
                        (s["isWallet"] ?? true)
                            ? Colors.green
                            : Colors.blue,
                  ),
                ),
              title: Text(s["name"]),
              subtitle: Text(s["identifier"]),
              onTap: () => openPayment(
                      {
                        "name": s["name"],
                        "identifier": s["identifier"],
                      },
                      s["isWallet"] ?? true,
                    ),
            );
          },
        ),
    ],
  ),
),

        const SizedBox(height: 26),
        // ================= ICON ROW =================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _PayOption(
              icon: Icons.flash_on,
              label: "Recharge",
              cashback: "2% cashback",
            ),
            _PayOption(
              icon: Icons.play_circle_fill,
              label: "Google Play",
              cashback: "5% cashback",
            ),
            _PayOption(
              icon: Icons.card_giftcard,
              label: "Cashbacks",
              cashback: "Up to 10%",
            ),
          ],
        ),

        const SizedBox(height: 30),

// ================= KYC CARD =================
if (!widget.isKycCompleted)
  GestureDetector(
    onTap: () async {
      final updated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDetailsScreen(
            regId: widget.regId,
          ),
        ),
      );

      if (updated == true) {
       widget.onKycUpdated(); 
 
      }
    },

    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              const Text(
                "KYC In Progress",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                "${(widget.kycProgress * 100).toInt()}%",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: widget.kycProgress,
          ),
        ],
      ),
    ),
  ),


      ],
    );
  }
}
// ================= PAY OPTION WIDGET =================
class _PayOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String cashback;

  const _PayOption({
    required this.icon,
    required this.label,
    required this.cashback,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE8ECFF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: const Color(0xFF4C6EF5)),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          cashback,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF4C6EF5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}


// ================= WALLET VIEW =================
class _WalletView extends StatefulWidget {
  final int regId;
  final String walletStatus;
  final String fullName;
  final String upiId;
  final String mobile;
  final int aadhaarVerified;
  final int panVerified;
  final VoidCallback onNewCredit;


 const _WalletView({
  required this.regId,
  required this.walletStatus,
  required this.fullName,
  required this.upiId,
  required this.mobile,
  required this.aadhaarVerified,
  required this.panVerified,
  required this.onNewCredit,
});



  @override
  State<_WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<_WalletView> {
  List<dynamic> transactions = [];
  bool loadingTxns = true;
  int? _lastTxnId;
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }
 void refreshAll() async {
  await _loadTransactions();
}


void showReceivedAnimation(double amount) {
  final overlay = Overlay.of(context);

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                "Received ₹${amount.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  Future.delayed(const Duration(seconds: 2), () {
    entry.remove();
  });
}


  Future<void> _loadTransactions() async {
  final newTxns =
      await ApiService.getTransactionHistory(widget.regId);

  if (!mounted) return;

  //  FIRST LOAD (important fix)
  if (_lastTxnId == null && newTxns.isNotEmpty) {
    _lastTxnId = newTxns.first["id"];
  }
  //  SUBSEQUENT LOADS
  else if (newTxns.isNotEmpty) {
    final latest = newTxns.first;

    final isNew = latest["id"] != _lastTxnId;
    final isCredit =
        latest["receiver_reg_id"] == widget.regId &&
        latest["status"] == "success";

    if (isNew && isCredit) {
      final double amount =
          double.tryParse(latest["amount"].toString()) ?? 0;

      showReceivedAnimation(amount);
      widget.onNewCredit();
    }

    _lastTxnId = latest["id"];
  }

  setState(() {
    transactions = newTxns; 
    loadingTxns = false;
  });
}



  @override
  Widget build(BuildContext context) {
    return Column(
  children: [
   _WalletBalanceStrip(
  regId: widget.regId,
  walletStatus: widget.walletStatus,
  fullName: widget.fullName,
  upiId: widget.upiId,
  mobile: widget.mobile,
  aadhaarVerified: widget.aadhaarVerified,
  panVerified: widget.panVerified,
),



    const SizedBox(height: 16),
    _MyQrCard(
  upiId: widget.upiId,
  name: widget.fullName,
  walletStatus: widget.walletStatus,
),


    const SizedBox(height: 16),
    _TransactionHistoryCard(
      loading: loadingTxns,
      transactions: transactions,
      regId: widget.regId,
    ),
    const SizedBox(height: 16),

GestureDetector(
  onTap: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinSettingsScreen(
          regId: widget.regId,
        ),
      ),
    );

    if (result == true && mounted) {
      final dashboardState =
          context.findAncestorStateOfType<_DashboardScreenState>();

      dashboardState?.setState(() {
        dashboardState.currentIndex = 1; 
      });
    }
  },



  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8),
      ],
    ),
    child: Row(
      children: const [
        Icon(
          Icons.lock_outline,
          color: Color(0xFF4C6EF5),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            "Wallet PIN",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Icon(Icons.chevron_right),
      ],
    ),
  ),
),

  ],
);

  }
}
// ================= TRANSACTION HISTORY CARD =================
class _TransactionHistoryCard extends StatelessWidget {
  final bool loading;
  final List<dynamic> transactions;
  final int regId;

  const _TransactionHistoryCard({
    required this.loading,
    required this.transactions,
    required this.regId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionsScreen(
              regId: regId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Transactions",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "View all",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4C6EF5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Color(0xFF4C6EF5),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ================= CONTENT =================
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "No transactions yet",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: transactions
                .take(5)
                .map<Widget>((t) => TransactionTile(
                    txn: t,
                  ))
                .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// ================= WALLET BALANCE STRIP =================
class _WalletBalanceStrip extends StatefulWidget {
  final int regId;
  final String walletStatus;
  final String fullName;
  final String upiId;
  final String mobile;
  final int aadhaarVerified;
  final int panVerified;


  const _WalletBalanceStrip({
  required this.regId,
  required this.walletStatus,
  required this.fullName,
  required this.upiId,
  required this.mobile,
  required this.aadhaarVerified,
  required this.panVerified,
});



  @override
  State<_WalletBalanceStrip> createState() => _WalletBalanceStripState();
}

class _WalletBalanceStripState extends State<_WalletBalanceStrip> {
  bool showBalance = false;
  bool loading = true;
  double balance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final b = await ApiService.getWalletBalance(widget.regId);
      if (!mounted) return;
      setState(() {
        balance = b;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        balance = 0.0;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.walletStatus == "active";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 20),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ================= LEFT CONTENT =================
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActive ? "Wallet balance" : "Wallet inactive",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),

              // BALANCE / DOTS (TAP TO TOGGLE)
              GestureDetector(
                onTap: () {
                  if (!isActive || loading) return;
                  setState(() {
                    showBalance = !showBalance;
                  });
                },
                child: loading
                    ? const Text(
                        "Loading...",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
                        showBalance
                            ? "₹ ${balance.toStringAsFixed(2)}"
                            : "₹ ••••••",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),

          const Spacer(),

          // ================= RIGHT ACTION =================
          if (isActive)
            GestureDetector(
  onTap: () async {
    final refreshed = await Navigator.push(
      context,
      MaterialPageRoute(
   builder: (_) => AddMoneyScreen(
  regId: widget.regId,
  fullName: widget.fullName,
  mobile: widget.mobile,
  upiId: widget.upiId,
  walletStatus: widget.walletStatus,
  aadhaarVerified: widget.aadhaarVerified,
  panVerified: widget.panVerified,
),



      ),
    );

    if (refreshed == true) {
  _loadBalance();
}
  },
  child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.add,
                      color: Color(0xFF4C6EF5),
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Add Money",
                      style: TextStyle(
                        color: Color(0xFF4C6EF5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Icon(
              Icons.lock_outline,
              color: Colors.grey,
            ),
        ],
      ),
    );
  }
}
class _MyQrCard extends StatefulWidget {
  final String upiId;
  final String name;
  final String walletStatus;

  const _MyQrCard({
    required this.upiId,
    required this.name,
    required this.walletStatus,
  });

  @override
  State<_MyQrCard> createState() => _MyQrCardState();
}

class _MyQrCardState extends State<_MyQrCard> {
  bool upiCopied = false;

  void _copyUpiId() async {
    await Clipboard.setData(
      ClipboardData(text: widget.upiId),
    );

    setState(() {
      upiCopied = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        upiCopied = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12),
        ],
      ),
      child: Column(
        children: [
          // ================= UPI ID =================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.upiId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _copyUpiId,
                  child: Icon(
                    upiCopied ? Icons.check_circle : Icons.copy,
                    size: 18,
                    color: upiCopied
                        ? Colors.green
                        : const Color(0xFF4C6EF5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ================= MY QR CODE =================
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyQrScreen(
                    name: widget.name,
                    upiId: widget.upiId,
                    walletActive: widget.walletStatus == "active",
                  ),
                ),
              );
            },
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.qr_code_2,
                    size: 48,
                    color: Color(0xFF4C6EF5),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "My QR Code",
                    style: TextStyle(
                      color: Color(0xFF4C6EF5),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

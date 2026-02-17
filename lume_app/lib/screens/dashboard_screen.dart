import 'package:flutter/material.dart';
import '../main.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lume_app/widgets/transaction_tile.dart';
import 'pin_settings_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'upi_payment_settings_screen.dart';
import 'pin_verify_screen.dart';
import 'package:lume_app/widgets/create_upi_dialog.dart';
import 'package:lume_app/screens/cashback_store_screen.dart';
import 'package:lume_app/screens/rewards/brand_vouchers_screen.dart';
import 'package:lume_app/screens/rewards/my_vouchers_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lume_app/screens/scholar_screen.dart';
import 'package:lume_app/screens/about/terms_conditions_screen.dart';
import 'package:lume_app/screens/about/privacy_policy_screen.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lume_app/screens/challenges_screen.dart';
import 'package:lume_app/screens/about/about_us_screen.dart';
import 'package:lume_app/screens/app_settings_screen.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/tier_assets.dart';
import '/widgets/tier_points_swap_widget.dart';
import '../widgets/liquid_progress_bar.dart';
import 'payment_result_screen.dart';
import 'package:lume_app/screens/rewards/cash_won_screen.dart';
import 'package:lume_app/screens/rewards/coupons_screen.dart';
import 'rewards/rewards_view_all_sheet.dart';
import '../widgets/card_transaction_tile.dart';
import 'card_centre_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int regId;
  final String fullName;
  final String mobile;
  final String? upiId;
  final String walletStatus;
  final int aadhaarVerified;
  final int panVerified;
  final String initialTab;
  final int? openSplitId;

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
    this.openSplitId,
  });

  @override
State<DashboardScreen> createState() => DashboardScreenState();
}
class DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {

  final LocalAuthentication _auth = LocalAuthentication();
  bool _authInProgress = false;
  bool _unlocked = false;
  bool _checkingLock = true;
  static const int _gracePeriodSeconds = 45;
  DateTime? _lastPausedTime;
  int currentIndex = 2;
  int unreadCount = 0;
  int unrevealedRewardsCount = 0;
  List<dynamic> cashWonList = [];
  Timer? _refreshTimer;

  bool aadhaarVerified = false;
  bool panVerified = false;
  String walletStatus = "inactive";
  double kycProgress = 0.0;
  bool isKycCompleted = false;
  String? upiId;
  String? userName;
  String? profileImageUrl;
  late final PageController _pageController;
  bool upiCopied = false;
  int rewardPoints = 0;
  String backendTier = "silver";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String appVersion = "";
  
Future<void> _checkAndAuthenticate() async {
  if (_unlocked || _authInProgress) return;

  _authInProgress = true;

  final prefs = await SharedPreferences.getInstance();
  final shouldLock = prefs.getBool("app_lock") ?? false;

  if (!shouldLock) {
    if (!mounted) return;
    setState(() {
      _unlocked = true;
      _checkingLock = false;
    });
    _authInProgress = false;
    return;
  }

  try {
    final success = await _auth.authenticate(
      localizedReason: 'Authenticate to open Lume',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: false,
      ),
    );

    if (!mounted) return;

    setState(() {
      _unlocked = success;
      _checkingLock = false;
    });
  } catch (_) {
    if (!mounted) return;
    setState(() {
      _unlocked = false;
      _checkingLock = false;
    });
  } finally {
    _authInProgress = false;
  }
}


  // ================= USER HELPERS =================
  String get initials {
  final name = widget.fullName.trim();
  if (name.isEmpty) return "XO";

  final parts = name.split(" ");

  if (parts.length >= 2) {
    return "${parts[0][0]}${parts[1][0]}".toUpperCase();
  }

  if (name.length == 1) {
    return name[0].toUpperCase();
  }

  return name.substring(0, 2).toUpperCase();
}


  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("session_reg_id");
    await prefs.remove("session_mobile");
    await prefs.remove("session_email");
    await prefs.remove("session_name");
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

Widget buildTopTierStatus() {
  return TierPointsSwapWidget(
    rewardPoints: rewardPoints,
    tier: backendTier,
  );
}


Widget buildKycStatusBadge() {
  final bool verified = isKycCompleted;

  return Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: verified ? Colors.green.shade50 : Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: verified ? Colors.green : Colors.red,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          verified ? Icons.check_circle : Icons.cancel,
          size: 14,
          color: verified ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 6),
        Text(
          verified ? "KYC Verified" : "KYC Not Verified",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: verified ? Colors.green : Colors.red,
          ),
        ),
      ],
    ),
  );
}

// Refresh wallet balance
Future<void> refreshWalletNow() async {

  // Trigger wallet reload via global refresh instead
  await refreshStudentState();
  await loadUnreadCount();

}


Future<void> refreshAllCounts() async {
  await Future.wait([
    loadUnreadCount(),
    loadUnrevealedRewardsCount(),
    loadCashWon(),
  ]);

  if (!mounted) return;
  setState(() {});
}



Future<void> _pickImage(ImageSource source) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    imageQuality: 80,
  );

  if (picked == null) return;

  await ApiService.uploadProfileImage(
    regId: widget.regId,
    imageFile: File(picked.path),
  );
  await refreshStudentState();
  setState(() {});
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

// Copy UPI
void _copyUpiId(String upi) async {
  await Clipboard.setData(ClipboardData(text: upi));

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

Future<void> loadUnreadCount()
 async {
  try {
    unreadCount =
        await ApiService.getUnreadNotificationCount(widget.regId);
    if (!mounted) return;
    setState(() {});
  } catch (_) {
  }
}

Future<void> loadUnrevealedRewardsCount() async {
  try {
    final data =
        await ApiService.getPendingDragRewards(widget.regId);

    if (!mounted) return;

    setState(() {
      unrevealedRewardsCount = data.length;
    });

  } catch (e) {
    print("Rewards count load error = $e");
  }
}

Future<void> loadCashWon() async {
  try {
    final data = await ApiService.getCashWon(widget.regId);

    if (!mounted) return;

    setState(() {
      cashWonList = data;
    });

  } catch (e) {
    print("CashWon load error = $e");
  }
}


void _startBackgroundRefresh() {
  _refreshTimer?.cancel();

  _refreshTimer = Timer.periodic(
    const Duration(seconds: 30),
    (_) async {
      if (!mounted) return;

      await refreshAllCounts();
    },
  );
}


@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);

  _persistRegId();
  _loadAppVersion();
  _checkAndAuthenticate(); 


  if (widget.initialTab == "card") {
    currentIndex = 0;
  } else if (widget.initialTab == "wallet") {
    currentIndex = 1;
  } else if (widget.initialTab == "pay") {
    currentIndex = 2;
  } else if (widget.initialTab == "rewards") {
    currentIndex = 3;
  } else {
    currentIndex = 2;
  }

  _pageController = PageController(initialPage: currentIndex);
  loadUnreadCount();
  loadUnrevealedRewardsCount();
  loadCashWon();
  refreshStudentState();
  Future.delayed(const Duration(seconds: 2), () {
    loadUnrevealedRewardsCount();
    _startBackgroundRefresh();

  });

}


Future<void> _persistRegId() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt("reg_id", widget.regId);
}
Future<void> openMyCampusApp() async {
  const String packageName = "com.mycampus.app";
  const String playStoreUrl =
      "https://play.google.com/store/apps/details?id=com.campXStudent.app";

  if (!Platform.isAndroid) return;

  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: packageName,
    );

    await intent.launch();
  } catch (e) {
    final uri = Uri.parse(playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}



@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _pageController.dispose();
  _refreshTimer?.cancel();
  super.dispose();
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused ||
      state == AppLifecycleState.inactive) {
    _lastPausedTime = DateTime.now();
  }

  if (state == AppLifecycleState.resumed) {
    final now = DateTime.now();
    if (_lastPausedTime == null) {
      _checkingLock = true;
      _unlocked = false;
      _checkAndAuthenticate();
      return;
    }
    final diff = now.difference(_lastPausedTime!).inSeconds;
    if (diff > _gracePeriodSeconds) {
      _checkingLock = true;
      _unlocked = false;
      _checkAndAuthenticate();
    }
    refreshAllCounts();
    loadCashWon();


  }
}


// App Version
Future<void> _loadAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  if (!mounted) return;

  setState(() {
    appVersion = info.version;
  });
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
          initialTab: "wallet",
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
Future<void> refreshStudentState()
 async {
  try {
    final data = await ApiService.getStudentDetails(widget.regId);
    if (!mounted) return;

    final int points =
    int.tryParse((data["reward_points"] ?? 0).toString()) ?? 0;

    final String tier =
        (data["tier"] ?? "silver").toString().toLowerCase();

    final double percent =
        double.tryParse(data["kyc_completion_percent"].toString()) ?? 0.0;

    setState(() {
      aadhaarVerified = data["aadhaar_verified"] == 1;
      panVerified = data["pan_verified"] == 1;
      walletStatus = data["wallet_status"] ?? "inactive";
      upiId = data["upi_id"];
      profileImageUrl = data["profile_image"];

      rewardPoints = points;
      backendTier = tier;
  

      kycProgress = percent / 100;
      isKycCompleted = kycProgress == 1.0;
    });
    await loadUnrevealedRewardsCount();

  } catch (_) {}
}



double get tierProgress {
  if (rewardPoints >= 1501) return 1;

  if (rewardPoints >= 901) {
    return ((rewardPoints - 901) / 600).clamp(0, 1);
  }

  if (rewardPoints >= 401) {
    return ((rewardPoints - 401) / 500).clamp(0, 1);
  }

  return (rewardPoints / 400).clamp(0, 1);
}



IconData get tierIcon {
  if (backendTier == "diamond") return Icons.diamond;
  if (backendTier == "platinum") return Icons.diamond;
  if (backendTier == "gold") return Icons.emoji_events;
  return Icons.star;
}


Color get tierColor {
  if (backendTier == "diamond") return const Color(0xFF00C2FF);
  if (backendTier == "platinum") return Colors.blueGrey;
  if (backendTier == "gold") return Colors.amber;
  return Colors.grey;
}



Widget buildUserAvatar(double radius) {
  if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(profileImageUrl!),
      backgroundColor: const Color(0xFFE8ECFF),
    );
  }

  return CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFFE8ECFF),
    child: Text(
      initials,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF4C6EF5),
      ),
    ),
  );
}


  @override
Widget build(BuildContext context) {
  if (_checkingLock) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  if (!_unlocked) {
    return const Scaffold(
      body: Center(child: Text("Authentication required")),
    );
  }

  return WillPopScope(
  onWillPop: () async => false,
  child: Scaffold(
    key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F8FC),

      // ================= DRAWER =================
      drawer: Drawer(
        child: SafeArea(
          child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: buildUserAvatar(24),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
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
              upiId == null || upiId!.isEmpty
            ? GestureDetector(
                onTap: () => showCreateUpiDialog(
                  context: context,
                  regId: widget.regId,
                  onSuccess: () {
                    refreshStudentState();
                  },
                ),
                child: const Text(
                  "+ Create UPI ID",
                  style: TextStyle(
                    color: Color(0xFF4C6EF5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            :Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ---- UPI ROW ----
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        upiId!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _copyUpiId(upiId!),
                        child: Icon(
                          upiCopied ? Icons.check_circle : Icons.copy,
                          size: 16,
                          color: upiCopied ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // ---- TIER BADGE ----
                  TierBadge(tier: backendTier),
                  const SizedBox(height: 8),

                  // ---- TIER PROGRESS BAR ----
                  SizedBox(
                    width: 160, 
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                      minHeight: 6,
                      value: tierProgress.clamp(0.02, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        tierProgress == 0 ? Colors.grey.shade400 : tierColor,
                      ),
                    ),
                    ),
                  ),
                  const SizedBox(height: 4),

                 if (rewardPoints < 2200)
                  Text(
                    rewardPoints < 401
                        ? "${401 - rewardPoints} pts to reach Gold"
                        : rewardPoints < 901
                            ? "${901 - rewardPoints} pts to reach Platinum"
                            : "${1501 - rewardPoints} pts to reach Diamond",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  buildKycStatusBadge(),
                ],
              ),

              const Divider(height: 40),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("My Details"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                    Navigator.of(context).pop();

                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentDetailsScreen(regId: widget.regId),
                      ),
                    );

                    if (updated == true) {
                      refreshStudentState();
                    }
                  },
              ),
              ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text("UPI & Payment Settings"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.of(context).pop();

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UpiPaymentSettingsScreen(
                          regId: widget.regId,
                          upiId: upiId,
                          mobile: widget.mobile,
                        ),
                      ),
                    );
                  },
                ),
                // ================= EXPLORE =================
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text("Scholar"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScholarScreen(),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.account_balance),
                  title: const Text("My Campus"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    openMyCampusApp();
                  },
                ),


                ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: const Text("Challenges"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChallengesScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text("App Settings"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppSettingsScreen(),
                      ),
                    );
                  },
                ),


                // ================= SUPPORT =================
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Support",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text("Support"),
                  subtitle: const Text("Student Support"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {    
                  },
                ),

                // ================= ABOUT =================
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "About",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

               ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("About Us"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context); 
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AboutUsScreen(),
                    ),
                  );
                },
              ),

                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text("Terms & Conditions"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsConditionsScreen(),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text("Privacy Policy"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),


                // ================= APP VERSION =================
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                    appVersion.isEmpty ? "" : "App Version $appVersion",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ),
                ),
              const SizedBox(height: 20),
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
      ),

      // ================= BODY =================
     body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================= TOP ROW =================
              SizedBox(
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Builder(
                      builder: (context) => GestureDetector(
                        onTap: () async {
                          _scaffoldKey.currentState?.closeDrawer();
                          await refreshStudentState();
                          if (!mounted) return;
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: buildUserAvatar(22),
                      ),
                    ),
                  ),

                  Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChallengesScreen(),
                        ),
                      );
                    },
                    child: buildTopTierStatus(),
                  ),
                ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Stack(
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
                            loadUnreadCount();
                          },
                        ),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

              const SizedBox(height: 20),

              // ================= TAB CONTENT (SLIDEABLE) =================
              Expanded(
                child: PageView(
                  controller: _pageController,
                onPageChanged: (index) async {
                setState(() {
                  currentIndex = index;
                });

                await refreshStudentState();
                await refreshAllCounts();
                if (index == 3) {
                  final rewardsView = context.findAncestorStateOfType<_RewardsViewState>();
                  rewardsView?.loadPendingDragRewards();
                }
              },

                  children: [
                    _CardView(
                    regId: widget.regId,
                    isKycCompleted: isKycCompleted,
                    kycProgress: kycProgress,
                  ),

                    _WalletView(
                      regId: widget.regId,
                      walletStatus: walletStatus,
                      fullName: widget.fullName,
                      upiId: upiId ?? "",
                      mobile: widget.mobile,
                      aadhaarVerified: widget.aadhaarVerified,
                      panVerified: widget.panVerified,
                      onNewCredit: loadUnreadCount,
                    ),

                    _PayView(
                      regId: widget.regId,
                      kycProgress: kycProgress,
                      isKycCompleted: isKycCompleted,
                      onKycUpdated: refreshStudentState,
                       openSplitId: widget.openSplitId, 
                    ),

                    _RewardsView(
                      dashboardCount: unrevealedRewardsCount,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ================= BOTTOM NAV =================
      bottomNavigationBar: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
         onTap: (i) async {
          setState(() => currentIndex = i);

          await _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );

          await refreshStudentState();
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
// ========= Tier Badge ===========
class TierBadge extends StatelessWidget {
  final String tier;

  const TierBadge({super.key, required this.tier});

  Color get _color {
    switch (tier) {
      case "diamond":
        return const Color(0xFF00C2FF);
      case "platinum":
        return const Color(0xFF9E9E9E);
      case "gold":
        return const Color(0xFFFFC107);
      default:
        return const Color(0xFFB0BEC5);
    }
  }


  String get _label =>
      tier[0].toUpperCase() + tier.substring(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            getTierAsset(tier),
            height: 16,
            width: 16,
          ),
          const SizedBox(width: 6),
          Text(
        _label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
        ],
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
  final int? openSplitId;
  
  
  const _PayView({
    required this.regId,
    required this.kycProgress,
    required this.isKycCompleted,
    required this.onKycUpdated,
    this.openSplitId,

  });

  @override
  State<_PayView> createState() => _PayViewState();
}
class _PayViewState extends State<_PayView>
    with SingleTickerProviderStateMixin {

  bool _animRunning = true;
  double balance = 0.0;
  bool loading = true;
  bool showBalance = false;
  bool showScanner = false;
  final TextEditingController upiController = TextEditingController();
  List<dynamic> paySuggestions = [];
  List<dynamic> recentPayees = [];
  bool loadingRecents = true;
  List<dynamic> splitRequests = [];
  bool loadingSplitRequests = true;
  bool showSplitSection = false;
  int getUnpaidSplitCount() {
  int count = 0;

  for (final split in splitRequests) {
    final members = split["members"] ?? [];

    Map<String, dynamic>? myMember;

    try {
      myMember = members.firstWhere(
        (m) => m["reg_id"] == widget.regId,
      );
    } catch (_) {
      myMember = null;
    }

    bool isPaidStatus(dynamic status) {
      if (status == null) return false;
      return status.toString().toLowerCase() == "paid";
    }

    final myPaid =
        myMember?["paid"] == true ||
        isPaidStatus(myMember?["status"]);

    final isClosed =
        split["closed"] == 1 ||
        split["closed"] == true;

    if (!myPaid && !isClosed && myMember != null) {
      count++;
    }
  }

  return count;
}



  List<Map<String, dynamic>> dedupeRecentPayees(List<dynamic> list) {
  final seen = <String>{};
  final result = <Map<String, dynamic>>[];

  for (final item in list) {
    final identifier = item["identifier"]?.toString();
    if (identifier == null) continue;

    if (!seen.contains(identifier)) {
      seen.add(identifier);
      result.add(Map<String, dynamic>.from(item));
    }
  }

  return result;
}
  bool asBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v == 1;
    return false;
  }
String getKycMessage() {
  final dashboard =
      context.findAncestorStateOfType<DashboardScreenState>();

  if (dashboard == null) return "";

  if (dashboard.upiId == null || dashboard.upiId!.isEmpty) {
    return "Verify your UPI ID to complete your profile and enjoy exclusive rewards";
  }

  if (!dashboard.aadhaarVerified) {
    return "Complete Aadhaar KYC to activate wallet and unlock payments";
  }

  if (!dashboard.panVerified) {
    return "Complete PAN verification to unlock higher transaction limits";
  }

  return "Your profile is fully verified. Enjoy all Lume benefits";
}

  @override
void initState() {
  super.initState();

  _startInnerAnimationLoop();
  _loadRecentPayees();
  _loadBalance();
  _loadSplitRequests();
  if (widget.openSplitId != null) {
    Future.delayed(const Duration(milliseconds: 600), () {
      _openSplitFromNotification(widget.openSplitId!);
    });
  }
  upiController.addListener(() {
    if (mounted) setState(() {});
  });
}


  @override
  void dispose() {
    _animRunning = false;
    super.dispose();
  }



void _openSplitFromNotification(int splitId) async {

  await _loadSplitRequests();

  dynamic split;

  try {
    split = splitRequests.firstWhere(
      (s) => (s["split_id"] ?? s["id"]) == splitId,
    );
  } catch (_) {
    split = null;
  }


  if (split != null) {
    // future scroll logic
  }
}



Future<void> _loadSplitRequests() async {
  try {
    final data =
        await ApiService.getSplitRequests(widget.regId);

    if (!mounted) return;

    setState(() {

      // SHOW SPLITS UNTIL CREATOR CLOSES
      splitRequests = data;
      loadingSplitRequests = false;
    });

  } catch (_) {
    loadingSplitRequests = false;
  }
}


  void _startInnerAnimationLoop() async {
  while (mounted && _animRunning) {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => showScanner = true);

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => showScanner = false);
  }
}
Future<void> _loadRecentPayees() async {
  try {
    final data = await ApiService.getRecentPayees(widget.regId);
    if (!mounted) return;

   setState(() {
    recentPayees = dedupeRecentPayees(data);
    loadingRecents = false;
  });

  } catch (_) {
    loadingRecents = false;
  }
}

 
  bool isInternalUpi(String v) =>
      v.toLowerCase().endsWith("@lumepay");

  bool isExternalUpi(String v) =>
      v.contains("@") && !isInternalUpi(v);
  bool isMobile(String v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v);
  bool isUpi(String v) => v.contains('@');

  void openPayment(Map to, bool isWallet) async {
    final dashboardState =
        context.findAncestorStateOfType<DashboardScreenState>();

    if (dashboardState == null || 
      dashboardState.upiId == null ||
      dashboardState.upiId!.isEmpty) {
    showCreateUpiDialog(
      context: context,
      regId: widget.regId,
      onSuccess: () {
    if (dashboardState != null) {
      dashboardState.refreshStudentState();
    }
  },

    );
    return;
  }
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PaymentAmountScreen(
        regId: widget.regId,
        payee: to["identifier"],
        payeeName: to["name"],
        isWalletTransfer: isWallet,
        profileImage: to["profile_image"],
      ),
    ),
  );

  if (result == true || result == "success") {
    upiController.clear();
    paySuggestions.clear();
    final dashboardState =
        context.findAncestorStateOfType<DashboardScreenState>();

    if (dashboardState != null) {
  await dashboardState.refreshWalletNow();
  await dashboardState.refreshStudentState();

  
}

  }    
}
Future<void> refreshBalance() async {
  await _loadBalance();
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
    Future<void> _refreshBalanceSilently() async {
    try {
      final b = await ApiService.getWalletBalance(widget.regId);
      if (!mounted) return;

      setState(() {
        balance = b; 
      });
    } catch (_) {
    }
  }
  
  Widget buildScannerAnimation() {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF4C6EF5),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Scanner frame
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          // Scanning line animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (_, value, __) {
              return Positioned(
                top: 25 + (value * 40),
                child: Container(
                  width: 60,
                  height: 2,
                  color: Colors.white,
                ),
              );
            },
          ),

          const Positioned(
            bottom: 16,
            child: Text(
              "Scanning...",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState =
      context.findAncestorStateOfType<DashboardScreenState>();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
        if (dashboardState != null &&
    (dashboardState.upiId == null ||
     dashboardState.upiId!.isEmpty))
  GestureDetector(
    onTap: () => showCreateUpiDialog(
      context: context,
      regId: widget.regId,
      onSuccess: () {
        dashboardState.refreshStudentState();
      },
    ),
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6), 
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFD27D),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.info_outline,
            color: Color(0xFFFF9800),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Note: Create your UPI ID to make payments.",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  ),

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
        _refreshBalanceSilently();
      },
    ),
    ],
  ),
),
const SizedBox(height: 16),


// ================= TAP & PAY =================
GestureDetector(
  onTap: () async {
    final dashboardState =
        context.findAncestorStateOfType<DashboardScreenState>();

    if (dashboardState == null ||
        dashboardState.upiId == null ||
        dashboardState.upiId!.isEmpty) {
      showCreateUpiDialog(
        context: context,
        regId: widget.regId,
        onSuccess: () {
          dashboardState?.refreshStudentState();
        },
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(regId: widget.regId),
      ),
    );

    if (result != null) {
      final payResult = await Navigator.push(
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

      if (payResult != null) {
      await dashboardState.refreshWalletNow();
      await dashboardState.refreshStudentState();
      await dashboardState.refreshAllCounts();
    }
    }
  },

  child: Container(
    height: 130,
    decoration: BoxDecoration(
      color: const Color(0xFF4C6EF5),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Center(
      child: SizedBox(
        height: 80,
        width: 220,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.95, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: showScanner
              ? _ScannerInner(key: const ValueKey("scanner"))
              : _ScanPayInner(key: const ValueKey("scan")),
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
        final v = value.trim();

        /// CLEAR IF EMPTY
        if (v.isEmpty) {
          setState(() {
            paySuggestions = [];
          });
          return;
        }

        if (v.length < 3) {
          setState(() {
            paySuggestions = [];
          });
          return;
        }

        /// CHECK IF ONLY DIGITS
        final bool onlyDigits = RegExp(r'^\d+$').hasMatch(v);

        /// MOBILE SEARCH → ONLY IF DIGITS
        if (isMobile(v) || onlyDigits) {
          paySuggestions =
              await ApiService.searchLumeUserByMobile(v);
        }

        /// UPI SEARCH → ANY TEXT OR CONTAINS @
        else if (isInternalUpi(v) ||
            isExternalUpi(v) ||
            !onlyDigits) {
          paySuggestions =
              await ApiService.searchLumeUserByUpi(v);
        }

        /// EXTERNAL UPI MANUAL FALLBACK
        if (paySuggestions.isEmpty && v.contains("@")) {
          paySuggestions = [
            {
              "name": v,
              "identifier": v,
              "isWallet": false,
              "profile_image": null,
            }
          ];
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
    if (upiController.text.isNotEmpty)
      GestureDetector(
        onTap: () {
          upiController.clear();
          setState(() {
            paySuggestions = [];
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Icon(
            Icons.close,
            size: 20,
            color: Colors.grey.shade600,
          ),
        ),
      ),
  ],
),

// ================= RECENT PAYEES =================
if (!loadingRecents &&
    recentPayees.isNotEmpty &&
    upiController.text.isEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentPayees.length,
            itemBuilder: (_, i) {
              final r = recentPayees[i];
              final bool isWallet =
                  r["isWallet"] == true || r["isWallet"] == 1;

              final String name = (r["name"] ?? "U").toString();
              final String? profileImage = r["profile_image"];

              return GestureDetector(
                onTap: () {
                  openPayment(
                  {
                    "name": r["name"],
                    "identifier": r["identifier"],
                    "profile_image": r["profile_image"],
                  },
                  isWallet,
                );

                },
                child: Container(
                  width: 76,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: isWallet
                            ? Colors.green.shade100
                            : Colors.blue.shade100,
                        backgroundImage:
                            (profileImage != null && profileImage.isNotEmpty)
                                ? NetworkImage(profileImage)
                                : null,
                        child: (profileImage == null ||
                                profileImage.isEmpty)
                            ? Text(
                                name
                                    .trim()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isWallet
                                      ? Colors.green
                                      : Colors.blue,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
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
                backgroundImage: (s["profile_image"] != null &&
                        s["profile_image"].toString().isNotEmpty)
                    ? NetworkImage(s["profile_image"])
                    : null,

                backgroundColor:
                    (s["isWallet"] ?? true)
                        ? Colors.green.shade100
                        : Colors.blue.shade100,

                child: (s["profile_image"] == null ||
                        s["profile_image"].toString().isEmpty)
                    ? Icon(
                        (s["isWallet"] ?? true)
                            ? Icons.person
                            : Icons.account_balance,
                        color: (s["isWallet"] ?? true)
                            ? Colors.green
                            : Colors.blue,
                      )
                    : null,
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
          children: [
            const _PayOption(
              icon: Icons.flash_on,
              label: "Recharge",
              cashback: "5% cashback",
            ),
            const _PayOption(
              icon: Icons.play_circle_fill,
              label: "Google Play",
              cashback: "5% cashback",
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CashbackStoreScreen(
                      regId: widget.regId,
                    ),
                  ),
                );
              },
              child: const _PayOption(
                icon: Icons.card_giftcard,
                label: "Cashbacks",
                cashback: "Up to 20%",
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),
        
// ================= SPLIT PAYMENTS BUTTON =================
GestureDetector(
  onTap: () async {
    setState(() {
      showSplitSection = !showSplitSection;
    });

    if (showSplitSection) {
      await _loadSplitRequests();
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
      children: [
        const Icon(Icons.call_split, color: Color(0xFF4C6EF5)),
        const SizedBox(width: 12),

        const Expanded(
          child: Text(
            "Split Payments",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ===== UNPAID COUNT BADGE =====
        if (getUnpaidSplitCount() > 0)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              getUnpaidSplitCount().toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        Icon(
          showSplitSection
              ? Icons.keyboard_arrow_up
              : Icons.chevron_right,
        ),
      ],
    ),
  ),
),

const SizedBox(height: 12),

AnimatedSize(
  duration: const Duration(milliseconds: 350),
  curve: Curves.easeInOut,
  child: showSplitSection
      ? Container(
    height: 340,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 10),
      ],
    ),

    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: splitRequests.map((split) {


final members = split["members"] ?? [];



// ===== SAFE PAID CHECK =====
bool isPaidStatus(dynamic status) {
  if (status == null) return false;
  final s = status.toString().toLowerCase().trim();
  return s == "paid";
}

// ===== FIND MY MEMBER (FIXED KEY HERE) =====
Map<String, dynamic>? myMember;

try {
  myMember = members.firstWhere(
    (m) => m["reg_id"] == widget.regId,   
  );
} catch (_) {
  myMember = null;
}

// ===== USE BACKEND PAID FLAG (BEST METHOD) =====
final myPaid =
    myMember?["paid"] == true ||
    isPaidStatus(myMember?["status"]);

final myAmount = double.tryParse(
  (myMember?["amount"] ?? 0).toString(),
) ?? 0;

final insufficientBalance = balance < myAmount;


// ===== GROUP COMPLETED CHECK =====
final isCompleted = members.every(
  (m) => isPaidStatus(m["status"]),
);
final int creatorRegId =
    int.tryParse(split["creator_reg_id"].toString()) ?? -1;

final bool isCreator = creatorRegId == widget.regId;

final bool isClosed =
    split["closed"] == 1 ||
    split["closed"] == true;


      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===== HEADER =====
            Row(
              children: [

                CircleAvatar(
                  backgroundImage: (split["creator_image"] != null &&
                          split["creator_image"].toString().isNotEmpty)
                      ? NetworkImage(split["creator_image"])
                      : null,
                  child: (split["creator_image"] == null ||
                          split["creator_image"].toString().isEmpty)
                      ? Text(
                          (split["creator_name"] ?? "U")[0]
                              .toUpperCase(),
                        )
                      : null,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        split["creator_name"] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Total ₹${split["total_amount"]}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== STATUS BADGE =====
                if (isClosed)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Closed",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCompleted ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Text(
                      isCompleted ? "Completed" : "Pending",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),

                // ===== YOU PAID BADGE =====
                if (myPaid)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      "You Paid",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

              ],
            ),

            const SizedBox(height: 14),

            const Text(
              "Members",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // ===== MEMBERS LIST =====
            ...members.map<Widget>((m) {

              final paid = isPaidStatus(m["status"]);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [

                    CircleAvatar(
                      radius: 16,
                      backgroundImage: (m["profile_image"] != null &&
                              m["profile_image"].toString().isNotEmpty)
                          ? NetworkImage(m["profile_image"])
                          : null,
                      child: (m["profile_image"] == null ||
                              m["profile_image"].toString().isEmpty)
                          ? Text(
                              (m["name"] ?? "U")[0]
                                  .toUpperCase(),
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        m["name"] ?? "",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),

                    Text(
                      "₹${m["amount"]}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Icon(
                      paid
                          ? Icons.check_circle
                          : Icons.pending,
                      color: paid ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 10),

          // ===== PAY BUTTON =====
            Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ===== CREATOR CLOSE BUTTON =====
                if (isCreator && isCompleted && !isClosed)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        barrierColor: Colors.black54,
                        builder: (_) => Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                // ===== ICON =====
                                Container(
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8ECFF),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF4C6EF5),
                                    size: 30,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // ===== TITLE =====
                                const Text(
                                  "Close Split",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // ===== MESSAGE =====
                                const Text(
                                  "This split will be marked as closed.\nNo further payments will be allowed.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // ===== BUTTON ROW =====
                                Row(
                                  children: [

                                    // CANCEL BUTTON
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.grey.shade700,
                                          side: BorderSide(color: Colors.grey.shade300),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text(
                                          "Cancel",
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // CLOSE BUTTON
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4C6EF5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          elevation: 0,
                                        ),
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text(
                                          "Close Split",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      if (confirm != true) return;

                      final ok = await ApiService.closeSplit(
                        splitId: split["split_id"] ?? split["id"],
                        creatorRegId: widget.regId,
                      );

                      if (ok) {
                        await _loadSplitRequests();

                        if (!mounted) return;

                        await showDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierColor: Colors.black54,
                          builder: (_) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  // ===== GREEN SUCCESS ICON =====
                                  Container(
                                    height: 64,
                                    width: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 36,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // ===== TITLE =====
                                  const Text(
                                    "Split Closed",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // ===== MESSAGE =====
                                  const Text(
                                    "This split has been successfully closed.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  const SizedBox(height: 22),

                                  // ===== OK BUTTON =====
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4C6EF5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        elevation: 0,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        "Done",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text("Close Split"),
                  ),


                // ===== MEMBER PAY BUTTON =====
                if (!isCreator) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C6EF5),
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: (myPaid || insufficientBalance || isClosed)
                      ? null
                      : () async {

                          final verified = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PinVerifyScreen(
                                regId: widget.regId,
                                type: "wallet",
                                amount: myAmount,
                              ),
                            ),
                          );

                          if (verified != true) return;

                          try {

                            final res = await ApiService.paySplit(
                              splitMemberId: myMember?["id"],
                              payerRegId: widget.regId,
                            );

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentResultScreen(
                                amount: myAmount,
                                status: "success",

                                payeeName: split["creator_name"] ?? "",

                                payee: split["creator_upi"] != null &&
                                        split["creator_upi"].toString().isNotEmpty
                                    ? split["creator_upi"]
                                    : split["creator_mobile"] ?? "",

                                note: split["note"],
                                paymentMethod: "Wallet",
                                txnTime: DateTime.now(),
                                paymentType: "Wallet",
                                regId: widget.regId,
                                fullName: dashboardState?.widget.fullName ?? "",
                                mobile: dashboardState?.widget.mobile ?? "",
                                upiId: dashboardState?.widget.upiId,
                                walletStatus: dashboardState?.widget.walletStatus ?? "",
                                aadhaarVerified: dashboardState?.widget.aadhaarVerified ?? 0,
                                panVerified: dashboardState?.widget.panVerified ?? 0,
                                direction: "debit",
                                earnedPoints: res?["earned_points"],
                                rewardToken: res?["reward_token"],
                              ),
                              ),
                            );

                            await _loadSplitRequests();
                            await _loadBalance();

                            final dashboard =
                                context.findAncestorStateOfType<DashboardScreenState>();

                           await dashboard?.refreshWalletNow();
                            await dashboard?.refreshStudentState();
                            await dashboard?.loadUnreadCount();
                            await dashboard?.loadUnrevealedRewardsCount();

                            final rewardsView =
                                context.findAncestorStateOfType<_RewardsViewState>();

                            await rewardsView?.loadPendingDragRewards();


                          } catch (e) {

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentResultScreen(
                                  amount: myAmount,
                                  status: "failed",
                                  payeeName: split["creator_name"] ?? "",
                                  payee: split["creator_mobile"] ?? "",
                                  paymentType: "Wallet",
                                  regId: widget.regId,
                                  fullName: dashboardState?.widget.fullName ?? "",
                                  mobile: dashboardState?.widget.mobile ?? "",
                                  upiId: dashboardState?.widget.upiId,
                                  walletStatus: dashboardState?.widget.walletStatus ?? "",
                                  aadhaarVerified: dashboardState?.widget.aadhaarVerified ?? 0,
                                  panVerified: dashboardState?.widget.panVerified ?? 0,
                                  direction: "debit",
                                  
                                ),
                              ),
                            );

                          }
                      },


                    child: Text(
                      isClosed
                        ? "Closed"
                        : myPaid
                          ? "Paid"
                          : insufficientBalance
                            ? "Low Balance"
                            : "Pay"
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isCreator && insufficientBalance && !myPaid)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Insufficient wallet balance",
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList(),
      ),
    ),
)

      : const SizedBox(),
),


// ================= KYC CARD =================
  if (widget.kycProgress < 1.0)
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

            LiquidKycProgressBar(
              progress: widget.kycProgress,
            ),

            const SizedBox(height: 10),
            Text(
              getKycMessage(),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),



      ],
      )
    );
  }
}
class _ScanPayInner extends StatelessWidget {
  const _ScanPayInner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
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
            "Scan & Pay",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
class _ScannerInner extends StatelessWidget {
  const _ScannerInner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (_, value, __) {
              return Positioned(
                top: 12 + (value * 44),
                left: 8,
                right: 8,
                child: Container(
                  height: 2,
                  color: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
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
    final isDebit =
    latest["sender_reg_id"] == widget.regId &&
    latest["status"] == "success";

    if (isNew && (isCredit || isDebit)) {
    final double amount =
        double.tryParse(latest["amount"].toString()) ?? 0;

    showReceivedAnimation(amount);
    widget.onNewCredit();
    final dashboard =
context.findAncestorStateOfType<DashboardScreenState>();

await Future.wait([
  dashboard?.refreshWalletNow() ?? Future.value(),
  dashboard?.refreshAllCounts() ?? Future.value(),
]);


final rewardsView =
    context.findAncestorStateOfType<_RewardsViewState>();

await rewardsView?.loadPendingDragRewards();



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
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
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

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 16),
            ],
          ),
          child: Row(
            children: [

              /// Icon
              Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8ECFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: widget.walletStatus == "active"
                      ? const Color(0xFF4C6EF5)
                      : Colors.grey,
                ),
              ),

              const SizedBox(width: 16),

              /// Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Wallet PIN",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.walletStatus != "active"
                          ? "Activate wallet to set PIN"
                          : "Manage your wallet security PIN",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              /// Action Button
              GestureDetector(
                onTap: widget.walletStatus == "active"
                    ? () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PinSettingsScreen(
                              regId: widget.regId,
                              initialTab: "wallet",
                            ),
                          ),
                        );

                        if (result == true && mounted) {
                          final dashboardState =
                              context.findAncestorStateOfType<DashboardScreenState>();
                          dashboardState?.setState(() {
                            dashboardState.currentIndex = 1;
                          });
                        }
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.walletStatus == "active"
                        ? const Color(0xFF4C6EF5)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Manage",
                    style: TextStyle(
                      color: widget.walletStatus == "active"
                          ? Colors.white
                          : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _TransactionHistoryCard(
          loading: loadingTxns,
          transactions: transactions,
          regId: widget.regId,
        ),

      ],
    ),
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
                  "Wallet Transactions",
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
                     regId: regId,
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

    if (refreshed == true && mounted) {
      _loadBalance();

      final dashboardState =
          context.findAncestorStateOfType<DashboardScreenState>();
      dashboardState?.refreshWalletNow();
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
  child: widget.upiId.isEmpty
      ? GestureDetector(
          onTap: () {
            final dashboardState =
    context.findAncestorStateOfType<DashboardScreenState>();

if (dashboardState == null) return;

showCreateUpiDialog(
  context: context,
  regId: dashboardState.widget.regId,
  onSuccess: () {
    dashboardState.refreshStudentState();
  },
);

          },
          child: const Text(
            "+ Create UPI ID",
            style: TextStyle(
              color: Color(0xFF4C6EF5),
              fontWeight: FontWeight.w600,
            ),
          ),
        )
      : Row(
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

              if (widget.upiId.isEmpty) {
                final dashboardState =
    context.findAncestorStateOfType<DashboardScreenState>();

if (dashboardState == null) return;

showCreateUpiDialog(
  context: context,
  regId: dashboardState.widget.regId,
  onSuccess: () {
    dashboardState.refreshStudentState();
  },
);

                return;
              }
    final dashboardState =
    context.findAncestorStateOfType<DashboardScreenState>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyQrScreen(
                    name: widget.name,
                    upiId: widget.upiId,
                    walletActive: widget.walletStatus == "active",
                    profileImageUrl: dashboardState?.profileImageUrl,
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
// ================= REWARDS VIEW =================
const double kRewardCardHeight = 90;
const double kRewardCardRadius = 18;
class _RewardsView extends StatefulWidget {
  final int dashboardCount;

  const _RewardsView({
    required this.dashboardCount,
  });

  @override
  State<_RewardsView> createState() => _RewardsViewState();
}
class _RewardsViewState extends State<_RewardsView>
    with AutomaticKeepAliveClientMixin {

    List<dynamic> pendingDragRewards = [];
    bool loadingPendingRewards = true;
    bool revealingReward = false;

Future<void> loadPendingDragRewards() async {
  try {
    final dashboard =
        context.findAncestorStateOfType<DashboardScreenState>();

    if (dashboard == null) return;

    final data = await ApiService.getPendingDragRewards(
      dashboard.widget.regId,
    );

    if (!mounted) return;

    setState(() {
      pendingDragRewards = data;
      loadingPendingRewards = false;
    });

  } catch (_) {
    if (!mounted) return;
    setState(() {
      loadingPendingRewards = false;
    });
  }
}


  @override
  bool get wantKeepAlive => true;

 @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    loadPendingDragRewards();
  });
}

void openRewardsSheet() {

  final dashboard =
      context.findAncestorStateOfType<DashboardScreenState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (_) {

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (_, controller) {

          return RewardsViewAllSheet(
            scrollController: controller,
            regId: dashboard!.widget.regId,
          );
        },
      );
    },
  ).then((_) async {
    await dashboard?.loadUnrevealedRewardsCount();
    await loadPendingDragRewards();
  });
}


 @override
Widget build(BuildContext context) {
  super.build(context);
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // -------- Top categories --------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [

            /// CASH WON
            GestureDetector(
              onTap: () {
                final dashboard =
                    context.findAncestorStateOfType<DashboardScreenState>();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CashWonScreen(
                      regId: dashboard!.widget.regId,
                    ),
                  ),
                );
              },
              child: const _RewardCategory(
                icon: Icons.account_balance_wallet,
                label: "Cash won",
              ),
            ),

            /// COUPONS
            GestureDetector(
              onTap: () {
                final dashboard =
                    context.findAncestorStateOfType<DashboardScreenState>();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CouponsScreen(
                      regId: dashboard!.widget.regId,
                    ),
                  ),
                );
              },
              child: const _RewardCategory(
                icon: Icons.confirmation_number,
                label: "Coupons",
              ),
            ),

            /// VOUCHERS 
            GestureDetector(
              onTap: () {
                final dashboard =
                context.findAncestorStateOfType<DashboardScreenState>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyVouchersScreen(
                      regId: dashboard!.widget.regId,
                    ),
                  ),
                );

              },
              child: const _RewardCategory(
                icon: Icons.card_giftcard,
                label: "Vouchers",
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),


    /// ================= MY REWARDS =================
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [

    Row(
      children: [
        const Text(
          "My Rewards",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(width: 8),

        if (widget.dashboardCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.dashboardCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    ),

    GestureDetector(
      onTap: openRewardsSheet,
      child: const Text(
        "View all",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4C6EF5),
          letterSpacing: 0.3,
        ),
      ),
    ),
  ],
),


const SizedBox(height: 16),

/// ===== CONTENT =====
if (loadingPendingRewards)
  const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: CircularProgressIndicator(),
    ),
  )

else ...[

  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      widget.dashboardCount > 0
      ? widget.dashboardCount == 1
          ? "1 reward waiting to be revealed"
          : "${widget.dashboardCount} rewards waiting to be revealed"
      : "No pending rewards",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: widget.dashboardCount > 0
            ? Colors.black
            : Colors.grey,
      ),
    ),
  ),

],

        // -------- Featured Brands --------
        const Text(
          "Featured Brands",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _FeaturedBrandCard(title: "gamepass", cashback: "8% back"),
              _FeaturedBrandCard(title: "prime", cashback: "6% back"),
              _FeaturedBrandCard(title: "swiggy", cashback: "12% back"),
              _FeaturedBrandCard(title: "playstore", cashback: "5% back"),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // -------- Discounts --------
        const Text(
          "Discounts",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),

        GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78, 
        children: const [
          _DiscountTile("apple", "15% back"),
          _DiscountTile("playstore", "5% back"),
          _DiscountTile("amazon", "12% back"),
          _DiscountTile("gamepass", "8% back"),
          _DiscountTile("prime", "6% back"),
          _DiscountTile("mcdonalds", "18% back"),
          _DiscountTile("armani", "12% back"),
          _DiscountTile("reliance", "5% back"),
          _DiscountTile("mmt", "10% back"),
          _DiscountTile("bookmyshow", "10% back"),
        ],
      ),
        const SizedBox(height: 28),

        GestureDetector(
          onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BrandVouchersScreen(),
            ),
          );
        },
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFFFC107),
                width: 1.6,
              ),
            ),
            child: const Center(
              child: Text(
                "View All Vouchers",
                style: TextStyle(
                  color: Color(0xFFFFC107),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),


      ],
    )
    );
  }
}
// ============ Rewards category ===============
class _RewardCategory extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RewardCategory({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFFE8ECFF),
          child: Icon(icon, color: const Color(0xFF4C6EF5)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
/// ==== Feature Brand card ===============
class _FeaturedBrandCard extends StatelessWidget {
  final String title;
  final String cashback;

  const _FeaturedBrandCard({
    required this.title,
    required this.cashback,
  });

  Color get _brandColor {
    switch (title) {
      case "gamepass":
        return Colors.white;
      case "prime":
        return  Colors.white;
      case "swiggy":
        return Colors.white;
      case "playstore":
        return Colors.white;
      default:
        return const Color(0xFF4C6EF5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: _brandColor,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/brands/$title.png',
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cashback,
            style: const TextStyle(
              color: Color(0xFF1DB954),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ======== Discount Title ==================
class _DiscountTile extends StatelessWidget {
  final String title;
  final String cashback;

  const _DiscountTile(this.title, this.cashback);

  Color get _brandColor {
    switch (title) {
      case "apple":
        return Colors.white;
      case "playstore":
        return Colors.white;
      case "amazon":
        return Colors.white; 
      case "gamepass":
        return Colors.white;
      case "prime":
        return Colors.white;
      case "mcdonalds":
        return const Color(0xFF000000);
      case "armani":
       return Colors.white;
      case "reliance":
        return Colors.white;
      case "mmt":
        return const Color(0xFFE53935);
      case "bookmyshow":
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF4C6EF5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: _brandColor,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/brands/$title.png',
              height: 34,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          cashback,
          style: const TextStyle(
            color: Color(0xFF1DB954),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}


// =========== CARD VIEW ===================
class _CardView extends StatefulWidget {
  final int regId;
  final bool isKycCompleted;
  final double kycProgress;

  const _CardView({
    required this.regId,
    required this.isKycCompleted,
    required this.kycProgress,
  });


  @override
  State<_CardView> createState() => _CardViewState();
}

class _CardViewState extends State<_CardView> with RouteAware {
  bool showBalance = false;
  bool loading = true;
  double balance = 0.0;
  bool showFlipHint = false;
  bool _hintShownOnce = false;
  List<dynamic> cardTransactions = [];
  bool loadingCardTxns = true;
  bool isCardLocked = false;
  bool loadingLockState = true;
  bool isCardBlocked = false;
  bool isCardPending = false;

  String cardLast4 = "";
  String maskedCardNumber = "****";
  String cardType = "";
  String cardExpiry = "";



  void _showLockBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// Drag indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 24),

            /// Icon container (Dashboard style)
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isCardLocked
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
                size: 36,
                color: const Color(0xFF4C6EF5),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isCardLocked ? "Unlock Card?" : "Lock Card?",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              isCardLocked
                  ? "Your card will be enabled for ATM, POS and online transactions."
                  : "Your card will be temporarily disabled for ATM, POS and online transactions.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 28),

            /// Primary Button
            SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
              Navigator.pop(context); 

              _showLockProcessingSheet(
                locking: !isCardLocked,
              );
            },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C6EF5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isCardLocked ? "Yes, Unlock" : "Yes, Lock",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),


            const SizedBox(height: 12),

            /// Secondary Button (Dashboard style)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFE8ECFF),
                  foregroundColor: const Color(0xFF4C6EF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          ],
        ),
      );
    },
  );
}

void _showCardSecurityFloating(bool locked) {
  final overlay = Overlay.of(context);

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Icon(
                locked ? Icons.lock : Icons.lock_open,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  locked
                      ? "Your card has been locked"
                      : "Your card has been unlocked",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  Future.delayed(const Duration(seconds: 3), () {
    entry.remove();
  });
}

void _showLockProcessingSheet({
  required bool locking,
}) {

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) {

      bool apiCalled = false;
      bool done = false;
      String last4 = maskedCardNumber.replaceAll("**** ", "");

      return StatefulBuilder(
        builder: (context, setModalState) {

          /// CALL API ONLY ONCE
          if (!apiCalled) {
            apiCalled = true;

            Future(() async {

              try {

                final locked =
                    await ApiService.toggleCardLock(widget.regId);

                final fetchedLast4 =
                    await ApiService.getCardLast4(widget.regId);

                if (!mounted) return;

                setState(() => isCardLocked = locked);

                setModalState(() {
                  done = true;
                  last4 = fetchedLast4 ?? last4;
                });

                _showCardSecurityFloating(locked);

                final dashboard =
                    context.findAncestorStateOfType<DashboardScreenState>();
                await dashboard?.loadUnreadCount();

                await Future.delayed(const Duration(seconds: 2));

                if (Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop();
                }

              } catch (_) {
                if (Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop();
                }
              }

            });
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 34),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 28),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: done
                      ? Container(
                          key: const ValueKey(1),
                          height: 72,
                          width: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4C6EF5),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey(2),
                          height: 72,
                          width: 72,
                          child: CircularProgressIndicator(strokeWidth: 4),
                        ),
                ),

                const SizedBox(height: 24),

                Text(
                  done
                      ? "XXXX $last4 is now ${locking ? "locked" : "unlocked"}!"
                      : (locking ? "Locking your card..." : "Unlocking your card..."),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                if (done)
                  Text(
                    locking
                        ? "Your card is temporarily disabled."
                        : "Your card is now active for transactions.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}



  void _showCardSpendAnimation(double amount) {
  final overlay = Overlay.of(context);

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 90,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                "Card spent ₹${amount.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
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

Future<void> _loadCardLockState() async {
  try {

    /// CARD STATUS
    final status = await ApiService.getCardStatus(widget.regId);

    /// CARD DETAILS
    final cardRes = await ApiService.getLumeCard(widget.regId);

    if (!mounted) return;

    if (cardRes["card_exists"] == true) {

      final c = cardRes["card"];

      final last4 = c["last4"] ?? "";
      final network = c["network"] ?? "";
      final expiry = c["expiry"] ?? "";

     setState(() {
      isCardLocked = status["is_locked"] == true;
      isCardBlocked = status["is_blocked"] == true;
      isCardPending = status["card_status"] == "pending";

      loadingLockState = false;


        /// IMPORTANT VALUES FOR UI
        maskedCardNumber = last4.isEmpty ? "****" : "**** $last4";
        cardType = network;
        cardExpiry = expiry;
      });

    } else {
      setState(() {
        loadingLockState = false;
      });
    }

  } catch (e) {
    if (!mounted) return;
    setState(() => loadingLockState = false);
  }
}




  Future<void> _loadCardTransactions() async {
  setState(() => loadingCardTxns = true);

  try {
    final data =
        await ApiService.getCardTransactions(widget.regId);

    final filtered = data
        .where((t) => t["txn_type"] == "spend")
        .toList();

    if (!mounted) return;

    final dashboard =
        context.findAncestorStateOfType<DashboardScreenState>();

    /// ===== CHECK IF NEW SPEND TRANSACTION ARRIVED =====
if (filtered.isNotEmpty) {

  final latestNew = filtered.first;

  if (cardTransactions.isNotEmpty) {

    final latestOld = cardTransactions.first;

    final bool isNew =
        latestNew["id"] != latestOld["id"];

    if (isNew) {

      final double amount =
          double.tryParse(latestNew["amount"].toString()) ?? 0;

      _showCardSpendAnimation(amount);

      await Future.wait([
        dashboard?.loadUnreadCount() ?? Future.value(),
        dashboard?.refreshWalletNow() ?? Future.value(),
      ]);
    }
  }
}


    /// ===== UPDATE STATE SAFELY =====
   setState(() {
      cardTransactions = filtered;
      loadingCardTxns = false;
    });


  } catch (e) {
    if (!mounted) return;

    setState(() => loadingCardTxns = false);
  }
}



  @override
  void initState() {
    super.initState();
    _loadCardTransactions();
    _loadCardLockState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hintShownOnce) {
        triggerFlipHint();
        _hintShownOnce = true;
      }
    });

    _loadBalance();
  }


  @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    }

  @override
    void dispose() {
      routeObserver.unsubscribe(this);
      super.dispose();
    }

  @override
  void didPopNext() {
    _loadCardLockState();
  }


  void triggerFlipHint() {
  setState(() {
    showFlipHint = true;
  });

  Future.delayed(const Duration(seconds: 3), () {
    if (!mounted) return;
    setState(() {
      showFlipHint = false;
    });
  });
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

Widget getCardLogo() {

  String asset = "assets/card/default.png";

  switch (cardType.toLowerCase()) {
    case "visa":
      asset = "assets/card/visa.png";
      break;

    case "mastercard":
      asset = "assets/card/mastercard.png";
      break;

    case "rupay":
      asset = "assets/card/rupay.png";
      break;
  }

  return Image.asset(
    asset,
    width: 34,
    height: 22,
    fit: BoxFit.contain,
  );
}




  Widget _buildLockedKycCard() {
  return GestureDetector(
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
        final dashboard =
            context.findAncestorStateOfType<DashboardScreenState>();
        await dashboard?.refreshStudentState();
      }
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 16),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 36,
              color: Color(0xFF4C6EF5),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            "Unlock Card Feature",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Complete your KYC to unlock Lume Card access",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: widget.kycProgress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(
                Color(0xFF4C6EF5),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "${(widget.kycProgress * 100).toInt()}% completed",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4C6EF5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              "Complete KYC",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [

        // ===== CARD BALANCE STRIP =====
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 20),
            ],
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// KYC WARNING
            if (!widget.isKycCompleted)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Complete your KYC to get LUME Card",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),



            /// CARD INFO ROW
            if (widget.isKycCompleted)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Row(
                    children: [
                      getCardLogo(),
                      const SizedBox(width: 10),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            maskedCardNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCardBlocked
                                  ? Colors.red.shade50
                                  : isCardPending
                                      ? Colors.orange.shade50
                                      : const Color(0xFFE8ECFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isCardBlocked
                                  ? "Blocked"
                                  : isCardPending
                                      ? "Awaiting Activation"
                                      : "Active",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isCardBlocked
                                    ? Colors.red
                                    : isCardPending
                                        ? Colors.orange
                                        : const Color(0xFF4C6EF5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "VALID THRU",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cardExpiry.isEmpty ? "--/--" : cardExpiry,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),


            if (widget.isKycCompleted) const SizedBox(height: 16),
            /// BALANCE ROW
            Row(
              children: [

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Card Balance",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: () {
                        if (loading) return;
                        setState(() => showBalance = !showBalance);
                      },
                      child: loading
                          ? const Text(
                              "Loading...",
                              style: TextStyle(
                                fontSize: 24,
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

                GestureDetector(
                  onTap: () {
                    final dashboard =
                        context.findAncestorStateOfType<DashboardScreenState>();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddMoneyScreen(
                          regId: widget.regId,
                          fullName: dashboard?.widget.fullName ?? "",
                          mobile: dashboard?.widget.mobile ?? "",
                          upiId: dashboard?.widget.upiId ?? "",
                          walletStatus: dashboard?.walletStatus ?? "active",
                          aadhaarVerified: dashboard?.widget.aadhaarVerified ?? 1,
                          panVerified: dashboard?.widget.panVerified ?? 1,
                        ),
                      ),
                    ).then((_) => _loadBalance());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8ECFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Color(0xFF4C6EF5), size: 18),
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
                ),
              ],
            ),
          ],
        ),

        ),

        // ===== CARD CENTER SECTION =====
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [

                // Accent indicator (matches dashboard theme)
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4C6EF5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                const SizedBox(width: 10),

                const Text(
                  "CARD CENTER",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isCardPending)
        Container(
         margin: const EdgeInsets.fromLTRB(0, 14, 0, 18),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8ECFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                "Your replacement card is ready",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                "Set your card PIN to activate it",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C6EF5),
                ),
                onPressed: () async {
                  final activated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PinSettingsScreen(
                        regId: widget.regId,
                        initialTab: "card",
                        forceSetup: true,
                      ),
                    ),
                  );

                  /// reload card state after PIN set
                  if (activated == true) {
                    await _loadCardLockState();
                    setState(() {});
                  }
                },
                child: const Text("Set PIN & Activate"),
              )
            ],
          ),
        ),


       const SizedBox(height: 18),
        widget.isKycCompleted
            ? Column(
                children: [
                  const _LumeVerticalFlipCard(),
                  const SizedBox(height: 10),

                  AnimatedOpacity(
                    opacity: showFlipHint ? 1 : 0,
                    duration: const Duration(milliseconds: 5000),
                    child: const Text(
                      "Tap card to flip",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [

                      _CardActionButton(
                        icon: Icons.visibility_outlined,
                        label: "View Details",
                        onTap: () {
                          final dashboard =
                              context.findAncestorStateOfType<DashboardScreenState>();

                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => _CardDetailsBottomSheet(
                              regId: dashboard!.widget.regId,
                            ),
                          );
                        },

                      ),

                      _CardActionButton(
                      icon: isCardPending
                          ? Icons.lock_outline
                          : isCardBlocked
                              ? Icons.block
                              : (isCardLocked ? Icons.lock : Icons.lock_open),
                      label: isCardPending
                          ? "Set PIN"
                          : isCardBlocked
                              ? "Blocked"
                              : (isCardLocked ? "Unlock Card" : "Lock Card"),
                      onTap: isCardPending
                          ? () async {
                              final activated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PinSettingsScreen(
                                    regId: widget.regId,
                                    initialTab: "card",
                                    forceSetup: true,
                                  ),
                                ),
                              );

                              if (activated == true) {
                                await _loadCardLockState();
                                setState(() {});
                              }
                            }
                          : (isCardBlocked ? () {} : _showLockBottomSheet),
                      disabled: isCardBlocked,
                    ),



                      _CardActionButton(
                        icon: Icons.settings_outlined,
                        label: "Settings",
                        onTap: () async {

                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CardCentreScreen(
                                regId: widget.regId,
                                maskedNumber: maskedCardNumber,
                              ),
                            ),
                          );

                          if (updated != null && mounted) {
                          final dashboard =
                              context.findAncestorStateOfType<DashboardScreenState>();

                          await dashboard?.refreshStudentState();
                          await _loadCardLockState();  
                        }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// ===== CARD TRANSACTIONS TILE =====
                  _CardTransactionHistoryCard(
                    loading: loadingCardTxns,
                    transactions: cardTransactions,
                    regId: widget.regId,  
                  ),


                  const SizedBox(height: 20),
                  _CardPinSection(
                    regId: widget.regId,
                  ),


                ],
              )
            : _buildLockedKycCard(),


        ],
      ),
      
    );
  }
}

class _LumeVerticalFlipCard extends StatefulWidget {
  const _LumeVerticalFlipCard({super.key});

  @override
  State<_LumeVerticalFlipCard> createState() => _LumeVerticalFlipCardState();
}

class _LumeVerticalFlipCardState extends State<_LumeVerticalFlipCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isFront = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _flipCard,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {

            final angle = _animation.value * 3.1416;
            final isBack = _animation.value > 0.5;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(3.1416),
                      child: _buildBackCard(),
                    )
                  : _buildFrontCard(),
            );
          },
        ),
      ),
    );
  }

  // ================= FRONT =================
  Widget _buildFrontCard() {
    return Container(
      height: 380,
      width: 240,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4C6EF5),
            Color(0xFF7A95FF),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Icon(
            Icons.credit_card,
            color: Colors.white,
            size: 28,
          ),

          const Spacer(),

          const Text(
            "LUME",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "Visa Prepaid",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),

          const Spacer(),

        ],
      ),
    );
  }

  // ================= BACK =================
  Widget _buildBackCard() {
    return Container(
      height: 380,
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),

      child: Column(
        children: [

          // Magnetic Strip
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(6),
            ),
          ),

          const SizedBox(height: 24),

          // CVV Strip
          Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                color: Colors.white,
                child: const Text(
                  "***",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool disabled;

  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
  });


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [

          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: disabled ? Colors.grey.shade200 : const Color(0xFFE8ECFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: disabled ? Colors.grey : const Color(0xFF4C6EF5),
            ),

          ),

          const SizedBox(height: 6),

          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: disabled ? Colors.grey : Colors.black,
            ),
          ),

        ],
      ),
    );
  }
}

class _CardDetailsBottomSheet extends StatefulWidget {
  final int regId;

  const _CardDetailsBottomSheet({
    super.key,
    required this.regId,
  });

  @override
  State<_CardDetailsBottomSheet> createState() =>
      _CardDetailsBottomSheetState();
}

class _CardDetailsBottomSheetState
    extends State<_CardDetailsBottomSheet> {

  bool loading = true;
  bool showCvvOnly = false;
  bool cardCopied = false;
  bool isBlocked = false;
  bool loadingStatus = true;

  String cardNumber = "";
  String expiry = "";
  String cvv = "";

  String maskCard(String number) {
    if (number.length < 4) return "****";
    return "**** **** **** ${number.substring(number.length - 4)}";
  }

  String maskExpiry() => "**/**";
  String maskCvv() => "***";

  @override
  void initState() {
    super.initState();
    _loadCardDetails();
    _loadBlockStatus();
  }

  Future<void> _loadCardDetails() async {
    try {
      final data =
          await ApiService.getLumeCardDetails(widget.regId);

      if (!mounted) return;

      setState(() {
        cardNumber = data["card_number"] ?? "";
        final month = data["expiry_month"]?.toString() ?? "";
        final year = data["expiry_year"]?.toString() ?? "";

        expiry = "$month/$year";

        cvv = data["cvv"] ?? "";
        loading = false;
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _loadBlockStatus() async {
  try {
    final status = await ApiService.getCardStatus(widget.regId);

    if (!mounted) return;

    setState(() {
      isBlocked = status["is_blocked"] == true;
      loadingStatus = false;
    });
  } catch (_) {
    if (!mounted) return;
    setState(() => loadingStatus = false);
  }
}


  void copyCardNumber() async {
  await Clipboard.setData(ClipboardData(text: cardNumber));

  setState(() {
    cardCopied = true;
  });

  Future.delayed(const Duration(seconds: 2), () {
    if (!mounted) return;
    setState(() {
      cardCopied = false;
    });
  });
}


  @override
  Widget build(BuildContext context) {
    final bool maskOthers = showCvvOnly;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: loading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// Drag Handle
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const Text(
                  "Card Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (!loadingStatus && isBlocked)
                Container(
                  margin: const EdgeInsets.only(top: 14, bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.block, color: Color(0xFF4C6EF5)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "This card is blocked",
                          style: TextStyle(
                            color: Color(0xFF4C6EF5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),


                const SizedBox(height: 24),

                /// CARD NUMBER
                _detailTile(
                  label: "Card Number",
                  value: maskOthers
                      ? maskCard(cardNumber)
                      : _formatCardNumber(cardNumber),
                  trailing: IconButton(
                    icon: Icon(
                      cardCopied ? Icons.check_circle : Icons.copy,
                      size: 18,
                      color: cardCopied ? Colors.green : Colors.black,
                    ),
                    onPressed: copyCardNumber,
                  ),

                ),

                const SizedBox(height: 14),

                /// EXPIRY
                _detailTile(
                  label: "Expiry",
                  value: maskOthers
                      ? maskExpiry()
                      : expiry,
                ),

                const SizedBox(height: 14),

                /// CVV + EYE
                _detailTile(
                  label: "CVV",
                  value: maskOthers
                      ? cvv
                      : maskCvv(),
                  trailing: IconButton(
                    icon: Icon(
                      maskOthers
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        showCvvOnly = !showCvvOnly;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  String _formatCardNumber(String number) {
    if (number.length != 16) return number;

    return "${number.substring(0, 4)} "
        "${number.substring(4, 8)} "
        "${number.substring(8, 12)} "
        "${number.substring(12)}";
  }

  Widget _detailTile({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

class _CardTransactionHistoryCard extends StatelessWidget {
  final bool loading;
  final List<dynamic> transactions;
  final int regId;

  const _CardTransactionHistoryCard({
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
               initialTab: "card",
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

            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Card Transactions",
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

            /// CONTENT
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "No card transactions yet",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: transactions
                    .take(5)
                    .map<Widget>((t) => CardTransactionTile(
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

class _CardPinSection extends StatefulWidget {
  final int regId;

  const _CardPinSection({
    required this.regId,
  });

  @override
  State<_CardPinSection> createState() => _CardPinSectionState();
}

class _CardPinSectionState extends State<_CardPinSection> {

  bool pinSet = false;
  bool loading = true;
  bool cardPending = false;

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
  try {

    final pinRes = await ApiService.getPinStatus(widget.regId);
    final cardStatus = await ApiService.getCardStatus(widget.regId);

    if (!mounted) return;

    final bool pending = cardStatus["card_status"] == "pending";

    setState(() {
      cardPending = pending;
      pinSet = pending ? false : (pinRes["card"] == true);

      loading = false;
    });

  } catch (_) {
    if (!mounted) return;
    setState(() => loading = false);
  }
}


  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 16),
        ],
      ),
      child: Row(
        children: [

          Container(
            height: 48,
            width: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE8ECFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              color: Color(0xFF4C6EF5),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Card PIN",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  loading
                      ? "Checking..."
                      : cardPending
                      ? "Set a new PIN to activate your card"
                      : pinSet
                          ? "Manage Your Card Security PIN"
                          : "Set your card PIN",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: loading
                ? null
                : () async {

                    final activated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PinSettingsScreen(
                            regId: widget.regId,
                            initialTab: "card",
                          ),
                        ),
                      );

                      _loadPinStatus();

                      if (activated == true) {
                        final dashboard =
                            context.findAncestorStateOfType<DashboardScreenState>();
                        dashboard?.refreshStudentState();
                      }

                    _loadPinStatus();
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF4C6EF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
              cardPending ? "Activate" : (pinSet ? "Manage" : "Set"),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

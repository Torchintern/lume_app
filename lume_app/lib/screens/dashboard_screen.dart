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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lume_app/widgets/transaction_tile.dart';
import 'pin_settings_screen.dart';
import 'dart:io';
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
class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {

  final LocalAuthentication _auth = LocalAuthentication();
  bool _authInProgress = false;
  bool _unlocked = false;
  bool _checkingLock = true;
  static const int _gracePeriodSeconds = 45;
  DateTime? _lastPausedTime;
  int currentIndex = 2;
  int unreadCount = 0;
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
    if (widget.fullName.trim().isEmpty) return "XO";
    final parts = widget.fullName.trim().split(" ");
    return parts.length >= 2
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : widget.fullName.substring(0, 2).toUpperCase();
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
  final walletState =
      context.findAncestorStateOfType<_WalletViewState>();
  walletState?.refreshAll();
  await _refreshStudentState();
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
  await _refreshStudentState();
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
  _loadUnreadCount();
  _refreshStudentState();
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
                    _refreshStudentState();
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
                      _refreshStudentState();
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
                  subtitle: const Text("Customer Support"),
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
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Builder(
                      builder: (context) => GestureDetector(
                        onTap: () async {
                          _scaffoldKey.currentState?.closeDrawer();
                          await _refreshStudentState();
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
                            _loadUnreadCount();
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
                    await _refreshStudentState();
                  },

                  children: [
                    const Center(child: Text("Card Coming Soon")),

                    _WalletView(
                      regId: widget.regId,
                      walletStatus: walletStatus,
                      fullName: widget.fullName,
                      upiId: upiId ?? "",
                      mobile: widget.mobile,
                      aadhaarVerified: widget.aadhaarVerified,
                      panVerified: widget.panVerified,
                      onNewCredit: _loadUnreadCount,
                    ),

                    _PayView(
                      regId: widget.regId,
                      kycProgress: kycProgress,
                      isKycCompleted: isKycCompleted,
                      onKycUpdated: _refreshStudentState,
                    ),

                    const _RewardsView(),
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

          await _refreshStudentState();
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
  
  const _PayView({
    required this.regId,
    required this.kycProgress,
    required this.isKycCompleted,
    required this.onKycUpdated,
  });

  @override
  State<_PayView> createState() => _PayViewState();
}
class _PayViewState extends State<_PayView>
    with SingleTickerProviderStateMixin {
  double balance = 0.0;
  bool loading = true;
  bool showBalance = false;
  bool showScanner = false;
  final TextEditingController upiController = TextEditingController();
  List<dynamic> paySuggestions = [];
  List<dynamic> recentPayees = [];
  bool loadingRecents = true;

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

  @override
  void initState() {
    super.initState();
     _startInnerAnimationLoop();
     _loadRecentPayees();
     _loadBalance();
     upiController.addListener(() {
    if (mounted) setState(() {});
  });
  }
  @override
  void dispose() {
    super.dispose();
  }

  void _startInnerAnimationLoop() async {
  while (mounted) {
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
        context.findAncestorStateOfType<_DashboardScreenState>();

    if (dashboardState == null || 
      dashboardState.upiId == null ||
      dashboardState.upiId!.isEmpty) {
    showCreateUpiDialog(
      context: context,
      regId: widget.regId,
      onSuccess: () {
    if (dashboardState != null) {
      dashboardState._refreshStudentState();
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
        context.findAncestorStateOfType<_DashboardScreenState>();
    if (dashboardState != null) {
  await dashboardState.refreshWalletNow();
  await dashboardState._refreshStudentState();

  dashboardState.setState(() {});
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
      context.findAncestorStateOfType<_DashboardScreenState>();
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
        dashboardState._refreshStudentState();
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
        context.findAncestorStateOfType<_DashboardScreenState>();

    if (dashboardState == null ||
        dashboardState.upiId == null ||
        dashboardState.upiId!.isEmpty) {
      showCreateUpiDialog(
        context: context,
        regId: widget.regId,
        onSuccess: () {
          dashboardState?._refreshStudentState();
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
      await dashboardState._refreshStudentState();
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
                    builder: (_) => CashbackStoreScreen(),
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

    final dashboardState =
        context.findAncestorStateOfType<_DashboardScreenState>();

    await dashboardState?.refreshWalletNow();
    await dashboardState?._refreshStudentState();
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

        const SizedBox(height: 16),

        _TransactionHistoryCard(
          loading: loadingTxns,
          transactions: transactions,
          regId: widget.regId,
        ),

        const SizedBox(height: 16),

        GestureDetector(
          onTap: widget.walletStatus == "active"
              ? () async {
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
                }
              : null,
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
                Icon(
                  widget.walletStatus == "active"
                      ? Icons.lock_open
                      : Icons.lock_outline,
                  color: widget.walletStatus == "active"
                      ? const Color(0xFF4C6EF5)
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Wallet PIN",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.walletStatus == "active"
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                      if (widget.walletStatus != "active")
                        const Text(
                          "Activate wallet to set PIN",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: widget.walletStatus == "active"
                      ? Colors.black
                      : Colors.grey,
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

    if (refreshed == true && mounted) {
      _loadBalance();

      final dashboardState =
          context.findAncestorStateOfType<_DashboardScreenState>();
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
    context.findAncestorStateOfType<_DashboardScreenState>();

if (dashboardState == null) return;

showCreateUpiDialog(
  context: context,
  regId: dashboardState.widget.regId,
  onSuccess: () {
    dashboardState._refreshStudentState();
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
    context.findAncestorStateOfType<_DashboardScreenState>();

if (dashboardState == null) return;

showCreateUpiDialog(
  context: context,
  regId: dashboardState.widget.regId,
  onSuccess: () {
    dashboardState._refreshStudentState();
  },
);

                return;
              }
    final dashboardState =
    context.findAncestorStateOfType<_DashboardScreenState>();
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
  const _RewardsView();

  @override
  State<_RewardsView> createState() => _RewardsViewState();
}
class _RewardsViewState extends State<_RewardsView>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

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
            const _RewardCategory(
              icon: Icons.account_balance_wallet,
              label: "Cash won",
            ),
            const _RewardCategory(
              icon: Icons.confirmation_number,
              label: "Coupons",
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyVouchersScreen(),
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

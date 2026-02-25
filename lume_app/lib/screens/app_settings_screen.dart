import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsScreen extends StatefulWidget {
  final int userId;

  const AppSettingsScreen({super.key, required this.userId});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

bool appLockEnabled = false;
bool biometricEnabled = false;
late String appLockKey;
late String biometricKey;

@override
void initState() {
  super.initState();
  appLockKey = "app_lock_${widget.userId}";
  biometricKey = "biometric_${widget.userId}";
  _loadSecurityPrefs();
}

Future<void> _loadSecurityPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    appLockEnabled = prefs.getBool(appLockKey) ?? false;
    biometricEnabled = prefs.getBool(biometricKey) ?? false;
  });
}

Future<bool> _authenticate({required bool biometricOnly}) async {
  try {
    return await _auth.authenticate(
      localizedReason: 'Authenticate to secure Lume app',
      options: AuthenticationOptions(
        biometricOnly: biometricOnly,
        stickyAuth: true,
      ),
    );
  } catch (_) {
    return false;
  }
}

Future<void> _toggleAppLock(bool value) async {
  if (value) {
    final success = await _authenticate(biometricOnly: false);
    if (!success) return;
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(appLockKey, value);
  if (!value) {
    await prefs.setBool(biometricKey, false);
  }

  setState(() {
    appLockEnabled = value;
    if (!value) biometricEnabled = false;
  });
}

Future<void> _toggleBiometric(bool value) async {
  if (value) {
    final canCheck = await _auth.canCheckBiometrics;
    if (!canCheck) return;

    final success = await _authenticate(biometricOnly: true);
    if (!success) return;
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(biometricKey, value);
  await prefs.setBool(appLockKey, true);

  setState(() {
    biometricEnabled = value;
    if (value) appLockEnabled = true;
  });
}


  Future<void> _openAppInfo() async {
  if (!Platform.isAndroid) return;

  final packageInfo = await PackageInfo.fromPlatform();
  final packageName = packageInfo.packageName;

  final intent = AndroidIntent(
    action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
    data: 'package:$packageName',
    flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
  );

  await intent.launch();
}


  // ================= LANGUAGE BOTTOM SHEET =================
  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
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

              const SizedBox(height: 20),

              ListTile(
                title: const Text(
                  "English",
                  style: TextStyle(fontSize: 16),
                ),
                trailing: const Icon(
                  Icons.check,
                  color: Color(0xFF4C6EF5),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ================= THEME BOTTOM SHEET =================
  void _showThemeBottomSheet(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final currentTheme = themeProvider.themeMode;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
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

              const SizedBox(height: 20),

              // ================= LIGHT =================
              ListTile(
                title: const Text(
                  "Light",
                  style: TextStyle(fontSize: 16),
                ),
                trailing: currentTheme == ThemeMode.light
                    ? const Icon(Icons.check, color: Color(0xFF4C6EF5))
                    : null,
                onTap: () {
                  themeProvider.setTheme(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),

              // ================= DARK =================
              ListTile(
                title: const Text(
                  "Dark",
                  style: TextStyle(fontSize: 16),
                ),
                trailing: currentTheme == ThemeMode.dark
                    ? const Icon(Icons.check, color: Color(0xFF4C6EF5))
                    : null,
                onTap: () {
                  themeProvider.setTheme(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),

              // ================= SYSTEM =================
              ListTile(
                title: const Text(
                  "Same as device setting",
                  style: TextStyle(fontSize: 16),
                ),
                trailing: currentTheme == ThemeMode.system
                    ? const Icon(Icons.check, color: Color(0xFF4C6EF5))
                    : null,
                onTap: () {
                  themeProvider.setTheme(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget settingTile({
  required IconData icon,
  required String title,
  required String subtitle,
  VoidCallback? onTap,
  Widget? trailing,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 12),
      ],
    ),
    child: ListTile(
      leading: Container(
        height: 44,
        width: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFE8ECFF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Color(0xFF4C6EF5)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}


  // ================= MAIN UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: const Color(0xFFF6F7FB),
    appBar: AppBar(
    title: const Text("App Settings"),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================= NOTIFICATIONS =================
          settingTile(
            icon: Icons.notifications_outlined,
            title: "Notifications",
            subtitle: "Manage push notifications",
            onTap: _openAppInfo,
          ),
          // ================= THEME =================
          settingTile(
            icon: Icons.palette_outlined,
            title: "Theme",
            subtitle: "Light / Dark mode",
            onTap: () => _showThemeBottomSheet(context),
          ),

          // ================= LANGUAGE =================
          settingTile(
            icon: Icons.language_outlined,
            title: "Language",
            subtitle: "Change app language",
            onTap: () => _showLanguageBottomSheet(context),
          ),

          const SizedBox(height: 16),

        // ================= SECURITY HEADING =================
        Row(
        children: [
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
            "SECURITY",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),


        // ================= APP LOCK =================
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.lock_outline, color: Color(0xFF4C6EF5)),
            title: const Text("App Lock", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("Require screen lock to open app"),
            value: appLockEnabled,
            onChanged: _toggleAppLock,
          ),
        ),


        // ================= BIOMETRIC =================
        Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 12),
              ],
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                height: 44,
                width: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8ECFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint,
                  color: Color(0xFF4C6EF5),
                ),
              ),
              title: const Text(
                "Biometric Unlock",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text("Use fingerprint or face ID"),
              value: biometricEnabled,
              onChanged: appLockEnabled ? _toggleBiometric : null,
            ),
          ),
        ],
      ),
    );
  }
}
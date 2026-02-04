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
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

bool appLockEnabled = false;
bool biometricEnabled = false;

@override
void initState() {
  super.initState();
  _loadSecurityPrefs();
}

Future<void> _loadSecurityPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    appLockEnabled = prefs.getBool("app_lock") ?? false;
    biometricEnabled = prefs.getBool("biometric") ?? false;
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
  await prefs.setBool("app_lock", value);

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
  await prefs.setBool("biometric", value);

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

  // ================= MAIN UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================= NOTIFICATIONS =================
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text("Notifications"),
            subtitle: const Text("Manage push notifications"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await _openAppInfo();
            },
          ),

          const Divider(),

          // ================= THEME =================
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text("Theme"),
            subtitle: const Text("Light / Dark mode"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showThemeBottomSheet(context);
            },
          ),

          const Divider(),

          // ================= LANGUAGE =================
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text("Language"),
            subtitle: const Text("Change app language"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showLanguageBottomSheet(context);
            },
          ),

          const Divider(),
          const SizedBox(height: 16),

        // ================= SECURITY HEADING =================
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Security",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),

        // ================= APP LOCK =================
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.lock_outline),
          title: const Text("App Lock"),
          subtitle: const Text("Require screen lock to open app"),
          value: appLockEnabled,
          onChanged: _toggleAppLock,
        ),

        // ================= BIOMETRIC =================
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.fingerprint),
          title: const Text("Biometric Unlock"),
          subtitle: const Text("Use fingerprint or face ID"),
          value: biometricEnabled,
          onChanged: appLockEnabled ? _toggleBiometric : null,
        ),

        ],
      ),
    );
  }
}

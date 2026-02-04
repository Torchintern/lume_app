import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockGuard {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> shouldLock() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("app_lock") ?? false;
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to open Lume',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

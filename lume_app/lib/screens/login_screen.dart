import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/otp_bottom_sheet.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController controller = TextEditingController();
  bool loading = false;
  String message = "";

  Color get messageColor {
    if (message.toLowerCase().contains("sent") ||
        message.toLowerCase().contains("success")) {
      return Colors.green;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      body: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 25,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ================= Title =================
              const Text(
                "LUME",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 14),

              // ================= Icon =================
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFE8F0FF),
                child: Icon(
                  Icons.school,
                  color: Color(0xFF0A66FF),
                  size: 28,
                ),
              ),

              // ================= Inline Message =================
              if (message.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: messageColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ================= Input =================
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "Mobile Number or Email",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 20),

              // ================= SEND OTP =================
              loading
                  ? const CircularProgressIndicator()
                  : PrimaryButton(
                      text: "SEND OTP",
                      enabled: controller.text.isNotEmpty,
                      onPressed: () async {
                        try {
                          setState(() {
                            loading = true;
                            message = "";
                          });

                          await ApiService.sendLoginOtp(controller.text);

                          setState(() {
                            loading = false;
                            message = "OTP sent";
                          });

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(26),
                              ),
                            ),
                            builder: (_) => OTPBottomSheet(
                              onVerify: (otp) async {
                                final res =
                                    await ApiService.verifyLoginOtp(
                                  controller.text,
                                  otp,
                                );

                                final dynamic rawRegId = res["reg_id"];
                                if (rawRegId == null) {
                                  setState(() {
                                    message =
                                        "Account data error. Please contact support.";
                                  });
                                  return;
                                }

                                final int regId = rawRegId is int
                                    ? rawRegId
                                    : int.tryParse(rawRegId.toString()) ?? -1;

                                if (regId <= 0) {
                                  setState(() {
                                    message =
                                        "Invalid account data. Please try again.";
                                  });
                                  return;
                                }

                                // CLOSE OTP SHEET SAFELY
                                if (Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).canPop()) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop();
                                }

                                if (!mounted) return;

                                // ✅ SAFE NAVIGATION (NO CRASH)
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => DashboardScreen(
                                      regId: regId,
                                      fullName: res["full_name"] ?? "",
                                      mobile:
                                          res["mobile"] ?? controller.text,
                                      upiId: res["upi_id"],
                                      walletStatus:
                                          res["wallet_status"] ?? "inactive",
                                      aadhaarVerified:
                                          res["aadhaar_verified"] == 1 ? 1 : 0,
                                      panVerified:
                                          res["pan_verified"] == 1 ? 1 : 0,
                                    ),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          );
                        } catch (_) {
                          setState(() {
                            loading = false;
                            message = "Number / Email not registered";
                          });
                        }
                      },
                    ),

              const SizedBox(height: 20),

              // ================= Register =================
              const Text(
                "Not yet registered to LUME?",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Register",
                  style: TextStyle(
                    color: Color(0xFF0A66FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

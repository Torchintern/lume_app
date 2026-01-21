import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/otp_bottom_sheet.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController universityCtrl = TextEditingController();
  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  bool mobileVerified = false;
  bool emailVerified = false;
  bool loading = false;
  String message = "";

  List<dynamic> universities = [];

  Color get messageColor {
    if (message.toLowerCase().contains("success") ||
        message.toLowerCase().contains("sent") ||
        message.toLowerCase().contains("verified")) {
      return Colors.green;
    }
    return Colors.red;
  }

  @override
  void initState() {
    super.initState();
    loadUniversities();
  }

  Future<void> loadUniversities() async {
    try {
      universities = await ApiService.getUniversities();
      setState(() {});
    } catch (_) {
      setState(() => message = "Failed to load universities");
    }
  }

  bool get canRegister => mobileVerified && emailVerified;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF), // light blue background
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
          child: SingleChildScrollView(
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

                const SizedBox(height: 22),

                // ================= University =================
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue value) {
                    if (value.text.isEmpty) return [];
                    return universities
                        .map((u) => u["name"].toString())
                        .where((u) =>
                            u.toLowerCase().contains(value.text.toLowerCase()))
                        .toList();
                  },
                  onSelected: (value) => universityCtrl.text = value,
                  fieldViewBuilder: (context, controller, focusNode, _) {
                    universityCtrl.text = controller.text;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: "College / University Name",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 15),

                // ================= Mobile =================
                TextField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: InputDecoration(
                    hintText: "Mobile Number",
                    counterText: "",
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    suffixIcon: mobileVerified
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : mobileCtrl.text.length == 10
                            ? TextButton(
                                child: const Text("SEND OTP"),
                                onPressed: () async {
                                  try {
                                    setState(() => message = "");

                                    await ApiService.sendRegisterOtp(
                                      mobile: mobileCtrl.text,
                                      email: emailCtrl.text.isEmpty
                                          ? "temp@mail.com"
                                          : emailCtrl.text,
                                    );

                                    setState(() =>
                                        message = "OTP sent to mobile");

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape:
                                          const RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.vertical(
                                          top: Radius.circular(26),
                                        ),
                                      ),
                                      builder: (_) => OTPBottomSheet(
                                        onVerify: (otp) async {
                                          await ApiService.verifyRegisterOtp(
                                            mobileOtp: otp,
                                            emailOtp: "123456",
                                          );
                                          setState(() {
                                            mobileVerified = true;
                                            message =
                                                "Mobile number verified";
                                          });
                                        },
                                      ),
                                    );
                                  } catch (_) {
                                    setState(() =>
                                        message = "Failed to send mobile OTP");
                                  }
                                },
                              )
                            : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 15),

                // ================= Email =================
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "College Email Address",
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    suffixIcon: emailVerified
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : emailCtrl.text.contains("@")
                            ? TextButton(
                                child: const Text("SEND OTP"),
                                onPressed: () async {
                                  try {
                                    setState(() =>
                                        message = "OTP sent to email");

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape:
                                          const RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.vertical(
                                          top: Radius.circular(26),
                                        ),
                                      ),
                                      builder: (_) => OTPBottomSheet(
                                        onVerify: (otp) async {
                                          await ApiService.verifyRegisterOtp(
                                            mobileOtp: "123456",
                                            emailOtp: otp,
                                          );
                                          setState(() {
                                            emailVerified = true;
                                            message = "Email verified";
                                          });
                                        },
                                      ),
                                    );
                                  } catch (_) {
                                    setState(() =>
                                        message = "Failed to send email OTP");
                                  }
                                },
                              )
                            : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 24),

                // ================= Complete Registration =================
                loading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(
                        text: "COMPLETE REGISTRATION",
                        enabled: canRegister,
                        onPressed: canRegister
                            ? () async {
                                try {
                                  setState(() {
                                    loading = true;
                                    message = "";
                                  });

                                  final selectedUniversity =
                                      universities.firstWhere(
                                    (u) =>
                                        u["name"] ==
                                        universityCtrl.text,
                                  );

                                  await ApiService.registerStudent(
                                    universityId:
                                        selectedUniversity["id"],
                                    mobile: mobileCtrl.text,
                                    email: emailCtrl.text,
                                  );

                                  setState(() {
                                    loading = false;
                                    message =
                                        "Registration successful. Please login.";
                                  });

                                  Future.delayed(
                                    const Duration(milliseconds: 700),
                                    () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const LoginScreen(),
                                        ),
                                      );
                                    },
                                  );
                                } catch (e) {
                                  setState(() {
                                    loading = false;
                                    message = e
                                            .toString()
                                            .contains("ALREADY")
                                        ? "You are already registered. Please login."
                                        : "Registration failed. Please try again.";
                                  });
                                }
                              }
                            : null,
                      ),

                const SizedBox(height: 18),

                // ================= Login =================
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Already registered? Login",
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
      ),
    );
  }
}

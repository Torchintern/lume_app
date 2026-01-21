import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/otp_bottom_sheet.dart';
import '../widgets/primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentDetailsScreen extends StatefulWidget {
  final int regId;
  const StudentDetailsScreen({super.key, required this.regId});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  Map<String, dynamic>? details;
  bool loading = true;

  String aadhaarMessage = "";
  String panMessage = "";
  String? verifiedAadhaar;
  String? verifiedPan;

  bool isUpiEditable = true;
  bool isUpiSaving = false;
  final TextEditingController upiCtrl = TextEditingController();
  String upiMessage = "";

  final TextEditingController aadhaarCtrl = TextEditingController();
  final TextEditingController panCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  // ================= LOAD DETAILS =================
  Future<void> loadDetails() async {
    setState(() => loading = true);

    final data = await ApiService.getStudentDetails(widget.regId);
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      details = data;
      verifiedAadhaar = prefs.getString("aadhaar_${widget.regId}");
      verifiedPan = prefs.getString("pan_${widget.regId}");

      if (data["upi_id"] != null) {
        upiCtrl.text =
            data["upi_id"].toString().replaceAll("@lumepay", "");
        isUpiEditable = false;
      }

      loading = false;
    });
  }

  // ================= KYC PROGRESS =================
  double get kycProgress {
    final aadhaar = details?["aadhaar_verified"] == 1;
    final pan = details?["pan_verified"] == 1;

    if (aadhaar && pan) return 1.0;
    if (aadhaar) return 0.75;
    return 0.56;
  }

  // ================= MASK HELPERS =================
  String maskAadhaar(String value) {
    if (value.isEmpty || value.length < 4) {
      return "XXXX XXXX XXXX";
    }
    return "XXXX XXXX ${value.substring(value.length - 4)}";
  }

  String maskPan(String value) {
    if (value.isEmpty || value.length < 10) {
      return "XXXXXXXXXX";
    }
    return "${value.substring(0, 5)}XXXX${value.substring(9)}";
  }

  // ================= AADHAAR =================
  void startAadhaarVerification() async {
    await ApiService.sendAadhaarOtp(
      registeredStudentId: widget.regId,
      mobile: details!["mobile"],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => OTPBottomSheet(
        otpSentMessage: "OTP sent to Aadhaar linked mobile number",
        onVerify: (otp) async {
          final res = await ApiService.verifyAadhaarKyc(
            registeredStudentId: widget.regId,
            mobile: details!["mobile"],
            otp: otp.toString().trim(),
          );

          if (res) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              "aadhaar_${widget.regId}",
              aadhaarCtrl.text,
            );

            aadhaarCtrl.clear();

            aadhaarMessage = "Aadhaar verified successfully";
            await loadDetails();
          } else {
            setState(() {
              aadhaarMessage = "Aadhaar verification failed";
            });
          }
        },
      ),
    );
  }

  // ================= PAN =================
  void startPanVerification() async {
    await ApiService.sendPanOtp(
      registeredStudentId: widget.regId,
      mobile: details!["mobile"],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => OTPBottomSheet(
        otpSentMessage: "OTP sent to PAN linked mobile number",
        onVerify: (otp) async {
          final res = await ApiService.verifyPanKyc(
            registeredStudentId: widget.regId,
            mobile: details!["mobile"],
            panNumber: panCtrl.text,
            otp: otp.toString().trim(),
          );

          if (res) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                "pan_${widget.regId}",
                panCtrl.text,
              );

              panCtrl.clear();

              panMessage = "PAN verified successfully";

              await loadDetails();
            } else {
            setState(() {
              panMessage = "PAN verification failed";
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading || details == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final aadhaarVerified = details!["aadhaar_verified"] == 1;
    final panVerified = details!["pan_verified"] == 1;
    final walletActive = details!["wallet_status"] == "active";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        leading: BackButton(
  onPressed: () {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
  },
),
        title: const Text("My Details"),
        backgroundColor: const Color(0xFF4C6EF5),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ================= KYC STATUS =================
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("KYC Status",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: kycProgress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          kycProgress == 1.0
                              ? "KYC Completed"
                              : "KYC ${(kycProgress * 100).toInt()}%",
                          style: TextStyle(
                            color: kycProgress == 1.0
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        const Spacer(),
                        if (kycProgress == 1.0)
                          const Icon(Icons.verified, color: Colors.green),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ================= STUDENT DETAILS =================
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _info("Name", details!["full_name"]),
                    _info("Mobile", details!["mobile"]),
                    _info("Email", details!["email"]),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ================= AADHAAR =================
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Aadhaar CARD",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    aadhaarVerified
                        ? Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                maskAadhaar(
                                  verifiedAadhaar ?? aadhaarCtrl.text,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: aadhaarCtrl,
                                keyboardType: TextInputType.number,
                                maxLength: 12,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  hintText: "Enter Aadhaar Number",
                                  counterText: "",
                                ),
                              ),
                              const SizedBox(height: 10),
                              PrimaryButton(
                                text: "VERIFY",
                                enabled: aadhaarCtrl.text.length == 12,
                                onPressed: startAadhaarVerification,
                              ),
                              if (aadhaarMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    aadhaarMessage,
                                    style: TextStyle(
                                      color: aadhaarMessage.contains("failed")
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ================= PAN =================
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PAN CARD",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    panVerified
                        ? Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                maskPan(
                                  verifiedPan ?? panCtrl.text,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: panCtrl,
                                maxLength: 10,
                                 onChanged: (_) => setState(() {}),
                                textCapitalization:
                                    TextCapitalization.characters,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[A-Z0-9]')),
                                  TextInputFormatter.withFunction(
                                    (oldValue, newValue) {
                                      return newValue.copyWith(
                                        text: newValue.text.toUpperCase(),
                                        selection: newValue.selection,
                                      );
                                    },
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  hintText: "Enter PAN Number",
                                  counterText: "",
                                ),
                              ),
                              const SizedBox(height: 10),
                              PrimaryButton(
                                text: "VERIFY",
                                enabled: panCtrl.text.length == 10,
                                onPressed: startPanVerification,
                              ),
                              if (panMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    panMessage,
                                    style: TextStyle(
                                      color: panMessage.contains("failed")
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ],
                ),
              ),

              if (walletActive) ...[
                const SizedBox(height: 20),

                // ================= UPI =================
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("UPI ID",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: upiCtrl,
                              enabled: isUpiEditable,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9]')),
                              ],
                              decoration: const InputDecoration(
                                hintText: "Enter UPI ID",
                                suffixText: "@lumepay",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          if (!isUpiEditable)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                setState(() {
                                  isUpiEditable = true;
                                  upiMessage = "";
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (isUpiEditable)
                        PrimaryButton(
                          text: isUpiSaving ? "SAVING..." : "SAVE",
                          enabled: !isUpiSaving,
                          onPressed: () async {
                            final rawUpi = upiCtrl.text.trim();
                            if (rawUpi.isEmpty) {
                              setState(() {
                                upiMessage = "UPI name cannot be empty";
                              });
                              return;
                            }

                            setState(() {
                              isUpiSaving = true;
                              upiMessage = "";
                            });

                            try {
                              await ApiService.updateUpi(
                                registeredStudentId: widget.regId,
                                upiId: "$rawUpi@lumepay",
                              );
                              setState(() {
                                isUpiEditable = false;
                                upiMessage = "UPI ID saved successfully";
                              });
                            } catch (e) {
                              setState(() {
                                upiMessage = e
                                    .toString()
                                    .replaceAll("Exception:", "");
                              });
                            } finally {
                              setState(() {
                                isUpiSaving = false;
                              });
                            }
                          },
                        ),
                      if (upiMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            upiMessage,
                            style: TextStyle(
                              color: upiMessage.contains("exists")
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ================= FINAL STATUS =================
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statusRow(
                      "KYC",
                      kycProgress == 1.0 ? "Completed" : "Pending",
                      active: kycProgress == 1.0,
                    ),
                    const SizedBox(height: 12),
                    _statusRow(
                      "Wallet",
                      walletActive ? "Active" : "Inactive",
                      active: walletActive,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12),
        ],
      ),
      child: child,
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child:
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(color: active ? Colors.green : Colors.red),
              ),
              if (active)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.verified, color: Colors.green),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

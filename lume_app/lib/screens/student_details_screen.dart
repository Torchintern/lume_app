import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/otp_bottom_sheet.dart';
import '../widgets/primary_button.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class StudentDetailsScreen extends StatefulWidget {
  final int regId;
  const StudentDetailsScreen({super.key, required this.regId});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  Map<String, dynamic>? details;
  bool loading = true;
  String liveWeatherTemp = "--";
  String liveWeatherCondition = "Loading...";
  bool weatherLoading = true;
  Timer? weatherTimer;

  String aadhaarMessage = "";
  String panMessage = "";
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
    loadLiveWeather();
    weatherTimer = Timer.periodic(
    const Duration(minutes: 5),
    (timer) => loadLiveWeather(),
  );
  }

  @override
  void dispose() {
    weatherTimer?.cancel();
    super.dispose();
  }

  // ===== WEATHER ICON HELPER =====  
  IconData weatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case "cloudy":
      case "partly cloudy":
        return Icons.cloud;
      case "rain":
        return Icons.umbrella;
      case "sunny":
      case "clear":
        return Icons.wb_sunny;
      default:
        return Icons.cloud;
    }
  }
  String weatherCodeToText(int code) {
  if (code == 0) return "Clear";
  if (code <= 3) return "Partly Cloudy";
  if (code <= 48) return "Foggy";
  if (code <= 67) return "Rain";
  if (code <= 77) return "Snow";
  return "Cloudy";
}
  LinearGradient getWeatherGradient(String condition) {
    switch (condition.toLowerCase()) {
      case "clear":
      case "sunny":
        return const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
        );

      case "rain":
        return const LinearGradient(
          colors: [Color(0xFF607D8B), Color(0xFF455A64)],
        );

      case "partly cloudy":
      case "cloudy":
      default:
        return const LinearGradient(
          colors: [Color(0xFF90A4AE), Color(0xFF607D8B)],
        );
    }
  }

  // ======== Greetings helper ===========
  String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return "Good Morning";
  if (hour < 17) return "Good Afternoon";
  return "Good Evening";
}

String getFormattedDate() {
  final now = DateTime.now();
  return "${_weekday(now.weekday)}, ${now.day.toString().padLeft(2, '0')} "
      "${_month(now.month)} ${now.year}";
}

String _weekday(int day) {
  const days = [
    "Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"
  ];
  return days[day - 1];
}

String _month(int m) {
  const months = [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
  ];
  return months[m - 1];
}

  // ================= LOAD DETAILS =================
  Future<void> loadDetails() async {
    setState(() => loading = true);

    final data = await ApiService.getStudentDetails(widget.regId);
    setState(() {
      details = data;
      if (data["upi_id"] != null && data["upi_id"].toString().isNotEmpty) {
      upiCtrl.text =
          data["upi_id"].toString().replaceAll("@lumepay", "");
      isUpiEditable = false;
      } else {
        upiCtrl.clear();
        isUpiEditable = true;
      }

      loading = false;
    });
  }

  Future<void> loadLiveWeather() async {
  try {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        weatherLoading = false;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    final lat = position.latitude;
    final lon = position.longitude;

    final url =
        "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true";

    final res = await http.get(Uri.parse(url));

    final data = jsonDecode(res.body);

    final temp = data["current_weather"]["temperature"];
    final code = data["current_weather"]["weathercode"];

    setState(() {
      liveWeatherTemp = temp.toString();
      liveWeatherCondition = weatherCodeToText(code);
      weatherLoading = false;
    });
  } catch (e) {
    setState(() {
      weatherLoading = false;
    });
  }
}

  // ================= KYC PROGRESS =================
  double get kycProgress {
    final aadhaar = details?["aadhaar_verified"] == 1;
    final pan = details?["pan_verified"] == 1;

    if (aadhaar && pan) return 1.0;
    if (aadhaar) return 0.75;
    return 0.56;
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
            aadhaarNumber: aadhaarCtrl.text.trim(),
            otp: otp.toString().trim(),
          );

          if (res) {
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
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        },
      ),
      title: const Text(
        "My Details",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ================= KYC STATUS =================
              if (kycProgress < 1.0) ...[
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
                      Text(
                        "KYC ${(kycProgress * 100).toInt()}%",
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ================= GREETING CARD =================
              _greetingCard(),

              const SizedBox(height: 20),

            // ================= STUDENT DETAILS =================

              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _info("Name", details!["full_name"]),
                    _info("Mobile", details!["mobile"]),
                    _info("Email", details!["email"]),
                    _info("College", details!["college"] ?? ""),
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
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            // Aadhaar Image
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    "assets/images/aadhaar_card.png",
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                // Verified Icon ONLY (no number overlay)
                                const Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Icon(
                                    Icons.verified,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                "XXXX XXXX ${details!["aadhaar_last4"]}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                ),
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
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            // PAN Image + Verified Icon
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    "assets/images/pan_card.png",
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                const Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Icon(
                                    Icons.verified,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                details!["pan_masked"] ?? "",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                ),
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
                              await loadDetails();
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
  
  // ===== Greeting card Helper ======
  Widget _greetingCard() {
  final name = details?["full_name"] ?? "";

  final weatherTemp = liveWeatherTemp;
  final weatherCondition = liveWeatherCondition;


  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
    gradient: getWeatherGradient(liveWeatherCondition),
    borderRadius: BorderRadius.circular(26),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi $name,",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${getGreeting()}, ${getFormattedDate()}",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Row(
              children: [
                Icon(
                  weatherIcon(weatherCondition),
                  size: 28,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  "$weatherTemp°C",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              weatherCondition,
              style: TextStyle(color: Colors.grey.shade600),
            )
          ],
        )
      ],
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lume_app/screens/about/terms_conditions_screen.dart';
import 'package:lume_app/screens/about/privacy_policy_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:lume_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ScholarScreen extends StatefulWidget {
  const ScholarScreen({super.key});

  @override
  State<ScholarScreen> createState() => _ScholarScreenState();
}

class _ScholarScreenState extends State<ScholarScreen> {
  // ================= TYPING TEXT =================
  final String fullText =
  "Dream big.\nStudy smarter.\nReach your ideal college with LUME.";
  String visibleText = "";
  int charIndex = 0;
  Timer? _typingTimer;
  Timer? _restartTimer;
  bool _isUserInteracting = false;
  String userName = "";
  bool hasApplication = false;
  String? applicationStatus;




  // ================= AUTO PAGE SWAP =================
  final PageController _pageController =
    PageController(viewportFraction: 1.0, initialPage: 1000);

  Timer? _pageTimer;
  int _currentPage = 1000;

 @override
  void initState() {
    super.initState();
    _loadUserName();
    _startTyping();
    _startPageTimer();
     _loadApplicationStatus();
  }
  
  Future<void> _loadApplicationStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final regId = prefs.getInt("reg_id");

  if (regId == null) return;

  final res = await ApiService.getScholarApplicationStatus(regId);

  setState(() {
    hasApplication = res["hasApplication"] == true;
    applicationStatus = res["status"];
  });
}

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "User";
    });
  }


  @override
  void dispose() {
    _typingTimer?.cancel();
    _restartTimer?.cancel();
    _pageTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ================= AUTO TYPING WITH 3s PAUSE =================
  void _startTyping() {
    _typingTimer?.cancel();
    visibleText = "";
    charIndex = 0;

    _typingTimer =
        Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (charIndex < fullText.length) {
        setState(() {
          visibleText += fullText[charIndex];
          charIndex++;
        });
      } else {
        timer.cancel();
        _restartTimer = Timer(const Duration(seconds: 5), () {
          if (!mounted) return;
          _startTyping();
        });
      }
    });
  }

  // ================= AUTO PAGE SWAP =================
  void _startPageTimer() {
  _pageTimer?.cancel();
  _pageTimer = Timer.periodic(const Duration(seconds: 5), (_) {
    if (!_pageController.hasClients || _isUserInteracting) return;

    _currentPage++;

    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Scholar",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    body: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // ================= COLORFUL AUTO TYPING TEXT =================
            SizedBox(
            height: 110,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF4C6EF5),
                  Color(0xFF00C2FF),
                  Color(0xFFFFC107),
                ],
              ).createShader(bounds),
              child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 28,             
                  fontWeight: FontWeight.w800, 
                  height: 1.4,
                  letterSpacing: 0.4, 
                ),
                children: [
                  TextSpan(
                    text: visibleText.split('\n').take(2).join('\n') + '\n',
                  ),
                  TextSpan(
                    text: visibleText.split('\n').length > 2
                        ? visibleText.split('\n')[2]
                        : '',
                    style: const TextStyle(
                      fontSize: 22,            
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            ),
          ),


            const SizedBox(height: 28),

            // ================= AUTO SWAPPING STATS =================
            SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              physics: const PageScrollPhysics(),
                onPageChanged: (index) {
                  _currentPage = index;
                },
                itemBuilder: (_, index) {
                  final items = [
                  const _ScholarStatCard(
                  logoPath: "assets/logos/university.png",
                  value: "5+",
                  label: "Partner Universities",
                ),

                  const _ScholarStatCard(
                  logoPath: "assets/logos/students.png",
                  value: "1 Lakh+",
                  label: "Students Guided",
                ),

                const _ScholarStatCard(
                logoPath: "assets/logos/loan.png",
                value: "₹2 Cr+",
                label: "Loans Processed",
              ),

                ];

                  return items[index % items.length];
                },
            ),
          ),
          const SizedBox(height: 32),

          // ================= LENDING PARTNER OFFERINGS =================
         _LendingPartnersSection(
          userName: userName,
          hasApplication: hasApplication,
          applicationStatus: applicationStatus,
          onApplicationSubmitted: () async {
            await _loadApplicationStatus();
            setState(() {});
          },
        ),
                  ],
        ),
      ),
    );
  }
}

// ================= STAT CARD =================
class _ScholarStatCard extends StatelessWidget {
  final String logoPath;
  final String value;
  final String label;

  const _ScholarStatCard({
  required this.logoPath,
  required this.value,
  required this.label,
});

  @override
  Widget build(BuildContext context) {
    return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Color(0xFFE5E7EB), 
        ),
      ),

        child: Row(
          children: [
            const SizedBox(width: 20),

            // -------- LEFT TEXT --------
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFC107),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // -------- RIGHT ICON --------
            Container(
              height: 72,
              width: 72,
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                logoPath,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LendingPartnersSection extends StatelessWidget {
  final String userName;
  final bool hasApplication;
  final String? applicationStatus;
  final VoidCallback onApplicationSubmitted; 
  const _LendingPartnersSection({
    Key? key,
    required this.userName,
    required this.hasApplication,
    required this.applicationStatus,
    required this.onApplicationSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/images/lend.png",
              height: 22,
              width: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              "Our Lending Partner Offerings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),


    const SizedBox(height: 12),
        _LendingTable(),
        const SizedBox(height: 24),
      _UserApplicationCard(
      userName: userName,
      hasApplication: hasApplication,
      applicationStatus: applicationStatus,
      onApplicationSubmitted: onApplicationSubmitted,
    ),

      ],
    );
  }
}

class _LendingTable extends StatefulWidget {
  @override
  State<_LendingTable> createState() => _LendingTableState();
}
class _LendingTableState extends State<_LendingTable> {
  int? _selectedIndex;

    @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 700,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            _TableHeader(),

            _buildRow(
              index: 0,
              logo: "assets/banks/pnb.png",
              name: "PNB",
              amount: "Up to ₹2 Crore",
              rate: "8.5% – 10%",
              time: "5–7 Days",
              fee: "₹5,000",
            ),

            _buildRow(
              index: 1,
              logo: "assets/banks/credila.png",
              name: "Credila",
              amount: "Up to ₹2 Crore",
              rate: "9% – 11%",
              time: "3–5 Days",
              fee: "₹4,500",
            ),

            _buildRow(
              index: 2,
              logo: "assets/banks/idfc.png",
              name: "IDFC First Bank",
              amount: "Up to ₹2 Crore",
              rate: "8% – 9.5%",
              time: "2–4 Days",
              fee: "₹6,000",
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildRow({
    required int index,
    required String logo,
    required String name,
    required String amount,
    required String rate,
    required String time,
    required String fee,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index; 
        });
      },
      child: _LendingRow(
        logo: logo,
        name: name,
        amount: amount,
        rate: rate,
        time: time,
        fee: fee,
        highlighted: _selectedIndex == index,
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFB3DBFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text("Bank Name", style: TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text("Loan    Amount")),
          Expanded(child: Text("Interest")),
          Expanded(child: Text("Prcessing Time")),
          Expanded(child: Text("Proessing Fee")),
        ],
      ),
    );
  }
}
class _LendingRow extends StatelessWidget {
  final String logo;
  final String name;
  final String amount;
  final String rate;
  final String time;
  final String fee;
  final bool highlighted;

  const _LendingRow({
    required this.logo,
    required this.name,
    required this.amount,
    required this.rate,
    required this.time,
    required this.fee,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: highlighted ? const Color(0xFFD1FAE5) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                SizedBox(
                width: 32,
                height: 32,
                child: Image.asset(
                  logo,
                  fit: BoxFit.contain,
                ),
              ),
                const SizedBox(width: 8),
               Flexible(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB), 
                ),
              ),
            ),

              ],
            ),
          ),
          Expanded(child: Text(amount)),
          Expanded(child: Text(rate)),
          Expanded(child: Text(time)),
          Expanded(child: Text(fee)),
        ],
      ),
    );
  }
}

class _UserApplicationCard extends StatelessWidget {
  final String userName;
  final bool hasApplication;
  final String? applicationStatus;
  final VoidCallback onApplicationSubmitted;

  const _UserApplicationCard({
    Key? key,
    required this.userName,
    required this.hasApplication,
    required this.applicationStatus,
    required this.onApplicationSubmitted,
  }) : super(key: key);


bool get canCreateNewApplication {
  if (!hasApplication) return true;
  if (applicationStatus == "completed") return true;
  return false; 
}


  Widget _buildStatusText() {
  if (!hasApplication) {
    return const Text(
      "No application found. Please apply.",
      style: TextStyle(color: Colors.grey),
    );
  }

  if (applicationStatus == "pending") {
    return const Text(
      "Application under review",
      style: TextStyle(
        color: Colors.orange,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  if (applicationStatus == "completed") {
    return const Text(
      "Application Reviewed. You can apply again.",
      style: TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  return const SizedBox.shrink();
}


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi $userName,",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            onPressed: canCreateNewApplication
          ? () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                enableDrag: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const _CreateApplicationSheet(),
              );

              if (result == true) {
                onApplicationSubmitted(); 
              }
            }
          : null,


              child: Text(
              hasApplication && applicationStatus == "completed"
                  ? "Apply Again"
                  : "Create New Application",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ),
          ),

          const SizedBox(height: 12),

          const SizedBox(height: 12),
            _buildStatusText(),
        ],
      ),
    );
  }
}

class _CreateApplicationSheet extends StatefulWidget {
  const _CreateApplicationSheet();

  @override
  State<_CreateApplicationSheet> createState() =>
      _CreateApplicationSheetState();
}
class _CreateApplicationSheetState extends State<_CreateApplicationSheet> {
  final _formKey = GlobalKey<FormState>();

  String? country;
  String? admissionStatus;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _loanController = TextEditingController();
  final _cityController = TextEditingController();
  final _intakeController = TextEditingController();


  final List<String> countries = [
    "USA",
    "UK",
    "Canada",
    "Australia",
    "Germany",
    "Ireland",
    "France",
    "India",
    "UAE",
    "New Zealand",
    "Others",
  ];

  final List<String> admissionStatuses = [
    "Not Applied",
    "Applied",
    "Confirmed",
  ];
bool get _isFormValid {
  return _formKey.currentState?.validate() == true &&
      country != null &&
      admissionStatus != null;
}
@override
void initState() {
  super.initState();
  country = null;
  admissionStatus = null;
}
@override
void dispose() {
  _nameController.dispose();
  _emailController.dispose();
  _phoneController.dispose();
  _loanController.dispose();
  _cityController.dispose();
  _intakeController.dispose();
  super.dispose();
}


Future<bool?> _showSuccessDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        backgroundColor: const Color(0xFFF7F8FC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check,
                  size: 40,
                  color: Color(0xFF16A34A),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Application Submitted",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                "We’ll reach out to you shortly to guide you further.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    "Got it",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ===== Drag Handle =====
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          const SizedBox(height: 12),

          // ===== Header =====
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ===== Highlight Text =====
          Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: const Color(0xFFFFF3C4),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        "assets/images/reach.png", 
        height: 16,          
        fit: BoxFit.contain,
      ),
      const SizedBox(width: 6),
      const Text(
        "We reach out within minutes",
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
),


          const SizedBox(height: 16),

          const Text(
            "Start Early, Avoid Last Minute Stress",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Text(
            "Help us with a few details below and we'll find the best education loan for you",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 20),

          // ===== FORM =====
          Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _InputField(
                    label: "FULL NAME*",
                    hint: "Full Name",
                    controller: _nameController,
                  ),

              _InputField(
                label: "EMAIL*",
                hint: "Email",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Required";
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),

                  _InputField(
                    label: "PHONE NUMBER*",
                    hint: "Mobile Number",
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Required";
                      if (value.length != 10) return "Enter 10-digit number";
                      return null;
                    },
                  ),

                 _InputField(
                    label: "LOAN AMOUNT*",
                    hint: "Enter Amount",
                    controller: _loanController,
                    keyboardType: TextInputType.number,
                  ),

                  _InputField(
                    label: "PERMANENT CITY*",
                    hint: "Permanent City",
                    controller: _cityController,
                  ),

                _DropdownField(
                  label: "COUNTRY OF STUDY*",
                  hint: "Select Country",
                  value: country,
                  items: countries,
                  onChanged: (value) {
                    setState(() => country = value);
                  },
                ),

                _DropdownField(
                  label: "ADMISSION STATUS*",
                  hint: "Select Status",
                  value: admissionStatus,
                  items: admissionStatuses,
                  onChanged: (value) {
                    setState(() => admissionStatus = value);
                  },
                ),


                 _InputField(
                    label: "TARGET INTAKE*",
                    hint: "MM/YYYY",
                    controller: _intakeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [MonthYearInputFormatter()],
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Required";

                      final regex = RegExp(r'^(0[1-9]|1[0-2])\/\d{4}$');
                      if (!regex.hasMatch(value)) {
                        return "Format should be MM/YYYY";
                      }
                      return null;
                    },
                  ),

                ],
              ),
            ),
          ),
          ),
          const SizedBox(height: 12),

          // ===== CONTINUE BUTTON =====
         SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFormValid
                  ? const Color(0xFF2563EB)
                  : Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isFormValid
              ? () async {
                  final prefs = await SharedPreferences.getInstance();
                  final regId = prefs.getInt("reg_id");

                  final payload = {
                    "registered_student_id": regId,
                    "full_name": _nameController.text.trim(),
                    "email": _emailController.text.trim(),
                    "phone": _phoneController.text.trim(),
                    "loan_amount": _loanController.text.trim(),
                    "city": _cityController.text.trim(),
                    "country": country,
                    "admission_status": admissionStatus,
                    "target_intake": _intakeController.text.trim(),
                  };


                  final success =
                      await ApiService.submitScholarApplication(payload);

                  if (success) {
                    final bool? confirmed = await _showSuccessDialog(context);

                    if (confirmed == true) {
                      Navigator.pop(context, true); 
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Something went wrong")),
                    );
                  }
                }
              : null,

            child: const Text(
              "Continue",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

          const SizedBox(height: 8),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              children: [
                const TextSpan(text: "By submitting you agree to our "),
                TextSpan(
                  text: "Terms & Conditions",
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsConditionsScreen(),
                        ),
                      );
                    },
                ),
                const TextSpan(text: " and "),
                TextSpan(
                  text: "Privacy Policy",
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller; 
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _InputField({
    required this.label,
    required this.hint,
    this.controller, 
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator ?? (value) {
              if (value == null || value.trim().isEmpty) {
                return "Required";
              }
              return null;
            },

            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _DropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            hint: Text(
              hint,
              style: const TextStyle(color: Colors.grey),
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: (value) =>
                value == null ? "Required" : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthYearInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length > 6) {
      digitsOnly = digitsOnly.substring(0, 6);
    }

    String formatted = digitsOnly;

    if (digitsOnly.length >= 3) {
      formatted =
          '${digitsOnly.substring(0, 2)}/${digitsOnly.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

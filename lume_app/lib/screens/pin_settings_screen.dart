import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/otp_bottom_sheet.dart';
import '../widgets/primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinSettingsScreen extends StatefulWidget {
  final int regId;
  final bool forceSetup;
  final String initialTab; 

  const PinSettingsScreen({
    super.key,
    required this.regId,
    this.forceSetup = false,
    this.initialTab = "wallet",
  });

  @override
  State<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

class _PinSettingsScreenState extends State<PinSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool walletHasPin = false;
  bool cardHasPin = false;

  bool walletOtpVerified = false;
  bool cardOtpVerified = false;

  bool loading = true;

  @override
  void initState() {
    super.initState();
   _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == "card" ? 1 : 0,
    );
    if (widget.forceSetup && widget.initialTab == "card") {
      _tabController.index = 1;
    }

    _loadPinStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  // ================= LOAD PIN STATUS =================
  Future<void> _loadPinStatus() async {
    try {
      final responses = await Future.wait([
        ApiService.getPinStatus(widget.regId),
        ApiService.getCardStatus(widget.regId),
      ]);

      final pin = responses[0];
      final card = responses[1];

      final bool cardPending = card["card_status"] != "active";

      if (!mounted) return;

      setState(() {
        walletHasPin = pin["wallet"] == true;

        cardHasPin = cardPending ? false : pin["card"] == true;

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        walletHasPin = false;
        cardHasPin = false;
        loading = false;
      });
    }
  }



  // ================= OTP FLOW =================
  Future<void> _openOtpSheet(bool isWallet) async {
    await ApiService.sendPinResetOtp(regId: widget.regId);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return OTPBottomSheet(
          otpSentMessage: "OTP sent to your registered mobile number",
          onVerify: (otp) async {
            await ApiService.verifyPinResetOtp(otp: otp);
            if (!mounted) return;

            setState(() {
              if (isWallet) {
                walletOtpVerified = true;
              } else {
                cardOtpVerified = true;
              }
            });
          },
        );
      },
    );
  }

  // ================= SAVE PIN =================
  Future<void> _savePin(bool isWallet, String pin) async {
    final success = await ApiService.setPin(
      regId: widget.regId,
      type: isWallet ? "wallet" : "card",
      pin: pin,
    );

    if (!mounted) return;

    if (!success) {
      _showResultDialog(
        success: false,
        message: "Unable to update PIN. Please try again.",
      );
      return;
    }

    if (isWallet) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("wallet_pin_set", true);
    }

    setState(() {
      if (isWallet) {
        walletHasPin = true;
        walletOtpVerified = false;
      } else {
        cardHasPin = true;
        cardOtpVerified = false;
      }
    });

    _showResultDialog(
      success: true,
      message: "Your PIN has been updated successfully.",
    );
  }

  // ================= RESULT DIALOG =================
  void _showResultDialog({
  required bool success,
  required String message,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 18),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// ICON CIRCLE
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECFF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check : Icons.close,
                size: 36,
                color: const Color(0xFF4C6EF5),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              success ? "PIN Updated" : "Action Failed",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 22),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C6EF5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text(
                  "Done",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

      return WillPopScope(
      onWillPop: () async => !widget.forceSetup,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.forceSetup,
        title: Column(
        children: [
          Text(
            widget.forceSetup ? "Activate Card" : "PIN Settings",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (widget.forceSetup)
            const Text(
              "Set your card PIN to continue",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),

      ),

        body: Column(
  children: [

    Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10),
          ],
        ),
       child: Material(
        color: Colors.transparent,
        child: SizedBox(
          height: 46,
          child: TabBar(
          controller: _tabController,
          physics: widget.forceSetup
              ? const NeverScrollableScrollPhysics()
              : null,

            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: EdgeInsets.zero,
            indicator: BoxDecoration(
              color: const Color(0xFF4C6EF5),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black54,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(child: Center(child: Text("Wallet"))),
              Tab(child: Center(child: Text("Card"))),
            ],
          ),
        ),
      ),


      ),
    ),

    Expanded(
      child: TabBarView(
      controller: _tabController,
      physics: widget.forceSetup
          ? const NeverScrollableScrollPhysics()
          : null,

        children: [

            _PinFlow(
              hasPin: walletHasPin,
              otpVerified: walletOtpVerified,
              forceSetup: widget.forceSetup,
              typeLabel: "Wallet",
              onForgotPin: () => _openOtpSheet(true),
              onSave: (pin) => _savePin(true, pin),
            ),


            _PinFlow(
              hasPin: cardHasPin,
              otpVerified: cardOtpVerified,
              forceSetup: widget.forceSetup,
              typeLabel: "Card",
              onForgotPin: () => _openOtpSheet(false),
              onSave: (pin) => _savePin(false, pin),
            ),


          ],
        ),
      ),
  ],
        ),
      ),
    );
  }
}

// ================= PIN FLOW =================
class _PinFlow extends StatefulWidget {
  final bool hasPin;
  final bool otpVerified;
  final bool forceSetup;
  final VoidCallback onForgotPin;
  final Function(String) onSave;
  final String typeLabel; // "Wallet" or "Card"


  const _PinFlow({
    required this.hasPin,
    required this.otpVerified,
    required this.forceSetup,
    required this.onForgotPin,
    required this.onSave,
    required this.typeLabel,
  });

  @override
  State<_PinFlow> createState() => _PinFlowState();
}

class _PinFlowState extends State<_PinFlow> {
  String pin = "";
  String confirmPin = "";
  bool confirmStep = false;

  bool get canEnterPin => !widget.hasPin || widget.otpVerified;
  bool get isFirstTime => !widget.hasPin;
  bool get isChanging => widget.hasPin && widget.otpVerified;
  bool get requiresOtp => widget.hasPin && !widget.otpVerified && !widget.forceSetup;

 @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SizedBox.expand(
        child: Container(


    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 16),
      ],
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
    Column(
      children: [

        Center(
          child: Text(
            confirmStep
            ? "Re-enter ${widget.typeLabel} PIN"
            : isFirstTime
                ? "Create ${widget.typeLabel} PIN"
                : isChanging
                    ? "Enter new ${widget.typeLabel} PIN"
                    : "${widget.typeLabel} PIN Locked",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        if (requiresOtp)
          Center(
            child: GestureDetector(
              onTap: widget.onForgotPin,
              child: const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Change / Forgot PIN",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4C6EF5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(height: 24),
      ],
    ),

          _dots(confirmStep ? confirmPin.length : pin.length),

          const SizedBox(height: 24),

          Expanded(
            child: Center(
              child: _keypad(),
            ),
          ),

          PrimaryButton(

            text: confirmStep ? "Set PIN" : "Confirm",
            enabled: canEnterPin &&
            (confirmStep ? confirmPin.length == 4 : pin.length == 4),
            onPressed: () {
              if (!confirmStep) {
                setState(() => confirmStep = true);
                return;
              }

              if (pin != confirmPin) {
                showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 18),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Container(
                          height: 72,
                          width: 72,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8ECFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 36,
                            color: Color(0xFF4C6EF5),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          "PIN Mismatch",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "The PINs you entered do not match. Please try again.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4C6EF5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Try Again"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

                setState(() => confirmPin = "");
                return;
              }

              widget.onSave(pin);
            },
          ),
        ],
      ),
  ),
  ),
    );
  }

  Widget _dots(int filled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled
            ? const Color(0xFF4C6EF5)
            : const Color(0xFFE8ECFF),
          ),
        ),
      ),
    );
  }

  Widget _keypad() {
    const keys = [
      ["1", "2", "3"],
      ["4", "5", "6"],
      ["7", "8", "9"],
      ["", "0", "⌫"],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 64);
            final size = MediaQuery.of(context).size.width / 5.2;
            return Padding(
              padding: const EdgeInsets.all(8),
             child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {

                  if (!canEnterPin) return;

                  setState(() {
                    if (k == "⌫") {
                      if (confirmStep && confirmPin.isNotEmpty) {
                        confirmPin =
                            confirmPin.substring(0, confirmPin.length - 1);
                      } else if (!confirmStep && pin.isNotEmpty) {
                        pin = pin.substring(0, pin.length - 1);
                      }
                    } else {
                      if (!confirmStep && pin.length < 4) {
                        pin += k;
                      } else if (confirmStep && confirmPin.length < 4) {
                        confirmPin += k;
                      }
                    }
                  });
                },
                child: Container(
                  width: size,
                  height: size,

                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8ECFF),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-2, -2),
                      blurRadius: 6,
                    ),
                    BoxShadow(
                      color: Color(0x1A000000),
                      offset: Offset(2, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),

                  child: Text(
                    k,
                    style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  ),
                ),
              ),
             ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

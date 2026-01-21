import 'dart:async';
import 'package:flutter/material.dart';
import 'primary_button.dart';

class OTPBottomSheet extends StatefulWidget {
  final Future<void> Function(String otp) onVerify;

  /// Message shown when OTP is sent (Aadhaar / PAN)
  final String otpSentMessage;

  const OTPBottomSheet({
    super.key,
    required this.onVerify,
    this.otpSentMessage = "OTP sent",
  });

  @override
  State<OTPBottomSheet> createState() => _OTPBottomSheetState();
}

class _OTPBottomSheetState extends State<OTPBottomSheet> {
  final List<TextEditingController> ctrls =
      List.generate(6, (_) => TextEditingController());

  bool loading = false;
  bool success = false;
  bool hideOtp = true;

  int seconds = 30;
  Timer? timer;

  String message = "";
  Color messageColor = Colors.green;

  String get otp => ctrls.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();

    // Initial OTP sent message
    message = widget.otpSentMessage;
    messageColor = Colors.green;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
      } else {
        setState(() => seconds--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final c in ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void clearOtp() {
    for (final c in ctrls) {
      c.clear();
    }
    FocusScope.of(context).unfocus();
  }

  void resendOtp() {
    setState(() {
      seconds = 30;
      message = widget.otpSentMessage;
      messageColor = Colors.green;
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
      } else {
        setState(() => seconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context)
          .viewInsets
          .add(const EdgeInsets.all(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Enter OTP",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          // ================= INLINE MESSAGE =================
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: messageColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 15),

          // ================= OTP INPUT =================
          Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    IconButton(
      icon: Icon(
        hideOtp ? Icons.visibility_off : Icons.visibility,
        color: Colors.grey[700],
      ),
      onPressed: () {
        setState(() {
          hideOtp = !hideOtp;
        });
      },
    ),
  ],
),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              return SizedBox(
                width: 45,
                child: TextField(
  controller: ctrls[i],
  maxLength: 1,
  textAlign: TextAlign.center,
  keyboardType: TextInputType.number,

  obscureText: hideOtp,      
  obscuringCharacter: '●',

  decoration: const InputDecoration(counterText: ""),
  onChanged: (v) {
    if (v.isNotEmpty && i < 5) {
      FocusScope.of(context).nextFocus();
    }
    if (v.isEmpty && i > 0) {
      FocusScope.of(context).previousFocus();
    }
  },
),


              );
            }),
          ),

          const SizedBox(height: 20),

          // ================= VERIFY BUTTON =================
          loading
              ? const CircularProgressIndicator()
              : PrimaryButton(
                  text: "VERIFY",
                  enabled: otp.length == 6,
                  onPressed: () async {
                    try {
                      setState(() {
                        loading = true;
                        message = "";
                      });

                      await widget.onVerify(otp);

                      // SUCCESS
                      setState(() {
                        loading = false;
                        success = true;
                        message = "OTP verified successfully";
                        messageColor = Colors.green;
                      });

                      // Auto close
                      Future.delayed(const Duration(milliseconds: 700), () {
                        if (mounted) Navigator.pop(context);
                      });
                    } catch (_) {
                      //  INVALID OTP
                      setState(() {
                        loading = false;
                        success = false;
                        message = "Invalid OTP";
                        messageColor = Colors.red;
                      });
                      clearOtp();
                    }
                  },
                ),

          const SizedBox(height: 10),

          // ================= RESEND =================
          GestureDetector(
            onTap: seconds == 0 ? resendOtp : null,
            child: Text(
              seconds > 0
                  ? "Didn't receive OTP? Resend in $seconds sec"
                  : "Didn't receive OTP? Resend",
              style: TextStyle(
                color: seconds == 0 ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

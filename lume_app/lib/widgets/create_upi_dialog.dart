import 'package:flutter/material.dart';
import '../services/api_service.dart';

Future<void> showCreateUpiDialog({
  required BuildContext context,
  required int regId,
  required VoidCallback onSuccess,
}) async {
  final TextEditingController controller = TextEditingController();
  bool isLoading = false;
  String? errorText;
  bool isSuccess = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (_, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Create UPI ID",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            // ================= CONTENT =================
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INPUT OR SUCCESS MESSAGE
                if (!isSuccess)
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: "example@lumepay",
                    ),
                  )
                else
                  Row(
                    children: const [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "UPI ID created successfully!",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                // ERROR MESSAGE
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),

            // ================= ACTIONS =================
            actions: [
              TextButton(
                onPressed: (isLoading || isSuccess)
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: (isLoading || isSuccess)
                    ? null
                    : () async {
                        final upi =
                            controller.text.trim().toLowerCase();

                        // RESET ERROR
                        setState(() => errorText = null);

                        // VALIDATION
                        if (upi.isEmpty) {
                          setState(() =>
                              errorText = "UPI ID cannot be empty");
                          return;
                        }

                        if (!upi.endsWith("@lumepay")) {
                          setState(() =>
                              errorText =
                                  "UPI ID must end with @lumepay");
                          return;
                        }

                        if (upi.length < 6) {
                          setState(() =>
                              errorText = "UPI ID is too short");
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          await ApiService.updateUpi(
                            registeredStudentId: regId,
                            upiId: upi,
                          );

                          // ✅ SHOW SUCCESS INSIDE DIALOG
                          setState(() {
                            isSuccess = true;
                            errorText = null;
                          });

                          // ⏳ AUTO CLOSE AFTER DELAY
                          Future.delayed(
                              const Duration(milliseconds: 1200), () {
                            Navigator.pop(dialogContext);
                            onSuccess();
                          });
                        } catch (e) {
                          final msg =
                              e.toString().toLowerCase();

                          setState(() {
                            if (msg.contains("already")) {
                              errorText =
                                  "This UPI ID is already taken";
                            } else {
                              errorText =
                                  "Unable to create UPI ID. Try again.";
                            }
                          });
                        } finally {
                          setState(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}

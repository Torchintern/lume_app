import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import 'my_qr_screen.dart';
import 'add_card_and_pay_screen.dart';
import 'wallet/card_payment_otp_screen.dart';
import '../utils/card_utils.dart';

class SelectPaymentMethodScreen extends StatefulWidget {
  final int regId;
  final double amount;
  final String fullName;
  final String mobile;
  final String upiId;
  final String walletStatus;
  final int aadhaarVerified;
  final int panVerified;

  const SelectPaymentMethodScreen({
    super.key,
    required this.regId,
    required this.amount,
    required this.fullName,
    required this.mobile,
    required this.upiId,
    required this.walletStatus,
    required this.aadhaarVerified,
    required this.panVerified,
  });

  @override
  State<SelectPaymentMethodScreen> createState() =>
      _SelectPaymentMethodScreenState();
}

class _SelectPaymentMethodScreenState
    extends State<SelectPaymentMethodScreen> {
  late Future<List<dynamic>> _savedCardsFuture;

  @override
  void initState() {
    super.initState();
    _savedCardsFuture = ApiService.getSavedCards(widget.regId);
  }

  // ================= PAY USING SAVED CARD =================
  Future<void> _payWithSavedCard(Map card) async {
    final txnId = await ApiService.initAddMoneyTransaction(
      regId: widget.regId,
      amount: widget.amount,
      paymentMethod: "card",
      savedCardId: card["id"],
    );

    if (!mounted || txnId == null) return;

    // 🔥 OTP SCREEN HANDLES RESULT + DASHBOARD REDIRECT
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardPaymentOtpScreen(
          txnId: txnId,
          saveCard: false,
          cardData: const {},
          regId: widget.regId,
          fullName: widget.fullName,
          mobile: widget.mobile,
          upiId: widget.upiId,
          walletStatus: widget.walletStatus,
          aadhaarVerified: widget.aadhaarVerified,
          panVerified: widget.panVerified,
        ),
      ),
    );
  }

  // ================= COPY UPI =================
  void _copyUpi() {
    Clipboard.setData(ClipboardData(text: widget.upiId));
    _showResultDialog(
      success: true,
      message: "UPI ID copied to clipboard",
    );
  }

  // ================= CONFIRM DELETE CARD =================
  void _confirmDeleteCard(int cardId) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_forever,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                "Remove saved card?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "This card will be permanently removed.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await ApiService.deleteSavedCard(cardId);
                        setState(() {
                          _savedCardsFuture =
                              ApiService.getSavedCards(widget.regId);
                        });
                      },
                      child: const Text("Remove"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= RESULT DIALOG =================
  void _showResultDialog({
    required bool success,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.cancel,
                size: 72,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Select payment method",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "₹${widget.amount.toStringAsFixed(0)} • To wallet",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              _simpleTile(
                icon: Icons.qr_code_2,
                title: "Show QR and receive money",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyQrScreen(
                        name: widget.fullName,
                        upiId: widget.upiId,
                        walletActive: true,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              _upiTile(),
              const SizedBox(height: 24),

              const Text(
                "Add payment method",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),

              _simpleTile(
                icon: Icons.credit_card,
                title: "Add debit or credit card",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddCardAndPayScreen(
                        regId: widget.regId,
                        amount: widget.amount,
                        fullName: widget.fullName,
                        mobile: widget.mobile,
                        upiId: widget.upiId,
                        walletStatus: widget.walletStatus,
                        aadhaarVerified: widget.aadhaarVerified,
                        panVerified: widget.panVerified,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ================= SAVED CARDS =================
              FutureBuilder<List<dynamic>>(
                future: _savedCardsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox();
                  }

                  return Column(
                    children: snapshot.data!.map((c) {
                      final brand = CardBrand.values.firstWhere(
                        (e) => e.name == c["card_brand"],
                        orElse: () => CardBrand.unknown,
                      );

                      final cardType = CardType.values.firstWhere(
                        (e) => e.name == c["card_type"],
                        orElse: () => CardType.debit,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => _payWithSavedCard(c),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12, blurRadius: 8),
                              ],
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  cardBrandSvg(brand),
                                  width: 36,
                                  height: 36,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "${cardTypeLabel(cardType)} • **** ${c["last4"]}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _confirmDeleteCard(c["id"]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UPI TILE =================
  Widget _upiTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.alternate_email,
              color: Color(0xFF4C6EF5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Receive via UPI ID",
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.upiId,
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.grey),
            onPressed: _copyUpi,
          ),
        ],
      ),
    );
  }

  // ================= SIMPLE TILE =================
  Widget _simpleTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4C6EF5)),
            const SizedBox(width: 12),
            Text(
              title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

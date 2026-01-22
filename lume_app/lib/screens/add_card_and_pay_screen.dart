import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import '../utils/card_utils.dart';
import '../utils/card_formatters.dart';
import 'wallet/card_payment_otp_screen.dart';

class AddCardAndPayScreen extends StatefulWidget {
  final int regId;
  final double amount;

  final String fullName;
  final String mobile;
  final String? upiId;
  final String walletStatus;
  final int aadhaarVerified;
  final int panVerified;

  const AddCardAndPayScreen({
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
  State<AddCardAndPayScreen> createState() => _AddCardAndPayScreenState();
}

class _AddCardAndPayScreenState extends State<AddCardAndPayScreen> {
  final cardController = TextEditingController();
  final nameController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  final nameFocus = FocusNode();
  final expiryFocus = FocusNode();
  final cvvFocus = FocusNode();

  CardBrand _brand = CardBrand.unknown;
  CardType _cardType = CardType.debit;
  int _cvvMaxLength = 3;

  bool saveCard = false;
  bool _showBrandIcon = false;
  bool loading = false;

  @override
  void dispose() {
    cardController.dispose();
    nameController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    nameFocus.dispose();
    expiryFocus.dispose();
    cvvFocus.dispose();
    super.dispose();
  }

  // ================= VALIDATION =================
  bool get isValid {
    final card = cardController.text.replaceAll(' ', '');
    return card.length >= 12 &&
        nameController.text.trim().isNotEmpty &&
        expiryController.text.length == 5 &&
        cvvController.text.length == _cvvMaxLength;
  }

  // ================= PAY NOW =================
  Future<void> _payNow() async {
    setState(() => loading = true);

    final txnId = await ApiService.initAddMoney(
      regId: widget.regId,
      amount: widget.amount,
    );

    setState(() => loading = false);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardPaymentOtpScreen(
          txnId: txnId,
          saveCard: saveCard,
          cardData: {
            "card_number": cardController.text.replaceAll(' ', ''),
            "brand": _brand.name,
            "cardType": _cardType.name, 
          },
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
          "Add Card & Pay",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================= CARD NUMBER =================
            _field(
              controller: cardController,
              hint: "Card number",
              keyboard: TextInputType.number,
              formatter: CardNumberFormatter(),
              suffix: _showBrandIcon && _brand != CardBrand.unknown
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: SvgPicture.asset(
                        cardBrandSvg(_brand),
                        width: 32,
                        height: 32,
                      ),
                    )
                  : null,
              onChanged: (value) {
                final clean = value.replaceAll(' ', '');

                if (clean.length < 6) {
                  setState(() {
                    _brand = CardBrand.unknown;
                    _cardType = CardType.debit;
                    _cvvMaxLength = 3;
                    _showBrandIcon = false;
                    cvvController.clear();
                  });
                  return;
                }

                final detectedBrand = detectCardBrand(clean);

                setState(() {
                  _brand = detectedBrand;
                  _showBrandIcon = detectedBrand != CardBrand.unknown;

                  if (detectedBrand == CardBrand.amex) {
                    _cardType = CardType.credit;
                    _cvvMaxLength = 4;
                  } else {
                    _cardType = CardType.debit;
                    _cvvMaxLength = 3;
                  }

                  if (cvvController.text.length > _cvvMaxLength) {
                    cvvController.clear();
                  }
                });

                if (clean.length >= 16) {
                  nameFocus.requestFocus();
                }
              },
            ),

            // ================= NAME =================
            _field(
              controller: nameController,
              hint: "Name on card",
              focus: nameFocus,
              onSubmitted: (_) => expiryFocus.requestFocus(),
            ),

            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: expiryController,
                    hint: "MM/YY",
                    keyboard: TextInputType.number,
                    focus: expiryFocus,
                    formatter: ExpiryDateFormatter(),
                    onSubmitted: (_) => cvvFocus.requestFocus(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: cvvController,
                    hint: "CVV",
                    keyboard: TextInputType.number,
                    obscure: true,
                    focus: cvvFocus,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(_cvvMaxLength),
                    ],
                  ),
                ),
              ],
            ),

            // ================= SAVE CARD =================
            Row(
              children: [
                Checkbox(
                  value: saveCard,
                  onChanged: (v) {
                    setState(() => saveCard = v ?? false);
                  },
                ),
                const Text("Save card for future payments"),
              ],
            ),

            const Spacer(),

            // ================= PAY BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C6EF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: (isValid && !loading) ? _payNow : null,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Pay ₹${widget.amount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INPUT FIELD =================
  Widget _field({
  required TextEditingController controller,
  required String hint,
  TextInputType keyboard = TextInputType.text,
  TextInputFormatter? formatter,
  List<TextInputFormatter>? formatters,
  Widget? suffix,
  FocusNode? focus,
  bool obscure = false,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6),
      ],
    ),
    child: TextField(
      controller: controller,
      focusNode: focus,
      keyboardType: keyboard,
      obscureText: obscure,
      inputFormatters:
          formatters ?? (formatter != null ? [formatter] : []),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        suffixIcon: suffix,
      ),
    ),
  );
}

}

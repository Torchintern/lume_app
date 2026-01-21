import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import '../utils/card_utils.dart';
import '../utils/card_formatters.dart';

class AddCardAndPayScreen extends StatefulWidget {
  final int regId;
  final double amount;

  const AddCardAndPayScreen({
    super.key,
    required this.regId,
    required this.amount,
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
        cvvController.text.length >= _cvvMaxLength; // ✅ FIXED
  }

  // ================= ADD CARD =================
  Future<void> _addCard() async {
    setState(() => loading = true);

    final success = await ApiService.saveCard(
      regId: widget.regId,
      cardNumber: cardController.text.replaceAll(' ', ''),
      name: nameController.text.trim(),
      expiry: expiryController.text,
      brand: _brand.name,
      cardType: _cardType.name,
    );

    if (!mounted) return;
    setState(() => loading = false);

    _showResultDialog(
      success: success,
      message:
          success ? "Card added successfully" : "Unable to add card",
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
                  onPressed: () {
                    Navigator.pop(context);
                    if (success) Navigator.pop(context, true);
                  },
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
          "Add new card",
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
                  } else if (detectedBrand == CardBrand.rupay) {
                    _cardType = CardType.debit;
                    _cvvMaxLength = 3;
                  } else {
                    final firstDigit =
                        int.tryParse(clean[0]) ?? 9;
                    _cardType = firstDigit <= 4
                        ? CardType.debit
                        : CardType.credit;
                    _cvvMaxLength = 3;
                  }

                  if (cvvController.text.length >
                      _cvvMaxLength) {
                    cvvController.clear();
                  }
                });

                if (clean.length >= 16) {
                  nameFocus.requestFocus();
                }
              },
            ),

            // ================= CARD TYPE MESSAGE =================
            if (_brand != CardBrand.unknown)
              Padding(
                padding:
                    const EdgeInsets.only(left: 4, bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _cardType == CardType.debit
                          ? "Debit Card"
                          : "Credit Card",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // ================= NAME =================
            _field(
              controller: nameController,
              hint: "Name on card",
              focus: nameFocus,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) =>
                  expiryFocus.requestFocus(),
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
                    onChanged: (_) =>
                        setState(() {}), // ✅ FIXED
                    onSubmitted: (_) =>
                        cvvFocus.requestFocus(),
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
                      LengthLimitingTextInputFormatter(
                          _cvvMaxLength),
                    ],
                    onChanged: (_) =>
                        setState(() {}), // ✅ FIXED
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ================= ADD CARD BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (isValid && !loading) ? _addCard : null,
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text(
                        "Add card",
                        style: TextStyle(
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
    Function(String)? onChanged,
    Function(String)? onSubmitted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focus,
        keyboardType: keyboard,
        obscureText: obscure,
        inputFormatters:
            formatters ??
                (formatter != null ? [formatter] : []),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ).copyWith(hintText: hint, suffixIcon: suffix),
      ),
    );
  }
}

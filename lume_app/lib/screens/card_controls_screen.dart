import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CardControlsScreen extends StatefulWidget {
  final int regId;

  const CardControlsScreen({super.key, required this.regId});

  @override
  State<CardControlsScreen> createState() => _CardControlsScreenState();
}

class _CardControlsScreenState extends State<CardControlsScreen> {

  bool posEnabled = false;
  bool onlineEnabled = false;
  bool contactlessEnabled = false;
  bool tokenisedEnabled = false;

  bool loading = true;
  bool hasChanges = false;
  int posLimit = 100000;
  int onlineLimit = 100000;
  int contactlessLimit = 100000;
  int tokenisedLimit = 100000;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    final data = await ApiService.getCardControls(widget.regId);

    setState(() {
      posEnabled = data["pos_enabled"] == 1;
      onlineEnabled = data["online_enabled"] == 1;
      contactlessEnabled = data["contactless_enabled"] == 1;
      tokenisedEnabled = data["tokenised_enabled"] == 1;

      posLimit = data["pos_limit"] ?? 100000;
      onlineLimit = data["online_limit"] ?? 100000;
      contactlessLimit = data["contactless_limit"] ?? 100000;
      tokenisedLimit = data["tokenised_limit"] ?? 100000;

      loading = false;
    });
  }

  int _getLimitByTitle(String title) {
  switch (title) {
    case "POS (In-store)":
      return posLimit;
    case "Online/Ecom":
      return onlineLimit;
    case "Contactless":
      return contactlessLimit;
    case "Tokenised":
      return tokenisedLimit;
    default:
      return 100000;
  }
}

void _setControlValue(String title, bool value) {
  switch (title) {

    case "POS (In-store)":
      posEnabled = value;
      if (!value) posLimit = 0;
      break;

    case "Online/Ecom":
      onlineEnabled = value;
      if (!value) onlineLimit = 0;
      break;

    case "Contactless":
      contactlessEnabled = value;
      if (!value) contactlessLimit = 0;
      break;

    case "Tokenised":
      tokenisedEnabled = value;
      if (!value) tokenisedLimit = 0;
      break;
  }
}


void _setLimitValue(String title, int limit) {
  switch (title) {
    case "POS (In-store)":
      posLimit = limit;
      break;
    case "Online/Ecom":
      onlineLimit = limit;
      break;
    case "Contactless":
      contactlessLimit = limit;
      break;
    case "Tokenised":
      tokenisedLimit = limit;
      break;
  }
}

void _openLimitSheet({
  required String title,
  required int currentLimit,
  required Function(int) onSave,
}) {
  double tempLimit = currentLimit == 0 ? 1000 : currentLimit.toDouble();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent, 
    isScrollControlled: true,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    "Set transaction limit to enable this feature",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4C6EF5),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    "₹ ${tempLimit.toInt()}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Slider(
                  value: tempLimit,
                  min: 1,
                  max: 100000,
                  divisions: 100,
                  activeColor: const Color(0xFF4C6EF5),
                  onChanged: (value) {
                    setModalState(() {
                      tempLimit = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF4C6EF5),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onSave(tempLimit.toInt());
                    },
                    child: const Text("Enable & Save"),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}



  Widget _controlTile({
  required IconData icon,
  required String title,
  required bool value,
}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: Row(
        children: [

          /// ICON BOX (matches Card Center)
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF4C6EF5)),
          ),

          const SizedBox(width: 14),

          Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value
                    ? "Limit: ₹${_getLimitByTitle(title).toString().replaceAllMapped(
                        RegExp(r'\B(?=(\d{3})+(?!\d))'),
                        (match) => ',',
                      )}"
                    : "Disabled",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: value
                      ? const Color(0xFF4C6EF5)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),


          Switch(
          value: value,
          activeColor: const Color(0xFF4C6EF5),
          onChanged: (val) {
          /// TURNING OFF → direct
          if (value == true) {
            setState(() {
              _setControlValue(title, false);
              hasChanges = true;
            });
            return;
          }

          /// TURNING ON → ask limit
          _openLimitSheet(
            title: title,
            currentLimit: _getLimitByTitle(title),
            onSave: (limit) {
              setState(() {
                _setControlValue(title, true);
                _setLimitValue(title, limit);
                hasChanges = true;
              });
            },
          );
        },

        ),



        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    await ApiService.updateCardControls(
    regId: widget.regId,
    posEnabled: posEnabled,
    posLimit: posLimit,
    onlineEnabled: onlineEnabled,
    onlineLimit: onlineLimit,
    contactlessEnabled: contactlessEnabled,
    contactlessLimit: contactlessLimit,
    tokenisedEnabled: tokenisedEnabled,
    tokenisedLimit: tokenisedLimit,
  );
    setState(() => hasChanges = false);
    _showResultDialog(
      success: true,
      message: "Your card control settings have been updated.",
    );
  }

  Future<bool> _confirmExit() async {

  if (!hasChanges) return true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (_) {
      return Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
                Icons.warning_amber_rounded,
                size: 36,
                color: Color(0xFF4C6EF5),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "Leave without saving?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "You have unsaved changes. If you leave now, they will be lost.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),

            const SizedBox(height: 24),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C6EF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _saveChanges();
                },
                child: const Text("Save changes"),
              ),
            ),

            const SizedBox(height: 10),

            /// LATER BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8ECFF),
                  foregroundColor: const Color(0xFF4C6EF5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text("I'll do it later"),
              ),
            ),
          ],
        ),
      );
    },
  );

  return result == true;
}


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
              decoration: const BoxDecoration(
                color: Color(0xFFE8ECFF),
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
              success ? "Changes Saved" : "Action Failed",
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

            /// DONE BUTTON
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


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
    onWillPop: _confirmExit,
    child: Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
      title: const Text("Card controls & limits"),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          final canLeave = await _confirmExit();
          if (canLeave && mounted) Navigator.pop(context);
        },
      ),

        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.public_off,
                  size: 18,
                  color: Color(0xFF4C6EF5),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "These controls apply only to domestic transactions",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4C6EF5),
                    ),
                  ),
                ),
              ],
            ),
          ),


            _controlTile(
              icon: Icons.store,
              title: "POS (In-store)",
              value: posEnabled,
            ),


            _controlTile(
              icon: Icons.shopping_cart_outlined,
              title: "Online/Ecom",
              value: onlineEnabled,
            ),

            _controlTile(
              icon: Icons.nfc,
              title: "Contactless",
              value: contactlessEnabled,
            ),

            _controlTile(
              icon: Icons.security,
              title: "Tokenised",
              value: tokenisedEnabled,
            ),

            const Spacer(),

            /// SAVE BUTTON (Dashboard Style)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: hasChanges ? _saveChanges : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C6EF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Save changes",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

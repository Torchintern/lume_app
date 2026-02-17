import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pin_settings_screen.dart';
import 'pin_verify_screen.dart';
import 'card_controls_screen.dart';
class CardCentreScreen extends StatefulWidget {
  final int regId;
  final String maskedNumber;

  const CardCentreScreen({
    super.key,
    required this.regId,
    required this.maskedNumber,
  });

  @override
  State<CardCentreScreen> createState() => _CardCentreScreenState();
}

class _CardCentreScreenState extends State<CardCentreScreen> {

  bool tapPayEnabled = false;
  bool ncmcEnabled = false;
  bool isCardBlocked = false;
  bool loadingCardState = true;

  bool get _cardDisabled => isCardBlocked;
  bool loadingTapPay = true;
  bool loadingNcmc = true;
  bool _notificationChanged = false;
  bool isCardLocked = false;
  bool loadingLockState = true;


  @override
  void initState() {
    super.initState();
    _loadSwitches();
    _loadCardLockState(); 
    _loadCardState();

  }

  Future<void> _loadCardState() async {
  try {
    final status = await ApiService.getCardStatus(widget.regId);

    if (!mounted) return;

    setState(() {
      isCardLocked = status["is_locked"] == true;
      isCardBlocked = status["is_blocked"] == true;
      loadingCardState = false;
    });

  } catch (_) {
    setState(() => loadingCardState = false);
  }
}


  Future<void> _loadSwitches() async {
    try {
      final tap = await ApiService.getTapPayStatus(widget.regId);
      final ncmc = await ApiService.getNcmcStatus(widget.regId);

      if (!mounted) return;

      setState(() {
        tapPayEnabled = tap;
        ncmcEnabled = ncmc;
        loadingTapPay = false;
        loadingNcmc = false;
      });
    } catch (_) {
      setState(() {
        loadingTapPay = false;
        loadingNcmc = false;
      });
    }
  }

Future<void> _loadCardLockState() async {
  try {
    final status = await ApiService.getCardStatus(widget.regId);
    if (!mounted) return;

    setState(() {
      isCardLocked = status["is_locked"] == true;
      loadingLockState = false;
    });
  } catch (_) {
    setState(() => loadingLockState = false);
  }
}

  Future<bool> _verifyCardSecurity() async {
    FocusScope.of(context).unfocus();

    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PinVerifyScreen(
          regId: widget.regId,
          type: "card",
        ),
      ),
    );

    await _loadSwitches(); 
    return verified == true;
  }



Future<void> _toggleTapPay(bool value) async {
  setState(() => tapPayEnabled = value);

  try {
    await ApiService.toggleTapPay(widget.regId, value);

    _showFeatureToast(
      value ? "Tap & Pay enabled" : "Tap & Pay disabled",
      value ? Icons.nfc : Icons.do_not_disturb_on,
    );


    await ApiService.createCardFeatureNotification(
      regId: widget.regId,
      title: "Tap & Pay ${value ? "Enabled" : "Disabled"}",
      body: value
          ? "Your card can now be used for contactless payments."
          : "Contactless payments have been disabled.",
    );

    _notificationChanged = true;

  } catch (_) {
    setState(() => tapPayEnabled = !value);
  }
}



Future<void> _toggleNcmc(bool value) async {
  setState(() => ncmcEnabled = value);

  try {
    await ApiService.toggleNcmc(widget.regId, value);

    _showFeatureToast(
      value ? "Transit payments enabled" : "Transit payments disabled",
      value ? Icons.directions_bus : Icons.block,
    );

    await ApiService.createCardFeatureNotification(
      regId: widget.regId,
      title: "NCMC ${value ? "Enabled" : "Disabled"}",
      body: value
          ? "You can now pay in metro & buses using your card."
          : "Transit payments are turned off.",
    );

    _notificationChanged = true;

  } catch (_) {
    setState(() => ncmcEnabled = !value);
  }
}


void _startLockFlow() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isCardLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                size: 36,
                color: const Color(0xFF4C6EF5),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isCardLocked ? "Unlock Card?" : "Lock Card?",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            Text(
              isCardLocked
                  ? "Your card will be enabled for ATM, POS and online transactions."
                  : "Your card will be temporarily disabled for ATM, POS and online transactions.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showProcessingSheet(locking: !isCardLocked);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C6EF5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(isCardLocked ? "Yes, Unlock" : "Yes, Lock"),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFE8ECFF),
                  foregroundColor: const Color(0xFF4C6EF5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Cancel"),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showBlockCardSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// Drag indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 24),

            /// Card Preview (matches dashboard card header)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Image.asset(
                    "assets/card/rupay.png",
                    width: 50,
                    height: 30,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Prepaid Card",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.maskedNumber,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Title
            const Text(
              "Block This Card?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            /// Subtitle
            Text(
              "This will permanently deactivate your card for all offline and online transactions.\n\nIf you would like to use this card in future, we suggest locking it instead.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 28),

            /// BLOCK BUTTON
            SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isCardLocked
                  ? null
                  : () {
                      Navigator.pop(context);
                      _startLockFlow();
                    },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    isCardLocked ? Colors.grey.shade200 : const Color(0xFFE8ECFF),
                foregroundColor:
                    isCardLocked ? Colors.grey : const Color(0xFF4C6EF5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Lock for Now",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),


            const SizedBox(height: 12),

            /// BLOCK BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                    final confirm = await _confirmBlockDialog();

                    if (confirm == true) {
                      Navigator.pop(context);
                      _showBlockProcessingSheet();
                    }
                  },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C6EF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Block Card",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          ],
        ),
      );
    },
  );
}

void _showReplaceCardSheet() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) {

      bool apiCalled = false;
      bool done = false;

      return StatefulBuilder(
        builder: (context, setModalState) {

          if (!apiCalled) {
            apiCalled = true;

            Future.microtask(() async {
              try {
                await ApiService.replaceCard(widget.regId);

                setModalState(() => done = true);

                await ApiService.createCardFeatureNotification(
                  regId: widget.regId,
                  title: "Card Replacement Ordered",
                  body: "Your new card will be issued shortly.",
                );

                _notificationChanged = true;

                await Future.delayed(const Duration(seconds: 3));

                if (Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop();
                  Navigator.pop(context, "replaced");

                }

              } catch (e) {
                Navigator.pop(sheetContext);
              }
            });
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 34),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(height: 20),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: done
                      ? Container(
                          height: 72,
                          width: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4C6EF5),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 36),
                        )
                      : const SizedBox(
                          height: 72,
                          width: 72,
                          child: CircularProgressIndicator(strokeWidth: 4),
                        ),
                ),

                const SizedBox(height: 24),

                Text(
                  done ? "Order Confirmed" : "Placing your order...",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Your replacement card will be delivered soon.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );
    },
  );
}


void _showBlockProcessingSheet() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) {

      bool apiCalled = false;
      bool done = false;

      return StatefulBuilder(
        builder: (context, setModalState) {

          if (!apiCalled) {
            apiCalled = true;

            Future.microtask(() async {
              try {
                final blocked = await ApiService.blockCard(widget.regId);
                if (!mounted) return;
                setState(() => isCardBlocked = blocked);
                setModalState(() => done = true);
                await _loadCardState();
                await _loadSwitches();
                await ApiService.createCardFeatureNotification(
                  regId: widget.regId,
                  title: "Card Blocked",
                  body: "Your card has been permanently blocked.",
                );

                _notificationChanged = true;

                _showSecurityToast(true);

                await Future.delayed(const Duration(seconds: 2));

                if (Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop();
                }

              } catch (e) {
                if (Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop();
                }
              }
            });
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 34),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(height: 28),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: done
                      ? Container(
                          height: 72,
                          width: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4C6EF5),
                          ),
                          child: const Icon(Icons.block, color: Colors.white, size: 36),
                        )
                      : const SizedBox(
                          height: 72,
                          width: 72,
                          child: CircularProgressIndicator(strokeWidth: 4),
                        ),
                ),

                const SizedBox(height: 24),

                Text(
                  done
                      ? "Your card has been blocked"
                      : "Blocking your card...",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 10),

                Text(
                  "This card can no longer be used for payments.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}



void _showProcessingSheet({required bool locking}) {

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) {

      bool apiCalled = false;
      bool done = false;
      String last4 = widget.maskedNumber.replaceAll("**** ", "");

      return StatefulBuilder(
        builder: (context, setModalState) {

          if (!apiCalled) {
            apiCalled = true;

            Future.microtask(() async {

              final locked = await ApiService.toggleCardLock(widget.regId);

              final fetchedLast4 =
                  await ApiService.getCardLast4(widget.regId);

              if (!mounted) return;

              setState(() => isCardLocked = locked);

              setModalState(() {
                done = true;
                last4 = fetchedLast4 ?? last4;
              });

              await _loadCardState();
              await _loadSwitches();

              await ApiService.createCardFeatureNotification(
                regId: widget.regId,
                title: locked ? "Card Locked" : "Card Unlocked",
                body: locked
                    ? "Your card is temporarily disabled."
                    : "Your card is now active for transactions.",
              );

              _notificationChanged = true;
        
              _showSecurityToast(locked);
        
              await Future.delayed(const Duration(seconds: 2));

              if (!mounted) return;
              if (Navigator.of(sheetContext).canPop()) {
                Navigator.of(sheetContext).pop();
              }


            });
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 34),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(height: 28),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: done
                      ? Container(
                          height: 72,
                          width: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4C6EF5),
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                        )
                      : const SizedBox(
                          height: 72,
                          width: 72,
                          child: CircularProgressIndicator(strokeWidth: 4),
                        ),
                ),

                const SizedBox(height: 24),

                Text(
                  done
                      ? "XXXX $last4 is now ${locking ? "locked" : "unlocked"}!"
                      : (locking ? "Locking your card..." : "Unlocking your card..."),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 10),

                if (done)
                  Text(
                    locking
                        ? "Your card is temporarily disabled."
                        : "Your card is now active for transactions.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showSecurityToast(bool locked) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 110,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: Row(
            children: [
              Icon(locked ? Icons.lock : Icons.lock_open, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  locked ? "Your card has been locked" : "Your card has been unlocked",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 3), () => entry.remove());
}

void _showFeatureToast(String text, IconData icon) {
 final overlay = Overlay.of(context, rootOverlay: true);
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 110,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 3), () => entry.remove());
}

Future<bool?> _confirmBlockDialog() {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Block Card Permanently?",
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          "This action cannot be undone. Your card will be permanently deactivated and cannot be used again.",
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [

          /// Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),

          /// Confirm button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C6EF5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Block Card"),
          ),
        ],
      );
    },
  );
}

Future<bool?> _confirmReplaceDialog() {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// ICON
              Container(
                height: 70,
                width: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8ECFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: Color(0xFF4C6EF5),
                  size: 36,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "Replace this card?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "You'll be Replaced with a New Lume Card.\nYou must set a new PIN to activate the New Lume card.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 22),

              Row(
                children: [

                  /// CANCEL
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFE8ECFF),
                        foregroundColor: const Color(0xFF4C6EF5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// CONFIRM
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C6EF5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Replace"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}


  Widget tile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [

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
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            trailing ??
                const Icon(Icons.chevron_right,
                    size: 20,
                    color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget divider() => const Padding(
        padding: EdgeInsets.only(left: 74),
        child: Divider(height: 1),
      );

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
     appBar: AppBar(
      title: const Text("Card centre"),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context, _notificationChanged);
        },
      ),
    ),


      body: ListView(
        children: [

          /// CARD HEADER (MATCH DASHBOARD STYLE)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isCardBlocked ? Colors.grey.shade200 : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 14),
              ],
            ),
            child: Row(
              children: [

                Image.asset(
                    "assets/card/rupay.png",
                    width: 60,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(width: 14),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Prepaid Card",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.maskedNumber,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          /// OPTIONS CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 12),
              ],
            ),
            child: Column(
              children: [

                /// NCMC
                tile(
                  icon: Icons.directions_bus_outlined,
                  title: "NCMC",
                  trailing: loadingNcmc
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch(
                        value: ncmcEnabled,
                        onChanged: (_cardDisabled || loadingNcmc)
                          ? null
                          : (value) async {

                              final verified = await _verifyCardSecurity();

                              if (!verified) {
                                setState(() {});
                                return;
                              }

                              _toggleNcmc(value);
                            },

                        activeColor: const Color(0xFF4C6EF5),
                      ),
                ),
                divider(),

                /// TAP & PAY
                tile(
                  icon: Icons.nfc,
                  title: "Tap & Pay",
                  trailing: loadingTapPay
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch(
                        value: tapPayEnabled,
                        onChanged: (_cardDisabled || loadingTapPay)
                        ? null
                        : (value) async {

                            final verified = await _verifyCardSecurity();

                            if (!verified) {
                              setState(() {}); // restore UI
                              return;
                            }

                            _toggleTapPay(value);
                          },

                        activeColor: const Color(0xFF4C6EF5),
                      ),
                ),
                divider(),

                /// PIN
                tile(
                  icon: Icons.pin_outlined,
                  title: "Card PIN",
                  onTap: isCardBlocked ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(  
                        builder: (_) => PinSettingsScreen(
                          regId: widget.regId,
                          initialTab: "card",
                        ),
                      ),
                    );
                  },
                ),
                divider(),

                /// LOCK
                tile(
                    icon: isCardLocked ? Icons.lock_open : Icons.lock_outline,
                    title: isCardLocked ? "Unlock this card?" : "Lock this card?",
                    onTap: (loadingLockState || isCardBlocked) ? null : _startLockFlow,
                  ),


                divider(),

                /// BLOCK
                tile(
                icon: Icons.block,
                title: isCardBlocked ? "Replace card" : "Block & replace card",
                onTap: () async {
                  if (!isCardBlocked) {
                    _showBlockCardSheet();
                    return;
                  }
                  final confirm = await _confirmReplaceDialog();
                  if (confirm == true) {
                    _showReplaceCardSheet();
                  }
                },
              ),


                divider(),

                /// LIMITS
                tile(
                  icon: Icons.settings_outlined,
                  title: "Card controls/limits",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CardControlsScreen(regId: widget.regId),
                      ),
                    );
                  },
                ),

                divider(),

                /// BENEFIT
                tile(
                  icon: Icons.card_giftcard,
                  title: "Card benefits",
                ),
                divider(),

                /// HELP
                tile(
                  icon: Icons.help_outline,
                  title: "Help",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

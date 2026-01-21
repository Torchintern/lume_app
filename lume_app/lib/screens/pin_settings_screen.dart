import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PinSettingsScreen extends StatefulWidget {
  final int regId;

  const PinSettingsScreen({
    super.key,
    required this.regId,
  });

  @override
  State<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

class _PinSettingsScreenState extends State<PinSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String walletPinPreview = "";
  String cardPinPreview = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _savePin({
    required bool isWallet,
    required String pin,
  }) async {
    // ================= WALLET ≠ CARD =================
    if (isWallet && cardPinPreview.isNotEmpty && pin == cardPinPreview) {
      _showDialog(
        title: "Invalid PIN",
        message: "Wallet PIN and Card PIN cannot be the same.",
      );
      return;
    }

    if (!isWallet && walletPinPreview.isNotEmpty && pin == walletPinPreview) {
      _showDialog(
        title: "Invalid PIN",
        message: "Wallet PIN and Card PIN cannot be the same.",
      );
      return;
    }

    // ================= API CALL =================
    final success = await ApiService.setPin(
      regId: widget.regId,
      type: isWallet ? "wallet" : "card",
      pin: pin,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        if (isWallet) {
          walletPinPreview = pin;
        } else {
          cardPinPreview = pin;
        }
      });

      _showDialog(
        title: "PIN Updated",
        message: isWallet
            ? "Wallet PIN updated successfully."
            : "Card PIN updated successfully.",
        closeScreen: true,
      );
    } else {
      _showDialog(
        title: "Error",
        message: "Failed to update PIN. Please try again.",
      );
    }
  }

  void _showDialog({
    required String title,
    required String message,
    bool closeScreen = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (closeScreen) {
                Navigator.pop(context);
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set PIN"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Wallet"),
            Tab(text: "Card"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PinTab(
            title: "Wallet PIN",
            isNew: walletPinPreview.isEmpty,
            onSave: (pin) => _savePin(isWallet: true, pin: pin),
          ),
          _PinTab(
            title: "Card PIN",
            isNew: cardPinPreview.isEmpty,
            onSave: (pin) => _savePin(isWallet: false, pin: pin),
          ),
        ],
      ),
    );
  }
}

class _PinTab extends StatefulWidget {
  final String title;
  final bool isNew;
  final Function(String) onSave;

  const _PinTab({
    required this.title,
    required this.isNew,
    required this.onSave,
  });

  @override
  State<_PinTab> createState() => _PinTabState();
}

class _PinTabState extends State<_PinTab> {
  final TextEditingController _pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isNew
                ? "Create a new 4-digit PIN"
                : "Change your 4-digit PIN",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Enter 4-digit PIN",
              counterText: "",
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final pin = _pinController.text.trim();
                if (pin.length != 4) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      title: const Text("Invalid PIN"),
                      content:
                          const Text("PIN must be exactly 4 digits."),
                      actions: [
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                widget.onSave(pin);
                _pinController.clear();
              },
              child: Text(
                widget.isNew ? "Create PIN" : "Update PIN",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

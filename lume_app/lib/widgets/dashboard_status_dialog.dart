import 'package:flutter/material.dart';

enum StatusDialogType {
  success,
  failed,
  pending,
}

class DashboardStatusDialog extends StatefulWidget {
  final StatusDialogType type;
  final String title;
  final String message;

  /// Auto close dialog after duration
  final Duration? autoCloseDuration;

  /// Show OK button or not
  final bool showButton;

  const DashboardStatusDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.autoCloseDuration,
    this.showButton = true,
  });

  @override
  State<DashboardStatusDialog> createState() =>
      _DashboardStatusDialogState();
}

class _DashboardStatusDialogState
    extends State<DashboardStatusDialog> {

  @override
  void initState() {
    super.initState();

    /// AUTO CLOSE SUPPORT
    if (widget.autoCloseDuration != null) {
      Future.delayed(widget.autoCloseDuration!, () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
  }

  Color get bgColor {
    switch (widget.type) {
      case StatusDialogType.success:
        return const Color(0xFFE9F9EF);
      case StatusDialogType.failed:
        return const Color(0xFFFFEBEB);
      case StatusDialogType.pending:
        return const Color(0xFFFFF4E5);
    }
  }

  Color get iconBgColor {
    switch (widget.type) {
      case StatusDialogType.success:
        return const Color(0xFFD4F5DD);
      case StatusDialogType.failed:
        return const Color(0xFFFFD6D6);
      case StatusDialogType.pending:
        return const Color(0xFFFFE2B8);
    }
  }

  Color get iconColor {
    switch (widget.type) {
      case StatusDialogType.success:
        return Colors.green;
      case StatusDialogType.failed:
        return Colors.red;
      case StatusDialogType.pending:
        return Colors.orange;
    }
  }

  IconData get icon {
    switch (widget.type) {
      case StatusDialogType.success:
        return Icons.check_circle_rounded;
      case StatusDialogType.failed:
        return Icons.cancel_rounded;
      case StatusDialogType.pending:
        return Icons.pending_actions_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ===== ICON =====
            Container(
              height: 66,
              width: 66,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 34,
                color: iconColor,
              ),
            ),

            const SizedBox(height: 18),

            // ===== TITLE =====
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            // ===== MESSAGE =====
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),

            if (widget.showButton) ...[
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C6EF5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

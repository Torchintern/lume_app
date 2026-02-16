import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/dashboard_screen.dart';
import 'dart:async';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  List<dynamic> notifications = [];
  List<dynamic> filtered = [];
  bool loading = true;
  dynamic _pendingDelete;
  int? _pendingDeleteIndex;
  Timer? _deleteTimer;
  List<dynamic>? _pendingClearAll;
  Timer? _clearAllTimer;
  bool showSwipeHint = false;
  bool _hintShownOnce = false;


  final TextEditingController searchController = TextEditingController();

 @override
  void initState() {
    super.initState();
    loadNotifications();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hintShownOnce) {
        _triggerSwipeHint();
        _hintShownOnce = true;
      }
    });
  }

  void _triggerSwipeHint() {
  setState(() => showSwipeHint = true);

  Future.delayed(const Duration(seconds: 3), () {
    if (!mounted) return;
    setState(() => showSwipeHint = false);
  });
}

  /// ================= LOAD =================
  Future loadNotifications() async {
  try {
    final regId = ApiService.currentUserRegId;
    if (regId == null) return;

    final res = await ApiService.getAllNotifications(regId);

    setState(() {
      notifications = res;
      filtered = res;
      loading = false;
    });

    final dashboard =
        context.findAncestorStateOfType<DashboardScreenState>();

    await dashboard?.loadUnreadCount();

  } catch (e) {
    print("NOTIFICATION LOAD ERROR: $e");
    setState(() => loading = false);
  }
}

  // Message
  void showUndoDeleteBanner() {

  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 80,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF4C6EF5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10),
            ],
          ),
          child: Row(
            children: [

              const Icon(Icons.delete, color: Colors.white),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  "Notification removed",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              GestureDetector(
              onTap: () {
                _deleteTimer?.cancel();

                setState(() {
                  if (_pendingDelete != null && _pendingDeleteIndex != null) {
                    notifications.insert(_pendingDeleteIndex!, _pendingDelete);
                    filtered = List.from(notifications);
                  }
                });

                entry.remove();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "UNDO",
                  style: TextStyle(
                    color: Color(0xFF4C6EF5),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            )

            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  /// AUTO DELETE AFTER 3 SEC
  _deleteTimer = Timer(const Duration(seconds: 3), () async {
    entry.remove();

    if (_pendingDelete != null) {
      await ApiService.deleteNotification(_pendingDelete["id"]);
    }
  });
}

void _showUndoClearAllBanner() {

  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 80,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF4C6EF5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10),
            ],
          ),
          child: Row(
            children: [

              const Icon(Icons.delete_sweep, color: Colors.white),
              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  "All notifications cleared",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  _clearAllTimer?.cancel();

                  setState(() {
                    if (_pendingClearAll != null) {
                      notifications = List.from(_pendingClearAll!);
                      filtered = List.from(notifications);
                    }
                  });

                  entry.remove();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "UNDO",
                    style: TextStyle(
                      color: Color(0xFF4C6EF5),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
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

  /// delayed delete
  _clearAllTimer = Timer(const Duration(seconds: 3), () async {
    entry.remove();

    if (_pendingClearAll != null) {
      final regId = ApiService.currentUserRegId;
      if (regId != null) {
        await ApiService.deleteAllNotifications(regId);
      }
    }
  });
}


  /// ================= SEARCH =================
  void onSearch(String q) {
    if (q.isEmpty) {
      setState(() => filtered = notifications);
      return;
    }

    final lower = q.toLowerCase();

    setState(() {
      filtered = notifications.where((n) {
        return (n["title"] ?? "")
                .toString()
                .toLowerCase()
                .contains(lower) ||
            (n["message"] ?? "")
                .toString()
                .toLowerCase()
                .contains(lower);
      }).toList();
    });
  }

  /// ================= MARK READ =================
  Future markRead(int notifId) async {
    try {
      await ApiService.markNotificationRead(notifId);

      setState(() {
      for (var n in notifications) {
        if (n["id"] == notifId) {
          n["is_read"] = 1;
        }
      }

      for (var n in filtered) {
        if (n["id"] == notifId) {
          n["is_read"] = 1;
        }
      }
    });


    } catch (e) {
      print("MARK READ ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!loading && notifications.isNotEmpty)
            TextButton(
              onPressed: _clearAllNotifications,
              child: const Text(
                "Clear all",
                style: TextStyle(
                  color: Color(0xFF4C6EF5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],

      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                /// SEARCH BAR
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearch,
                    decoration: InputDecoration(
                      hintText: "Search notifications",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                /// LIST
                /// Swipe hint
                AnimatedOpacity(
                  opacity: showSwipeHint ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.swipe_left, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(
                          "Swipe left to remove",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: filtered.isEmpty
                      ? _emptyView()
                      : _listView(),
                ),

              ],
            ),
    );
  }
void _clearAllNotifications() async {

  _pendingClearAll = List.from(notifications);

  setState(() {
    notifications.clear();
    filtered.clear();
  });

  final dashboard =
      context.findAncestorStateOfType<DashboardScreenState>();

  await dashboard?.loadUnreadCount();
  await dashboard?.loadUnrevealedRewardsCount();

  _showUndoClearAllBanner();
}

  /// ================= EMPTY =================
  Widget _emptyView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none,
                size: 36, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "No notifications found",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= LIST WITH DATE LABELS =================
  Widget _listView() {

    Map<String, List<dynamic>> grouped = {};

    for (var n in filtered) {

      final dt = (DateTime.tryParse(n["created_at"] ?? "") ??
            DateTime.now())
        .toLocal();

      final key = _dateLabel(dt);

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(n);
    }

    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: keys.length,
      itemBuilder: (_, i) {

        final label = keys[i];
        final items = grouped[label]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// DATE LABEL
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),

            ...items.map(_notificationTile).toList(),

            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  /// ================= SINGLE TILE =================
  Widget _notificationTile(dynamic n) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Dismissible(
        key: Key(n["id"].toString()),
        direction: DismissDirection.endToStart, // Right → Left

        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),

       onDismissed: (_) async {
      _pendingDelete = n;
      _pendingDeleteIndex = notifications.indexWhere((e) => e["id"] == n["id"]);

      setState(() {
        notifications.removeWhere((e) => e["id"] == n["id"]);
        filtered.removeWhere((e) => e["id"] == n["id"]);
      });

      final dashboard =
          context.findAncestorStateOfType<DashboardScreenState>();

      await dashboard?.loadUnreadCount();
      await dashboard?.loadUnrevealedRewardsCount();

      showUndoDeleteBanner();
    },



        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final regId = ApiService.currentUserRegId;
            if (regId == null) return;

            final user =
                await ApiService.getStudentDetails(regId);

            await markRead(n["id"]);
            final dashboard =
              context.findAncestorStateOfType<DashboardScreenState>();

          await dashboard?.loadUnreadCount();
          await dashboard?.loadUnrevealedRewardsCount();
          

            if (n["type"] == "system") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardScreen(
                  regId: regId,
                  fullName: user["full_name"],
                  mobile: user["mobile"],
                  upiId: user["upi_id"],
                  walletStatus: user["wallet_status"],
                  aadhaarVerified: user["aadhaar_verified"],
                  panVerified: user["pan_verified"],
                  initialTab: "pay",
                  openSplitId: n["ref_id"],
                ),
              ),
            );
          }
          else if (n["type"] == "card_spend") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardScreen(
                  regId: regId,
                  fullName: user["full_name"],
                  mobile: user["mobile"],
                  upiId: user["upi_id"],
                  walletStatus: user["wallet_status"],
                  aadhaarVerified: user["aadhaar_verified"],
                  panVerified: user["pan_verified"],
                  initialTab: "card",
                ),
              ),
            );
          }
          else if (n["type"] == "reward") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardScreen(
                  regId: regId,
                  fullName: user["full_name"],
                  mobile: user["mobile"],
                  upiId: user["upi_id"],
                  walletStatus: user["wallet_status"],
                  aadhaarVerified: user["aadhaar_verified"],
                  panVerified: user["pan_verified"],
                  initialTab: "rewards",
                ),
              ),
            );
          }
          else if (n["type"] == "reward_earned") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardScreen(
                    regId: regId,
                    fullName: user["full_name"],
                    mobile: user["mobile"],
                    upiId: user["upi_id"],
                    walletStatus: user["wallet_status"],
                    aadhaarVerified: user["aadhaar_verified"],
                    panVerified: user["pan_verified"],
                    initialTab: "rewards",
                  ),
                ),
              );
            }


          },

          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: n["is_read"] == 1
                  ? Colors.grey.shade100
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),

            child: Row(
              children: [

                if (n["is_read"] == 0)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4C6EF5),
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        n["title"] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n["message"] ?? "",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= DATE LABEL HELPER =================
  String _dateLabel(DateTime d) {
    final now = DateTime.now();

    if (d.year == now.year &&
        d.month == now.month &&
        d.day == now.day) return "Today";

    final y = now.subtract(const Duration(days: 1));

    if (d.year == y.year &&
        d.month == y.month &&
        d.day == y.day) return "Yesterday";

    return "${d.day}/${d.month}/${d.year}";
  }
}

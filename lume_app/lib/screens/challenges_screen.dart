import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/tier_assets.dart';
import 'package:intl/intl.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}
class _ChallengesScreenState extends State<ChallengesScreen> {

  bool loading = true;

  int rewardPoints = 0;
  String tier = "silver";

  DateTime? cycleStart;
  DateTime? cycleEnd;

  @override
  void initState() {
    super.initState();
    loadData();
  }

Future<void> loadData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final regId = prefs.getInt("reg_id");

    if (regId == null) {
      if (mounted) {
        setState(() => loading = false);
      }
      return;
    }

    final data = await ApiService.getStudentDetails(regId);

    final points =
        int.tryParse((data["reward_points"] ?? 0).toString()) ?? 0;

    final backendTier =
        (data["tier"] ?? "silver").toString().toLowerCase();

    final cycleStartStr = data["tier_cycle_start"];

    DateTime start;

    if (cycleStartStr != null) {
      try {
        start = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'")
            .parseUtc(cycleStartStr)
            .toLocal();
      } catch (e) {
        print("Cycle date parse failed: $e");
        start = DateTime.now();
      }
    } else {
      start = DateTime.now();
    }


    final end = DateTime(
      start.year,
      start.month + 3,
      start.day,
    ).subtract(const Duration(days: 1));

    setState(() {
      rewardPoints = points;
      tier = backendTier;
      cycleStart = start;
      cycleEnd = end;
      loading = false;
    });
    } catch (e) {
    print("Challenges load error: $e");

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

}
// Tier helpers 
String get tierLabel =>
    tier[0].toUpperCase() + tier.substring(1);

IconData get tierIcon {
  if (tier == "diamond") return Icons.diamond;
  if (tier == "platinum") return Icons.diamond;
  if (tier == "gold") return Icons.emoji_events;
  return Icons.star;
}
double get progress {

  if (tier == "diamond") {
    return ((rewardPoints - 1501) / 699).clamp(0, 1);
  }

  if (tier == "platinum") {
    return ((rewardPoints - 901) / 599).clamp(0, 1);
  }

  if (tier == "gold") {
    return ((rewardPoints - 401) / 499).clamp(0, 1);
  }

  // silver
  return (rewardPoints / 400).clamp(0, 1);
}

// Date formates
String formatDate(DateTime d) {
  const months = [
    "Jan","Feb","Mar","Apr","May","Jun",
    "Jul","Aug","Sep","Oct","Nov","Dec"
  ];
  return "${months[d.month-1]} ${d.day}";
}
// Tier Range Helpers
int get minPoints {
  if (tier == "diamond") return 1501;
  if (tier == "platinum") return 901;
  if (tier == "gold") return 401;
  return 0;
}

int get maxPoints {
  if (tier == "diamond") return 2200;
  if (tier == "platinum") return 1500;
  if (tier == "gold") return 900;
  return 400;
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF8FA3AD),
        leading: const BackButton(color: Colors.white),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "Learn more",
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
      body: loading
    ? const Center(child: CircularProgressIndicator())
    : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: const BoxDecoration(
              color: Color(0xFF8FA3AD),
            ),
            child: Column(
              children: [
                Image.asset(
                  getTierAsset(tier),
                  height: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  "Lume $tierLabel",
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                if (cycleEnd != null)
                  Text(
                    "until ${formatDate(cycleEnd!)}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          /// DATE RANGE
          if (cycleStart != null && cycleEnd != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "${formatDate(cycleStart!)} - ${formatDate(cycleEnd!)}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),

          const SizedBox(height: 10),

          /// POINTS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "$rewardPoints points",
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// PROGRESS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// LEFT MIN POINTS
                    Text(
                      "$minPoints",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    /// RIGHT ICON + MAX POINTS
                    Row(
                      children: [
                        Image.asset(
                          getTierAsset(tier),
                          height: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$maxPoints",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
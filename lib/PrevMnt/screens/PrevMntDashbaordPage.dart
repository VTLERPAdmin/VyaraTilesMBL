import 'package:flutter/material.dart';
import 'PrevMntEquipmentDetailsPage.dart';
import '../screens/task_utils.dart';

class PrevMntDashbaordPage extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const PrevMntDashbaordPage({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final user = userData ?? {};

    String userName = user["UserName"] ?? "User";
    bool isSupervisor = user["IsSupervisor"] ?? false;

    List eqList = user["EqTypeSumm"] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ================= HEADER =================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06224D),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            color: Color(0xFF06224D)),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Good Morning",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSupervisor
                                  ? "Supervisor: $userName"
                                  : "Employee: $userName",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ================= STATS (REMOVED LOGIC → API ONLY) =================
                Row(
                  children: [
                    _statCard(
                      "Total",
                      _safe(eqList, "TotalTasks"),
                      Colors.blue,
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      "Pending",
                      _safe(eqList, "PendingTasks"),
                      Colors.orange,
                    ),
                    _statCard(
                      "Completed",
                      _safe(eqList, "CompletedTasks"),
                      Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ================= EQUIPMENT LIST =================
                Column(
                  children: List.generate(eqList.length, (index) {
                    final eq = eqList[index];

                    int total = eq["TotalTasks"] ?? 0;
                    int done = (eq["Tasks"] as List?)
                            ?.where((t) => TaskUtils.isDone(t["StatusID"] ?? 0))
                            .length ??
                        0;

                    double progress = total == 0 ? 0 : done / total;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrevMntEquipmentDetailsPage(
                              empId: user["EmpID"] ?? 0,
                              eqTypeId: eq["EqTypeID"] ?? 0,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eq["EqType"] ?? "-",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),

                            Text(
                              "Total: $total | Completed: $done",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 10),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade300,
                                color: Colors.green,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "${(progress * 100).toStringAsFixed(0)}% Completed",
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= SAFE VALUE HELPER =================
  int _safe(List list, String key) {
    int total = 0;
    for (var item in list) {
      total += (item[key] ?? 0) as int;
    }
    return total;
  }

  // ================= UI CARD =================
  Widget _statCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              "$value",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }
}
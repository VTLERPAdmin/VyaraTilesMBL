import 'package:flutter/material.dart';
import '../services/PrevMnt_api_services.dart';
import 'PrevMntTaskScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrevMntEquipmentDetailsPage extends StatefulWidget {
  final int empId;
  final int eqTypeId;

  const PrevMntEquipmentDetailsPage({
    super.key,
    required this.empId,
    required this.eqTypeId,
  });

  @override
  State<PrevMntEquipmentDetailsPage> createState() =>
      _PrevMntEquipmentDetailsPageState();
}

class _PrevMntEquipmentDetailsPageState
    extends State<PrevMntEquipmentDetailsPage> {
  bool loading = true;
  List equipmentList = [];
  String userRole = "Employee";

  @override
  void initState() {
    super.initState();
    getUserRole();
    loadData();
  }

  Future<void> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userRole = prefs.getString("role") ?? "";
    });
  }

  Future<void> loadData() async {
    try {
      final res = await PrevMntApiService.getEquipmentList(
        widget.empId,
        widget.eqTypeId,
      );

      equipmentList = res["EqSumm"] ?? [];
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      loading = false;
    });
  }

  String getFrequency(int value) {
    switch (value) {
      case 1:
        return "Hourly";
      case 2:
        return "Daily";
      case 3:
        return "Weekly";
      case 4:
        return "Monthly";
      case 5:
        return "Quarterly";
      case 6:
        return "Half Yearly";
      case 7:
        return "Yearly";
      default:
        return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF06224D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Equipment Details",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: equipmentList.length,

              itemBuilder: (context, index) {
                final item = equipmentList[index];

                // ✅ ONLY FIX: no stat calculation logic anymore
                int total = item["TotalTasks"] ?? 0;
                int pending = item["PendingTasks"] ?? 0;
                int completed = item["CompletedTasks"] ?? 0;

                return GestureDetector(
                  onTap: () {
                    final result = Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrevMntTaskScreen(
                          empId: widget.empId,
                          eqId: item["EqID"],
                        ),
                      ),
                    );

                    if (result == true) {
                      setState(() {
                        loading = true;
                      });
                      loadData();
                    }
                  },

                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          item["EqName"] ?? "-",
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF06224D),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ================= STATS UI (UNCHANGED) =================
                        Row(
                          children: [
                            _box("Total", "$total", Colors.blue),
                            const SizedBox(width: 8),
                            _box("Pending", "$pending", Colors.orange),
                            const SizedBox(width: 8),
                            _box("Done", "$completed", Colors.green),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _info(
                          "Frequency",
                          getFrequency(item["Frequency"] ?? 0),
                        ),

                        if (userRole != "Employee")
                          _info(
                            "Assigned Employee",
                            item["AssignedEmpName"] ?? "-",
                          ),

                        if (userRole != "Supervisor")
                          _info(
                            "Supervisor",
                            item["AssignedSupervisorName"] ?? "-",
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _box(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          const Text(": "),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
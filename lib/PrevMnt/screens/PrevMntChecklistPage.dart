import 'package:flutter/material.dart';
import '../services/PrevMnt_api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrevMntChecklistPage extends StatefulWidget {
  const PrevMntChecklistPage({super.key});

  @override
  State<PrevMntChecklistPage> createState() => _PrevMntChecklistPageState();
}

class _PrevMntChecklistPageState extends State<PrevMntChecklistPage> {
  bool loading = true;
  List tasks = [];

  String role = "";
  String userName = "";
  int userId = 0;

  Map<int, TextEditingController> notes = {};

  @override
  void initState() {
    super.initState();
    init();
  }

  // ================= INIT USER =================
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    role = prefs.getString("role") ?? "Employee";
    userName = prefs.getString("userName") ?? "";
    userId = prefs.getInt("userId") ?? 0;

    await loadTasks();
  }

  // ================= LOAD TASKS (FIXED SAFE VERSION) =================

Future<void> loadTasks() async {
  try {
    final res = await PrevMntApiService.getPrevMntTask();

    debugPrint("=== RAW RESPONSE START ===");
    debugPrint(res.toString());
    debugPrint("TYPE: ${res.runtimeType}");
    debugPrint("=== RAW RESPONSE END ===");

    tasks = [];

    setState(() {
      loading = false;
    });
  } catch (e) {
    debugPrint("ERROR: $e");

    setState(() {
      loading = false;
    });
  }
}
  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ================= EMPTY STATE =================
    if (tasks.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            "No tasks found",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // ================= MAIN UI =================
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checklist"),
        backgroundColor: const Color(0xFF06224D),
      ),

      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final t = tasks[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t["TaskHeading"] ?? "-",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Equipment: ${t["EqName"] ?? "-"}",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: notes[index],
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Notes",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Employee: ${t["AssignedEmpName"] ?? "-"}",
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Supervisor: ${t["ReviewedBy"] ?? "Pending"}",
                    style: const TextStyle(color: Colors.green),
                  ),

                  if ((t["ReviewNotes"] ?? "").toString().isNotEmpty)
                    Text(
                      "Remarks: ${t["ReviewNotes"]}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
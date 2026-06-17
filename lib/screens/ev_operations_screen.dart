import 'package:flutter/material.dart';
import '../models/ev_model.dart';
import '../services/api_services.dart';
import '../services/session_manager.dart';
import '../screens/ev_detail_screen.dart';
import '../screens/loader_service.dart';

class EVOperationsScreen extends StatefulWidget {
  const EVOperationsScreen({super.key});

  @override
  State<EVOperationsScreen> createState() => _EVOperationsScreenState();
}

class _EVOperationsScreenState extends State<EVOperationsScreen> {
  List<EVModel> evList = [];
  bool loading = true;


@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    loadEV();
  });
}

Future<void> loadEV() async {
  try {
    LoaderService.show(
      context,
      title: "Loading EV List",
      subtitle: "Please wait...",
    );

    final userId = await SessionManager.getUserId();

    final data = await ApiService.getEVList(userId);

    if (!mounted) return;

    setState(() {
      evList = data;
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  } finally {
    LoaderService.hide();

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xFF06224D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "EV List",
          style: TextStyle(color: Colors.white),
        ),
      ),

      // ================= BODY =================
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              itemCount: evList.length,
              itemBuilder: (context, index) {
                final ev = evList[index];

                return InkWell(
                 onTap: () async {
  try {
    final userId = await SessionManager.getUserId();

    final detail = await ApiService.getEVDetails(
      userId: userId,
      eqId: ev.eqId,
    );

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EVDetailScreen(
          detail: detail,
        ),
      ),
    );

    if (result == true) {
      await loadEV();
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
},

                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(isTablet ? 14 : 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ================= NAME + ICON =================
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06224D).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.electric_bolt,
                                size: 18,
                                color: Color(0xFF06224D),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                ev.eqName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF06224D),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ================= EQ TYPE =================
                        _row("Eq Type", ev.eqType),

                        const SizedBox(height: 4),

                        // ================= LOCATION =================
                        _row("Location", ev.locName),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ================= ROW WIDGET =================
  Widget _row(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            "$label:",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../screens/so_status_screen.dart';
import '../screens/loader_service.dart';

class SalesOrderScreen extends StatelessWidget {
  const SalesOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF06224D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Sales Order",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),

          onTap: () async {
            try {
              // 1. SHOW LOADER
              LoaderService.show(
                context,
                title: "Loading",
                subtitle: "Opening SO Status...",
              );

              // 2. small delay (optional UI smoothness)
              await Future.delayed(const Duration(milliseconds: 300));

              // 3. HIDE LOADER BEFORE NAVIGATION (IMPORTANT FIX)
              LoaderService.hide();

              if (!context.mounted) return;

              // 4. NAVIGATE
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SoStatusScreen(),
                ),
              );
            } catch (e) {
              LoaderService.hide(); // safety fallback
              debugPrint("Error: $e");
            }
          },

          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                )
              ],
            ),
            child: const Center(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.receipt_long, color: Colors.white),
                ),
                title: Text(
                  "SO Status Report",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Generate sales order PDF report"),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
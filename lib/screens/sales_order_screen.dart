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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= SALES ORDER (PLACEHOLDER) =================
            _moduleCard(
              context: context,
              title: "Sales Order",
              subtitle: "Create & Manage Orders",
              icon: Icons.assignment_outlined,
              iconBg: const Color(0xFFFFF1E6),
              iconColor: const Color(0xFFEA580C),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "This module will be avilable here soon",
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // ================= SO STATUS REPORT =================
            _moduleCard(
              context: context,
              title: "SO Status Report",
              subtitle: "Generate sales order PDF report",
              icon: Icons.receipt_long,
              iconBg: const Color(0xFFFFF4E5),
              iconColor: const Color(0xFFF59E0B),
              onTap: () async {
                try {
                  LoaderService.show(
                    context,
                    title: "Loading",
                    subtitle: "Opening SO Status...",
                  );

                  await Future.delayed(const Duration(milliseconds: 300));

                  LoaderService.hide();

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SoStatusScreen(),
                    ),
                  );
                } catch (e) {
                  LoaderService.hide();
                  debugPrint("Error: $e");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= REUSABLE MODULE CARD (matches ERP dashboard style) =================
  Widget _moduleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
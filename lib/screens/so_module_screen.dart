import 'package:flutter/material.dart';
import '../screens/loader_service.dart';
import 'so_approval_screen.dart';
import 'so_acknowledge_screen.dart';

class SOModuleScreen extends StatelessWidget {
  const SOModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF06224D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Sales Order",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// ================= SO APPROVAL =================
            _moduleCard(
              context: context,
              title: "SO Approval",
              subtitle: "Approve pending sales orders",
              icon: Icons.fact_check,
              iconBg: const Color(0xFFEDE9FE),
              iconColor: const Color(0xFF4F46E5),
              onTap: () async {
                LoaderService.show(
                  context,
                  title: "Loading",
                  subtitle: "Opening SO Approval...",
                );

                await Future.delayed(
                  const Duration(milliseconds: 250),
                );

                LoaderService.hide();

                if (!context.mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SOApprovalScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            /// ================= SO ACKNOWLEDGE =================
            _moduleCard(
              context: context,
              title: "SO Acknowledge",
              subtitle: "Acknowledge approved sales orders",
              icon: Icons.assignment_turned_in_outlined,
              iconBg: const Color(0xFFE7F8EF),
              iconColor: const Color(0xFF059669),
              onTap: () async {
                LoaderService.show(
                  context,
                  title: "Loading",
                  subtitle: "Opening SO Acknowledge...",
                );

                await Future.delayed(
                  const Duration(milliseconds: 250),
                );

                LoaderService.hide();

                if (!context.mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SOAcknowledgeScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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

            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

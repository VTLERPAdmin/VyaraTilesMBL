// ===============================
// FILE: screens/movable_asset_hub_screen.dart
// ===============================
//
// Entry screen for the Movable Asset menu, in the same style as the
// Sales Order screen: two cards, "Movable Asset Sent" (the existing
// issue screen) and "Movable Asset Receive".

import 'package:flutter/material.dart';
import '../screens/movable_asset_screen.dart';
import '../screens/movable_asset_receive_screen.dart';

class MovableAssetHubScreen extends StatelessWidget {
  const MovableAssetHubScreen({super.key});

  static const primaryBlue = Color(0xFF06275B);
  static const backgroundColor = Color(0xFFF5F8FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Movable Asset",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _moduleCard(
                  title: "Movable Asset Sent",
                  subtitle: "Issue assets to client / site / agency",
                  icon: Icons.outbox_outlined,
                  iconBg: const Color(0xFFE8F0FE),
                  iconColor: const Color(0xFF2563EB),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MovableAssetScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _moduleCard(
                  title: "Movable Asset Receive",
                  subtitle: "Receive issued assets back",
                  icon: Icons.move_to_inbox_outlined,
                  iconBg: const Color(0xFFE7F8EF),
                  iconColor: const Color(0xFF059669),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MovableAssetReceiveScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Same card as the Sales Order / dashboard module cards.
  Widget _moduleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
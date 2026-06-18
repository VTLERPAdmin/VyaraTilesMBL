import 'package:flutter/material.dart';

import 'PrevMntChecklistPage.dart';
import 'PrevMntDashbaordPage.dart';
import 'history.dart';
import 'spares.dart';

class PrevMntHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PrevMntHomeScreen({
    super.key,
    required this.userData,
  });

  @override
  State<PrevMntHomeScreen> createState() => _PrevMntHomeScreenState();
}

class _PrevMntHomeScreenState extends State<PrevMntHomeScreen> {
  int currentIndex = 0;

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      PrevMntDashbaordPage(userData: widget.userData),

      const PrevMntChecklistPage(),

      const PrevMntSparesPage(),
      const PrevMntHistoryPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: "Aprroved ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: "Spares",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),
        ],
      ),
    );
  }
}
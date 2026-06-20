import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../screens/loader_service.dart';
import '../screens/so_approval_screen.dart';
import 'sales_order_screen.dart';
import '../screens/ledger_screen.dart';
import 'dispatch_plan_screen.dart';
import '../screens/ev_operations_screen.dart';
import '../services/session_manager.dart';
import '../screens/dispatch_plan_report_screen.dart';
import '../PrevMnt/services/PrevMnt_api_services.dart';
import '../PrevMnt/screens/PrevMntHomeScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "User";
  List<String> menus = [];
  bool isLoading = true;
  
  bool get  hasEVPermission => menus.contains("mnuMblEVRead");
  bool get hasPrevMntPermission => menus.contains("mnuPrevMnt");
  String getGreeting() {
  final hour = DateTime.now().hour; 
  

  if (hour >= 5 && hour < 12) {
    return "Good Morning";
  } else if (hour >= 12 && hour < 17) {
    return "Good Afternoon";
  } else if (hour >= 17 && hour < 21) {
    return "Good Evening";
  } else {
    return "Good Night";
  }
}




  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    LoaderService.show(
      context,
      title: "Loading Dashboard",
      subtitle: "Fetching user permissions...",
    );

    loadUser().then((_) {
      LoaderService.hide();
    });
  });
}
 Future<void> loadUser() async {
  final prefs = await SharedPreferences.getInstance();

  userName = prefs.getString("userName") ?? "User";
  menus = (prefs.getStringList("menus") ?? [])
      .map((e) => e.trim())
      .toList();

  setState(() {});
}

  // ================= OPEN PREVENTIVE MAINTENANCE MODULE =================
  Future<void> openPrevMnt(BuildContext context) async {
    LoaderService.show(
      context,
      title: "Loading Preventive Maintenance",
      subtitle: "Authenticating...",
    );

    try {
      final session = await SessionManager.getSession();

      if (session == null) {
        LoaderService.hide();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired. Please log in again.")),
        );
        return;
      }

      final response = await PrevMntApiService.login(
        session["userId"],
        session["password"],
      );

      LoaderService.hide();

      if (!context.mounted) return;

      if (response["StatusCode"] == 200) {
        // Save role/userName for screens inside the module that read from prefs
        final prefs = await SharedPreferences.getInstance();
        bool isSupervisor = response["IsSupervisor"] ?? false;
        await prefs.setString("role", isSupervisor ? "Supervisor" : "Employee");
        await prefs.setString("userName", response["UserName"] ?? userName);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrevMntHomeScreen(userData: response),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["Message"] ?? "Preventive Maintenance login failed")),
        );
      }
    } catch (e) {
      LoaderService.hide();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void logout() {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 34,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "Confirm Logout",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Do you want to logout as\n$userName ?",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("No"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs =
                            await SharedPreferences.getInstance();

                        await prefs.clear();

                        if (!context.mounted) return;

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Yes",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final menuMap = {
    "mnuProdDOPlanSOItem": true,
    "mnuRptDispatchDispPlans": true,
    "mnuRptLedgerMkt": true,
    "mnuRptSOStatus": true,
    "mnuRptWOStatus": true,
    "mnuProdSOAppr": true,
  };

  final visibleMenus = menus
      .where((e) => menuMap.containsKey(e.trim()))
      .toList();


    int crossAxisCount = 2;
    if (width > 1200) crossAxisCount = 5;
    else if (width > 900) crossAxisCount = 4;
    else if (width > 700) crossAxisCount = 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
    appBar: PreferredSize(
  preferredSize: const Size.fromHeight(130),
  child: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF061A3A),
          Color(0xFF0A3A80),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 15,
          offset: Offset(0, 5),
        )
      ],
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // LEFT TEXT
            Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // GREETING
      Text(
        getGreeting(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      const SizedBox(height: 4),

      // USERNAME + ICON (FIXED PROPERLY)
     Row(
  mainAxisSize: MainAxisSize.min,
  children: [

    const Icon(
      Icons.person_2_rounded,
      size: 16,
      color: Colors.white70,
    ),

    const SizedBox(width: 6),

    Flexible(
      child: Text(
        userName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    const SizedBox(width: 6),

    const Text(
      "👋",
      style: TextStyle(fontSize: 14),
    ),
  ],
),

      const SizedBox(height: 6),

      // SUBTITLE
      const Text(
        "Welcome to Vyara Tiles ERP App",
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
    ],
  ),
),

            // LOGOUT BUTTON
            InkWell(
              onTap: logout,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
      body: Stack(
  children: [

    // MAIN UI
    SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 15,
          right: 15,
          top: 8,
          bottom: 15,
        ),
        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        const Text(
                        "ERP Operations",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                          const SizedBox(height: 12),
                    // ================= ERP GRID =================
                    GridView.builder(
                      padding: EdgeInsets.zero,
                      //itemCount: menus.length,
                      itemCount: visibleMenus.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 145,
                      ),
                      itemBuilder: (context, index) {
                       // return _buildCard(context, menus[index]);
                        return _buildCard(context, visibleMenus[index]);
                      },
                    ),

                    const SizedBox(height: 15),

                    if (hasEVPermission) ...[
  const Text(
    "EV Operations",
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Color(0xFF111827),
    ),
  ),

  const SizedBox(height: 12),

  InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EVOperationsScreen(),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.ev_station,
              color: Color(0xFF2563EB),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "EV Operations",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Vehicle Management",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  ),

  const SizedBox(height: 25),
],
if (hasPrevMntPermission) ...[
  const Text(
    "Preventive Maintenance",
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Color(0xFF111827),
    ),
  ),

  const SizedBox(height: 12),

  InkWell(
    onTap: () {
      openPrevMnt(context);
    },
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
              color: const Color(0xFFE7F8EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              color: Color(0xFF059669),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Preventive Maintenance",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Machine Service Scheduling",
                  style: TextStyle(
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
  ),
],


            
                                        ],
                                      ),
                                    ),
                                  ),
                        ],
                            ),
                            );
                        }

  Widget _buildCard(BuildContext context, String menu) {
    final cleanMenu = menu.trim();

    final Map<String, dynamic> map = {
  "mnuProdDOPlanSOItem": {
    "title": "Dispatch Planning",
    "subtitle": "Plan Dispatch",
    "icon": Icons.local_shipping_outlined,
    "color": const Color.fromARGB(255, 236, 240, 32),
  },
  "mnuRptDispatchDispPlans": {
  "title": "Planning Report",
  "subtitle": "Dispatch Plan Analytics",
  "icon": Icons.analytics_outlined,
  "color": const Color(0xFF0891B2),
},

  "mnuRptLedgerMkt": {
    "title": "Ledger",
    "subtitle": "Customer Reports",
    "icon": Icons.bar_chart,
    "color": const Color(0xFF8B5CF6),
  },

  "mnuRptSOStatus": {
    "title": "SO Status Report",
    "subtitle": "Sales Order Tracking",
    "icon": Icons.receipt_long,
    "color": const Color(0xFFF59E0B),
  },

  "mnuRptWOStatus": {
    "title": "Work Orders",
    "subtitle": "Manufacturing",
    "icon": Icons.engineering,
    "color": const Color(0xFF6B7280),
  },

  "mnuProdSOAppr": {
    "title": "SO Approval",
    "subtitle": "Pending Approval",
    "icon": Icons.fact_check,
    "color": const Color(0xFF4F46E5),
  },
};

    final item = map[cleanMenu];

    if (item == null) return const SizedBox();

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();

        switch (cleanMenu) {
          case "mnuRptSOStatus":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SalesOrderScreen()),
            );
            break;

          case "mnuRptLedgerMkt":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LedgerScreen()),
            );
            break;

          case "mnuProdSOAppr":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SOApprovalScreen()),
            );
            break;

          case "mnuProdDOPlanSOItem":
            SessionManager.getUserId().then((userId) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DispatchPlanScreen(userId: userId),
                ),
              );
            });
            break;

            case "mnuRptDispatchDispPlans":
          SessionManager.getUserId().then((userId) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DispatchPlanReportScreen(
                  userId: userId,
                ),
              ),
            );
          });
          break;

          default:
            debugPrint("Unknown menu: $cleanMenu");
        }
      },
      child: Container(
        decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
       child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: item["color"].withOpacity(.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item["icon"],
                      color: item["color"],
                      size: 28,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    item["title"],
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    item["subtitle"],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../screens/loader_service.dart';
import '../models/dispatch_plan_report_model.dart';

class DispatchPlanReportScreen extends StatefulWidget {
  final String userId;

  const DispatchPlanReportScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<DispatchPlanReportScreen> createState() =>
      _DispatchPlanReportScreenState();
}

class _DispatchPlanReportScreenState
    extends State<DispatchPlanReportScreen> {
  static const Color primaryColor = Color(0xff06275B);

  DispatchPlanReportModel? model;

  int? selectedFactory;
int? selectedMktPerson;

String? selectedClientGroup;
int? selectedClient;
int? selectedSite;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchFilters();
    });
  }

  Future<void> fetchFilters() async {
    LoaderService.show(
      context,
      title: "Loading",
      subtitle: "Fetching filters...",
    );

    try {
      final uri = Uri.parse(
        "https://vyaratiles.co.in/Api/DispPlanRptData?UserID=${widget.userId}",
      );

      debugPrint("API CALL => $uri");

      final response = await http.get(uri);

      debugPrint("STATUS => ${response.statusCode}");
      debugPrint("BODY => ${response.body}");

      if (response.statusCode != 200) {
        throw Exception(
          "Server returned status ${response.statusCode}",
        );
      }

      final jsonData = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        model = DispatchPlanReportModel.fromJson(jsonData);
      });
    } catch (e) {
      debugPrint("FETCH FILTER ERROR => $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    } finally {
      LoaderService.hide();
    }
  }

  bool isGenerating = false;

  Future<void> generateReport() async {
    if (isGenerating) return;

    setState(() {
      isGenerating = true;
    });

    LoaderService.show(
      context,
      title: "Generating Report",
      subtitle: "Please wait...",
    );

    try {
      final uri = Uri.parse(
        "https://vyaratiles.co.in/Api/DispPlanReport",
      );

     final body = {
  "UserID": widget.userId,
  "MktPersonID": selectedMktPerson ?? 0,
  "FactoryID": selectedFactory ?? 0,

  "ClientGroup": selectedClientGroup ?? "",
  "ClientID": selectedClient ?? 0,
  "SiteID": selectedSite ?? 0,
};
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      debugPrint("REPORT STATUS => ${response.statusCode}");
      debugPrint("REPORT BODY => ${response.body}");

      final data = jsonDecode(response.body);

      final reportUrl = data["Message"];

      if (reportUrl != null &&
          reportUrl.toString().trim().isNotEmpty) {
        final fixedUrl = reportUrl.toString().startsWith("http")
            ? reportUrl.toString()
            : "https:$reportUrl";

        await launchUrl(
          Uri.parse(fixedUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No report generated"),
          ),
        );
      }
    } catch (e) {
      debugPrint("REPORT ERROR => $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    } finally {
      LoaderService.hide();

      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Dispatch Plan Report",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.02,
        ),
        child: Column(
          children: [
            _filterCard(w),
            SizedBox(height: h * 0.02),
            _actionCard(w),
          ],
        ),
      ),
    );
  }

  Widget _filterCard(double w) {
    return Card(
  color: Colors.white,
  surfaceTintColor: Colors.white,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
      child: Padding(
        padding: EdgeInsets.all(w * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Filters",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              value: selectedFactory,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Factory",
                border: OutlineInputBorder(),
                 filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),
              items: model?.factories.map((e) {
                    return DropdownMenuItem<int>(
                      value: e.id,
                      child: Text(
                        e.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList() ??
                  [],
              onChanged: (value) {
                setState(() {
                  selectedFactory = value;
                });
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              value: selectedMktPerson,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Marketing Person",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),
              items: model?.mktPersons.map((e) {
                    return DropdownMenuItem<int>(
                      value: e.id,
                      child: Text(
                        e.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList() ??
                  [],
              onChanged: (value) {
                setState(() {
                  selectedMktPerson = value;
                });
              },
            ),

            const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedClientGroup,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Client Group",
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
            ),
            items: model?.clientGroups.map((e) {
                  return DropdownMenuItem<String>(
                    value: e,
                    child: Text(
                      e,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList() ??
                [],
            onChanged: (value) {
              setState(() {
                selectedClientGroup = value;

                selectedClient = null;
                selectedSite = null;
              });
            },
          ),

          const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              value: selectedClient,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Client",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),

              items: model?.clients
                  .where((client) =>
                      selectedClientGroup == null ||
                      client.clientGroup == selectedClientGroup)
                  .map((e) {

                    return DropdownMenuItem<int>(
                      value: e.id,
                      child: Text(
                        e.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );

                  }).toList() ?? [],

              onChanged: (value) {

                setState(() {

                  selectedClient = value;
                  selectedSite = null;

                });

              },
            ),

            const SizedBox(height: 12),

DropdownButtonFormField<int>(
  value: selectedSite,
  isExpanded: true,
  decoration: const InputDecoration(
    labelText: "Site",
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
  ),

  items: model?.clients
      .firstWhere(
        (client) => client.id == selectedClient,
        orElse: () => model!.clients.first,
      )
      .sites
      .map((site) {

        return DropdownMenuItem<int>(
          value: site.siteId,
          child: Text(
            site.siteName,
            overflow: TextOverflow.ellipsis,
          ),
        );

      }).toList() ?? [],


  onChanged: (value){

    setState((){

      selectedSite = value;

    });

  },

),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(double w) {
    return Card(
      elevation: 0,
      color: Colors.white,
  surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: EdgeInsets.all(w * 0.04),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedFactory = null;
                      selectedMktPerson = null;
                      selectedClientGroup = null;
                      selectedClient = null;
                      selectedSite = null;
                    });
                  },
                  child: const Text(
                    "RESET",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: w * 0.03),

            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: isGenerating
                      ? null
                      : generateReport,
                  child: isGenerating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "GENERATE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
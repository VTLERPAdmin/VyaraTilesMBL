import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/session_manager.dart';
import '../services/api_services.dart';
import '../models/so_status_model.dart';
import '../screens/loader_service.dart';

class SoStatusScreen extends StatefulWidget {
  const SoStatusScreen({super.key});

  @override
  State<SoStatusScreen> createState() => _SoStatusScreenState();
}

class _SoStatusScreenState extends State<SoStatusScreen> {
  bool loading = true;
  bool generating = false;

  SoStatusModel? model;

  DropdownItemModel? selectedStatus;
  DropdownItemModel? selectedLocation;
  DropdownItemModel? selectedUnit;
  DropdownItemModel? selectedEqType;
  DropdownItemModel? selectedMktPerson;

  String? selectedClientGroup;
  ClientModel? selectedClient;
  SiteModel? selectedSite;
  ProductGroupModel? selectedProductGroup;
  ProductModel? selectedProduct;

  final TextEditingController soNoController = TextEditingController();
  final TextEditingController poNoController = TextEditingController();
  final TextEditingController startsWithController = TextEditingController();
  final TextEditingController containsController = TextEditingController();

  bool withStock = true;
  bool clubOrders = false;
  bool clubSites = false;
  bool clubLots = false;

String userId = "";
String token = "";
  

 @override
void initState() {
  super.initState();
  loadSession();
}

  Future<void> loadSession() async {
  final session = await SessionManager.getSession();

  if (session != null) {
    userId = session["userId"] ?? "";
    token = "ab";

    print("CURRENT USER => $userId");

    await loadFilters();
  } else {
    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Session expired. Please login again."),
      ),
    );
  }
}

  Future<void> loadFilters() async {
  LoaderService.show(
    context,
    title: "Loading SO Status",
    subtitle: "Fetching filter data...",
  );

  try {
    final data = await ApiService.getSOFilters(userId, token);

    if (!mounted) return;

    setState(() {
      model = data;
      loading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  } finally {
    LoaderService.hide();
  }
}
 Future<void> generateReport() async {
  

  LoaderService.show(
    context,
    title: "Generating Report",
    subtitle: "Please wait...",
  );

  try {
    final body = {
      "SOStatusID": selectedStatus?.id ?? 0,
      "ForLocID": selectedLocation?.id ?? 0,
      "ClientGroup": selectedClientGroup ?? "",
      "ClientID": selectedClient?.id ?? 0,
      "SiteID": selectedSite?.siteId ?? 0,
      "MktPersonID": selectedMktPerson?.id ?? 0,
      "ProductGroupID": selectedProductGroup?.id ?? 0,
      "ProductID": selectedProduct?.id ?? 0,
      "EqTypeID": selectedEqType?.id ?? 0,
      "SONo": soNoController.text.trim(),
      "PONo": poNoController.text.trim(),
      "ProductStartsWith": startsWithController.text.trim(),
      "ProductContains": containsController.text.trim(),
      "WithStock": withStock ? 1 : 0,
      "ClubOrders": clubOrders ? 1 : 0,
      "ClubSites": clubSites ? 1 : 0,
      "ClubLots": clubLots ? 1 : 0,
      "UnitID": selectedUnit?.id ?? 0,
    };

    final pdfUrl = await ApiService.getSOStatusReport(
      userId: userId,
      token: token,
      body: body,
    );

    if (pdfUrl.isNotEmpty) {
      await launchUrl(Uri.parse(pdfUrl),
          mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    String message = e.toString().replaceAll("Exception:", "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Message"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  } finally {
    LoaderService.hide();
    
  }
}

  @override
Widget build(BuildContext context) {

  // 🔴 SAFE CHECK (THIS IS THE FIX)
 if (loading || model == null) {
  return const Scaffold(
    backgroundColor: Color(0xFFF5F8FF),
    body: SizedBox(),
  );
}

 // final data = model!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF06224D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "SO Status",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600 ? 600 : constraints.maxWidth;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    buildDropdown(
                        "Status", selectedStatus, model!.soStatus, (v) {
                      setState(() => selectedStatus = v);
                    }),

                    buildDropdown(
                        "Location", selectedLocation, model!.forLocs, (v) {
                      setState(() => selectedLocation = v);
                    }),

                    buildStringDropdown(
                        "Client Group", selectedClientGroup, model!.clientGroups,
                        (v) {
                      setState(() => selectedClientGroup = v);
                    }),

                    buildClientDropdown(),
                    buildSiteDropdown(),

                    buildDropdown("Marketing Person", selectedMktPerson,
                        model!.mktPersons, (v) {
                      setState(() => selectedMktPerson = v);
                    }),

                    buildProductGroupDropdown(),
                    buildProductDropdown(),

                    buildDropdown("Equipment Type", selectedEqType,
                        model!.eqTypes, (v) {
                      setState(() => selectedEqType = v);
                    }),

                    buildTextField("SO No", soNoController),
                    buildTextField("PO No", poNoController),
                    buildTextField(
                        "Product Starts With", startsWithController),
                    buildTextField("Product Contains", containsController),

                    CheckboxListTile(
                        value: withStock,
                        onChanged: (v) =>
                            setState(() => withStock = v ?? false),
                        title: const Text("With Stock")),

                    CheckboxListTile(
                        value: clubOrders,
                        onChanged: (v) =>
                            setState(() => clubOrders = v ?? false),
                        title: const Text("Club Orders")),

                    CheckboxListTile(
                        value: clubSites,
                        onChanged: (v) =>
                            setState(() => clubSites = v ?? false),
                        title: const Text("Club Sites")),

                    CheckboxListTile(
                        value: clubLots,
                        onChanged: (v) =>
                            setState(() => clubLots = v ?? false),
                        title: const Text("Club Lots")),

                    buildDropdown(
                        "Unit", selectedUnit, model!.units, (v) {
                      setState(() => selectedUnit = v);
                    }),

                    const SizedBox(height: 20),
                                SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF06224D),
                                            ),
                                            onPressed: generating ? null : generateReport,
                                            child: const Text(
                                              "Generate Report",
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        )
                                                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTextField(String title, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: title,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget buildDropdown(String title, DropdownItemModel? value,
      List<DropdownItemModel> items, Function(DropdownItemModel?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<DropdownItemModel>(
        value: items.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: title,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        items: items
            .map((e) =>
                DropdownMenuItem(value: e, child: Text(e.name)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget buildStringDropdown(String title, String? value,
      List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: title,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        items: items
            .map((e) =>
                DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget buildClientDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<ClientModel>(
        value: selectedClient,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: "Client",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        items: model!.clients
            .map((e) =>
                DropdownMenuItem(value: e, child: Text(e.name)))
            .toList(),
        onChanged: (v) {
          setState(() {
            selectedClient = v;
            selectedSite = null;
          });
        },
      ),
    );
  }

  Widget buildSiteDropdown() {
    final sites = selectedClient?.sites ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<SiteModel>(
        value: selectedSite,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: "Site",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        items: sites
            .map((e) =>
                DropdownMenuItem(value: e, child: Text(e.siteName)))
            .toList(),
        onChanged: (v) {
          setState(() => selectedSite = v);
        },
      ),
    );
  }

  Widget buildProductGroupDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<ProductGroupModel>(
        value: selectedProductGroup,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: "Product Group",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        items: model!.productGroups
            .map((e) => DropdownMenuItem(
                value: e, child: Text(e.productGroup)))
            .toList(),
        onChanged: (v) {
          setState(() {
            selectedProductGroup = v;
            selectedProduct = null;
          });
        },
      ),
    );
  }

  Widget buildProductDropdown() {
    final products = selectedProductGroup?.products ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<ProductModel>(
        value: selectedProduct,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: "Product",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        items: products
            .map((e) =>
                DropdownMenuItem(value: e, child: Text(e.productName)))
            .toList(),
        onChanged: (v) {
          setState(() => selectedProduct = v);
        },
      ),
    );
  }
}
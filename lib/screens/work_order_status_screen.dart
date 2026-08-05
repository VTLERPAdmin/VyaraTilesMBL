import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/session_manager.dart';
import '../services/api_services.dart';
import '../models/work_order_status_model.dart';
import '../screens/loader_service.dart';

class WorkOrderStatusScreen extends StatefulWidget {
  const WorkOrderStatusScreen({super.key});

  @override
  State<WorkOrderStatusScreen> createState() => _WorkOrderStatusScreenState();
}

class _WorkOrderStatusScreenState extends State<WorkOrderStatusScreen> {
  bool loading = true;
  bool generating = false;

  WorkOrderStatusModel? model;

  DropdownItemModel? selectedLocation;
  DropdownItemModel? selectedUnit;
  DropdownItemModel? selectedEqType;

  ClientModel? selectedClient;
  SiteModel? selectedSite;
  ProductGroupModel? selectedProductGroup;
  ProductModel? selectedProduct;

  final TextEditingController woNoController = TextEditingController();
  final TextEditingController woDateController = TextEditingController();
  final TextEditingController lotNoController = TextEditingController();
  final TextEditingController startsWithController = TextEditingController();
  final TextEditingController containsController = TextEditingController();

  bool showSite = false;
  bool includeZeroValues = false;

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

      print("WO STATUS CURRENT USER => $userId");

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
      title: "Loading Work Order Status",
      subtitle: "Fetching filter data...",
    );

    try {
      final data = await ApiService.getWOFilters(userId, token);

      if (!mounted) return;

      setState(() {
        model = data;
        loading = false;
        print("✅ WO FILTERS LOADED => Locations: ${data.locations.length}, ProductGroups: ${data.productGroups.length}, Products: ${data.products.length}, Clients: ${data.clients.length}, Equipment: ${data.equipmentTypes.length}, Units: ${data.units.length}, Statuses: ${data.statuses.length}");
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

  Future<void> generateReport(String reportType) async {
    LoaderService.show(
      context,
      title: "Generating Report",
      subtitle: "Please wait...",
    );

    try {
      final body = {
        "ReportType": reportType,
      
        "ForLocID": selectedLocation?.id ?? 0,
        "ClientID": selectedClient?.id ?? 0,
        "SiteID": selectedSite?.siteId ?? 0,
        "ProductGroupID": selectedProductGroup?.id ?? 0,
        "ProductID": selectedProduct?.id ?? 0,
        "EqTypeID": selectedEqType?.id ?? 0,
        "WONo": woNoController.text.trim(),
        "LotNo": lotNoController.text.trim(),
        "ProductStartsWith": startsWithController.text.trim(),
        "ProductContains": containsController.text.trim(),
        "ShowSite": showSite ? 1 : 0,
        "IncludeZeroValues": includeZeroValues ? 1 : 0,
        "UnitID": selectedUnit?.id ?? 0,
      };

      final pdfUrl = await ApiService.getWorkOrderReport(
        userId: userId,
        token: token,
        body: body,
        reportType: reportType,
      );

      if (pdfUrl.isNotEmpty) {
        await launchUrl(Uri.parse(pdfUrl),
            mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      String message = e.toString().replaceAll("Exception:", "");

      if (!mounted) return;
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
    if (loading || model == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F8FF),
        body: SizedBox(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06224D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Work Order Status",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth =
              constraints.maxWidth > 600 ? 600 : constraints.maxWidth;

          return Center(
            child: SingleChildScrollView(
              child: SizedBox(
                width: maxWidth,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Factory/Location
                      buildDropdown(
                        "Factory",
                        selectedLocation,
                        model!.locations,
                        (v) => setState(() => selectedLocation = v),
                        () => setState(() => selectedLocation = null),
                      ),

                      // Product Group
                      buildProductGroupDropdown(),

                      // Product
                      buildProductDropdown(),

                      // Client
                      buildClientDropdown(),

                      // Site
                      buildSiteDropdown(),

                      // Equipment Type
                      buildDropdown(
                        "Equipment",
                        selectedEqType,
                        model!.equipmentTypes,
                        (v) => setState(() => selectedEqType = v),
                        () => setState(() => selectedEqType = null),
                      ),

                      // WO Date + WO No
                      Row(
                        children: [
                          Expanded(
                            child: buildTextField(
                              "WO Date",
                              woDateController,
                              isDate: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: buildTextField("WO No.", woNoController),
                          ),
                        ],
                      ),

                      // Show Site checkbox with better mobile formatting
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Checkbox(
                              value: showSite,
                              onChanged: (v) =>
                                  setState(() => showSite = v ?? false),
                            ),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Show", style: TextStyle(fontSize: 13)),
                                  Text("Site", style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lot No
                      buildTextField("Lot No.", lotNoController),

                      // Unit
                      buildDropdown(
                        "Unit",
                        selectedUnit,
                        model!.units,
                        (v) => setState(() => selectedUnit = v),
                        () => setState(() => selectedUnit = null),
                      ),

                      // Product Filters
                      buildTextField(
                        "Product Name Starts with",
                        startsWithController,
                      ),

                      buildTextField(
                        "Product Name Contains",
                        containsController,
                      ),

                      // Include Zero Values
                      CheckboxListTile(
                        value: includeZeroValues,
                        onChanged: (v) =>
                            setState(() => includeZeroValues = v ?? false),
                        title: const Text("Include Zero Values in Summary"),
                      ),

                      const SizedBox(height: 15),

                      // Report Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildReportButton(
                            "WO-Wise",
                            onPressed: generating
                                ? null
                                : () => generateReport("WO Wise"),
                          ),
                          _buildReportButton(
                            "Equip. Wise",
                            onPressed: generating
                                ? null
                                : () => generateReport("Equ Wise"),
                          ),
                          _buildReportButton(
                            "Summary",
                            onPressed: generating
                                ? null
                                : () => generateReport("Summary"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTextField(String title, TextEditingController controller, {bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        readOnly: isDate,
        onTap: isDate
            ? () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  controller.text =
                      "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year.toString().substring(2)}";
                  setState(() {
                    
                  });
                }

              }
            : null,
        decoration: InputDecoration(
          labelText: title,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
         suffixIcon: isDate
    ? (controller.text.isNotEmpty
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Clear X button
              InkWell(
                onTap: () {
                  controller.clear();
                  setState(() {});
                },
                child: const Icon(
                  Icons.close,
                  size: 18,
                ),
              ),

              const SizedBox(width: 8),

              // Calendar icon
              const Icon(
                Icons.calendar_today,
                size: 18,
              ),

              const SizedBox(width: 8),
            ],
          )
        : const Icon(
            Icons.calendar_today,
            size: 18,
          ))
    : (controller.text.isNotEmpty
        ? InkWell(
            onTap: () {
              controller.clear();
              setState(() {});
            },
            child: const Icon(
              Icons.close,
              size: 18,
            ),
          )
        : null),
        ),
      ),
    );
  }

  Widget buildDropdown(
    String title,
    DropdownItemModel? value,
    List<DropdownItemModel> items,
    Function(DropdownItemModel?) onChanged,
    VoidCallback onClear,
  ) {
    print("🔍 DROPDOWN $title => Items: ${items.length}, Value: ${value?.name}");
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownSearch<DropdownItemModel>(
        selectedItem: value,
        enabled: items.isNotEmpty,

        items: (filter, _) => items,

        itemAsString: (e) => e.name,

        compareFn: (a, b) => a.id == b.id,

        onChanged: (v) => v == null ? onClear() : onChanged(v),

        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: title,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),

        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search $title",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          emptyBuilder: (context, searchEntry) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text("No ${title.toLowerCase()} available"),
            ),
          ),
        ),

        suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(isVisible: true),
        ),
      ),
    );
  }

  Widget buildProductGroupDropdown() {
    print("🔍 PRODUCT GROUP DROPDOWN => Items: ${model!.productGroups.length}, Value: ${selectedProductGroup?.name}");
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownSearch<ProductGroupModel>(
        selectedItem: selectedProductGroup,
        enabled: model!.productGroups.isNotEmpty,
        

        items: (filter, _) => model!.productGroups,

        itemAsString: (e) => e.name,

        compareFn: (a, b) => a.id == b.id,

        onChanged: (v) => setState(() => selectedProductGroup = v),

        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Group",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),

        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              
              hintText: "Search Group",
              prefixIcon: const Icon(Icons.search),
              
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          emptyBuilder: (context, searchEntry) => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text("No groups available"),
            ),
          ),
        ),

        suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(isVisible: true),
        ),
      ),
    );
  }

  Widget buildProductDropdown() {
    print("🔍 PRODUCT DROPDOWN => Items: ${model!.products.length}, Value: ${selectedProduct?.name}");
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownSearch<ProductModel>(
        selectedItem: selectedProduct,
        enabled: model!.products.isNotEmpty,

        items: (filter, _) => model!.products,

        itemAsString: (e) => e.name,

        compareFn: (a, b) => a.id == b.id,

        onChanged: (v) => setState(() => selectedProduct = v),

        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Product",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),

        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search Product",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          emptyBuilder: (context, searchEntry) => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text("No products available"),
            ),
          ),
        ),

        suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(isVisible: true),
        ),
      ),
    );
  }

  Widget buildClientDropdown() {
    print("🔍 CLIENT DROPDOWN => Items: ${model!.clients.length}, Value: ${selectedClient?.name}");
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownSearch<ClientModel>(
        selectedItem: selectedClient,
        enabled: model!.clients.isNotEmpty,

        items: (filter, _) => model!.clients,

        itemAsString: (e) => e.name,

        compareFn: (a, b) => a.id == b.id,

        onChanged: (v) {
          setState(() {
            selectedClient = v;
            selectedSite = null;

            if (v != null) {
              final matchedSites = model!.sites
                  .where((site) => site.code == v.id.toString())
                  .toList();

              if (matchedSites.length == 1) {
                selectedSite = matchedSites.first;
              }
            }
          });
        },

        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Client",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),

        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search Client",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          emptyBuilder: (context, searchEntry) => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text("No clients available"),
            ),
          ),
        ),

        suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(isVisible: true),
        ),
      ),
    );
  }

 Widget buildSiteDropdown() {

  final sites = selectedClient?.sites ?? [];

  print(
    "🔍 SITE DROPDOWN => Items: ${sites.length}, Value: ${selectedSite?.name}"
  );

  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownSearch<SiteModel>(
      selectedItem: selectedSite,
      enabled: sites.isNotEmpty,

      items: (filter, _) => sites,

      itemAsString: (e) => e.name,

      compareFn: (a, b) => a.siteId == b.siteId,

      onChanged: (v) => setState(() => selectedSite = v),

      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: "Site",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),

      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Search Site",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        emptyBuilder: (context, searchEntry) => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text("No sites available"),
          ),
        ),
      ),

      suffixProps: const DropdownSuffixProps(
        clearButtonProps: ClearButtonProps(isVisible: true),
      ),
    ),
  );
}

  Widget _buildReportButton(String label, {required VoidCallback? onPressed}) {
    return SizedBox(
      width: 110,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF06224D),
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
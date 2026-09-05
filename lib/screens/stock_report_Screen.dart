// ===============================
// FILE: screens/stock_report_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../screens/loader_service.dart';
import '../models/stock_report_model.dart';
import '../services/api_services.dart';
import '../services/session_manager.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  // ================= COLORS (existing app style) =================
  static const Color primaryColor = Color(0xFF06275B);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFD9DEE7);
  static const Color textColor = Color(0xFF172033);
  static const Color mutedColor = Color(0xFF667085);

  // ================= BREAKPOINTS =================
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  bool loading = true;
  bool generating = false;
  String? errorMessage;

  StockReportFilterModel? model;

  // The Generate Report API takes a single ID for each of these
  // (LocID, ProductGroupID, ProductID, EqTypeID, SecMixTypeID) —
  // so every filter here is single-select, not multi.
  StockLookupItem? selectedLocation;
  StockLookupItem? selectedEqType;
  StockLookupItem? selectedSecMixType;
  StockLookupItem? selectedProductGroup;
  StockLookupItem? selectedProduct;

  String userId = "";
  String userpwd = "";

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  // ================= SESSION =================
  Future<void> loadSession() async {
    final session = await SessionManager.getSession();

    if (!mounted) return;

    if (session == null || session["userId"] == null) {
      setState(() {
        loading = false;
        errorMessage = "Session expired. Please login again.";
      });
      return;
    }

    userId = session["userId"];
    userpwd = session["password"];

    await loadFilters();
  }

  // ================= FILTER API =================
  Future<void> loadFilters() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    if (mounted) {
      LoaderService.show(
        context,
        title: "Loading Stock Report",
        subtitle: "Fetching data from server...",
      );
    }

    try {
      final data = await ApiService.getStockReportFilters(
        userId,
        userpwd,
      );

      if (!mounted) return;

      setState(() {
        model = data;
        loading = false;

        
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      LoaderService.hide();
    }
  }

  // ================= GENERATE REPORT =================
  Future<void> generateReport() async {
    if (selectedLocation == null) {
      showMessage("Please select a Factory / Location");
      return;
    }
    if (selectedProductGroup == null) {
      showMessage("Please select a Product Group");
      return;
    }
    if (selectedProduct == null) {
      showMessage("Please select a Product");
      return;
    }

    setState(() => generating = true);

    if (mounted) {
      LoaderService.show(
        context,
        title: "Generating Stock Report",
        subtitle: "Please wait...",
      );
    }

    try {
      final pdfUrl = await ApiService.generateStockReport(
        userId: userId,
        userPwd: userpwd,
        locId: selectedLocation!.id,
        productGroupId: selectedProductGroup!.id,
        productId: selectedProduct!.id,
        eqTypeId: selectedEqType?.id ?? 0,
        secMixTypeId: selectedSecMixType?.id ?? 0,
      );

      if (pdfUrl.isEmpty) {
        throw Exception("PDF path is empty");
      }

      await launchUrl(
        Uri.parse(pdfUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (!mounted) return;
      showMessage(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      LoaderService.hide();
      if (mounted) {
        setState(() => generating = false);
      }
    }
  }

  // ================= DIALOG =================
  void showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Message"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text(
            "Stock Report",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null || model == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Stock Report",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 42),
                const SizedBox(height: 12),
                Text(
                  errorMessage ?? "Something went wrong.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: loadFilters,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    "Retry",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= desktopBreakpoint;
    final fieldWidth =
        isDesktop ? 260.0 : (width >= tabletBreakpoint ? 220.0 : double.infinity);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Stock Report",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  buildField(fieldWidth, buildLocationDropdown()),
                  buildField(fieldWidth, buildProductGroupDropdown()),
                  buildField(fieldWidth, buildProductDropdown()),
                  buildField(fieldWidth, buildEqTypeDropdown()),
                  buildField(fieldWidth, buildSecMixTypeDropdown()),

                  SizedBox(
                    width: isDesktop ? 250 : double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      onPressed: generating ? null : generateReport,
                      child: generating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Generate Report",
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= WIDGETS =================

  Widget buildField(double width, Widget child) {
    return SizedBox(width: width, child: child);
  }

  Widget buildLocationDropdown() => DropdownSearch<StockLookupItem>(
        selectedItem: selectedLocation,
        items: (filter, _) => model!.locations,
        itemAsString: (item) => item.name,
        compareFn: (a, b) => a.id == b.id,
        onChanged: (v) => setState(() => selectedLocation = v),
        decoratorProps: const DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Factory / Location *",
            border: OutlineInputBorder(),
          ),
        ),
        popupProps: const PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search Location",
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(isVisible: true),
        ),
      );

  Widget buildProductGroupDropdown() =>
    DropdownSearch<StockLookupItem>(
      selectedItem: selectedProductGroup,
      items: (filter, _) => model!.productGroups,
      itemAsString: (item) => item.name,
      compareFn: (a, b) => a.id == b.id,

      onChanged: (v) {
        setState(() {
          selectedProductGroup = v;

          // Clear selected product when group changes
          selectedProduct = null;
        });
      },

      decoratorProps: const DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: "Product Group *",
          border: OutlineInputBorder(),
        ),
      ),

      popupProps: const PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Search Product Group",
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),

      suffixProps: const DropdownSuffixProps(
        clearButtonProps: ClearButtonProps(
          isVisible: true,
        ),
      ),
    );

    Widget buildProductDropdown() =>
    DropdownSearch<StockLookupItem>(
      selectedItem: selectedProduct,

      items: (filter, _) {
        // No Product Group selected
        if (selectedProductGroup == null) {
          return [];
        }

        // Filter products according to Product Group ID
        final groupId = selectedProductGroup!.id.toString();

        final query = filter.trim().toLowerCase();

        return model!.products.where((product) {
          // Product code is being used as Product Group ID
          final belongsToGroup = product.code == groupId;

          if (!belongsToGroup) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          return product.name.toLowerCase().contains(query) ||
              product.code.toLowerCase().contains(query) ||
              product.id.toString().contains(query);
        }).toList();
      },

      itemAsString: (item) => item.name,

      compareFn: (a, b) => a.id == b.id,

      onChanged: (v) {
        setState(() {
          selectedProduct = v;
        });
      },

      decoratorProps: const DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: "Product *",
          border: OutlineInputBorder(),
        ),
      ),

      popupProps: const PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Search Product (name or code)",
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),

      suffixProps: const DropdownSuffixProps(
        clearButtonProps: ClearButtonProps(
          isVisible: true,
        ),
      ),
    );

  

  Widget buildEqTypeDropdown() => DropdownSearch<StockLookupItem>(
        selectedItem: selectedEqType,
        items: (filter, _) => model!.eqTypes,
        itemAsString: (item) => item.name,
        compareFn: (a, b) => a.id == b.id,
        onChanged: (v) => setState(() => selectedEqType = v),
        decoratorProps: const DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Equipment Type",
            border: OutlineInputBorder(),
          ),
        ),
        popupProps: const PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search Equipment Type",
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(isVisible: true),
        ),
      );

  Widget buildSecMixTypeDropdown() => DropdownSearch<StockLookupItem>(
        selectedItem: selectedSecMixType,
        items: (filter, _) => model!.secMixTypes,
        itemAsString: (item) => item.name,
        compareFn: (a, b) => a.id == b.id,
        onChanged: (v) => setState(() => selectedSecMixType = v),
        decoratorProps: const DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Seconds / Mix Type",
            border: OutlineInputBorder(),
          ),
        ),
        popupProps: const PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search Type",
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(isVisible: true),
        ),
      );
}
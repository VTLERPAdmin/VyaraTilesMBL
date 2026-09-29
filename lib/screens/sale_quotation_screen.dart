


// ===============================
// FILE: screens/sale_quotation_screen.dart
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import '../models/sale_quotation_model.dart';
import '../services/api_services.dart';
import '../services/session_manager.dart';
import '../screens/loader_service.dart';

class SaleQuotationScreen extends StatefulWidget {
  const SaleQuotationScreen({super.key});

  @override
  State<SaleQuotationScreen> createState() => _SaleQuotationScreenState();
}

class _SaleQuotationScreenState extends State<SaleQuotationScreen> {
  static const primaryBlue = Color(0xFF06275B);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const borderColor = Color(0xFFD9DEE7);
  static const mutedColor = Color(0xFF667085);
  static const textColor = Color(0xFF172033);

  bool loading = true;
  String? errorMessage;

  QuotListModel? model;
  List<QuotItem> filteredList = [];

  QuotMktPersonItem? selectedMktPerson;
  QuotClientSiteItem? selectedClient;
  QuotClientSiteItem? selectedSite;

  final quotNoController = TextEditingController();
  Timer? _searchDebounce;

  // Tracks which quotation's PDF is currently being generated, so we
  // can disable/spin just that row's Print button (and block a
  // double-tap) without blocking the rest of the screen.
  int? printingId;

  String userId = "";
  String userpwd = "";

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  @override
  void dispose() {
    quotNoController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
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

    await loadData();
  }

  // ================= LOAD =================
  Future<void> loadData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    if (mounted) {
      LoaderService.show(
        context,
        title: "Loading Quotations",
        subtitle: "Fetching data from server...",
      );
    }

    try {
      final data = await ApiService.getQuotList(
        userId: userId,
        userPwd: userpwd,
      );

      if (!mounted) return;

      setState(() {
        model = data;

        filteredList = data.quotations;
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

  // ================= CASCADING OPTIONS =================
  // Client options narrow to whatever the selected Mkt Person actually
  // has quotations against (matched by MktID). Site options narrow
  // further to whatever the selected Client (and/or Mkt Person) has
  // quotations against (matched by ClientCode). This mirrors exactly
  // how the rows are linked in the QuotList JSON.
  List<QuotClientSiteItem> get availableClients {
    if (model == null) return [];
    if (selectedMktPerson == null) return model!.clients;

    final codes = model!.quotations
        .where((q) => q.mktId == selectedMktPerson!.id)
        .map((q) => q.clientCode)
        .toSet();

    return model!.clients.where((c) => codes.contains(c.code)).toList();
  }

  List<QuotClientSiteItem> get availableSites {
    if (model == null) return [];

    Iterable<QuotItem> rows = model!.quotations;

    if (selectedMktPerson != null) {
      rows = rows.where((q) => q.mktId == selectedMktPerson!.id);
    }
    if (selectedClient != null) {
      rows = rows.where((q) => q.clientCode == selectedClient!.code);
    }

    final codes = rows.map((q) => q.siteCode).toSet();

    return model!.sites.where((s) => codes.contains(s.code)).toList();
  }

  // ================= FILTER CHANGE HANDLERS =================
  void onMktPersonChanged(QuotMktPersonItem? v) {
    setState(() {
      selectedMktPerson = v;

      // Drop any Client/Site selection that no longer belongs to the
      // newly selected Mkt Person.
      final validClientCodes = availableClients.map((c) => c.code).toSet();
      if (selectedClient != null &&
          !validClientCodes.contains(selectedClient!.code)) {
        selectedClient = null;
      }

      final validSiteCodes = availableSites.map((s) => s.code).toSet();
      if (selectedSite != null &&
          !validSiteCodes.contains(selectedSite!.code)) {
        selectedSite = null;
      }
    });

    applyFilters();
  }

  void onClientChanged(QuotClientSiteItem? v) {
    setState(() {
      selectedClient = v;

      // Drop any Site selection that no longer belongs to the
      // newly selected Client.
      final validSiteCodes = availableSites.map((s) => s.code).toSet();
      if (selectedSite != null &&
          !validSiteCodes.contains(selectedSite!.code)) {
        selectedSite = null;
      }
    });

    applyFilters();
  }

  void onSiteChanged(QuotClientSiteItem? v) {
    setState(() => selectedSite = v);
    applyFilters();
  }

  // ================= FILTERING (final list) =================
  void applyFilters() {
    if (model == null) return;

    final query = quotNoController.text.trim().toLowerCase();

    final result = model!.quotations.where((q) {
      final matchesMkt =
          selectedMktPerson == null || q.mktId == selectedMktPerson!.id;
      final matchesClient =
          selectedClient == null || q.clientCode == selectedClient!.code;
      final matchesSite =
          selectedSite == null || q.siteCode == selectedSite!.code;
      final matchesQuery =
          query.isEmpty || q.quotNo.toLowerCase().contains(query);

      return matchesMkt && matchesClient && matchesSite && matchesQuery;
    }).toList();

    setState(() => filteredList = result);
  }

  void onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), applyFilters);
  }

  void clearFilters() {
    setState(() {
      selectedMktPerson = null;
      selectedClient = null;
      selectedSite = null;
      quotNoController.clear();
      filteredList = model?.quotations ?? [];
    });
  }

  // ================= PRINT =================
  Future<void> printQuotation(QuotItem item) async {
    if (printingId != null) return; // block double-tap

    setState(() => printingId = item.id);

    try {
      final pdfUrl = await ApiService.getQuotPrint(
        userId: userId,
        userPwd: userpwd,
        locId: item.locId,
        id: item.id,
        saleType: item.saleType,
      );

      await launchUrl(
        Uri.parse(pdfUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (!mounted) return;
      showMessage(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => printingId = null);
      }
    }
  }

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
          backgroundColor: primaryBlue,
          title: const Text(
            "Sale Quotations",
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
          backgroundColor: primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Sale Quotations",
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
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                  onPressed: loadData,
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Sale Quotations",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _filterCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  "Showing ${filteredList.length} of ${model!.quotations.length}",
                  style: const TextStyle(color: mutedColor, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadData,
              child: filteredList.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Icon(Icons.search_off, size: 48, color: mutedColor),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            "No quotations match your filters.",
                            style: TextStyle(color: mutedColor),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filteredList.length,
                      itemBuilder: (_, index) =>
                          _quotationCard(filteredList[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= FILTER CARD =================
  // One dropdown per row (single column), in cascading order:
  // Mkt Person -> Client -> Site -> Quot No. search.
  Widget _filterCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mktPersonDropdown(),
          const SizedBox(height: 10),
          _clientDropdown(),
          const SizedBox(height: 10),
          _siteDropdown(),
          const SizedBox(height: 10),
          TextField(
            controller: quotNoController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              labelText: "Quot No.",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: quotNoController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        quotNoController.clear();
                        applyFilters();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: clearFilters,
              icon: const Icon(Icons.close, size: 18),
              label: const Text("Cancel / Clear Filters"),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _mktPersonDropdown() => DropdownSearch<QuotMktPersonItem>(
        selectedItem: selectedMktPerson,
        items: (filter, _) => model!.mktPersons,
        itemAsString: (item) => item.name,
        compareFn: (a, b) => a.id == b.id,
        onChanged: onMktPersonChanged,
        decoratorProps: const DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Mkt Person",
            border: OutlineInputBorder(),
          ),
        ),
        popupProps: const PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search Mkt Person",
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(isVisible: true),
        ),
      );

  // Client list narrows to the selected Mkt Person's clients.
  Widget _clientDropdown() => DropdownSearch<QuotClientSiteItem>(
        key: ValueKey('client_${selectedMktPerson?.id}'),
        selectedItem: selectedClient,
        items: (filter, _) => availableClients,
        itemAsString: (item) => item.name,
        compareFn: (a, b) => a.code == b.code,
        onChanged: onClientChanged,
        decoratorProps: const DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Client",
            border: OutlineInputBorder(),
          ),
        ),
        popupProps: const PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search Client",
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(isVisible: true),
        ),
      );

  // Site list narrows to the selected Mkt Person / Client.
  Widget _siteDropdown() => DropdownSearch<QuotClientSiteItem>(
        key: ValueKey('site_${selectedMktPerson?.id}_${selectedClient?.code}'),
        selectedItem: selectedSite,
        items: (filter, _) => availableSites,
        itemAsString: (item) => item.name,
        compareFn: (a, b) => a.code == b.code,
        onChanged: onSiteChanged,
        decoratorProps: const DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Site",
            border: OutlineInputBorder(),
          ),
        ),
        popupProps: const PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search Site",
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(isVisible: true),
        ),
      );

  // ================= QUOTATION CARD =================
  Widget _quotationCard(QuotItem item) {
    final isPrinting = printingId == item.id;
    final dateText = item.quotDate != null
        ? DateFormat('dd/MM/yyyy').format(item.quotDate!)
        : "-";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.quotNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                dateText,
                style: const TextStyle(color: mutedColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.client, style: const TextStyle(color: textColor)),
          if (item.siteName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                item.siteName,
                style: const TextStyle(color: mutedColor, fontSize: 13),
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Mkt: ${item.mktPerson}",
                  style: const TextStyle(fontSize: 12, color: mutedColor),
                ),
              ),
              if (item.soNo.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    "SO: ${item.soNo}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: isPrinting ? null : () => printQuotation(item),
              icon: isPrinting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.print, size: 18, color: Colors.white),
              label: Text(
                isPrinting ? "Generating..." : "Print",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




// ====================================================================================================================================================================================
                                                                        // new 
// ====================================================================================================================================================================================
                                                                        // new 

// ====================================================================================================================================================================================




/*

// ===============================
// FILE: screens/sale_quotation_screen.dart
// ===============================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';

import '../models/sale_quotation_model.dart';
import '../services/api_services.dart';
import '../services/session_manager.dart';
import '../screens/loader_service.dart';

class SaleQuotationScreen extends StatefulWidget {
  const SaleQuotationScreen({super.key});

  @override
  State<SaleQuotationScreen> createState() =>
      _SaleQuotationScreenState();
}

class _SaleQuotationScreenState
    extends State<SaleQuotationScreen> {

  // ============================================================
  // COLORS
  // ============================================================

  static const primaryBlue = Color(0xFF06275B);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const borderColor = Color(0xFFD9DEE7);
  static const mutedColor = Color(0xFF667085);
  static const textColor = Color(0xFF172033);

  // ============================================================
  // STATE
  // ============================================================

  bool loading = true;
  String? errorMessage;

  QuotListModel? model;

  List<QuotItem> filteredList = [];

  // New model uses QuotDropdownItem for all dropdowns.
  QuotDropdownItem? selectedMktPerson;
  QuotDropdownItem? selectedClient;
  QuotDropdownItem? selectedSite;

  final TextEditingController quotNoController =
      TextEditingController();

  Timer? _searchDebounce;

  // Tracks quotation currently being printed.
  int? printingId;

  String userId = "";
  String userpwd = "";

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  @override
  void dispose() {
    quotNoController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ============================================================
  // SESSION
  // ============================================================

  Future<void> loadSession() async {
    final session = await SessionManager.getSession();

    if (!mounted) return;

    if (session == null || session["userId"] == null) {
      setState(() {
        loading = false;
        errorMessage =
            "Session expired. Please login again.";
      });

      return;
    }

    userId = session["userId"]?.toString() ?? "";
    userpwd = session["password"]?.toString() ?? "";

    await loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> loadData() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    if (mounted) {
      LoaderService.show(
        context,
        title: "Loading Quotations",
        subtitle: "Fetching data from server...",
      );
    }

    try {
      final data = await ApiService.getQuotList(
        userId: userId,
        userPwd: userpwd,
      );

      if (!mounted) return;

      setState(() {
        model = data;

        filteredList = data.quotations;

        // Clear old selections after fresh API data.
        selectedMktPerson = null;
        selectedClient = null;
        selectedSite = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }

      LoaderService.hide();
    }
  }

  // ============================================================
  // CASCADING CLIENT OPTIONS
  //
  // Client options are taken directly from QuotList.
  //
  // If Marketing Person is selected:
  // only clients belonging to that Mkt Person are shown.
  // ============================================================

  List<QuotDropdownItem> get availableClients {
    if (model == null) return [];

    if (selectedMktPerson == null) {
      return model!.clients;
    }

    final selectedMktId =
        int.tryParse(selectedMktPerson!.value);

    if (selectedMktId == null) {
      return model!.clients;
    }

    final clientCodes = model!.quotations
        .where((q) => q.mktId == selectedMktId)
        .map((q) => q.clientCode)
        .where((code) => code.isNotEmpty)
        .toSet();

    return model!.clients
        .where((client) => clientCodes.contains(client.value))
        .toList();
  }

  // ============================================================
  // CASCADING SITE OPTIONS
  //
  // Site options are narrowed by:
  //
  // Mkt Person
  // +
  // Client
  // ============================================================

  List<QuotDropdownItem> get availableSites {
    if (model == null) return [];

    Iterable<QuotItem> rows = model!.quotations;

    // Filter by Mkt Person
    if (selectedMktPerson != null) {
      final mktId =
          int.tryParse(selectedMktPerson!.value);

      if (mktId != null) {
        rows = rows.where(
          (q) => q.mktId == mktId,
        );
      }
    }

    // Filter by Client
    if (selectedClient != null) {
      rows = rows.where(
        (q) => q.clientCode == selectedClient!.value,
      );
    }

    final siteCodes = rows
        .map((q) => q.siteCode)
        .where((code) => code.isNotEmpty)
        .toSet();

    return model!.sites
        .where((site) => siteCodes.contains(site.value))
        .toList();
  }

  // ============================================================
  // MARKETING PERSON CHANGE
  // ============================================================

  void onMktPersonChanged(
    QuotDropdownItem? value,
  ) {
    setState(() {
      selectedMktPerson = value;

      // Check whether currently selected client
      // is still valid.
      final validClientCodes =
          availableClients.map((c) => c.value).toSet();

      if (selectedClient != null &&
          !validClientCodes.contains(
            selectedClient!.value,
          )) {
        selectedClient = null;
      }

      // Check whether currently selected site
      // is still valid.
      final validSiteCodes =
          availableSites.map((s) => s.value).toSet();

      if (selectedSite != null &&
          !validSiteCodes.contains(
            selectedSite!.value,
          )) {
        selectedSite = null;
      }
    });

    applyFilters();
  }

  // ============================================================
  // CLIENT CHANGE
  // ============================================================

  void onClientChanged(
    QuotDropdownItem? value,
  ) {
    setState(() {
      selectedClient = value;

      // Check whether selected site is still valid.
      final validSiteCodes =
          availableSites.map((s) => s.value).toSet();

      if (selectedSite != null &&
          !validSiteCodes.contains(
            selectedSite!.value,
          )) {
        selectedSite = null;
      }
    });

    applyFilters();
  }

  // ============================================================
  // SITE CHANGE
  // ============================================================

  void onSiteChanged(
    QuotDropdownItem? value,
  ) {
    setState(() {
      selectedSite = value;
    });

    applyFilters();
  }

  // ============================================================
  // FILTER
  // ============================================================

  void applyFilters() {
    if (model == null) return;

    final query =
        quotNoController.text.trim().toLowerCase();

    final selectedMktId =
        selectedMktPerson == null
            ? null
            : int.tryParse(
                selectedMktPerson!.value,
              );

    final selectedClientCode =
        selectedClient?.value;

    final selectedSiteCode =
        selectedSite?.value;

    final result = model!.quotations.where((q) {

      // Mkt Person
      final matchesMkt =
          selectedMktId == null ||
          q.mktId == selectedMktId;

      // Client
      final matchesClient =
          selectedClientCode == null ||
          q.clientCode == selectedClientCode;

      // Site
      final matchesSite =
          selectedSiteCode == null ||
          q.siteCode == selectedSiteCode;

      // Quotation number
      final matchesQuery =
          query.isEmpty ||
          q.quotNo
              .toLowerCase()
              .contains(query);

      return matchesMkt &&
          matchesClient &&
          matchesSite &&
          matchesQuery;
    }).toList();

    if (!mounted) return;

    setState(() {
      filteredList = result;
    });
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 250),
      applyFilters,
    );
  }

  // ============================================================
  // CLEAR FILTERS
  // ============================================================

  void clearFilters() {
    setState(() {
      selectedMktPerson = null;
      selectedClient = null;
      selectedSite = null;

      quotNoController.clear();

      filteredList =
          model?.quotations ?? [];
    });
  }

  // ============================================================
  // PRINT QUOTATION
  // ============================================================

  Future<void> printQuotation(
    QuotItem item,
  ) async {
    if (printingId != null) return;

    setState(() {
      printingId = item.id;
    });

    try {
      final pdfUrl =
          await ApiService.getQuotPrint(
        userId: userId,
        userPwd: userpwd,
        locId: item.locId,
        id: item.id,
        saleType: item.saleType,
      );

      await launchUrl(
        Uri.parse(pdfUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          printingId = null;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Message"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryBlue,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          title: const Text(
            "Sale Quotations",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (errorMessage != null || model == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryBlue,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          title: const Text(
            "Sale Quotations",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 42,
                ),

                const SizedBox(height: 12),

                Text(
                  errorMessage ??
                      "Something went wrong.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: loadData,
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  label: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // MAIN SCREEN
    // ==========================================================

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          "Sale Quotations",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: Column(
        children: [

          // FILTERS
          _filterCard(),

          // COUNT
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              children: [
                Text(
                  "Showing ${filteredList.length} "
                  "of ${model!.quotations.length}",
                  style: const TextStyle(
                    color: mutedColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadData,

              child: filteredList.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),

                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: mutedColor,
                        ),

                        SizedBox(height: 12),

                        Center(
                          child: Text(
                            "No quotations match "
                            "your filters.",
                            style: TextStyle(
                              color: mutedColor,
                            ),
                          ),
                        ),
                      ],
                    )

                  : ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),

                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        16,
                      ),

                      itemCount:
                          filteredList.length,

                      itemBuilder: (_, index) {
                        return _quotationCard(
                          filteredList[index],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CARD
  // ============================================================

  Widget _filterCard() {
    return Container(
      color: Colors.white,

      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        4,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,

        children: [

          // ----------------------------------------------------
          // MKT PERSON
          // ----------------------------------------------------

          _mktPersonDropdown(),

          const SizedBox(height: 10),

          // ----------------------------------------------------
          // CLIENT
          // ----------------------------------------------------

          _clientDropdown(),

          const SizedBox(height: 10),

          // ----------------------------------------------------
          // SITE
          // ----------------------------------------------------

          _siteDropdown(),

          const SizedBox(height: 10),

          // ----------------------------------------------------
          // QUOTATION NUMBER SEARCH
          // ----------------------------------------------------

          TextField(
            controller: quotNoController,
            onChanged: onSearchChanged,

            decoration: InputDecoration(
              labelText: "Quot No.",

              prefixIcon: const Icon(
                Icons.search,
              ),

              suffixIcon:
                  quotNoController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                          ),
                          onPressed: () {
                            quotNoController.clear();
                            applyFilters();
                          },
                        )
                      : null,

              border:
                  const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          // ----------------------------------------------------
          // CLEAR
          // ----------------------------------------------------

          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: clearFilters,

              icon: const Icon(
                Icons.close,
                size: 18,
              ),

              label: const Text(
                "Cancel / Clear Filters",
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ============================================================
  // MKT PERSON DROPDOWN
  // ============================================================

  Widget _mktPersonDropdown() {
    return DropdownSearch<QuotDropdownItem>(
      selectedItem: selectedMktPerson,

      items: (filter, _) {
        return model?.mktPersons ?? [];
      },

      itemAsString: (item) => item.name,

      compareFn: (a, b) =>
          a.value == b.value,

      onChanged: onMktPersonChanged,

      decoratorProps:
          const DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: "Mkt Person",
          border: OutlineInputBorder(),
        ),
      ),

      popupProps:
          const PopupProps.menu(
        showSearchBox: true,

        searchFieldProps:
            TextFieldProps(
          decoration:
              InputDecoration(
            hintText:
                "Search Mkt Person",
            prefixIcon:
                Icon(Icons.search),
          ),
        ),
      ),

      suffixProps:
          const DropdownSuffixProps(
        clearButtonProps:
            ClearButtonProps(
          isVisible: true,
        ),
      ),
    );
  }

  // ============================================================
  // CLIENT DROPDOWN
  // ============================================================

  Widget _clientDropdown() {
    return DropdownSearch<QuotDropdownItem>(
      key: ValueKey(
        'client_${selectedMktPerson?.value}',
      ),

      selectedItem: selectedClient,

      items: (filter, _) {
        return availableClients;
      },

      itemAsString: (item) => item.name,

      compareFn: (a, b) =>
          a.value == b.value,

      onChanged: onClientChanged,

      decoratorProps:
          const DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: "Client",
          border: OutlineInputBorder(),
        ),
      ),

      popupProps:
          const PopupProps.menu(
        showSearchBox: true,

        searchFieldProps:
            TextFieldProps(
          decoration:
              InputDecoration(
            hintText:
                "Search Client",
            prefixIcon:
                Icon(Icons.search),
          ),
        ),
      ),

      suffixProps:
          const DropdownSuffixProps(
        clearButtonProps:
            ClearButtonProps(
          isVisible: true,
        ),
      ),
    );
  }

  // ============================================================
  // SITE DROPDOWN
  // ============================================================

  Widget _siteDropdown() {
    return DropdownSearch<QuotDropdownItem>(
      key: ValueKey(
        'site_'
        '${selectedMktPerson?.value}_'
        '${selectedClient?.value}',
      ),

      selectedItem: selectedSite,

      items: (filter, _) {
        return availableSites;
      },

      itemAsString: (item) => item.name,

      compareFn: (a, b) =>
          a.value == b.value,

      onChanged: onSiteChanged,

      decoratorProps:
          const DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: "Site",
          border: OutlineInputBorder(),
        ),
      ),

      popupProps:
          const PopupProps.menu(
        showSearchBox: true,

        searchFieldProps:
            TextFieldProps(
          decoration:
              InputDecoration(
            hintText:
                "Search Site",
            prefixIcon:
                Icon(Icons.search),
          ),
        ),
      ),

      suffixProps:
          const DropdownSuffixProps(
        clearButtonProps:
            ClearButtonProps(
          isVisible: true,
        ),
      ),
    );
  }

  // ============================================================
  // QUOTATION CARD
  // ============================================================

  Widget _quotationCard(
    QuotItem item,
  ) {
    final isPrinting =
        printingId == item.id;

    final dateText =
        item.quotDate != null
            ? DateFormat(
                'dd/MM/yyyy',
              ).format(item.quotDate!)
            : "-";

    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),

      padding:
          const EdgeInsets.all(12),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(12),

        border:
            Border.all(
          color: borderColor,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ==================================================
          // QUOTATION NO + DATE
          // ==================================================

          Row(
            children: [

              Expanded(
                child: Text(
                  item.quotNo,

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w700,

                    color:
                        primaryBlue,

                    fontSize: 15,
                  ),
                ),
              ),

              Text(
                dateText,

                style:
                    const TextStyle(
                  color: mutedColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ==================================================
          // CLIENT
          // ==================================================

          Text(
            item.client,
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),

          // ==================================================
          // SITE
          // ==================================================

          if (item.siteName.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 2,
              ),

              child: Text(
                item.siteName,

                style:
                    const TextStyle(
                  color: mutedColor,
                  fontSize: 13,
                ),
              ),
            ),

          const SizedBox(height: 6),

          // ==================================================
          // MKT PERSON + SO
          // ==================================================

          Row(
            children: [

              Expanded(
                child: Text(
                  "Mkt: ${item.mktPerson}",

                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                  ),
                ),
              ),

              if (item.soNo.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.green.shade50,

                    borderRadius:
                        BorderRadius.circular(
                      6,
                    ),

                    border:
                        Border.all(
                      color:
                          Colors.green.shade200,
                    ),
                  ),

                  child: Text(
                    "SO: ${item.soNo}",

                    style:
                        TextStyle(
                      fontSize: 11,

                      color:
                          Colors.green.shade800,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const Divider(
            height: 16,
          ),

          // ==================================================
          // PRINT BUTTON
          // ==================================================

          Align(
            alignment:
                Alignment.centerRight,

            child:
                ElevatedButton.icon(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryBlue,

                foregroundColor:
                    Colors.white,
              ),

              onPressed:
                  isPrinting
                      ? null
                      : () =>
                          printQuotation(item),

              icon: isPrinting
                  ? const SizedBox(
                      width: 14,
                      height: 14,

                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.print,
                      size: 18,
                      color: Colors.white,
                    ),

              label: Text(
                isPrinting
                    ? "Generating..."
                    : "Print",

                style:
                    const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

*/
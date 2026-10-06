// ===============================
// FILE: screens/inv_print_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/inv_print_model.dart';
import '../services/api_services.dart';
import '../services/session_manager.dart';
import '../screens/loader_service.dart';
import '../screens/inv_print_filter_screen.dart';

class InvPrintScreen extends StatefulWidget {
  const InvPrintScreen({super.key});

  @override
  State<InvPrintScreen> createState() => _InvPrintScreenState();
}

class _InvPrintScreenState extends State<InvPrintScreen> {
  static const primaryBlue = Color(0xFF06275B);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const borderColor = Color(0xFFD9DEE7);
  static const mutedColor = Color(0xFF667085);
  static const textColor = Color(0xFF172033);

  bool loading = true;
  String? errorMessage;

  InvPrintListModel? model;
  List<InvPrintItem> filteredList = [];

  // Cascading: ClientGroup -> Client -> Site
  String? selectedClientGroup;
  InvIdNameItem? selectedClient;
  InvIdNameItem? selectedSite;

  // Independent filters
  InvIdNameItem? selectedMkt;
  InvIdNameItem? selectedLocation;

  String invNo = "";
  String soNo = "";

  DateTime? fromDate;
  DateTime? toDate;

  bool hideChallans = true;
  bool preSigned = false;

  // Tracks which row's PDF is currently being generated (rowKey =
  // "LocID_ID", since ID alone is not globally unique).
  String? printingKey;

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
        title: "Loading Invoices",
        subtitle: "Fetching data from server...",
      );
    }

    try {
      final data = await ApiService.getInvPrintData(
        userId: userId,
        userPwd: userpwd,
      );

      if (!mounted) return;

      setState(() {
        model = data;
        loading = false;
      });

      applyFilters();
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

  // ================= FILTERING (final list) =================
  void applyFilters() {
    if (model == null) return;

    final invQuery = invNo.trim().toLowerCase();
    final soQuery = soNo.trim().toLowerCase();
    final fromOnly = fromDate != null ? _dateOnly(fromDate!) : null;
    final toOnly = toDate != null ? _dateOnly(toDate!) : null;

    final result = model!.items.where((r) {
      final matchesClientGroup = selectedClientGroup == null ||
          r.clientGroup == selectedClientGroup;
      final matchesClient =
          selectedClient == null || r.ledgerId == selectedClient!.id;
      final matchesSite = selectedSite == null || r.siteId == selectedSite!.id;
      final matchesMkt = selectedMkt == null || r.bookId == selectedMkt!.id;
      final matchesLocation =
          selectedLocation == null || r.locId == selectedLocation!.id;

      final matchesInvNo =
          invQuery.isEmpty || r.vouNo.toLowerCase().contains(invQuery);
      final matchesSoNo =
          soQuery.isEmpty || r.refNo.toLowerCase().contains(soQuery);

      final rowDate = r.vouDate != null ? _dateOnly(r.vouDate!) : null;
      final matchesFrom = fromOnly == null ||
          (rowDate != null && !rowDate.isBefore(fromOnly));
      final matchesTo =
          toOnly == null || (rowDate != null && !rowDate.isAfter(toOnly));

      final matchesChallan = !hideChallans || !r.isChallan;

      return matchesClientGroup &&
          matchesClient &&
          matchesSite &&
          matchesMkt &&
          matchesLocation &&
          matchesInvNo &&
          matchesSoNo &&
          matchesFrom &&
          matchesTo &&
          matchesChallan;
    }).toList();

    setState(() => filteredList = result);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int get activeFilterCount {
    var count = 0;
    if (selectedClientGroup != null) count++;
    if (selectedClient != null) count++;
    if (selectedSite != null) count++;
    if (selectedMkt != null) count++;
    if (selectedLocation != null) count++;
    if (invNo.isNotEmpty) count++;
    if (soNo.isNotEmpty) count++;
    if (fromDate != null) count++;
    if (toDate != null) count++;
    return count;
  }

  // ================= OPEN FILTER SCREEN =================
  Future<void> openFilters() async {
    if (model == null) return;

    final result = await Navigator.push<InvPrintFilterResult>(
      context,
      MaterialPageRoute(
        builder: (_) => InvPrintFilterScreen(
          model: model!,
          initialClientGroup: selectedClientGroup,
          initialClient: selectedClient,
          initialSite: selectedSite,
          initialMkt: selectedMkt,
          initialLocation: selectedLocation,
          initialInvNo: invNo,
          initialSoNo: soNo,
          initialFromDate: fromDate,
          initialToDate: toDate,
          initialHideChallans: hideChallans,
          initialPreSigned: preSigned,
        ),
      ),
    );

    if (result == null || !mounted) return; // cancelled, nothing changes

    setState(() {
      selectedClientGroup = result.clientGroup;
      selectedClient = result.client;
      selectedSite = result.site;
      selectedMkt = result.mkt;
      selectedLocation = result.location;
      invNo = result.invNo;
      soNo = result.soNo;
      fromDate = result.fromDate;
      toDate = result.toDate;
      hideChallans = result.hideChallans;
      preSigned = result.preSigned;
    });

    applyFilters();
  }

  void clearFilters() {
    setState(() {
      selectedClientGroup = null;
      selectedClient = null;
      selectedSite = null;
      selectedMkt = null;
      selectedLocation = null;
      invNo = "";
      soNo = "";
      fromDate = null;
      toDate = null;
      hideChallans = true;
      preSigned = false;
    });
    applyFilters();
  }

  // ================= PRINT =================
  Future<void> printInvoice(InvPrintItem item) async {
    if (printingKey != null) return; // block double-tap

    setState(() => printingKey = item.rowKey);

    try {
      final pdfUrl = await ApiService.getInvPrintReport(
        userId: userId,
        userPwd: userpwd,
        locId: item.locId,
        id: item.id,
        preSigned: preSigned,
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
        setState(() => printingKey = null);
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
            "Inv. Print",
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
            "Inv. Print",
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
                  style:
                      ElevatedButton.styleFrom(backgroundColor: primaryBlue),
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
          "Inv. Print",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _filterBar(),
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
                            "No invoices match your filters.",
                            style: TextStyle(color: mutedColor),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filteredList.length,
                      itemBuilder: (_, index) =>
                          _invoiceCard(filteredList[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SLIM FILTER BAR =================
 /* Widget _filterBar() {
    final count = activeFilterCount;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: openFilters,
              icon: const Icon(Icons.filter_list, size: 18),
              label: Text(count > 0 ? "Filters ($count)" : "Filters"),
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: clearFilters,
              child: const Text("Clear"),
            ),
          ],
          const SizedBox(width: 10),
          Text(
            "${filteredList.length}/${model!.items.length}",
            style: const TextStyle(color: mutedColor, fontSize: 12),
          ),
        ],
      ),
    );
  } */

 Widget _filterBar() {
  final count = activeFilterCount;

  return Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    child: Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: openFilters,
            icon: const Icon(Icons.filter_list, size: 18, color: Colors.white),
            label: Text(
              count > 0 ? "Filters ($count)" : "Filters",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 10),
          TextButton(
            onPressed: clearFilters,
            child: const Text("Clear"),
          ),
        ],
        const SizedBox(width: 10),
        Text(
          "${filteredList.length}/${model!.items.length}",
          style: const TextStyle(color: mutedColor, fontSize: 12),
        ),
      ],
    ),
  );
}

  // ================= INVOICE CARD =================
  Widget _invoiceCard(InvPrintItem item) {
    final isPrinting = printingKey == item.rowKey;
    final dateText = item.vouDate != null
        ? DateFormat('dd/MM/yyyy').format(item.vouDate!)
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
                  item.vouNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
                    fontSize: 15,
                  ),
                ),
              ),
              if (item.isChallan)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    "Challan",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
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
          Text(item.ledgerName, style: const TextStyle(color: textColor)),
          if (item.site.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                item.site,
                style: const TextStyle(color: mutedColor, fontSize: 13),
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Mkt: ${item.bookName}",
                  style: const TextStyle(fontSize: 12, color: mutedColor),
                ),
              ),
              if (item.refNo.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    "SO: ${item.refNo}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Amount: ${item.amount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: isPrinting ? null : () => printInvoice(item),
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
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../screens/loader_service.dart';
import '../models/ledger_model.dart';
import '../services/api_services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/session_manager.dart';
import '../config/app_config.dart';


class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  bool loading = true;
  bool generating = false;

  LedgerFilterModel? model;

  LedgerDropdownModel? selectedAcGroup;
  String? selectedClientGroup;

  List<LedgerClientModel> filteredClients = [];
  List<LedgerClientModel> selectedClients = [];

  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  String userId = "";
  String userpwd = "";
 

  bool mergeClients = false;
  bool grandTotal = false;

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  // ================= SESSION =================
  Future<void> loadSession() async {
  final session = await SessionManager.getSession();

  if (session == null || session["userId"] == null) {
    setState(() => loading = false);
    showError("Session expired. Please login again.");
    return;
  }

  userId = session["userId"];
  userpwd = session["password"];

  await loadFilters();
}

  // ================= FILTER API =================
  Future<void> loadFilters() async {
      LoaderService.show(
          context,
          title: "Loading Ledger",
          subtitle: "Fetching filter data...",
        );

    try {
      final data = await ApiService.getLedgerFilters(userId, userpwd, AppConfig.verNo);

      fromDateController.text = formatDate(data.startDate);
      toDateController.text = formatDate(data.endDate);

      setState(() {
        model = data;
        filteredClients = data.clients;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      showError(e.toString());
    }
    finally {
    LoaderService.hide();
  }

  }

  String formatDate(String apiDate) {
    try {
      final date = DateTime.parse(apiDate);
      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
    } catch (_) {
      return "";
    }
  }

  // ================= FILTER CLIENTS =================
  void filterClients() {
    if (model == null) return;

    final clients = model!.clients.where((client) {
      final acMatch = selectedAcGroup == null ||
          client.acGroupId == selectedAcGroup!.id;

      final groupMatch = selectedClientGroup == null ||
          selectedClientGroup!.isEmpty ||
          client.clientGroup == selectedClientGroup;

      return acMatch && groupMatch;
    }).toList();

    setState(() {
      filteredClients = clients;
      selectedClients.clear();
    });
  }

  // ================= DATE PICKER =================
  Future<void> pickDate(TextEditingController controller) async {
    DateTime initialDate = DateTime.now();

    try {
      final parts = controller.text.split("/");
      initialDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text =
          "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year}";
    }
  }

  // ================= CLIENT SELECTOR =================
Future<void> openClientSelector() async {
  List<LedgerClientModel> tempSelected = List.from(selectedClients);

  final searchController = TextEditingController();
  List<LedgerClientModel> dialogClients = List.from(filteredClients);

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setDialog) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Select Clients",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search Client",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setDialog(() {
                                  dialogClients =
                                      List.from(filteredClients);
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setDialog(() {
                        dialogClients = filteredClients
                            .where((e) => e.name
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setDialog(() {
                            tempSelected =
                                List.from(filteredClients);
                          });
                        },
                        icon: const Icon(Icons.select_all),
                        label: const Text("Select All"),
                      ),

                      const Spacer(),

                      TextButton.icon(
                        onPressed: () {
                          setDialog(() {
                            tempSelected.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text("Clear"),
                      ),
                    ],
                  ),

                  const Divider(),

                  Expanded(
                    child: dialogClients.isEmpty
                        ? const Center(
                            child: Text("No clients found"),
                          )
                        : ListView.builder(
                            itemCount: dialogClients.length,
                            itemBuilder: (_, index) {
                              final client = dialogClients[index];

                              final selected = tempSelected.any(
                                (e) => e.id == client.id,
                              );

                              return CheckboxListTile(
                                dense: true,
                                value: selected,
                                title: Text(client.name),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (_) {
                                  setDialog(() {
                                    if (selected) {
                                      tempSelected.removeWhere(
                                        (e) =>
                                            e.id == client.id,
                                      );
                                    } else {
                                      tempSelected.add(client);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel"),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF06224D),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedClients = tempSelected;
                            });

                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Done",
                            style:
                                TextStyle(color: Colors.white),
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
    },
  );
}

  // ================= GENERATE REPORT =================
    // ================= GENERATE REPORT =================
  Future generateReport() async {
    if (selectedClients.isEmpty) {
      showError("Please select client");
      return;
    }

    if (fromDateController.text.isEmpty ||
        toDateController.text.isEmpty) {
      showError("Please select dates");
      return;
    }

    setState(() {
      generating = true;
    });

    LoaderService.show(
      context,
      title: "Generating Ledger",
      subtitle: "Preparing your report...",
    );

    // Make sure the loader is hidden exactly once.
    bool loaderShown = true;
    void hideLoader() {
      if (loaderShown) {
        loaderShown = false;
        LoaderService.hide();
      }
    }

    try {
      final clientIds = selectedClients.map((e) => e.id).join(",");

      print("================================");
      print("GENERATING LEDGER");
      print("UserID => $userId");
      print("ClientIDs => $clientIds");
      print("FromDate => ${fromDateController.text}");
      print("ToDate => ${toDateController.text}");
      print("MergeClients => $mergeClients");
      print("GrandTotal => $grandTotal");
      print("================================");

      // The API returns the PDF file itself (bytes), not a URL.
      final pdfBytes = await ApiService.getLedgerReport(
        clientIds: clientIds,
        fromDate: fromDateController.text,
        toDate: toDateController.text,
        mergeClients: mergeClients,
        grandTotal: grandTotal,
        userId: userId,
        userPwd: userpwd,
      );

      hideLoader();

      if (!mounted) return;

      // Show the PDF in the report viewer (Android, iOS and Chrome).
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LedgerPdfViewScreen(
            pdfBytes: pdfBytes,
            fromDate: fromDateController.text,
            toDate: toDateController.text,
            clientCount: selectedClients.length,
            clientName:
                selectedClients.length == 1 ? selectedClients.first.name : null,
            mergeClients: mergeClients,
            grandTotal: grandTotal,
          ),
        ),
      );
    } catch (e) {
      hideLoader();
      if (mounted) {
        showError(e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      if (mounted) {
        setState(() {
          generating = false;
        });
      }
    }
  }
  // ================= ERROR DIALOG =================
  void showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Message"),
        content: Text(message.replaceAll("Exception:", "")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
   

 if (loading || model == null) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF06224D),
        title: const Text(
          "Ledger Report",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06224D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Ledger Report",
            style: TextStyle(color: Colors.white)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                buildAcGroup(),
                buildClientGroup(),
                buildClientSelector(),
                buildDateField("From Date", fromDateController),
                buildDateField("To Date", toDateController),

                buildCheckBox("Merge Clients", mergeClients, (v) {
                  setState(() => mergeClients = v ?? false);
                }),

                buildCheckBox("Grand Total", grandTotal, (v) {
                  setState(() => grandTotal = v ?? false);
                }),

               SizedBox(
  width: isDesktop ? 250 : double.infinity,
  height: 50,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF06224D),
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
    );
  }

  // ================= WIDGETS =================
 Widget buildAcGroup() => buildContainer(
      DropdownSearch<LedgerDropdownModel>(
        selectedItem: selectedAcGroup,

        items: (filter, _) => model!.acGroups,

        itemAsString: (item) => item.name,

        compareFn: (a, b) => a.id == b.id,

        onChanged: (v) {
          setState(() => selectedAcGroup = v);
          filterClients();
        },

        decoratorProps: const DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "A/c Group",
            border: OutlineInputBorder(),
          ),
        ),

        popupProps: const PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search A/c Group",
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),

        suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(
            isVisible: true,
          ),
        ),
      ),
    );

Widget buildClientGroup() => buildContainer(
      DropdownSearch<String>(
        selectedItem: selectedClientGroup,

        items: (filter, _) => model!.clientGroups,

        onChanged: (v) {
          setState(() => selectedClientGroup = v);
          filterClients();
        },

        decoratorProps: const DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Client Group",
            border: OutlineInputBorder(),
          ),
        ),

        popupProps: const PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search Client Group",
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),

        suffixProps: const DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(
            isVisible: true,
          ),
        ),
      ),
    );
  Widget buildClientSelector() => buildContainer(
        InkWell(
          onTap: openClientSelector,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: "Clients",
              border: OutlineInputBorder(),
            ),
            child: selectedClients.isEmpty
                ? const Text("Select Clients")
                : Text(
                    "Clients (${selectedClients.length} selected)"),
          ),
        ),
      );

  Widget buildDateField(
          String title, TextEditingController controller) =>
      buildContainer(
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => pickDate(controller),
            ),
          ),
        ),
      );

  Widget buildCheckBox(
    String title,
    bool value,
    Function(bool?) onChanged,
  ) =>
      SizedBox(
        width: 250,
        child: CheckboxListTile(
          value: value,
          onChanged: onChanged,
          title: Text(title),
        ),
      );

  Widget buildContainer(Widget child) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return SizedBox(
      width: isDesktop ? 250 : double.infinity,
      child: child,
    );
  }
}

// =====================================================================
// LEDGER REPORT VIEWER
// =====================================================================
//
// Shows the ledger PDF in the app's style:
//   * app bar with the period under the title
//   * a summary card (client(s), period, options)
//   * the PDF pages as white cards on the grey app background
//   * a bottom bar with Share and Print / Save PDF
class LedgerPdfViewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String fromDate;
  final String toDate;
  final int clientCount;
  final String? clientName;
  final bool mergeClients;
  final bool grandTotal;

  const LedgerPdfViewScreen({
    super.key,
    required this.pdfBytes,
    required this.fromDate,
    required this.toDate,
    required this.clientCount,
    this.clientName,
    required this.mergeClients,
    required this.grandTotal,
  });

  static const primaryColor = Color(0xFF06275B);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const borderColor = Color(0xFFD9DEE7);
  static const textColor = Color(0xFF172033);
  static const mutedColor = Color(0xFF667085);

  String get _fileName =>
      "Ledger_${fromDate.replaceAll("/", "-")}_to_${toDate.replaceAll("/", "-")}.pdf";

  String get _clientsText => clientName ??
      (clientCount == 1 ? "1 client" : "$clientCount clients");

  Future<void> _share(BuildContext context) async {
    try {
      await Printing.sharePdf(bytes: pdfBytes, filename: _fileName);
    } catch (e) {
      if (context.mounted) _showError(context, "Could not share the report.\n$e");
    }
  }

  Future<void> _print(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        name: _fileName,
        onLayout: (_) async => pdfBytes,
      );
    } catch (e) {
      if (context.mounted) _showError(context, "Could not print the report.\n$e");
    }
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Message"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ledger Report",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "$fromDate  to  $toDate",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Share",
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => _share(context),
          ),
          IconButton(
            tooltip: "Print / Save PDF",
            icon: const Icon(Icons.print_outlined, color: Colors.white),
            onPressed: () => _print(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _summaryCard(),
          Expanded(
            child: PdfPreview(
              build: (_) async => pdfBytes,
              pdfFileName: _fileName,
              // Our own bottom bar replaces the default toolbar.
              useActions: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              maxPageWidth: 820,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              previewPageMargin: const EdgeInsets.only(bottom: 14),
              scrollViewDecoration: const BoxDecoration(color: backgroundColor),
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              loadingWidget: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 12),
                  Text(
                    "Opening report...",
                    style: TextStyle(color: mutedColor),
                  ),
                ],
              ),
              onError: (context, error) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      "Could not display the report.\n$error",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(context),
    );
  }

  // ---- Summary card above the pages ----
  Widget _summaryCard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 844),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _clientsText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _chip(Icons.date_range_outlined, "$fromDate - $toDate"),
                        if (mergeClients)
                          _chip(Icons.merge_type, "Merged"),
                        if (grandTotal)
                          _chip(Icons.functions, "Grand Total"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: mutedColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: textColor, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  // ---- Bottom action bar ----
  Widget _bottomBar(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _share(context),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text("Share"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _print(context),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text(
                      "Print / Save PDF",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
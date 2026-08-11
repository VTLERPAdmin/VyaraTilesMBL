import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/loader_service.dart';
import '../models/ledger_model.dart';
import '../services/api_services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/session_manager.dart';

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
      final data = await ApiService.getLedgerFilters(userId);

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

  try {
    final clientIds =
        selectedClients.map((e) => e.id).join(",");

    print("================================");
    print("GENERATING LEDGER");
    print("UserID => $userId");
    print("ClientIDs => $clientIds");
    print("FromDate => ${fromDateController.text}");
    print("ToDate => ${toDateController.text}");
    print("MergeClients => $mergeClients");
    print("GrandTotal => $grandTotal");
    print("================================");

    final pdfUrl = await ApiService.getLedgerReport(
      clientIds: clientIds,
      fromDate: fromDateController.text,
      toDate: toDateController.text,
      mergeClients: mergeClients,
      grandTotal: grandTotal,
      userId: userId,
    );

    print("PDF URL => $pdfUrl");

    if (pdfUrl.toString().isEmpty) {
      throw Exception("PDF path is empty");
    }

    await launchUrl(
      Uri.parse(pdfUrl.toString()),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    showError(e.toString());
  } finally {
    if (mounted) {

      LoaderService.hide();
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
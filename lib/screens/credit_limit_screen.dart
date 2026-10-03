// ===============================
// FILE: screens/credit_limit_screen.dart
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import '../models/credit_limit_model.dart';
import '../services/api_services.dart';
import '../services/session_manager.dart';
import '../screens/loader_service.dart';

class CreditLimitScreen extends StatefulWidget {
  const CreditLimitScreen({super.key});

  @override
  State<CreditLimitScreen> createState() => _CreditLimitScreenState();
}

class _CreditLimitScreenState extends State<CreditLimitScreen> {
  static const primaryBlue = Color(0xFF06275B);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const borderColor = Color(0xFFD9DEE7);
  static const mutedColor = Color(0xFF667085);
  static const textColor = Color(0xFF172033);

  bool loading = true;
  String? errorMessage;

  CrLimitDataModel? model;
  List<CrLimitRecordModel> filteredList = [];

  CrLimitLookupItem? selectedMktPerson;
  bool currentLimitsOnly = true;

  final clientSearchController = TextEditingController();
  Timer? _searchDebounce;

  String userId = "";
  String userpwd = "";

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  @override
  void dispose() {
    clientSearchController.dispose();
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
        title: "Loading Credit Limits",
        subtitle: "Fetching data from server...",
      );
    }

    try {
      final data = await ApiService.getCrLimitData(
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

  // ================= FILTERING =================
  void applyFilters() {
    if (model == null) return;

    final query = clientSearchController.text.trim().toLowerCase();
    final today = _dateOnly(DateTime.now());

    final result = model!.records.where((r) {
      final matchesMkt = selectedMktPerson == null ||
          r.mktPersonId == selectedMktPerson!.id;

      final matchesClient =
          query.isEmpty || r.client.toLowerCase().contains(query);

      final matchesCurrent = !currentLimitsOnly ||
          (!_dateOnly(r.effFrom).isAfter(today) &&
              !_dateOnly(r.effTill).isBefore(today));

      return matchesMkt && matchesClient && matchesCurrent;
    }).toList();

    setState(() => filteredList = result);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), applyFilters);
  }

  void onMktPersonChanged(CrLimitLookupItem? v) {
    setState(() => selectedMktPerson = v);
    applyFilters();
  }

  void onCurrentLimitsChanged(bool? v) {
    setState(() => currentLimitsOnly = v ?? true);
    applyFilters();
  }

  // ================= MESSAGE DIALOG =================
  // Used for validation errors and save failures inside the
  // Add/Edit/Deactivate dialog — shown as a stacked AlertDialog
  // (front and center) instead of a SnackBar.
  void _showDialogError(BuildContext ctx, String message) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text("Message"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ================= ADD / EDIT / DEACTIVATE DIALOG =================
  Future<void> _showCrLimitDialog({
    CrLimitRecordModel? record,
    required String mode, // "add" | "edit" | "deactivate"
  }) async {
    if (model == null) return;

    final isAdd = mode == "add";
    final isDeactivate = mode == "deactivate";

    // Add creates a new limit for the client whose record menu was used.
    CrLimitClientOption? selectedClientOption;
    if (isAdd && record != null) {
      selectedClientOption = CrLimitClientOption(
        clientId: record.clientId,
        client: record.client,
        mktPersonId: record.mktPersonId,
      );
    }

    final effFromCtrl = TextEditingController(
      text: !isAdd && record != null
          ? DateFormat('dd/MM/yyyy').format(record.effFrom)
          : "",
    );
    final effTillCtrl = TextEditingController(
      text: !isAdd && record != null
          ? DateFormat('dd/MM/yyyy').format(record.effTill)
          : "",
    );
    final crLimitCtrl = TextEditingController(
      text: !isAdd && record != null
          ? record.crLimit.toStringAsFixed(2)
          : "",
    );
    final crLimitRefCtrl = TextEditingController(
      text: !isAdd && record != null ? record.crLimitRef : "",
    );

    CrLimitLookupItem? selectedAuthPerson = isAdd
        ? null
        : record != null
            ? model!.authPersons.firstWhere(
            (a) => a.id == record.crLimitAuthId,
            orElse: () => model!.authPersons.isNotEmpty
                ? model!.authPersons.first
                : CrLimitLookupItem(id: 0, name: ""),
          )
            : (model!.authPersons.isNotEmpty
                ? model!.authPersons.first
                : null);

    bool isSaving = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> handleSave() async {
              final clientOption = selectedClientOption;
              if (isAdd && clientOption == null) {
                _showDialogError(dialogContext, "Please select a Client");
                return;
              }

              final effFrom =
                  _tryParseDate(effFromCtrl.text) ?? DateTime.now();
              final effTill =
                  _tryParseDate(effTillCtrl.text) ?? DateTime.now();

              if (effTill.isBefore(effFrom)) {
                _showDialogError(
                  dialogContext,
                  "Eff. To cannot be before Eff. From",
                );
                return;
              }

              final crLimitValue = double.tryParse(crLimitCtrl.text) ?? 0;
              if (!isDeactivate && crLimitValue <= 0) {
                _showDialogError(dialogContext, "Please enter Cr. Limit");
                return;
              }

              setDialogState(() => isSaving = true);

              try {
                late final CrLimitRecordModel recordToSave;
                if (isAdd) {
                  recordToSave = CrLimitRecordModel(
                    id: 0,
                    clientId: clientOption!.clientId,
                    client: clientOption.client,
                    mktPersonId: clientOption.mktPersonId,
                    effFrom: effFrom,
                    effTill: effTill,
                    crLimit: crLimitValue,
                    crLimitAuthId: selectedAuthPerson?.id ?? 0,
                    crLimitRef: crLimitRefCtrl.text.trim(),
                  );
                } else if (record != null) {
                  // Deactivate only changes Eff. To; other fields stay unchanged.
                  recordToSave = isDeactivate
                      ? record.copyWith(effTill: effTill)
                      : record.copyWith(
                          effFrom: effFrom,
                          effTill: effTill,
                          crLimit: crLimitValue,
                          crLimitAuthId: selectedAuthPerson?.id,
                          crLimitRef: crLimitRefCtrl.text.trim(),
                        );
                } else {
                  throw StateError("A credit-limit record is required.");
                }

                await ApiService.saveCrLimit(
                  userId: userId,
                  userPwd: userpwd,
                  record: recordToSave,
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } catch (e) {
                setDialogState(() => isSaving = false);
                if (!dialogContext.mounted) return;
                _showDialogError(
                  dialogContext,
                  e.toString().replaceFirst("Exception: ", ""),
                );
              }
            }

            Future<void> pickDate(TextEditingController ctrl) async {
              final initial = _tryParseDate(ctrl.text) ?? DateTime.now();
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() {
                  ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isAdd
                            ? "New Credit Limit"
                            : (isDeactivate
                                ? "Deactivate Credit Limit"
                                : "Edit Credit Limit"),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // LEDGER / CLIENT
                     /* if (isAdd)
                        DropdownSearch<CrLimitClientOption>(
                          selectedItem: selectedClientOption,
                          items: (filter, _) => model!.clientOptions,
                          itemAsString: (item) => item.client,
                          compareFn: (a, b) => a.clientId == b.clientId,
                          onChanged: (v) =>
                              setDialogState(() => selectedClientOption = v),
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
                        )
                      else */
                        TextField(
                          readOnly: true,
                          enabled: false,
                          controller:
                              TextEditingController(text: record?.client),
                          decoration: const InputDecoration(
                            labelText: "Client",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 12),

                      // EFF FROM -- locked in Deactivate mode
                      TextField(
                        controller: effFromCtrl,
                        readOnly: true,
                        enabled: !isDeactivate,
                        onTap: isDeactivate
                            ? null
                            : () => pickDate(effFromCtrl),
                        decoration: const InputDecoration(
                          labelText: "Eff. From",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // EFF TILL -- always editable (this is the field
                      // Deactivate is specifically for)
                      TextField(
                        controller: effTillCtrl,
                        readOnly: true,
                        onTap: () => pickDate(effTillCtrl),
                        decoration: const InputDecoration(
                          labelText: "Eff. To",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // CR LIMIT -- locked in Deactivate mode
                      TextField(
                        controller: crLimitCtrl,
                        readOnly: isDeactivate,
                        enabled: !isDeactivate,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: "Cr. Limits",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // AUTH BY -- locked in Deactivate mode
                      DropdownButtonFormField<CrLimitLookupItem>(
                        initialValue: selectedAuthPerson,
                        items: model!.authPersons
                            .map(
                              (a) => DropdownMenuItem(
                                value: a,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                        onChanged: isDeactivate
                            ? null
                            : (v) =>
                                setDialogState(() => selectedAuthPerson = v),
                        decoration: const InputDecoration(
                          labelText: "Auth By",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // CR LIMIT REF -- locked in Deactivate mode
                      TextField(
                        controller: crLimitRefCtrl,
                        readOnly: isDeactivate,
                        enabled: !isDeactivate,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Remarks ",
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(dialogContext, false),
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                              ),
                              onPressed: isSaving ? null : handleSave,
                              child: isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Save",
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      await loadData();
    }
  }

  DateTime? _tryParseDate(String value) {
    try {
      return DateFormat('dd/MM/yyyy').parse(value);
    } catch (_) {
      return null;
    }
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
            "Temporary Cr. Limits",
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
            "Temporary Cr. Limits",
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
          "Temporary Cr. Limits",
          style: TextStyle(color: Colors.white),
        ),
      ),
     /* floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        onPressed: () => _showCrLimitDialog(mode: "add"),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New", style: TextStyle(color: Colors.white)),
      ),*/
      body: Column(
        children: [
          _filterCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  "Showing ${filteredList.length} of ${model!.records.length}",
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
                            "No credit limits match your filters.",
                            style: TextStyle(color: mutedColor),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: filteredList.length,
                      itemBuilder: (_, index) =>
                          _recordCard(filteredList[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= FILTER CARD =================
  Widget _filterCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownSearch<CrLimitLookupItem>(
            selectedItem: selectedMktPerson,
            items: (filter, _) => model!.mktPersons,
            itemAsString: (item) => item.name,
            compareFn: (a, b) => a.id == b.id,
            onChanged: onMktPersonChanged,
            decoratorProps: const DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: "Mkt.",
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
          ),
          const SizedBox(height: 10),
          TextField(
            controller: clientSearchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              labelText: "Client",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: clientSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        clientSearchController.clear();
                        applyFilters();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          CheckboxListTile(
            value: currentLimitsOnly,
            onChanged: onCurrentLimitsChanged,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text("Current Limits"),
          ),
        ],
      ),
    );
  }

  // ================= RECORD CARD =================
  Widget _recordCard(CrLimitRecordModel record) {
    final authName = model!.authPersons
        .firstWhere(
          (a) => a.id == record.crLimitAuthId,
          orElse: () => CrLimitLookupItem(id: 0, name: "-"),
        )
        .name;

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
                  record.client,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: primaryBlue),
                onSelected: (value) {
                  if (value == "edit") {
                    _showCrLimitDialog(record: record, mode: "edit");
                  } else if (value == "deactivate") {
                    _showCrLimitDialog(record: record, mode: "deactivate");
                  } else if (value == "add") {
                    _showCrLimitDialog(record: record, mode: "add");
                  }
                },
                itemBuilder: (context) => const [
                   PopupMenuItem(
                    value: "add",
                    child: Text("Add"),
                  ),
                  PopupMenuItem(value: "edit", child: Text("Edit")),
                  PopupMenuItem(
                    value: "deactivate",
                    child: Text("Deactivate"),
                  ),
                 
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Cr. Limit: ${record.crLimit.toStringAsFixed(2)}",
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${DateFormat('dd/MM/yyyy').format(record.effFrom)} - "
            "${DateFormat('dd/MM/yyyy').format(record.effTill)}",
            style: const TextStyle(color: mutedColor, fontSize: 13),
          ),
          if (record.crLimitRef.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                record.crLimitRef,
                style: const TextStyle(color: mutedColor, fontSize: 13),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            "Auth By: $authName",
            style: const TextStyle(color: mutedColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
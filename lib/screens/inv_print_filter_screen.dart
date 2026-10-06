// ===============================
// FILE: screens/inv_print_filter_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import '../models/inv_print_model.dart';

class InvPrintFilterResult {
  final String? clientGroup;
  final InvIdNameItem? client;
  final InvIdNameItem? site;
  final InvIdNameItem? mkt;
  final InvIdNameItem? location;
  final String invNo;
  final String soNo;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool hideChallans;
  final bool preSigned;

  InvPrintFilterResult({
    required this.clientGroup,
    required this.client,
    required this.site,
    required this.mkt,
    required this.location,
    required this.invNo,
    required this.soNo,
    required this.fromDate,
    required this.toDate,
    required this.hideChallans,
    required this.preSigned,
  });
}

class InvPrintFilterScreen extends StatefulWidget {
  final InvPrintListModel model;
  final String? initialClientGroup;
  final InvIdNameItem? initialClient;
  final InvIdNameItem? initialSite;
  final InvIdNameItem? initialMkt;
  final InvIdNameItem? initialLocation;
  final String initialInvNo;
  final String initialSoNo;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final bool initialHideChallans;
  final bool initialPreSigned;

  const InvPrintFilterScreen({
    super.key,
    required this.model,
    this.initialClientGroup,
    this.initialClient,
    this.initialSite,
    this.initialMkt,
    this.initialLocation,
    this.initialInvNo = "",
    this.initialSoNo = "",
    this.initialFromDate,
    this.initialToDate,
    this.initialHideChallans = true,
    this.initialPreSigned = false,
  });

  @override
  State<InvPrintFilterScreen> createState() => _InvPrintFilterScreenState();
}

class _InvPrintFilterScreenState extends State<InvPrintFilterScreen> {
  static const primaryBlue = Color(0xFF06275B);
  static const borderColor = Color(0xFFD9DEE7);

  String? clientGroup;
  InvIdNameItem? client;
  InvIdNameItem? site;
  InvIdNameItem? mkt;
  InvIdNameItem? location;

  late TextEditingController invNoController;
  late TextEditingController soNoController;

  DateTime? fromDate;
  DateTime? toDate;

  bool hideChallans = true;
  bool preSigned = false;

  @override
  void initState() {
    super.initState();
    clientGroup = widget.initialClientGroup;
    client = widget.initialClient;
    site = widget.initialSite;
    mkt = widget.initialMkt;
    location = widget.initialLocation;
    invNoController = TextEditingController(text: widget.initialInvNo);
    soNoController = TextEditingController(text: widget.initialSoNo);
    fromDate = widget.initialFromDate;
    toDate = widget.initialToDate;
    hideChallans = widget.initialHideChallans;
    preSigned = widget.initialPreSigned;
  }

  @override
  void dispose() {
    invNoController.dispose();
    soNoController.dispose();
    super.dispose();
  }

  // ================= CASCADING OPTIONS =================
  List<InvIdNameItem> get availableClients {
    if (clientGroup == null) return widget.model.allClients;

    final ids = widget.model.items
        .where((r) => r.clientGroup == clientGroup)
        .map((r) => r.ledgerId)
        .toSet();

    return widget.model.allClients.where((c) => ids.contains(c.id)).toList();
  }

  List<InvIdNameItem> get availableSites {
    Iterable<InvPrintItem> rows = widget.model.items;

    if (clientGroup != null) {
      rows = rows.where((r) => r.clientGroup == clientGroup);
    }
    if (client != null) {
      rows = rows.where((r) => r.ledgerId == client!.id);
    }

    final ids = rows.map((r) => r.siteId).toSet();
    return widget.model.allSites.where((s) => ids.contains(s.id)).toList();
  }

  void onClientGroupChanged(String? v) {
    setState(() {
      clientGroup = v;

      final validClientIds = availableClients.map((c) => c.id).toSet();
      if (client != null && !validClientIds.contains(client!.id)) {
        client = null;
      }

      final validSiteIds = availableSites.map((s) => s.id).toSet();
      if (site != null && !validSiteIds.contains(site!.id)) {
        site = null;
      }
    });
  }

  void onClientChanged(InvIdNameItem? v) {
    setState(() {
      client = v;

      final validSiteIds = availableSites.map((s) => s.id).toSet();
      if (site != null && !validSiteIds.contains(site!.id)) {
        site = null;
      }
    });
  }

  Future<void> pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => fromDate = picked);
  }

  Future<void> pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => toDate = picked);
  }

  void clearAll() {
    setState(() {
      clientGroup = null;
      client = null;
      site = null;
      mkt = null;
      location = null;
      invNoController.clear();
      soNoController.clear();
      fromDate = null;
      toDate = null;
      hideChallans = true;
      preSigned = false;
    });
  }

  void apply() {
    Navigator.pop(
      context,
      InvPrintFilterResult(
        clientGroup: clientGroup,
        client: client,
        site: site,
        mkt: mkt,
        location: location,
        invNo: invNoController.text.trim(),
        soNo: soNoController.text.trim(),
        fromDate: fromDate,
        toDate: toDate,
        hideChallans: hideChallans,
        preSigned: preSigned,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 600; // tablet / landscape -> 2 columns
    final fieldWidth =
        isWide ? (width - 16 * 2 - 12) / 2 : double.infinity;

    final fields = <Widget>[
      _clientGroupDropdown(),
      _clientDropdown(),
      _siteDropdown(),
      _mktDropdown(),
      _locationDropdown(),
      _textField(
        controller: invNoController,
        label: "Inv. No.",
      ),
      _textField(
        controller: soNoController,
        label: "SO No.",
      ),
      _dateField(
        label: "From",
        value: fromDate,
        onTap: pickFromDate,
        onClear: () => setState(() => fromDate = null),
      ),
      _dateField(
        label: "To",
        value: toDate,
        onTap: pickToDate,
        onClear: () => setState(() => toDate = null),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Filters", style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final f in fields)
                      SizedBox(width: fieldWidth, child: f),
                    SizedBox(
                      width: isWide ? double.infinity : double.infinity,
                      child: CheckboxListTile(
                        value: preSigned,
                        onChanged: (v) =>
                            setState(() => preSigned = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text("Pre-Signed (Logged Employee)"),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: CheckboxListTile(
                        value: hideChallans,
                        onChanged: (v) =>
                            setState(() => hideChallans = v ?? true),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text("Hide Challans"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: clearAll,
                      child: const Text("Clear All"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                      onPressed: apply,
                      child: const Text(
                        "Apply",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : null,
        ),
        child: Text(value != null ? DateFormat('dd/MM/yyyy').format(value) : "-"),
      ),
    );
  }

  Widget _clientGroupDropdown() => DropdownSearch<String>(
        selectedItem: clientGroup,
        items: (filter, _) => widget.model.allClientGroups,
        onChanged: onClientGroupChanged,
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
          clearButtonProps: ClearButtonProps(isVisible: true),
        ),
      );

  Widget _clientDropdown() => DropdownSearch<InvIdNameItem>(
        key: ValueKey('client_$clientGroup'),
        selectedItem: client,
        items: (filter, _) => availableClients,
        itemAsString: (item) => item.name,
        compareFn: (a, b) => a.id == b.id,
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

  Widget _siteDropdown() => DropdownSearch<InvIdNameItem>(
        key: ValueKey('site_${clientGroup}_${client?.id}'),
        selectedItem: site,
        items: (filter, _) => availableSites,
        itemAsString: (item) => item.name,
        compareFn: (a, b) => a.id == b.id,
        onChanged: (v) => setState(() => site = v),
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

  Widget _mktDropdown() => DropdownSearch<InvIdNameItem>(
        selectedItem: mkt,
        items: (filter, _) => widget.model.allMktPersons,
        itemAsString: (item) => item.name,
        compareFn: (a, b) => a.id == b.id,
        onChanged: (v) => setState(() => mkt = v),
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
      );

  Widget _locationDropdown() => DropdownSearch<InvIdNameItem>(
        selectedItem: location,
        items: (filter, _) => widget.model.allLocations,
        itemAsString: (item) => item.name,
        compareFn: (a, b) => a.id == b.id,
        onChanged: (v) => setState(() => location = v),
        decoratorProps: const DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "Location",
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
}
// ===============================
// FILE: screens/dispatch_planned_screen.dart
// ===============================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/dispatch_plan_detail_model.dart';
import '../config/app_config.dart';
import '../screens/loader_service.dart';

class DispatchPlanedScreen extends StatefulWidget {
  final int soId;
  final int soSrNo;
  final String userId;
  final String userPwd;
  final int solocId;

  const DispatchPlanedScreen({
    super.key,
    required this.soId,
    required this.soSrNo,
    required this.userId,
    required this.userPwd,
    required this.solocId,
  });

  @override
  State<DispatchPlanedScreen> createState() => _DispatchPlaneScreenState();
}

class _DispatchPlaneScreenState extends State<DispatchPlanedScreen> {
  static const primaryBlue = Color(0xff06275B);
  static const dispatchGrey = Color(0xFFE9EDF2);
  static const mutedColor = Color(0xFF667085);
  static const borderColor = Color(0xFFD9DEE7);

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  DispatchPlanDetailModel? model;

  // Working copy of the plan rows shown in the grid: existing rows
  // fetched from the API, plus any added/edited in this session.
  List<DispatchPlanRow> planRows = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchData();
    });
  }

  // ================= FETCH =================
  Future<void> fetchData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      LoaderService.show(
        context,
        title: "Loading Details",
        subtitle: "Fetching dispatch data...",
      );
    }

    try {
      final uri = Uri.parse(
        "https://vyaratiles.co.in/Api/DPlanSO",
      ).replace(queryParameters: {
        "UserID": widget.userId,
        "UserPwd": widget.userPwd,
        "VerNo": AppConfig.verNo.toString(),
        "SOLocID": widget.solocId.toString(),
        "SOID": widget.soId.toString(),
        "SOSrNo": widget.soSrNo.toString(),
      });

      final res = await http.get(uri);
      final decoded = jsonDecode(res.body);

      if (decoded["StatusCode"] != 200) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage =
              decoded["Message"]?.toString() ?? "Failed to load plan data.";
        });
        return;
      }

      final parsed = DispatchPlanDetailModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );

      if (!mounted) return;

      setState(() {
        model = parsed;
        planRows = List.from(parsed.details);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    } finally {
      LoaderService.hide();
    }
  }

  // ================= SAVE =================
  // Sends the full body: header/context fields (mirrored from the
  // GET response) + UserID/UserPwd/VerNo + the entire current
  // Details array (existing rows, edited rows, and newly added rows).
  Future<void> savePlan() async {
    if (isSaving || model == null) return;

    setState(() => isSaving = true);

    if (mounted) {
      LoaderService.show(
        context,
        title: "Saving Plan",
        subtitle: "Please wait...",
      );
    }

    try {
      final url = Uri.parse("https://vyaratiles.co.in/Api/Dplan");
      final m = model!;

      final body = {
        "UserID": widget.userId,
        "UserPwd": widget.userPwd,
        "VerNo": AppConfig.verNo,

        // Header placeholders (mirrors the DPlanSO "template" shape;
        // the real per-row data lives in Details below).
        "PlanID": 0,
        "PlanDate": DateFormat('dd/MM/yyyy').format(DateTime.now()),
        "PlanType": "A",
        "PlannedQty": 0.0,
        "SaleQty": 0.0,
        "PendingPlanQty": 0.0,
        "AddLessQty": 0.0,
        "NetPlanQty": 0.0,
        "TotalPlanQty": 0.0,

        "StatusCode": 200,
        "Message": "OK",

        "SONo": m.soNo,
        "SODate": m.soDate,
        "SaleLoc": m.saleLoc,
        "PendSaleQty": m.pendSaleQty,
        "StockQty": m.stockQty,
        "Grade": m.grade,
        "Finish": m.finish,
        "LotNo": m.lotNo,
        "MaxPlanQty": m.maxPlanQty,

        "DispatchLocID": m.dispatchLocId,
        "PlanLocID": m.planLocId,
        "SOLocID": m.soLocId,
        "SOID": m.soId,
        "SOSrNo": m.soSrNo,

        "UoMCode": m.uom,
        "Rate": m.rate,

        "ClientID": m.clientId,
        "ClientName": m.clientName,
        "SiteID": m.siteId,
        "SiteName": m.siteName,
        "ProductID": m.productId,
        "ProductName": m.productName,
        "MktPersonID": m.mktPersonId,

        "OrdQty": m.ordQty,
        "ClientGroup": m.clientGroup,
        "ProductType": m.productType,

        "CreditLimit": m.creditLimit,
        "BalAmt": m.balAmt,
        "BalType": m.balType,
        "IsInternal": m.isInternal,
        "AvailableBal": m.availableBal,

        // The full current plan grid — every row, changed or not.
        "Details": planRows.map((r) => r.toJson()).toList(),
      };

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (!mounted) return;

      if (data["StatusCode"] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Plan Saved Successfully")),
        );

        // Reload so the grid reflects the server's saved state
        // (new PlanIDs assigned, etc.).
        await fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["Message"]?.toString() ?? "Save Failed"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      LoaderService.hide();
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  // ================= ADD / EDIT / VIEW DIALOG =================
  Future<void> _showPlanDialog({
    DispatchPlanRow? row,
    required String mode, // "add" | "edit" | "view"
    int? index,
  }) async {
    if (model == null) return;

    final isView = mode == "view";
    final isAdd = mode == "add";

    final dateCtrl = TextEditingController(
      text: row != null
          ? DateFormat('dd/MM/yyyy').format(row.planDate)
          : DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );

    final orgPlanCtrl = TextEditingController(
      text: (row?.plannedQty ?? 0).toStringAsFixed(2),
    );

    // Sale Qty and current Pending (Curr Plan) Qty are always
    // informational: 0 for a brand-new row, fixed/locked for an
    // existing one.
    final saleQty = row?.saleQty ?? 0.0;
    final pendingPlanQty = row?.pendingPlanQty ?? 0.0;

    final addLessCtrl = TextEditingController(
      text: (row?.addLessQty ?? 0).toStringAsFixed(2),
    );

    String planType =
        (row?.planType.isNotEmpty ?? false) ? row!.planType : "A";

    double parsedOrgPlan() => double.tryParse(orgPlanCtrl.text) ?? 0.0;
    double parsedAddLess() => double.tryParse(addLessCtrl.text) ?? 0.0;
    double netPlanQty() => pendingPlanQty + parsedAddLess();
    double totalPlanQty() => parsedOrgPlan() + parsedAddLess();

    final result = await showDialog<DispatchPlanRow>(
      context: context,
      barrierDismissible: !isView,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isAdd
                            ? "New Plan"
                            : (isView ? "View Plan" : "Edit Plan"),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // DATE
                      TextField(
                        controller: dateCtrl,
                        readOnly: true,
                        enabled: !isView,
                        onTap: isView
                            ? null
                            : () async {
                                final initial =
                                    _tryParseDate(dateCtrl.text) ??
                                        DateTime.now();

                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: initial,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    dateCtrl.text =
                                        DateFormat('dd/MM/yyyy').format(picked);
                                  });
                                }
                              },
                        decoration: const InputDecoration(
                          labelText: "Date",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ORG PLAN QTY -- editable only when adding new
                      TextField(
                        controller: orgPlanCtrl,
                        readOnly: true,
                        enabled: false,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: "Org. Plan Qty",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // SALE QTY -- informational, always read-only
                      TextField(
                        readOnly: true,
                        enabled: false,
                        controller:
                            TextEditingController(text: saleQty.toStringAsFixed(2)),
                        decoration: const InputDecoration(
                          labelText: "Sale Qty",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // CURR PLAN / PENDING QTY -- informational, always read-only
                      TextField(
                        readOnly: true,
                        enabled: false,
                        controller: TextEditingController(
                          text: pendingPlanQty.toStringAsFixed(2),
                        ),
                        decoration: const InputDecoration(
                          labelText: "Curr. Plan Qty",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ADD/LESS QTY -- editable in add/edit
                      TextField(
                        controller: addLessCtrl,
                        readOnly: isView,
                        enabled: !isView,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: "Add/Less Qty",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // NET PLAN QTY -- computed, always read-only
                      TextField(
                        readOnly: true,
                        enabled: false,
                        controller: TextEditingController(
                          text: netPlanQty().toStringAsFixed(2),
                        ),
                        decoration: const InputDecoration(
                          labelText: "Net Plan Qty",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // TOTAL PLAN QTY -- computed, always read-only
                      TextField(
                        readOnly: true,
                        enabled: false,
                        controller: TextEditingController(
                          text: totalPlanQty().toStringAsFixed(2),
                        ),
                        decoration: const InputDecoration(
                          labelText: "Total Plan Qty",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // TYPE
                      DropdownButtonFormField<String>(
                        initialValue: planType,
                        items: const [
                          DropdownMenuItem(value: "A", child: Text("A")),
                          DropdownMenuItem(value: "B", child: Text("B")),
                          DropdownMenuItem(value: "C", child: Text("C")),
                          DropdownMenuItem(value: "D", child: Text("D")),
                        ],
                        onChanged: isView
                            ? null
                            : (v) => setDialogState(() => planType = v ?? "A"),
                        decoration: const InputDecoration(
                          labelText: "Type",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(isView ? "Close" : "Cancel"),
                            ),
                          ),
                          if (!isView) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                ),
                                onPressed: () {
                                  if (parsedAddLess() == 0) {
                                    showDialog(
                                      context: dialogContext,
                                      builder: (context) => AlertDialog(
                                        title: const Text("VALIDATION ⚠️"),
                                        content: const Text(
                                            "Please enter Add Less Plan Qty"),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }

                                  if (netPlanQty() < 0) {
                                    showDialog(
                                      context: dialogContext,
                                      builder: (context) => AlertDialog(
                                        title: const Text("VALIDATION ⚠️"),
                                        content: const Text(
                                            "Net Plan Qty cannot be zero"),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }

                                  final newRow = DispatchPlanRow(
                                    planLocId:
                                        row?.planLocId ?? model!.planLocId,
                                    planId: row?.planId ?? 0,
                                    planDate:
                                        DateFormat('dd/MM/yyyy').parse(dateCtrl.text),
                                    entryDate: row?.entryDate ?? DateTime.now(),
                                    soLocId: row?.soLocId ?? model!.soLocId,
                                    soId: row?.soId ?? model!.soId,
                                    soSrNo: row?.soSrNo ?? model!.soSrNo,
                                    planType: planType,
                                    plannedQty: parsedOrgPlan(),
                                    saleQty: saleQty,
                                    pendingPlanQty: pendingPlanQty,
                                    addLessQty: parsedAddLess(),
                                    netPlanQty: netPlanQty(),
                                    totalPlanQty: totalPlanQty(),
                                  );

                                  Navigator.pop(dialogContext, newRow);
                                },
                                child: Text(
                                  isAdd ? "ADD" : "OK",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
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

    if (result == null || !mounted) return;

    setState(() {
      if (isAdd) {
        planRows.add(result);
      } else if (index != null && index >= 0 && index < planRows.length) {
        planRows[index] = result;
      }
    });
  }

  DateTime? _tryParseDate(String value) {
    try {
      return DateFormat('dd/MM/yyyy').parse(value);
    } catch (_) {
      return null;
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text("Dispatch Planning"),
      ),
      floatingActionButton: (!isLoading && model != null)
          ? FloatingActionButton.extended(
              backgroundColor: primaryBlue,
              onPressed: () => _showPlanDialog(mode: "add"),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "New Plan",
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      // CHANGED: was `model == null ? SizedBox.shrink() : ...`, which
      // silently showed a blank screen on any load failure. Now shows
      // a spinner while loading and a visible error + Retry on failure.
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (errorMessage != null || model == null)
              ? _errorState()
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.03,
                    vertical: h * 0.015,
                  ),
                  child: Column(
                    children: [
                      _dispatchCard(w),
                      SizedBox(height: h * 0.015),
                      _plansGridCard(w),
                      SizedBox(height: h * 0.015),
                      _summaryCard(w),
                      SizedBox(height: h * 0.08),
                    ],
                  ),
                ),
    );
  }

  // NEW
  Widget _errorState() {
    return Center(
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
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              onPressed: fetchData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label:
                  const Text("Retry", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DISPATCH =================
  Widget _dispatchCard(double w) {
    final m = model!;

    return Card(
      elevation: 0,
      color: dispatchGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          _header("Dispatch Details"),
          Padding(
            padding: EdgeInsets.all(w * 0.03),
            child: Column(
              children: [
                _box("Client", m.clientName),
                _gap(),
                _box("Site", m.siteName),
                _gap(),
                _box("Product", m.productName),
                _gap(),
                Row(
                  children: [
                    Expanded(child: _mini("Grade", m.grade)),
                    _sp(),
                    Expanded(child: _mini("Finish", m.finish)),
                    _sp(),
                    Expanded(child: _mini("Lot No.", m.lotNo)),
                  ],
                ),
                _gap(),
                Row(
                  children: [
                    Expanded(child: _mini("UOM", m.uom)),
                    _sp(),
                    Expanded(child: _mini("Rate", m.rate.toStringAsFixed(2))),
                  ],
                ),
                _gap(),
                Row(
                  children: [
                    Expanded(
                        child: _mini("Order Qty", m.ordQty.toStringAsFixed(2))),
                    _sp(),
                    Expanded(
                        child: _mini(
                            "Pending Qty", m.pendSaleQty.toStringAsFixed(2))),
                  ],
                ),
                _gap(),
                Row(
                  children: [
                    Expanded(
                        child: _mini(
                            "Credit Limit", m.creditLimit.toStringAsFixed(2))),
                    _sp(),
                    Expanded(
                        child: _mini("Current Bal", m.balAmt.toStringAsFixed(2))),
                  ],
                ),
                _gap(),
                Row(
                  children: [
                    Expanded(
                        child: _mini(
                            "Avail. Bal", m.availableBal.toStringAsFixed(2))),
                    _sp(),
                    Expanded(
                        child: _mini(
                            "Max Qty", m.maxPlanQty.toStringAsFixed(2))),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ================= PLANS GRID =================
  Widget _plansGridCard(double w) {
    return Card(
      elevation: 0,
      color: dispatchGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(w * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Existing Plans",
              style: TextStyle(fontWeight: FontWeight.w700, color: primaryBlue),
            ),
            const Divider(),
            const SizedBox(height: 6),
            if (planRows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.event_note, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      "No plans yet. Tap \"New Plan\" to add one.",
                      style: TextStyle(color: mutedColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...List.generate(
                planRows.length,
                (index) => _planRowCard(planRows[index], index),
              ),
          ],
        ),
      ),
    );
  }

  Widget _planRowCard(DispatchPlanRow row, int index) {
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
                  "Date: ${DateFormat('dd/MM/yyyy').format(row.planDate)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Type ${row.planType}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: primaryBlue),
                onPressed: () {
                  _showPlanDialog(
                    row: row,
                    mode: "edit",
                    index: index,
                  );
                },
              ),
            ],
          ),
          const Divider(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _rowStat("Plan Qty", row.plannedQty),
              _rowStat("Add/Less", row.addLessQty),
              _rowStat("Sale Qty", row.saleQty),
              _rowStat("Eff. Qty", row.netPlanQty),
              _rowStat("Pend. Qty", row.pendingPlanQty),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rowStat(String label, double value) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: mutedColor)),
          const SizedBox(height: 2),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172033),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _summaryCard(double w) {
    final m = model!;

    final totalPlannedAcrossRows =
        planRows.fold<double>(0, (sum, r) => sum + r.netPlanQty);

    final totalPlannedAmt = totalPlannedAcrossRows * m.rate;
    final balAfterPlan = m.availableBal - totalPlannedAmt;

    return Card(
      elevation: 0,
      color: dispatchGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(w * 0.03),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const Text(
                "Summary",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _mini(
                    "Total Planned Qty",
                    totalPlannedAcrossRows.toStringAsFixed(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _mini(
                    "Planned Amt.",
                    totalPlannedAmt.toStringAsFixed(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _mini(
                    "Bal Amt.",
                    balAfterPlan.toStringAsFixed(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _mini("Max Qty", m.maxPlanQty.toStringAsFixed(2)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        isSaving ? null : () => Navigator.of(context).maybePop(),
                    child: const Text(
                      "CANCEL",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                    onPressed: isSaving ? null : savePlan,
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "SAVE",
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= SHARED WIDGETS =================
  Widget _header(String t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Text(t,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      );

  Widget _box(String k, String? v) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text("$k : ${v?.isNotEmpty == true ? v : "-"}"),
      );

  Widget _mini(String k, String? v) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              k,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              (v == null || v.isEmpty || v == "null") ? "-" : v,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _gap() => const SizedBox(height: 10);
  Widget _sp() => const SizedBox(width: 10);
}
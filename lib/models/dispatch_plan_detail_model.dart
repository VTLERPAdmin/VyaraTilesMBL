// ===============================
// FILE: models/dispatch_plan_detail_model.dart
// ===============================

import 'package:intl/intl.dart';

double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is int) return v.toDouble();
  if (v is double) return v;
  return double.tryParse(v.toString()) ?? 0.0;
}

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

bool _b(dynamic v) => v == true;

// The API returns dates as "dd/MM/yyyy" (e.g. "11/09/2026") inside
// Details items. This parses that safely, with an ISO fallback in
// case a different endpoint ever sends "2026-09-23T00:00:00+05:30"
// style dates, and never throws — falls back to DateTime.now()
// instead of crashing the whole parse (which is what caused the
// blank screen before).
DateTime _parseApiDate(dynamic v) {
  if (v == null) return DateTime.now();

  final value = v.toString().trim();
  if (value.isEmpty) return DateTime.now();

  try {
    return DateFormat('dd/MM/yyyy').parseStrict(value);
  } catch (_) {
    // Not dd/MM/yyyy — try ISO 8601 as a fallback.
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
  }

  return DateTime.now();
}

String _formatApiDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

// ============================================================
// One existing (or newly added) plan row, from/for the
// "Details" array.
// ============================================================
class DispatchPlanRow {
  final int planLocId;
  final int planId;
  final DateTime planDate;
  final DateTime entryDate;
  final int soLocId;
  final int soId;
  final int soSrNo;
  final String planType;
  final double plannedQty;
  final double saleQty;
  final double pendingPlanQty;
  final double addLessQty;
  final double netPlanQty;
  final double totalPlanQty;

  DispatchPlanRow({
    required this.planLocId,
    required this.planId,
    required this.planDate,
    required this.entryDate,
    required this.soLocId,
    required this.soId,
    required this.soSrNo,
    required this.planType,
    required this.plannedQty,
    required this.saleQty,
    required this.pendingPlanQty,
    required this.addLessQty,
    required this.netPlanQty,
    required this.totalPlanQty,
  });

  factory DispatchPlanRow.fromJson(Map<String, dynamic> json) {
    return DispatchPlanRow(
      planLocId: _i(json["PlanLocID"]),
      planId: _i(json["PlanID"]),
      planDate: _parseApiDate(json["PlanDate"]),
      entryDate: _parseApiDate(json["EntryDate"]),
      soLocId: _i(json["SOLocID"]),
      soId: _i(json["SOID"]),
      soSrNo: _i(json["SOSrNo"]),
      planType: (json["PlanType"]?.toString().isNotEmpty ?? false)
          ? json["PlanType"].toString()
          : "A",
      plannedQty: _d(json["PlannedQty"]),
      saleQty: _d(json["SaleQty"]),
      pendingPlanQty: _d(json["PendingPlanQty"]),
      addLessQty: _d(json["AddLessQty"]),
      netPlanQty: _d(json["NetPlanQty"]),
      totalPlanQty: _d(json["TotalPlanQty"]),
    );
  }

  // NOTE: PlanDate/EntryDate are formatted back to "dd/MM/yyyy"
  // strings here — jsonEncode() cannot serialize a raw DateTime,
  // it would throw at save time otherwise.
  Map<String, dynamic> toJson() => {
        "PlanLocID": planLocId,
        "PlanID": planId,
        "PlanDate": _formatApiDate(planDate),
        "EntryDate": _formatApiDate(entryDate),
        "SOLocID": soLocId,
        "SOID": soId,
        "SOSrNo": soSrNo,
        "PlanType": planType,
        "PlannedQty": plannedQty,
        "SaleQty": saleQty,
        "PendingPlanQty": pendingPlanQty,
        "AddLessQty": addLessQty,
        "NetPlanQty": netPlanQty,
        "TotalPlanQty": totalPlanQty,
      };
}

// ============================================================
// One entry of "BalanceDetails"
// ============================================================
class BalanceDetailModel {
  final String type;
  final String company;
  final double amt;
  final String displayAmt;

  BalanceDetailModel({
    required this.type,
    required this.company,
    required this.amt,
    required this.displayAmt,
  });

  factory BalanceDetailModel.fromJson(Map<String, dynamic> json) {
    return BalanceDetailModel(
      type: json["Type"]?.toString() ?? "",
      company: json["Company"]?.toString() ?? "",
      amt: _d(json["Amt"]),
      displayAmt: json["DisplayAmt"]?.toString() ?? "",
    );
  }
}

// ============================================================
// Full DPlanSO response
// ============================================================
class DispatchPlanDetailModel {
  final int statusCode;
  final String message;

  final String soNo;
  final String soDate;
  final String saleLoc;
  final double pendSaleQty;
  final double stockQty;
  final String grade;
  final String finish;
  final String lotNo;
  final double maxPlanQty;

  final int dispatchLocId;
  final int planLocId;
  final int soLocId;
  final int soId;
  final int soSrNo;

  final String uom;
  final double rate;

  final int clientId;
  final String clientName;
  final int siteId;
  final String siteName;
  final int productId;
  final String productName;
  final int mktPersonId;

  final double ordQty;
  final String clientGroup;
  final int productType;

  final double creditLimit;
  final double balAmt;
  final List<BalanceDetailModel> balanceDetails;
  final String balType;
  final bool isInternal;
  final double availableBal;

  final List<DispatchPlanRow> details;

  DispatchPlanDetailModel({
    required this.statusCode,
    required this.message,
    required this.soNo,
    required this.soDate,
    required this.saleLoc,
    required this.pendSaleQty,
    required this.stockQty,
    required this.grade,
    required this.finish,
    required this.lotNo,
    required this.maxPlanQty,
    required this.dispatchLocId,
    required this.planLocId,
    required this.soLocId,
    required this.soId,
    required this.soSrNo,
    required this.uom,
    required this.rate,
    required this.clientId,
    required this.clientName,
    required this.siteId,
    required this.siteName,
    required this.productId,
    required this.productName,
    required this.mktPersonId,
    required this.ordQty,
    required this.clientGroup,
    required this.productType,
    required this.creditLimit,
    required this.balAmt,
    required this.balanceDetails,
    required this.balType,
    required this.isInternal,
    required this.availableBal,
    required this.details,
  });

  factory DispatchPlanDetailModel.fromJson(Map<String, dynamic> json) {
    final detailsRaw = json["Details"] as List? ?? [];
    final balanceRaw = json["BalanceDetails"] as List? ?? [];

    return DispatchPlanDetailModel(
      statusCode: _i(json["StatusCode"]),
      message: json["Message"]?.toString() ?? "",
      soNo: json["SONo"]?.toString() ?? "",
      soDate: json["SODate"]?.toString() ?? "",
      saleLoc: json["SaleLoc"]?.toString() ?? "",
      pendSaleQty: _d(json["PendSaleQty"]),
      stockQty: _d(json["StockQty"]),
      grade: json["Grade"]?.toString() ?? "",
      finish: json["Finish"]?.toString() ?? "",
      lotNo: json["LotNo"]?.toString() ?? "",
      maxPlanQty: _d(json["MaxPlanQty"]),
      dispatchLocId: _i(json["DispatchLocID"]),
      planLocId: _i(json["PlanLocID"]),
      soLocId: _i(json["SOLocID"]),
      soId: _i(json["SOID"]),
      soSrNo: _i(json["SOSrNo"]),
      uom: json["UoMCode"]?.toString() ?? "",
      rate: _d(json["Rate"]),
      clientId: _i(json["ClientID"]),
      clientName: json["ClientName"]?.toString() ?? "",
      siteId: _i(json["SiteID"]),
      siteName: json["SiteName"]?.toString() ?? "",
      productId: _i(json["ProductID"]),
      productName: json["ProductName"]?.toString() ?? "",
      mktPersonId: _i(json["MktPersonID"]),
      ordQty: _d(json["OrdQty"]),
      clientGroup: json["ClientGroup"]?.toString() ?? "",
      productType: _i(json["ProductType"]),
      creditLimit: _d(json["CreditLimit"]),
      balAmt: _d(json["BalAmt"]),
      balanceDetails: balanceRaw
          .whereType<Map>()
          .map((e) =>
              BalanceDetailModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      balType: json["BalType"]?.toString() ?? "",
      isInternal: _b(json["IsInternal"]),
      availableBal: _d(json["AvailableBal"]),
      details: detailsRaw
          .whereType<Map>()
          .map((e) => DispatchPlanRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
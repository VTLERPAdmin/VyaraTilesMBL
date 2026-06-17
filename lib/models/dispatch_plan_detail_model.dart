class DispatchPlanDetailModel {
  final String soNo;
  final int soId;
  final int soSrNo;

  // Master data
  final int clientId;
  final int siteId;
  final int productId;
  final int DispatchLocID;
  final String siteName;
  final String clientName;
  final String productName;

  final String grade;
  final String finish;
  final String lotNo;
  final String uom;

  // Qty / stock
  final double rate;
  final double ordQty;
  final double saleQty;
  final double pendSaleQty;
  final double stockQty;
  final double CreditLimit;
  final double BalAmt;
  final double availableBal;
  final double maxPlanQty;

  // Planning fields
  final int planId;
  final int PlannedQty;
  final DateTime? planDate;
  final String planType;
  final double addLessQty;

  DispatchPlanDetailModel({
    required this.soNo,
    required this.soId,
    required this.soSrNo,
    required this.DispatchLocID,
    required this.clientId,
    required this.siteId,
    required this.productId,

    required this.siteName,
    required this.clientName,
    required this.productName,

    required this.grade,
    required this.finish,
    required this.lotNo,
    required this.uom,

    required this.rate,
    required this.ordQty,
    required this.saleQty,
    required this.pendSaleQty,
    required this.stockQty,
    required this.CreditLimit,
    required this.BalAmt,
    required this.availableBal,
    required this.maxPlanQty,

    required this.planId,
    required this.PlannedQty,
    required this.planDate,
    required this.planType,
    required this.addLessQty,
  });

  factory DispatchPlanDetailModel.fromJson(Map<String, dynamic> json) {
    return DispatchPlanDetailModel(
      soNo: json["SONo"]?.toString() ?? "",
      soId: int.tryParse(json["SOID"].toString()) ?? 0,
      soSrNo: int.tryParse(json["SOSrNo"].toString()) ?? 0,
      DispatchLocID: int.tryParse(json["DispatchLocID"].toString()) ?? 0,
      // IDs (IMPORTANT FOR SAVE API)
      clientId: int.tryParse(json["ClientID"].toString()) ?? 0,
      siteId: int.tryParse(json["SiteID"].toString()) ?? 0,
      productId: int.tryParse(json["ProductID"].toString()) ?? 0,

      siteName: json["SiteName"] ?? "",
      clientName: json["ClientName"] ?? "",
      productName: json["ProductName"] ?? "",

      grade: json["Grade"] ?? "",
      finish: json["Finish"] ?? "",
      lotNo: json["LotNo"] ?? "",
      uom: json["UoMCode"] ?? "",

      rate: double.tryParse(json["Rate"].toString()) ?? 0,
      ordQty: double.tryParse(json["OrdQty"].toString()) ?? 0,
      saleQty: double.tryParse(json["SaleQty"].toString()) ?? 0,
      pendSaleQty: double.tryParse(json["PendSaleQty"].toString()) ?? 0,
      stockQty: double.tryParse(json["StockQty"].toString()) ?? 0,
      CreditLimit: double.tryParse(json["CreditLimit"].toString()) ?? 0,
      BalAmt: double.tryParse(json["BalAmt"].toString()) ?? 0,
      availableBal: double.tryParse(json["AvailableBal"].toString()) ?? 0,
      maxPlanQty: double.tryParse(json["MaxPlanQty"].toString()) ?? 0,

      planId: int.tryParse(json["PlanID"].toString()) ?? 0,
      PlannedQty: int.tryParse(json["Planned Qty"].toString()) ??0,

      planDate: json["PlanDate"] != null && json["PlanDate"].toString().isNotEmpty
          ? DateTime.tryParse(json["PlanDate"].toString())
          : null,

      planType: json["PlanType"] ?? "A",

      addLessQty: double.tryParse(json["AddLessQty"].toString()) ?? 0,
    );
  }
}
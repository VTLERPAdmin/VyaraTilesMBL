class SOAcknowledgementModel {
  final int locId;
  final int soId;

  final String soNo;
  final String soDate;

  final String revisionNo;
  final String revisionDate;

  final String client;
  final String siteName;
  final String mktPerson;

  final int saleType;
  final int soType;

  final String preferredApprover;
  final int approvedByID;

  final bool approved;
  final bool lowRate;
  final bool rateChange;

  final String reason;
  final String notes;
  final String userId;

  final bool selected;

  SOAcknowledgementModel({
    required this.locId,
    required this.soId,
    required this.soNo,
    required this.soDate,
    required this.revisionNo,
    required this.revisionDate,
    required this.client,
    required this.siteName,
    required this.mktPerson,
    required this.saleType,
    required this.soType,
    required this.preferredApprover,
    required this.approvedByID,
    required this.approved,
    required this.lowRate,
    required this.rateChange,
    required this.reason,
    required this.notes,
    required this.userId,
    required this.selected,
  });

  factory SOAcknowledgementModel.fromJson(Map<String, dynamic> json) {
    // Debug: Print the actual JSON response to see what fields are available
    print("🔍 SO ACKNOWLEDGEMENT JSON => $json");
    
    return SOAcknowledgementModel(
      locId: json["LocID"] ?? json["LocId"] ?? json["locationId"] ?? 0,
      soId: json["SOID"] ?? json["SOId"] ?? json["soId"] ?? 0,
      soNo: json["SONo"] ?? "",
      soDate: json["SODate"] ?? "",
      revisionNo: json["RevisionNo"]?.toString() ?? "",
      revisionDate: json["RevisionDate"] ?? "",
      client: json["Client"] ?? "",
      siteName: json["SiteName"] ?? "",
      mktPerson: json["MktPerson"] ?? "",
      saleType: json["SaleType"] ?? 0,
      soType: json["SOType"] ?? 0,
      preferredApprover: json["PreferredApprover"] ?? json["LastApprovedBy"] ?? "",
      approvedByID: json["ApprovedByID"] ?? 0,
      approved: json["Approved"] ?? false,
      lowRate: json["LowRate"] ?? false,
      rateChange: json["RateChange"] ?? false,
      reason: json["Reason"] ?? "",
      notes: json["Notes"] ?? "",
      userId: json["UserID"] ?? "",
      selected: json["Selected"] ?? false,
    );
  }
}

class SOApprovalModel {
  final int locId;
  final int id;

  final String soNo;
  final String soDate;

  final String revisionNo;
  final String revisionDate;

  final String client;
  final String siteName;   // 🔥 ADD THIS
  final String mktPerson;

  final String reason;
  final String notes;

  final bool lowRate;
  final bool rateChange;

  final bool approved;
  final bool acknowledged;
  
  final String preferredApprover;  // Last Approved By

  SOApprovalModel({
    required this.locId,
    required this.id,
    required this.soNo,
    required this.soDate,
    required this.revisionNo,
    required this.revisionDate,
    required this.client,
    required this.siteName,   // 🔥 ADD
    required this.mktPerson,
    required this.reason,
    required this.notes,
    required this.lowRate,
    required this.rateChange,
    required this.approved,
    required this.acknowledged,
    required this.preferredApprover,
  });

  factory SOApprovalModel.fromJson(Map<String, dynamic> json) {
    // Debug: Print the actual JSON response to see what fields are available
    print("🔍 SO APPROVAL JSON => $json");
    
    return SOApprovalModel(
      locId: json["LocID"] ?? json["LocId"] ?? json["locationId"] ?? 0,
      id: json["SOID"] ?? json["SOId"] ?? json["soId"] ?? 0,

      soNo: json["SONo"] ?? "",
      soDate: json["SODate"] ?? "",

      revisionNo: json["RevisionNo"]?.toString() ?? "",
      revisionDate: json["RevisionDate"] ?? "",

      client: json["Client"] ?? "",
      siteName: json["SiteName"] ?? "",   // 🔥 ADD
      mktPerson: json["MktPerson"] ?? "",

      reason: json["Reason"] ?? "",
      notes: json["Notes"] ?? "",

      lowRate: json["LowRate"] ?? false,
      rateChange: json["RateChange"] ?? false,
      approved: json["Approved"] ?? false,
      acknowledged: json["Acknowledged"] ?? false,
      preferredApprover: json["PreferredApprover"] ?? json["LastApprovedBy"] ?? "",
    );
  }
}
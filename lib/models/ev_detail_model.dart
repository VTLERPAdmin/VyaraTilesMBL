class EVDetailModel {
  int entryId;
  final int eqId;
  final String eqName;
  final String eqType;
  final String locName;
  final String status;
  final String userName;
  final String lastChargeDate;

  EVInfo startInfo;
  EVInfo endInfo;

  EVDetailModel({
    required this.entryId,
    required this.eqId,
    required this.eqName,
    required this.eqType,
    required this.locName,
    required this.status,
    required this.userName,
    required this.lastChargeDate,
    required this.startInfo,
    required this.endInfo,
  });

  factory EVDetailModel.fromJson(Map<String, dynamic> json) {
    final ev = json["EVInfo"];

    return EVDetailModel(
      entryId: ev["EntryID"] ?? 0,
      eqId: ev["EqID"] ?? 0,
      eqName: ev["EqName"] ?? "",
      eqType: ev["EqType"] ?? "",
      locName: ev["LocName"] ?? "",
      status: ev["Status"] ?? "",
      userName: ev["UserName"] ?? "",
      lastChargeDate: ev["LastChargeDate"] ?? "",
      startInfo: EVInfo.fromJson(ev["StartInfo"] ?? {}),
      endInfo: EVInfo.fromJson(ev["EndInfo"] ?? {}),
    );
  }

  // ✅ IMPORTANT: helps update entryId / startInfo / endInfo safely
  EVDetailModel copyWith({
    int? entryId,
    EVInfo? startInfo,
    EVInfo? endInfo,
  }) {
    return EVDetailModel(
      entryId: entryId ?? this.entryId,
      eqId: eqId,
      eqName: eqName,
      eqType: eqType,
      locName: locName,
      status: status,
      userName: userName,
      lastChargeDate: lastChargeDate,
      startInfo: startInfo ?? this.startInfo,
      endInfo: endInfo ?? this.endInfo,
    );
  }
}

class EVInfo {
  final String readDate;
  final double chargeReading;
  final double meterReading;
  final String notes;
  final String imagePath;

  EVInfo({
    required this.readDate,
    required this.chargeReading,
    required this.meterReading,
    required this.notes,
    required this.imagePath,
  });

  factory EVInfo.fromJson(Map<String, dynamic> json) {
    return EVInfo(
      readDate: json["ReadDate"]?.toString() ?? "",
      chargeReading: (json["ChargeReading"] ?? 0).toDouble(),
      meterReading: (json["MeterReading"] ?? 0).toDouble(),
      notes: json["Notes"] ?? "",
      imagePath: json["Img"] ?? "", // ✅ FIXED (important)
    );
  }
}
class EVModel {
  final int eqId;
  final String eqName;
  final String eqType;
  final String locName;
  

  EVModel({
    required this.eqId,
    required this.eqName,
    required this.eqType,
    required this.locName,

  });

  factory EVModel.fromJson(Map<String, dynamic> json) {
    return EVModel(
      eqId: json["EqID"] ?? 0,
      eqName: json["EqName"] ?? "",
      eqType: json["EqType"] ?? "",
      locName: json["LocName"] ?? "",
      // ✅ MAP FROM API
    );
  }
}
// ===============================
// FILE: models/movable_asset_receive_model.dart
// ===============================
//
// GET  https://vyaratiles.co.in/api/movableAssetReceive
//      -> { RAssets: [...], StatusCode, Message, FileContent }
// POST https://vyaratiles.co.in/api/movableAssetReceivedsave
//      -> body = one RAssets row with UserID / UserPwd / VerNo filled
//         and isReceived = true

class MaReceiveRow {
  /// The row exactly as the server sent it. The save body is built
  /// from this, so any field the app doesn't use still goes back.
  final Map<String, dynamic> raw;

  final int locId;
  final int id;
  final int srNo;
  final int subSrNo;
  final String client;
  final String site;
  final String agency;
  final String location;
  final String description;
  final String uomCode;
  final double qty;
  final bool isReceived;
  final int empId;

  MaReceiveRow({
    required this.raw,
    required this.locId,
    required this.id,
    required this.srNo,
    required this.subSrNo,
    required this.client,
    required this.site,
    required this.agency,
    required this.location,
    required this.description,
    required this.uomCode,
    required this.qty,
    required this.isReceived,
    required this.empId,
  });

  static int _int(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? "") ?? 0;

  static double _double(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? "") ?? 0;

  static String _str(dynamic v) => (v ?? "").toString().trim();

  static bool _bool(dynamic v) =>
      v == true || v?.toString().toLowerCase() == "true" || v == 1;

  factory MaReceiveRow.fromJson(Map<String, dynamic> json) {
    return MaReceiveRow(
      raw: Map<String, dynamic>.from(json),
      locId: _int(json["loc_id"]),
      id: _int(json["id"]),
      srNo: _int(json["srno"]),
      subSrNo: _int(json["subsrno"]),
      client: _str(json["client"]),
      site: _str(json["site"]),
      agency: _str(json["agency"]),
      location: _str(json["location"]),
      description: _str(json["description"]),
      uomCode: _str(json["uom_code"]),
      qty: _double(json["qty"]),
      isReceived: _bool(json["isReceived"]),
      empId: _int(json["EmpID"]),
    );
  }

  /// Unique per card: voucher location + id + line + sub-line.
  String get key => "${locId}_${id}_${srNo}_$subSrNo";

  /// Assumption: subsrno 0 = the asset row itself, > 0 = an item
  /// under that asset.
  bool get isItem => subSrNo != 0;

  /// "VY/MA/HMX/002-21 - RUBI MAKE ... MIXER" -> code + name.
  String get code {
    final i = description.indexOf(" - ");
    return i > 0 ? description.substring(0, i).trim() : "";
  }

  String get name {
    final i = description.indexOf(" - ");
    return i > 0 ? description.substring(i + 3).trim() : description;
  }

  /// Save body: the original row, with credentials filled in and
  /// isReceived set to true.
  Map<String, dynamic> toSaveJson({
    required String userId,
    required String userPwd,
    required int verNo,
  }) {
    return {
      ...raw,
      "UserID": userId,
      "UserPwd": userPwd,
      "VerNo": verNo,
      "isReceived": true,
    };
  }
}
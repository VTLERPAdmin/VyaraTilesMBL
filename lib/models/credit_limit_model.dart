// ===============================
// FILE: models/credit_limit_model.dart
// ===============================

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String _s(dynamic v) => v?.toString() ?? "";

double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is int) return v.toDouble();
  if (v is double) return v;
  return double.tryParse(v.toString()) ?? 0.0;
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

// The API stores dates as ISO-midnight, e.g. "2025-01-28T00:00:00".
// This writes back in exactly that shape.
String formatIsoMidnight(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return "$y-$m-${day}T00:00:00";
}

// ============================================================
// Simple _ID/_Name lookup item, used for both MktPersons and
// AuthPersons (both are reliable, unlike some other lookup
// arrays we've seen elsewhere in this app).
// ============================================================
class CrLimitLookupItem {
  final int id;
  final String name;

  CrLimitLookupItem({required this.id, required this.name});

  factory CrLimitLookupItem.fromJson(Map<String, dynamic> json) {
    return CrLimitLookupItem(
      id: _i(json["_ID"]),
      name: _s(json["_Name"]),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CrLimitLookupItem && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

// ============================================================
// A distinct client, derived from the existing credit-limit
// records — used only for the "New" popup's Ledger picker,
// since New only offers clients that already have at least one
// credit-limit record (per the ERP behaviour).
// ============================================================
class CrLimitClientOption {
  final int clientId;
  final String client;
  final int mktPersonId; // inherited from that client's existing record(s)

  CrLimitClientOption({
    required this.clientId,
    required this.client,
    required this.mktPersonId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrLimitClientOption && other.clientId == clientId);

  @override
  int get hashCode => clientId.hashCode;

  @override
  String toString() => client;
}

// ============================================================
// One credit-limit record (one row of the API's "Clients" array
// — despite the name, this is the limit-period record, not a
// client master row; the same ClientID can have several of
// these over time).
// ============================================================
class CrLimitRecordModel {
  final int id;
  final int clientId;
  final String client;
  final int mktPersonId;
  final DateTime effFrom;
  final DateTime effTill;
  final double crLimit;
  final int crLimitAuthId;
  final String crLimitRef;

  CrLimitRecordModel({
    required this.id,
    required this.clientId,
    required this.client,
    required this.mktPersonId,
    required this.effFrom,
    required this.effTill,
    required this.crLimit,
    required this.crLimitAuthId,
    required this.crLimitRef,
  });

  factory CrLimitRecordModel.fromJson(Map<String, dynamic> json) {
    return CrLimitRecordModel(
      id: _i(json["ID"]),
      clientId: _i(json["ClientID"]),
      client: _s(json["Client"]),
      mktPersonId: _i(json["MktPersonID"]),
      effFrom: _date(json["EffFrom"]) ?? DateTime.now(),
      effTill: _date(json["EffTill"]) ?? DateTime.now(),
      crLimit: _d(json["CrLimit"]),
      crLimitAuthId: _i(json["CrLimitAuthID"]),
      crLimitRef: _s(json["CrLimitRef"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "ID": id,
        "ClientID": clientId,
        "Client": client,
        "MktPersonID": mktPersonId,
        "EffFrom": formatIsoMidnight(effFrom),
        "EffTill": formatIsoMidnight(effTill),
        "CrLimit": crLimit,
        "CrLimitAuthID": crLimitAuthId,
        "CrLimitRef": crLimitRef,
      };

  CrLimitRecordModel copyWith({
    DateTime? effFrom,
    DateTime? effTill,
    double? crLimit,
    int? crLimitAuthId,
    String? crLimitRef,
  }) {
    return CrLimitRecordModel(
      id: id,
      clientId: clientId,
      client: client,
      mktPersonId: mktPersonId,
      effFrom: effFrom ?? this.effFrom,
      effTill: effTill ?? this.effTill,
      crLimit: crLimit ?? this.crLimit,
      crLimitAuthId: crLimitAuthId ?? this.crLimitAuthId,
      crLimitRef: crLimitRef ?? this.crLimitRef,
    );
  }
}

// ============================================================
// Full CrLimitData response
// ============================================================
class CrLimitDataModel {
  final List<CrLimitRecordModel> records;
  final List<CrLimitLookupItem> mktPersons;
  final List<CrLimitLookupItem> authPersons;
  final int statusCode;
  final String message;

  CrLimitDataModel({
    required this.records,
    required this.mktPersons,
    required this.authPersons,
    required this.statusCode,
    required this.message,
  });

  factory CrLimitDataModel.fromJson(Map<String, dynamic> json) {
    final records = (json["Clients"] as List? ?? [])
        .whereType<Map>()
        .map((e) => CrLimitRecordModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final mktPersons = (json["MktPersons"] as List? ?? [])
        .whereType<Map>()
        .map((e) => CrLimitLookupItem.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final authPersons = (json["AuthPersons"] as List? ?? [])
        .whereType<Map>()
        .map((e) => CrLimitLookupItem.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return CrLimitDataModel(
      records: records,
      mktPersons: mktPersons,
      authPersons: authPersons,
      statusCode: _i(json["StatusCode"]),
      message: _s(json["Message"]),
    );
  }

  // Distinct clients (deduped by ClientID) for the "New" Ledger
  // picker — New only offers a client that already has at least
  // one credit-limit record.
  List<CrLimitClientOption> get clientOptions {
    final map = <int, CrLimitClientOption>{};
    for (final r in records) {
      map[r.clientId] = CrLimitClientOption(
        clientId: r.clientId,
        client: r.client,
        mktPersonId: r.mktPersonId,
      );
    }
    final list = map.values.toList()
      ..sort((a, b) => a.client.compareTo(b.client));
    return list;
  }
}
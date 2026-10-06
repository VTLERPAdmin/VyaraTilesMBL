// ===============================
// FILE: models/inv_print_model.dart
// ===============================
//
// Single source of truth: only "InvList" is parsed. There are no
// separate ClientGroup/Client/Site/Mkt/Location lookup arrays in
// this API at all — every row already carries ClientGroup,
// LedgerID+LedgerName, SiteID+Site, BookID+BookName, and
// LocID+LocName directly, so every dropdown's options are simply
// derived (deduped) from the rows themselves.
//
// NOTE: each raw row also has a "VouInfo._objVou" object, which is
// unused boilerplate (identical empty shape on every single row —
// it's what makes the raw JSON huge). It is intentionally not
// parsed here since nothing in the UI uses it.

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

bool _b(dynamic v) => v == true;

DateTime? _date(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

// ============================================================
// Generic id+name dropdown option, used for Client, Site,
// Mkt Person, and Location (all are int-keyed in this API).
// ============================================================
class InvIdNameItem {
  final int id;
  final String name;

  InvIdNameItem({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is InvIdNameItem && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

// ============================================================
// One row of "InvList"
// ============================================================
class InvPrintItem {
  final String clientGroup;
  final String locName;
  final int locId;
  final int id;
  final bool isChallan;
  final String vouNo;
  final DateTime? vouDate;
  final String refNo;
  final int ledgerId;
  final String ledgerName;
  final int siteId;
  final String site;
  final int bookId;
  final String bookName;
  final double amount;

  InvPrintItem({
    required this.clientGroup,
    required this.locName,
    required this.locId,
    required this.id,
    required this.isChallan,
    required this.vouNo,
    required this.vouDate,
    required this.refNo,
    required this.ledgerId,
    required this.ledgerName,
    required this.siteId,
    required this.site,
    required this.bookId,
    required this.bookName,
    required this.amount,
  });

  // Combined key — "ID" alone is NOT globally unique across
  // locations (it resets per LocID), so anything that needs to
  // identify one specific row (e.g. tracking an in-flight print)
  // must use this.
  String get rowKey => "${locId}_$id";

  factory InvPrintItem.fromJson(Map<String, dynamic> json) {
    return InvPrintItem(
      clientGroup: _s(json["ClientGroup"]),
      locName: _s(json["LocName"]),
      locId: _i(json["LocID"]),
      id: _i(json["ID"]),
      isChallan: _b(json["IsChallan"]),
      vouNo: _s(json["VouNo"]),
      vouDate: _date(json["VouDate"]),
      refNo: _s(json["RefNo"]),
      ledgerId: _i(json["LedgerID"]),
      ledgerName: _s(json["LedgerName"]),
      siteId: _i(json["SiteID"]),
      site: _s(json["Site"]),
      bookId: _i(json["BookID"]),
      bookName: _s(json["BookName"]),
      amount: _d(json["Amount"]),
    );
  }
}

// ============================================================
// Full InvPrintData response
// ============================================================
class InvPrintListModel {
  final List<InvPrintItem> items;
  final int statusCode;
  final String message;

  InvPrintListModel({
    required this.items,
    required this.statusCode,
    required this.message,
  });

  factory InvPrintListModel.fromJson(Map<String, dynamic> json) {
    final items = (json["InvList"] as List? ?? [])
        .whereType<Map>()
        .map((e) => InvPrintItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return InvPrintListModel(
      items: items,
      statusCode: _i(json["StatusCode"]),
      message: _s(json["Message"]),
    );
  }

  // -------- Derived dropdown option lists (full, unfiltered) --------

  List<String> get allClientGroups {
    final set = <String>{};
    for (final r in items) {
      if (r.clientGroup.isNotEmpty) set.add(r.clientGroup);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<InvIdNameItem> get allClients {
    final map = <int, InvIdNameItem>{};
    for (final r in items) {
      if (r.ledgerId != 0) {
        map[r.ledgerId] = InvIdNameItem(id: r.ledgerId, name: r.ledgerName);
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<InvIdNameItem> get allSites {
    final map = <int, InvIdNameItem>{};
    for (final r in items) {
      if (r.siteId != 0) {
        map[r.siteId] = InvIdNameItem(id: r.siteId, name: r.site);
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<InvIdNameItem> get allMktPersons {
    final map = <int, InvIdNameItem>{};
    for (final r in items) {
      if (r.bookId != 0) {
        map[r.bookId] = InvIdNameItem(id: r.bookId, name: r.bookName);
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<InvIdNameItem> get allLocations {
    final map = <int, InvIdNameItem>{};
    for (final r in items) {
      if (r.locId != 0) {
        map[r.locId] = InvIdNameItem(id: r.locId, name: r.locName);
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
}
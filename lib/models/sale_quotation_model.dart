
 
  // ===============================
// FILE: models/sale_quotation_model.dart
// ===============================

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String _s(dynamic v) => v?.toString() ?? "";

DateTime? _date(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

// ============================================================
// Mkt Person dropdown option.
// _ID is reliable here (confirmed against MktID in QuotList).
// ============================================================

class QuotMktPersonItem {
  final int id;
  final String name;

  QuotMktPersonItem({required this.id, required this.name});

  factory QuotMktPersonItem.fromJson(Map<String, dynamic> json) {
    return QuotMktPersonItem(
      id: _i(json["_ID"]),
      name: _s(json["_Name"]),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is QuotMktPersonItem && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

// ============================================================
// Client / Site dropdown option.
//
// IMPORTANT: the API's "_ID" field is NOT reliable for either
// Clients or Sites — Clients._ID actually duplicates the row's
// MktID, and Sites._ID is 0 for every row. The only field that
// reliably identifies a unique client/site (and matches
// ClientCode/SiteCode on the QuotList rows) is "_Code".
// So this model is keyed by `code`, not `id`.
// ============================================================
class QuotClientSiteItem {
  final String code;
  final String name;

  QuotClientSiteItem({required this.code, required this.name});

  factory QuotClientSiteItem.fromJson(Map<String, dynamic> json) {
    return QuotClientSiteItem(
      code: _s(json["_Code"]),
      name: _s(json["_Name"]),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuotClientSiteItem && other.code == code);

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => name;
}

// ============================================================
// One row of "QuotList"
// ============================================================
class QuotItem {
  final int locId;
  final int id;
  final String quotNo;
  final DateTime? quotDate;
  final int quotPtyLocId;
  final int quotPtyId;
  final String clientCode;
  final String client;
  final int quotSiteId;
  final String siteCode;
  final String siteName;
  final int mktId;
  final String mktPerson;
  final String soNo;
  final int saleType;

  QuotItem({
    required this.locId,
    required this.id,
    required this.quotNo,
    required this.quotDate,
    required this.quotPtyLocId,
    required this.quotPtyId,
    required this.clientCode,
    required this.client,
    required this.quotSiteId,
    required this.siteCode,
    required this.siteName,
    required this.mktId,
    required this.mktPerson,
    required this.soNo,
    required this.saleType,
  });

  factory QuotItem.fromJson(Map<String, dynamic> json) {
    return QuotItem(
      locId: _i(json["LocID"]),
      id: _i(json["ID"]),
      quotNo: _s(json["QuotNo"]),
      quotDate: _date(json["QuotDate"]),
      quotPtyLocId: _i(json["QuotPtyLocID"]),
      quotPtyId: _i(json["QuotPtyID"]),
      clientCode: _s(json["ClientCode"]),
      client: _s(json["Client"]),
      quotSiteId: _i(json["QuotSiteID"]),
      siteCode: _s(json["SiteCode"]),
      siteName: _s(json["SiteName"]),
      mktId: _i(json["MktID"]),
      mktPerson: _s(json["MktPerson"]),
      soNo: _s(json["SONo"]),
      saleType: _i(json["SaleType"]),
    );
  }
}

// ============================================================
// Full QuotList response
// ============================================================
class QuotListModel {
  final List<QuotMktPersonItem> mktPersons;
  final List<QuotClientSiteItem> clients;
  final List<QuotClientSiteItem> sites;
  final List<QuotItem> quotations;
  final int statusCode;
  final String message;

  QuotListModel({
    required this.mktPersons,
    required this.clients,
    required this.sites,
    required this.quotations,
    required this.statusCode,
    required this.message,
  });

  factory QuotListModel.fromJson(Map<String, dynamic> json) {
    final quotations = (json["QuotList"] as List? ?? [])
        .whereType<Map>()
        .map((e) => QuotItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // MktPersons: _ID is reliable, dedupe by id.
    final mktMap = <int, QuotMktPersonItem>{};
    for (final raw in (json["MktPersons"] as List? ?? []).whereType<Map>()) {
      final item = QuotMktPersonItem.fromJson(Map<String, dynamic>.from(raw));
      if (item.id != 0) mktMap[item.id] = item;
    }
    final mktPersons = mktMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // Clients: _ID is unreliable, dedupe by _Code.
    final clientMap = <String, QuotClientSiteItem>{};
    for (final raw in (json["Clients"] as List? ?? []).whereType<Map>()) {
      final item = QuotClientSiteItem.fromJson(Map<String, dynamic>.from(raw));
      if (item.code.isNotEmpty) clientMap[item.code] = item;
    }
    final clients = clientMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // Sites: _ID is always 0, dedupe by _Code.
    final siteMap = <String, QuotClientSiteItem>{};
    for (final raw in (json["Sites"] as List? ?? []).whereType<Map>()) {
      final item = QuotClientSiteItem.fromJson(Map<String, dynamic>.from(raw));
      if (item.code.isNotEmpty) siteMap[item.code] = item;
    }
    final sites = siteMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return QuotListModel(
      mktPersons: mktPersons,
      clients: clients,
      sites: sites,
      quotations: quotations,
      statusCode: _i(json["StatusCode"]),
      message: _s(json["Message"]),
    );
  }
}


/*


// ================================================================================================================================================================================
                                                                    // new
// ================================================================================================================================================================================

// ================================================================================================================================================================================


// ===============================
// FILE: models/sale_quotation_model.dart
// ===============================

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String _s(dynamic v) => v?.toString() ?? "";

DateTime? _date(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

// ============================================================
// ONE QUOTATION
//
// QuotList already contains:
// - Marketing Person
// - Client
// - Site
// - Quotation information
//
// Therefore this is the main model used by the Flutter screen.
// ============================================================

class QuotItem {
  final int locId;
  final int id;

  final String quotNo;
  final DateTime? quotDate;

  final int quotPtyLocId;
  final int quotPtyId;

  // Client
  final String clientCode;
  final String client;

  // Site
  final int quotSiteId;
  final String siteCode;
  final String siteName;

  // Marketing Person
  final int mktId;
  final String mktPerson;

  // Other quotation information
  final String soNo;
  final int saleType;

  QuotItem({
    required this.locId,
    required this.id,
    required this.quotNo,
    required this.quotDate,
    required this.quotPtyLocId,
    required this.quotPtyId,
    required this.clientCode,
    required this.client,
    required this.quotSiteId,
    required this.siteCode,
    required this.siteName,
    required this.mktId,
    required this.mktPerson,
    required this.soNo,
    required this.saleType,
  });

  factory QuotItem.fromJson(Map<String, dynamic> json) {
    return QuotItem(
      locId: _i(json["LocID"]),
      id: _i(json["ID"]),

      quotNo: _s(json["QuotNo"]),
      quotDate: _date(json["QuotDate"]),

      quotPtyLocId: _i(json["QuotPtyLocID"]),
      quotPtyId: _i(json["QuotPtyID"]),

      // Client
      clientCode: _s(json["ClientCode"]),
      client: _s(json["Client"]),

      // Site
      quotSiteId: _i(json["QuotSiteID"]),
      siteCode: _s(json["SiteCode"]),
      siteName: _s(json["SiteName"]),

      // Marketing Person
      mktId: _i(json["MktID"]),
      mktPerson: _s(json["MktPerson"]),

      // Other
      soNo: _s(json["SONo"]),
      saleType: _i(json["SaleType"]),
    );
  }
}

// ============================================================
// DROPDOWN OPTION
//
// Used for Marketing Person / Client / Site dropdowns.
//
// These are NOT separate API models.
// They are generated from QuotItem data.
// ============================================================

class QuotDropdownItem {
  final String value;
  final String name;

  QuotDropdownItem({
    required this.value,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuotDropdownItem &&
          other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => name;
}

// ============================================================
// FULL QUOTATION LIST RESPONSE
//
// IMPORTANT:
// QuotList is now the SINGLE SOURCE OF TRUTH.
//
// MktPersons / Clients / Sites are NOT read from the API
// response anymore.
//
// They are automatically generated from QuotList.
// ============================================================

class QuotListModel {
  final List<QuotItem> quotations;

  final int statusCode;
  final String message;

  QuotListModel({
    required this.quotations,
    required this.statusCode,
    required this.message,
  });

  factory QuotListModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final quotations = (json["QuotList"] as List? ?? [])
        .whereType<Map>()
        .map(
          (e) => QuotItem.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();

    return QuotListModel(
      quotations: quotations,
      statusCode: _i(json["StatusCode"]),
      message: _s(json["Message"]),
    );
  }

  // ==========================================================
  // MARKETING PERSON DROPDOWN
  //
  // Created directly from QuotList
  // ==========================================================

  List<QuotDropdownItem> get mktPersons {
    final map = <String, String>{};

    for (final quotation in quotations) {
      if (quotation.mktId != 0 &&
          quotation.mktPerson.isNotEmpty) {
        map[quotation.mktId.toString()] =
            quotation.mktPerson;
      }
    }

    final result = map.entries
        .map(
          (e) => QuotDropdownItem(
            value: e.key,
            name: e.value,
          ),
        )
        .toList();

    result.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return result;
  }

  // ==========================================================
  // CLIENT DROPDOWN
  //
  // Created directly from QuotList
  // ==========================================================

  List<QuotDropdownItem> get clients {
    final map = <String, String>{};

    for (final quotation in quotations) {
      if (quotation.clientCode.isNotEmpty &&
          quotation.client.isNotEmpty) {
        map[quotation.clientCode] =
            quotation.client;
      }
    }

    final result = map.entries
        .map(
          (e) => QuotDropdownItem(
            value: e.key,
            name: e.value,
          ),
        )
        .toList();

    result.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return result;
  }

  // ==========================================================
  // SITE DROPDOWN
  //
  // Created directly from QuotList
  // ==========================================================

  List<QuotDropdownItem> get sites {
    final map = <String, String>{};

    for (final quotation in quotations) {
      if (quotation.siteCode.isNotEmpty &&
          quotation.siteName.isNotEmpty) {
        map[quotation.siteCode] =
            quotation.siteName;
      }
    }

    final result = map.entries
        .map(
          (e) => QuotDropdownItem(
            value: e.key,
            name: e.value,
          ),
        )
        .toList();

    result.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return result;
  }

  // ==========================================================
  // FILTER QUOTATIONS
  // ==========================================================

  List<QuotItem> filter({
    String? mktId,
    String? clientCode,
    String? siteCode,
  }) {
    return quotations.where((quotation) {
      // Marketing Person
      if (mktId != null &&
          mktId.isNotEmpty &&
          quotation.mktId.toString() != mktId) {
        return false;
      }

      // Client
      if (clientCode != null &&
          clientCode.isNotEmpty &&
          quotation.clientCode != clientCode) {
        return false;
      }

      // Site
      if (siteCode != null &&
          siteCode.isNotEmpty &&
          quotation.siteCode != siteCode) {
        return false;
      }

      return true;
    }).toList();
  }
}

*/
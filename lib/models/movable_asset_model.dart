// ===============================
// FILE: models/movable_asset_model.dart
// ===============================
//
// Built from the real MovableAsset response. What the data showed:
//
//  * LocList / Client / Site / Agencys / Emps / Taxes all use
//    { _ID, _Name, _Code } and their _ID is unique.
//  * Assets use a different shape:
//      { ID, Name, AssetCode, Code (= HSN code), Rate }
//    Asset codes repeat for a few assets, so assets are keyed by ID.
//    In the current data every asset has Rate 0 and an empty HSN code
//    — the screen shows them as returned.
//  * Items use { ID, Name, Code (= HSN code), UoMCode, Rate }. Most items
//    have an HSN code of "0" in the current data.
//  * UOM has only two entries and BOTH have _ID = 0, so a UOM is
//    identified by its name (NOS / SET), never by its id.
//  * Site._Code holds the owning client's _ID (this is what lets Site
//    be narrowed by Client). 56% of clients have no site at all.

import 'dart:typed_data';

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is int) return v.toDouble();
  if (v is double) return v;
  return double.tryParse(v.toString()) ?? 0.0;
}

String _s(dynamic v) => v?.toString() ?? "";

// ------------------------------------------------------------
// Generic { _ID, _Name, _Code } item: Location, Client, Site,
// Agency, Employee, Tax.
// ------------------------------------------------------------
class MaLookupItem {
  final int id;
  final String name;
  final String code;

  MaLookupItem({required this.id, required this.name, required this.code});

  factory MaLookupItem.fromJson(Map<String, dynamic> json) {
    return MaLookupItem(
      id: _i(json["_ID"]),
      name: _s(json["_Name"]).trim(),
      code: _s(json["_Code"]).trim(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MaLookupItem && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

// ------------------------------------------------------------
// Asset: { ID, Name, AssetCode, Code (HSN), Rate }
// ------------------------------------------------------------
class MaAsset {
  final int id;
  final String name;
  final String assetCode;
  final String hsnCode;
  final double rate;

  MaAsset({
    required this.id,
    required this.name,
    required this.assetCode,
    required this.hsnCode,
    required this.rate,
  });

  factory MaAsset.fromJson(Map<String, dynamic> json) {
    return MaAsset(
      id: _i(json["ID"]),
      name: _s(json["Name"]).trim(),
      assetCode: _s(json["AssetCode"]).trim(),
      hsnCode: _s(json["Code"]).trim(),
      rate: _d(json["Rate"]),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MaAsset && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

// ------------------------------------------------------------
// Item: { ID, Name, Code (HSN), Rate }
// ------------------------------------------------------------
class MaItem {
  final int id;
  final String name;
  final String hsnCode;
  final String uomCode;
  final double rate;

  MaItem({
    required this.id,
    required this.name,
    required this.hsnCode,
    required this.uomCode,
    required this.rate,
  });

  factory MaItem.fromJson(Map<String, dynamic> json) {
    return MaItem(
      id: _i(json["ID"]),
      name: _s(json["Name"]).trim(),
      hsnCode: _s(json["Code"]).trim(),
      uomCode: _s(json["UoMCode"]).trim(),
      rate: _d(json["Rate"]),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MaItem && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

// ------------------------------------------------------------
// UOM: { _ID (always 0), _Name (NOS / SET), _Code (Number / SET) }
// Identified by name because _ID is 0 for every entry.
// ------------------------------------------------------------
class MaUom {
  final String name;
  final String code;

  MaUom({required this.name, required this.code});

  factory MaUom.fromJson(Map<String, dynamic> json) {
    return MaUom(
      name: _s(json["_Name"]).trim(),
      code: _s(json["_Code"]).trim(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MaUom && other.name == name);

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

// ------------------------------------------------------------
// One item under an asset (the voucher's "SubItems"): the item,
// its tax, qty, UOM and remarks.
// ------------------------------------------------------------
class MaItemEntry {
  final MaItem item;
  final String hsnCode;
  final MaLookupItem tax;
  final double qty;
  final MaUom uom;
  final String remarks;

  MaItemEntry({
    required this.item,
    required this.hsnCode,
    required this.tax,
    required this.qty,
    required this.uom,
    required this.remarks,
  });
}

// ------------------------------------------------------------
// One asset line of the voucher: the asset, its GST, its photo, and
// zero or more items (items are optional).
// ------------------------------------------------------------
class MaAssetLine {
  final MaAsset asset;
  final String hsnCode;
  final MaLookupItem? tax; // GST picked for the asset itself
  final List<MaItemEntry> items;
  final Uint8List photoBytes; // compressed photo of the asset
  final String photoExt; // jpg / png / ...

  MaAssetLine({
    required this.asset,
    required this.hsnCode,
    this.tax,
    required this.items,
    required this.photoBytes,
    required this.photoExt,
  });
}

// ------------------------------------------------------------
// Full MovableAsset response
// ------------------------------------------------------------
class MovableAssetLookups {
  final List<MaLookupItem> locations;
  final List<MaLookupItem> clients;
  final List<MaLookupItem> sites;
  final List<MaLookupItem> agencies;
  final List<MaLookupItem> emps;
  final List<MaLookupItem> taxes;
  final List<MaAsset> assets;
  final List<MaItem> items;
  final List<MaUom> uoms;
  final Map<int, List<MaLookupItem>> sitesByClient;
  final int statusCode;
  final String message;

  MovableAssetLookups({
    required this.locations,
    required this.clients,
    required this.sites,
    required this.agencies,
    required this.emps,
    required this.taxes,
    required this.assets,
    required this.items,
    required this.uoms,
    required this.sitesByClient,
    required this.statusCode,
    required this.message,
  });

  factory MovableAssetLookups.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(String key) {
      final raw = json[key];
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    int byName(String a, String b) =>
        a.toLowerCase().compareTo(b.toLowerCase());

    List<MaLookupItem> lookup(String key, {bool sort = true}) {
      final list = maps(key)
          .map(MaLookupItem.fromJson)
          .where((e) => e.id != 0 && e.name.isNotEmpty)
          .toList();
      if (sort) list.sort((a, b) => byName(a.name, b.name));
      return list;
    }

    final sites = lookup("Site");

    // Site._Code = owning client's _ID
    final byClient = <int, List<MaLookupItem>>{};
    for (final s in sites) {
      final clientId = int.tryParse(s.code);
      if (clientId != null) {
        byClient.putIfAbsent(clientId, () => []).add(s);
      }
    }

    final assets =
        maps("Assets")
            .map(MaAsset.fromJson)
            .where((e) => e.id != 0 && e.name.isNotEmpty)
            .toList()
          ..sort((a, b) => byName(a.name, b.name));

    final items =
        maps("Items")
            .map(MaItem.fromJson)
            .where((e) => e.id != 0 && e.name.isNotEmpty)
            .toList()
          ..sort((a, b) => byName(a.name, b.name));

    // UOM: both entries have _ID 0, so dedupe by name.
    final uomMap = <String, MaUom>{};
    for (final u in maps("UOM").map(MaUom.fromJson)) {
      if (u.name.isNotEmpty) uomMap[u.name] = u;
    }

    return MovableAssetLookups(
      locations: lookup("LocList"),
      clients: lookup("Client"),
      sites: sites,
      agencies: lookup("Agencys"),
      emps: lookup("Emps"),
      // Keep the API's own order for taxes (5%, 12%, 18%, IGST).
      taxes: lookup("Taxes", sort: false),
      assets: assets,
      items: items,
      uoms: uomMap.values.toList(),
      sitesByClient: byClient,
      statusCode: _i(json["StatusCode"]),
      message: _s(json["Message"]),
    );
  }

  /// All sites when no client is chosen, otherwise only that client's sites.
  List<MaLookupItem> sitesForClient(int? clientId) {
    if (clientId == null) return sites;
    return sitesByClient[clientId] ?? const [];
  }
}
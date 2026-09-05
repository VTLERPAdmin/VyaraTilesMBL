// ===============================
// FILE: models/stock_report_models.dart
// ===============================


class StockLookupItem {
  final int id;
  final String name;
  final String code;
  final bool disposedValue;

  StockLookupItem({
    required this.id,
    required this.name,
    required this.code,
    required this.disposedValue,
  });

  factory StockLookupItem.fromJson(Map<String, dynamic> json) {
    return StockLookupItem(
      id: json["_ID"] is int
          ? json["_ID"]
          : int.tryParse("${json["_ID"]}") ?? 0,
      name: json["_Name"]?.toString() ?? "",
      code: json["_Code"]?.toString() ?? "",
      disposedValue: json["disposedValue"] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        "_ID": id,
        "_Name": name,
        "_Code": code,
        "disposedValue": disposedValue,
      };

  // Used by DropdownSearch's compareFn / equality checks.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockLookupItem && other.id == id);

  @override
  int get hashCode => id.hashCode;

  // So DropdownSearch(itemAsString: ...) works even if not explicitly set,
  // and so this prints nicely in debug logs / selected chips.
  @override
  String toString() => name;
}

class StockReportFilterModel {
  final List<StockLookupItem> locations;
  final List<StockLookupItem> eqTypes;
  final List<StockLookupItem> secMixTypes;
  final List<StockLookupItem> productGroups;
  final List<StockLookupItem> products;

  final int statusCode;
  final String message;

  StockReportFilterModel({
    required this.locations,
    required this.eqTypes,
    required this.secMixTypes,
    required this.productGroups,
    required this.products,
    required this.statusCode,
    required this.message,
  });

  factory StockReportFilterModel.fromJson(Map<String, dynamic> json) {
    List<StockLookupItem> parseList(String key) {
      final raw = json[key];
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => StockLookupItem.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    }

    return StockReportFilterModel(
      locations: parseList("Locations"),
      eqTypes: parseList("EqTypes"),
      secMixTypes: parseList("SecMixTypes"),
      productGroups: parseList("ProductGroups"),
      products: parseList("Products"),
      statusCode: json["StatusCode"] is int
          ? json["StatusCode"]
          : int.tryParse("${json["StatusCode"]}") ?? 0,
      message: json["Message"]?.toString() ?? "",
    );
  }
}
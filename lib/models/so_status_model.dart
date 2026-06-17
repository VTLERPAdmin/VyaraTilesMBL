// ===============================
// FILE: so_status_model.dart
// ===============================

class DropdownItemModel {
  final int id;
  final String name;

  DropdownItemModel({
    required this.id,
    required this.name,
  });

  factory DropdownItemModel.fromJson(Map<String, dynamic> json) {
    return DropdownItemModel(
      id: json['_ID'] ?? json['ID'] ?? 0,
      name: json['_Name'] ?? json['Name'] ?? '',
    );
  }
}

class ProductModel {
  final int id;
  final String productName;

  ProductModel({
    required this.id,
    required this.productName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['ID'] ?? 0,
      productName: json['ProductName'] ?? '',
    );
  }
}

class ProductGroupModel {
  final int id;
  final String productGroup;
  final List<ProductModel> products;

  ProductGroupModel({
    required this.id,
    required this.productGroup,
    required this.products,
  });

  factory ProductGroupModel.fromJson(Map<String, dynamic> json) {
    return ProductGroupModel(
      id: json['ID'] ?? 0,
      productGroup: json['ProductGroup'] ?? '',
      products: (json['Products'] as List<dynamic>? ?? [])
          .map((e) => ProductModel.fromJson(e))
          .toList(),
    );
  }
}

class SiteModel {
  final int siteId;
  final String siteName;

  SiteModel({
    required this.siteId,
    required this.siteName,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      siteId: json['SiteID'] ?? 0,
      siteName: json['SiteName'] ?? '',
    );
  }
}

class ClientModel {
  final int id;
  final String name;
  final String clientGroup;
  final List<SiteModel> sites;

  ClientModel({
    required this.id,
    required this.name,
    required this.clientGroup,
    required this.sites,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['ID'] ?? 0,
      name: json['Name'] ?? '',
      clientGroup: json['ClientGroup'] ?? '',
      sites: (json['Sites'] as List<dynamic>? ?? [])
          .map((e) => SiteModel.fromJson(e))
          .toList(),
    );
  }
}

class SoStatusModel {
  final List<DropdownItemModel> units;
  final List<DropdownItemModel> soStatus;
  final List<DropdownItemModel> forLocs;
  final List<DropdownItemModel> eqTypes;
  final List<ProductGroupModel> productGroups;
  final List<String> clientGroups;
  final List<ClientModel> clients;
  final List<DropdownItemModel> mktPersons;

  SoStatusModel({
    required this.units,
    required this.soStatus,
    required this.forLocs,
    required this.eqTypes,
    required this.productGroups,
    required this.clientGroups,
    required this.clients,
    required this.mktPersons,
  });

  factory SoStatusModel.fromJson(Map<String, dynamic> json) {
    return SoStatusModel(
      units: (json['Units'] as List<dynamic>? ?? [])
          .map((e) => DropdownItemModel.fromJson(e))
          .toList(),

      soStatus: (json['SOStatus'] as List<dynamic>? ?? [])
          .map((e) => DropdownItemModel.fromJson(e))
          .toList(),

      forLocs: (json['ForLocs'] as List<dynamic>? ?? [])
          .map((e) => DropdownItemModel.fromJson(e))
          .toList(),

      eqTypes: (json['EqTypes'] as List<dynamic>? ?? [])
          .map((e) => DropdownItemModel.fromJson(e))
          .toList(),

      productGroups: (json['ProductGroups'] as List<dynamic>? ?? [])
          .map((e) => ProductGroupModel.fromJson(e))
          .toList(),

      clientGroups:
          (json['ClientGroups'] as List<dynamic>? ?? []).cast<String>(),

      clients: (json['Clients'] as List<dynamic>? ?? [])
          .map((e) => ClientModel.fromJson(e))
          .toList(),

      mktPersons: (json['MktPersons'] as List<dynamic>? ?? [])
          .map((e) => DropdownItemModel.fromJson(e))
          .toList(),
    );
  }
}
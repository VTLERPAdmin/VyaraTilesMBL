class DispatchPlanModel {
  final List<FactoryModel> factories;
  final List<MktPersonModel> mktPersons;
  final List<String> clientGroups;
  final List<ClientModel> clients;
  final List<ProductModel> products;

  DispatchPlanModel({
    required this.factories,
    required this.mktPersons,
    required this.clientGroups,
    required this.clients,
    required this.products,
  });

  factory DispatchPlanModel.fromJson(Map<String, dynamic> json) {
    return DispatchPlanModel(
      factories: (json["Factories"] as List? ?? [])
          .map((e) => FactoryModel.fromJson(e))
          .toList(),

      mktPersons: (json["MktPersons"] as List? ?? [])
          .map((e) => MktPersonModel.fromJson(e))
          .toList(),

      clientGroups: List<String>.from(json["ClientGroups"] ?? []),

      clients: (json["Clients"] as List? ?? [])
          .map((e) => ClientModel.fromJson(e))
          .toList(),

      products: (json["Products"] as List? ?? [])
          .map((e) => ProductModel.fromJson(e))
          .toList(),
    );
  }
}

class FactoryModel {
  final int id;
  final String name;

  FactoryModel({
    required this.id,
    required this.name,
  });

  factory FactoryModel.fromJson(Map<String, dynamic> json) {
    return FactoryModel(
      id: json["_ID"] ?? 0,
      name: json["_Name"] ?? "",
    );
  }
}

class MktPersonModel {
  final int id;
  final String name;

  MktPersonModel({
    required this.id,
    required this.name,
  });

  factory MktPersonModel.fromJson(Map<String, dynamic> json) {
    return MktPersonModel(
      id: json["_ID"] ?? 0,
      name: json["_Name"] ?? "",
    );
  }
}

class ClientModel {
  final int id;
  final String name;
  final String clientGroup;
  final int mktPersonId;
  final List<SiteModel> sites;

  ClientModel({
    required this.id,
    required this.name,
    required this.clientGroup,
    required this.mktPersonId,
    required this.sites,
  });

  factory ClientModel.fromJson(
      Map<String, dynamic> json) {
    return ClientModel(
      id: json["ID"] ?? 0,
      name: json["Name"] ?? "",
      clientGroup: json["ClientGroup"] ?? "",
      mktPersonId: json["MktPersonID"] ?? 0,
      sites: (json["Sites"] as List? ?? [])
          .map((e) => SiteModel.fromJson(e))
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
      siteId: json["SiteID"] ?? 0,
      siteName: json["SiteName"] ?? "",
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
      id: json["ID"] ?? 0,
      productName: json["ProductName"] ?? "",
    );
  }
}

class DispatchPlanRowModel {
  final String site;
  final int soId;
  final int soSrNo;
  final int solocId;
  final String soNo;
  final String poNo;
  final String product;
  final String grade;
  final String finish;
  final String lotNo;
  final String unit;
  final String orderQty;
  final String pendingQty;
  final String planQty;
  final String factory;
  final String client;
  final String clientGroup;
  final String mktPerson;

  DispatchPlanRowModel({
    required this.site,
    required this.soId,
    required this.soSrNo,
    required this.solocId,
    required this.soNo,
    required this.poNo,
    required this.product,
    required this.grade,
    required this.finish,
    required this.lotNo,
    required this.unit,
    required this.orderQty,
    required this.pendingQty,
    required this.planQty,
    required this.factory,
    required this.client,
    required this.clientGroup,
    required this.mktPerson,
  });

  factory DispatchPlanRowModel.fromJson(Map<String, dynamic> json) {
  return DispatchPlanRowModel(
    site: (json["SiteName"] ?? "").toString(),

    soId: int.tryParse(json["SOID"].toString()) ?? 0,
    soSrNo: int.tryParse(json["SrNo"].toString()) ?? 0,
    solocId: int.tryParse(json["LocID"].toString()) ?? 0,

    soNo: (json["SONo"] ?? "").toString(),
    poNo: (json["PONo"] ?? "").toString(),
    product: (json["ProductName"] ?? "").toString(),
    grade: (json["ProductGrade"] ?? "").toString(),
    finish: (json["FinishCode"] ?? "").toString(),
    lotNo: (json["LotNo"] ?? "").toString(),
    unit: (json["UoMCode"] ?? "").toString(),
    orderQty: (json["SOQty"] ?? "").toString(),
    pendingQty: (json["PendingSaleQty"] ?? "").toString(),
    planQty: (json["PendingPlanQty"] ?? "").toString(),
    factory: (json["Factory"] ?? "").toString(),
    client: (json["Client"] ?? "").toString(),
    clientGroup: (json["ClientGroup"] ?? "").toString(),
    mktPerson: (json["MktPerson"] ?? "").toString(),
  );
}
}
    



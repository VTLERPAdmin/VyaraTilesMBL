class DispatchPlanReportModel {
  final List<Factory> factories;
  final List<MktPerson> mktPersons;
  final List<String> clientGroups;
  final List<Client> clients;

  DispatchPlanReportModel({
    required this.factories,
    required this.mktPersons,
    required this.clientGroups,
    required this.clients,
  });

  factory DispatchPlanReportModel.fromJson(Map<String, dynamic> json) {
    return DispatchPlanReportModel(
      factories: (json["Factories"] as List)
          .map((e) => Factory.fromJson(e))
          .toList(),
      mktPersons: (json["MktPersons"] as List)
          .map((e) => MktPerson.fromJson(e))
          .toList(),
      clientGroups:
          List<String>.from(json["ClientGroups"] ?? []),
      clients: (json["Clients"] as List)
          .map((e) => Client.fromJson(e))
          .toList(),
    );
  }
}

class Factory {
  final int id;
  final String name;

  Factory({required this.id, required this.name});

  factory Factory.fromJson(Map<String, dynamic> json) {
    return Factory(
      id: json["_ID"],
      name: json["_Name"],
    );
  }
}

class MktPerson {
  final int id;
  final String name;

  MktPerson({required this.id, required this.name});

  factory MktPerson.fromJson(Map<String, dynamic> json) {
    return MktPerson(
      id: json["_ID"],
      name: json["_Name"],
    );
  }
}

class Client {
  final int id;
  final String name;
  final String clientGroup;
  final List<Site> sites;

  Client({
    required this.id,
    required this.name,
    required this.clientGroup,
    required this.sites,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json["ID"],
      name: json["Name"],
      clientGroup: json["ClientGroup"] ?? "",
      sites: (json["Sites"] as List)
          .map((e) => Site.fromJson(e))
          .toList(),
    );
  }
}

class Site {
  final int siteId;
  final String siteName;

  Site({required this.siteId, required this.siteName});

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      siteId: json["SiteID"] ?? 0,
      siteName: json["SiteName"] ?? "",
    );
  }
}
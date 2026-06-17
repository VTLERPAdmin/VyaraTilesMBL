class LedgerDropdownModel {
  final int id;
  final String name;

  LedgerDropdownModel({
    required this.id,
    required this.name,
  });

  factory LedgerDropdownModel.fromJson(Map<String, dynamic> json) {
    return LedgerDropdownModel(
      id: json['_ID'] ?? json['ID'] ?? 0,
      name: json['_Name'] ?? json['Name'] ?? '',
    );
  }
}

class LedgerClientModel {
  final int id;
  final String name;
  final int acGroupId;
  final String clientGroup;

  LedgerClientModel({
    required this.id,
    required this.name,
    required this.acGroupId,
    required this.clientGroup,
  });

  factory LedgerClientModel.fromJson(Map<String, dynamic> json) {
    return LedgerClientModel(
      id: json['ID'] ?? 0,
      name: json['Name'] ?? '',
      acGroupId: json['AcGroupID'] ?? 0,
      clientGroup: json['ClientGroup'] ?? '',
    );
  }
}

class LedgerFilterModel {
  final String startDate;
  final String endDate;

  final List<LedgerDropdownModel> acGroups;
  final List<String> clientGroups;
  final List<LedgerClientModel> clients;

  LedgerFilterModel({
    required this.startDate,
    required this.endDate,
    required this.acGroups,
    required this.clientGroups,
    required this.clients,
  });

  factory LedgerFilterModel.fromJson(Map<String, dynamic> json) {
    return LedgerFilterModel(
      startDate: json['StartDate'] ?? '',
      endDate: json['EndDate'] ?? '',

      acGroups: (json['AcGroups'] as List<dynamic>? ?? [])
          .map((e) => LedgerDropdownModel.fromJson(e))
          .toList(),

      clientGroups:
          (json['ClientGroups'] as List<dynamic>? ?? []).cast<String>(),

      clients: (json['Clients'] as List<dynamic>? ?? [])
          .map((e) => LedgerClientModel.fromJson(e))
          .toList(),
    );
  }
}
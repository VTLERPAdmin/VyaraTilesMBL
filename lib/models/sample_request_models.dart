// ============================================================
// FILE: sample_request_models.dart
// Sample Request - All Models
// ============================================================

class SampleRequestLookupModel {
  final int id;
  final String name;
  final String code;
  final bool disposedValue;

  SampleRequestLookupModel({
    required this.id,
    required this.name,
    required this.code,
    required this.disposedValue,
  });

  factory SampleRequestLookupModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SampleRequestLookupModel(
      id: _toInt(json["_ID"]),
      name: _toString(json["_Name"]),
      code: _toString(json["_Code"]),
      disposedValue: json["disposedValue"] == true,
    );
  }
}


// ============================================================
// ADDRESS
// ============================================================

class SampleRequestAddressModel {
  final String address1;
  final String address2;
  final String address3;
  final String zipCode;
  final bool disposedValue;
  final String city;
  final String state;
  final String stateCode;
  final String country;
  final int cityId;
  final int stateId;

  SampleRequestAddressModel({
    required this.address1,
    required this.address2,
    required this.address3,
    required this.zipCode,
    required this.disposedValue,
    required this.city,
    required this.state,
    required this.stateCode,
    required this.country,
    required this.cityId,
    required this.stateId,
  });

  factory SampleRequestAddressModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SampleRequestAddressModel(
      address1: _toString(json["_strAddress1"]),
      address2: _toString(json["_strAddress2"]),
      address3: _toString(json["_strAddress3"]),
      zipCode: _toString(json["_strZipCode"]),
      disposedValue: json["disposedValue"] == true,
      city: _toString(json["_strCity"]),
      state: _toString(json["_strState"]),
      stateCode: _toString(json["_strStateCode"]),
      country: _toString(json["_strCountry"]),
      cityId: _toInt(json["_CityID"]),
      stateId: _toInt(json["_StateID"]),
    );
  }

  factory SampleRequestAddressModel.empty() {
    return SampleRequestAddressModel(
      address1: "",
      address2: "",
      address3: "",
      zipCode: "",
      disposedValue: false,
      city: "",
      state: "",
      stateCode: "",
      country: "",
      cityId: 0,
      stateId: 0,
    );
  }

  String get fullAddress {
    return [
      address1,
      address2,
      address3,
      city,
      state,
      zipCode,
      country,
    ]
        .where((e) => e.trim().isNotEmpty)
        .join(", ");
  }
}


// ============================================================
// SITE
// ============================================================

class SampleRequestSiteModel {
  final String id;
  final String name;

  // true when the site was created locally by the user and has
  // not yet been confirmed/saved by the backend.
  final bool isNew;

  SampleRequestSiteModel({
    required this.id,
    required this.name,
    this.isNew = false,
  });

  factory SampleRequestSiteModel.fromJson(dynamic json) {
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);

      return SampleRequestSiteModel(
        id: _toString(
          map["ID"] ??
              map["_ID"] ??
              map["SiteID"] ??
              map["Id"],
        ),
        name: _toString(
          map["Name"] ??
              map["_Name"] ??
              map["SiteName"] ??
              map["Site"],
        ),
      );
    }

    // Some APIs may just return a flat list of site name strings.
    final value = _toString(json);

    return SampleRequestSiteModel(
      id: value,
      name: value,
    );
  }
}


// ============================================================
// LEDGER / CLIENT
// ============================================================

class SampleRequestLedgerModel {
  final String id;
  final String name;
  final SampleRequestAddressModel address;

  final List<SampleRequestSiteModel> sites;

  // true when this ledger/client was created locally by the user
  // (typed a new name) and has not yet been saved by the backend.
  final bool isNew;

  // internal marker used only inside the dropdown's item list to
  // represent the synthetic "Add new client" row. Never a real ledger.
  final bool isAddNewPlaceholder;

  SampleRequestLedgerModel({
    required this.id,
    required this.name,
    required this.address,
    required this.sites,
    this.isNew = false,
    this.isAddNewPlaceholder = false,
  });

  factory SampleRequestLedgerModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final addressJson =
        json["Address"] is Map<String, dynamic>
            ? json["Address"] as Map<String, dynamic>
            : <String, dynamic>{};

    final rawSites = json["Sites"];

    return SampleRequestLedgerModel(
      id: _toString(json["ID"]),
      name: _toString(json["Name"]),
      address: SampleRequestAddressModel.fromJson(
        addressJson,
      ),
      sites: rawSites is List
          ? rawSites
              .map(
                (e) => SampleRequestSiteModel.fromJson(e),
              )
              .toList()
          : <SampleRequestSiteModel>[],
    );
  }

  /// Creates a brand-new, locally-added client from typed text.
  /// Not yet known to the backend -- `id` is a temporary local id.
  factory SampleRequestLedgerModel.newClient(String name) {
    return SampleRequestLedgerModel(
      id: "NEW-${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      address: SampleRequestAddressModel.empty(),
      sites: <SampleRequestSiteModel>[],
      isNew: true,
    );
  }

  /// Synthetic "Add "<query>" as new client" row shown at the
  /// bottom of the dropdown list when there is no exact match.
  factory SampleRequestLedgerModel.addNewPlaceholder(String query) {
    return SampleRequestLedgerModel(
      id: "__ADD_NEW__",
      name: 'Add "$query" as new client',
      address: SampleRequestAddressModel.empty(),
      sites: <SampleRequestSiteModel>[],
      isAddNewPlaceholder: true,
    );
  }
}


// ============================================================
// PRODUCT
// ============================================================

class SampleRequestProductModel {
  final int quotBreakage;
  final double correctionFactor;
  final double surfaceArea;
  final int sampleId;
  final int primaryProductId;

  final String gstHsnCode;
  final String gstHsnShortCode;

  final double stockQty;
  final double noOfPieces;
  final double kgWhtPerSqmt;

  final bool sctThickReq;
  final bool hasImage;

  final int productId;
  final String productName;

  final int groupId;
  final String groupName;

  final int dmmGroupId;
  final String dmmGroupName;

  final int dmmSubGroupId;
  final String dmmSubGroupName;

  final String uomCode;

  final double rate;
  final double mrpRate;

  final int productType;

  final int eqTypeId;
  final String eqType;

  final int secProdId;

  final bool isNew;
  final bool isActive;

  SampleRequestProductModel({
    required this.quotBreakage,
    required this.correctionFactor,
    required this.surfaceArea,
    required this.sampleId,
    required this.primaryProductId,
    required this.gstHsnCode,
    required this.gstHsnShortCode,
    required this.stockQty,
    required this.noOfPieces,
    required this.kgWhtPerSqmt,
    required this.sctThickReq,
    required this.hasImage,
    required this.productId,
    required this.productName,
    required this.groupId,
    required this.groupName,
    required this.dmmGroupId,
    required this.dmmGroupName,
    required this.dmmSubGroupId,
    required this.dmmSubGroupName,
    required this.uomCode,
    required this.rate,
    required this.mrpRate,
    required this.productType,
    required this.eqTypeId,
    required this.eqType,
    required this.secProdId,
    required this.isNew,
    required this.isActive,
  });

  factory SampleRequestProductModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SampleRequestProductModel(
      quotBreakage: _toInt(json["QuotBreakage"]),
      correctionFactor: _toDouble(json["CorrectionFactor"]),
      surfaceArea: _toDouble(json["SurfaceArea"]),
      sampleId: _toInt(json["SampleID"]),
      primaryProductId: _toInt(json["PrimaryProductID"]),
      gstHsnCode: _toString(json["GSTHSNCode"]),
      gstHsnShortCode: _toString(json["GSTHSNShortCode"]),
      stockQty: _toDouble(json["StockQty"]),
      noOfPieces: _toDouble(json["NoOfPieces"]),
      kgWhtPerSqmt: _toDouble(json["KGWhtPerSQMT"]),
      sctThickReq: json["SctThickReq"] == true,
      hasImage: json["HasImage"] == true,
      productId: _toInt(json["ProductID"]),
      productName: _toString(json["ProductName"]),
      groupId: _toInt(json["GroupID"]),
      groupName: _toString(json["GroupName"]),
      dmmGroupId: _toInt(json["DMMGroupID"]),
      dmmGroupName: _toString(json["DMMGroupName"]),
      dmmSubGroupId: _toInt(json["DMMSubGroupID"]),
      dmmSubGroupName: _toString(json["DMMSubGroupName"]),
      uomCode: _toString(json["UoMCode"]),
      rate: _toDouble(json["Rate"]),
      mrpRate: _toDouble(json["MRPRate"]),
      productType: _toInt(json["ProductType"]),
      eqTypeId: _toInt(json["EqTypeID"]),
      eqType: _toString(json["EqType"]),
      secProdId: _toInt(json["SecProdID"]),
      isNew: json["IsNew"] == true,
      isActive: json["IsActive"] == true,
    );
  }
}


// ============================================================
// PRODUCTS WRAPPER
// ============================================================

class SampleRequestProductsModel {
  final List<SampleRequestProductModel> baseData;

  final int id;
  final String product;

  final int groupId;
  final int dmmGroupId;
  final int dmmSubGroupId;
  final int eqTypeId;

  final int isActive;
  final int productType;

  final bool stockReq;
  final int stockLocId;

  SampleRequestProductsModel({
    required this.baseData,
    required this.id,
    required this.product,
    required this.groupId,
    required this.dmmGroupId,
    required this.dmmSubGroupId,
    required this.eqTypeId,
    required this.isActive,
    required this.productType,
    required this.stockReq,
    required this.stockLocId,
  });

  factory SampleRequestProductsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawBaseData = json["BaseData"];

    final products = rawBaseData is List
        ? rawBaseData
            .whereType<Map>()
            .map(
              (e) => SampleRequestProductModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <SampleRequestProductModel>[];

    return SampleRequestProductsModel(
      baseData: products,
      id: _toInt(json["ID"]),
      product: _toString(json["Product"]),
      groupId: _toInt(json["GroupID"]),
      dmmGroupId: _toInt(json["DMMGroupID"]),
      dmmSubGroupId: _toInt(json["DMMSubGroupID"]),
      eqTypeId: _toInt(json["EqTypeID"]),
      isActive: _toInt(json["IsActive"]),
      productType: _toInt(json["ProductType"]),
      stockReq: json["StockReq"] == true,
      stockLocId: _toInt(json["StockLocID"]),
    );
  }
}


// ============================================================
// MASTER RESPONSE
// ============================================================

class SampleRequestMasterModel {
  final List<SampleRequestLookupModel> locations;
  final List<SampleRequestLookupModel> reasons;
  final List<SampleRequestLookupModel> deliveryModes;
  final List<SampleRequestLookupModel> employees;

  final List<SampleRequestLedgerModel> ledgers;

  final List<SampleRequestLookupModel> contacts;

  final SampleRequestProductsModel products;

  final List<SampleRequestLookupModel> grades;
  final List<SampleRequestLookupModel> finishes;
  final List<SampleRequestLookupModel> units;

  final int statusCode;
  final String message;

  SampleRequestMasterModel({
    required this.locations,
    required this.reasons,
    required this.deliveryModes,
    required this.employees,
    required this.ledgers,
    required this.contacts,
    required this.products,
    required this.grades,
    required this.finishes,
    required this.units,
    required this.statusCode,
    required this.message,
  });

  factory SampleRequestMasterModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SampleRequestMasterModel(
      locations: _lookupList(json["LocList"]),
      reasons: _lookupList(json["Reasons"]),
      deliveryModes: _lookupList(json["DeliveryModes"]),
      employees: _lookupList(json["EmpList"]),
      ledgers: _ledgerList(json["Ledgers"]),
      contacts: _lookupList(json["ContactNos"]),
      products: SampleRequestProductsModel.fromJson(
        json["Products"] is Map
            ? Map<String, dynamic>.from(json["Products"])
            : <String, dynamic>{},
      ),
      grades: _lookupList(json["Grades"]),
      finishes: _lookupList(json["Finish"]),
      units: _lookupList(json["Units"]),
      statusCode: _toInt(json["StatusCode"]),
      message: _toString(json["Message"]),
    );
  }

  static List<SampleRequestLookupModel> _lookupList(
    dynamic value,
  ) {
    if (value is! List) {
      return <SampleRequestLookupModel>[];
    }

    return value
        .whereType<Map>()
        .map(
          (e) => SampleRequestLookupModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  static List<SampleRequestLedgerModel> _ledgerList(
    dynamic value,
  ) {
    if (value is! List) {
      return <SampleRequestLedgerModel>[];
    }

    return value
        .whereType<Map>()
        .map(
          (e) => SampleRequestLedgerModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }
}


// ============================================================
// SAMPLE REQUEST PRODUCT LINE
// This is our UI/request state, NOT the API master product.
// ============================================================

class SampleRequestLineModel {
  SampleRequestProductModel? product;
  SampleRequestLookupModel? grade;
  SampleRequestLookupModel? finish;
  SampleRequestLookupModel? unit;

  double quantity;
  double rate;

  String notes;
  bool isDryMix;

  SampleRequestLineModel({
    this.product,
    this.grade,
    this.finish,
    this.unit,
    this.quantity = 0,
    this.rate = 0,
    this.notes = "",
    this.isDryMix = false,
  });

  double get value => quantity * rate;
}


// ============================================================
// SAFE CONVERSION HELPERS
// ============================================================

String _toString(dynamic value) {
  if (value == null) {
    return "";
  }

  return value.toString();
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  return int.tryParse(
        value.toString(),
      ) ??
      0;
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  return double.tryParse(
        value.toString(),
      ) ??
      0;
}
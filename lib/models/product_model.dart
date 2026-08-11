class ProductModel {
  final int productTypeID;
  final String productType;

  final int businessDivID;
  final String businessDiv;

  final int productGroupID;
  final String productGroup;

  final int dmmGroupID;
  final String dmmGroup;

  final int dmmSubGroupID;
  final String dmmSubGroup;

  final String design;
  final String thicknessOrSize;
  final String color;

  final int eqTypeID;
  final String eqType;

  final double pcsPerSqMt;
  final String uom;
  final double mrp;
  final String Weight;

  final String cementType;

  final int id;
  final String productName;

  ProductModel({
    required this.productTypeID,
    required this.productType,
    required this.businessDivID,
    required this.businessDiv,
    required this.productGroupID,
    required this.productGroup,
    required this.dmmGroupID,
    required this.dmmGroup,
    required this.dmmSubGroupID,
    required this.dmmSubGroup,
    required this.design,
    required this.thicknessOrSize,
    required this.color,
    required this.eqTypeID,
    required this.eqType,
    required this.pcsPerSqMt,
    required this.uom,
    required this.mrp,
    required this.Weight,
    required this.cementType,
    required this.id,
    required this.productName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productTypeID: json["ProductTypeID"] ?? 0,
      productType: json["ProductType"] ?? "",

      businessDivID: json["BusinessDivID"] ?? 0,
      businessDiv: json["BusinessDiv"] ?? "",

      productGroupID: json["ProductGroupID"] ?? 0,
      productGroup: json["ProductGroup"] ?? "",

      dmmGroupID: json["DMMGroupID"] ?? 0,
      dmmGroup: json["DMMGroup"] ?? "",

      dmmSubGroupID: json["DMMSubGroupID"] ?? 0,
      dmmSubGroup: json["DMMSubGroup"] ?? "",

      design: json["Design"] ?? "",
      thicknessOrSize: json["ThicknessOrSize"] ?? "",
      color: json["Color"] ?? "",

      eqTypeID: json["EqTypeID"] ?? 0,
      eqType: json["EqType"] ?? "",

      pcsPerSqMt:
    double.tryParse(
      json["PcsPerSqMt"].toString(),
    ) ??
    0,
    Weight: json["Weight"] ?? "",

      uom: json["uom"] ?? "",

   mrp:
    double.tryParse(
      json["MRP"].toString(),
    ) ??
    0,

      cementType: json["CementType"] ?? "",

      id: json["ID"] ?? 0,

      productName: json["ProductName"] ?? "",
    );
  }
}
class WorkOrderStatusModel {
  final List<DropdownItemModel> locations;
  final List<ProductGroupModel> productGroups;
  final List<ProductModel> products;
  final List<ClientModel> clients;
  final List<SiteModel> sites;
  final List<DropdownItemModel> equipmentTypes;
  final List<DropdownItemModel> units;
  final List<DropdownItemModel> statuses;

  WorkOrderStatusModel({
    required this.locations,
    required this.productGroups,
    required this.products,
    required this.clients,
    required this.sites,
    required this.equipmentTypes,
    required this.units,
    required this.statuses,
  });


  factory WorkOrderStatusModel.fromJson(Map<String, dynamic> json) {


    final siteList = (json["Sites"] ?? [])
        .map<SiteModel>(
          (e) => SiteModel.fromJson(e),
        )
        .toList();


    final clientList = (json["Clients"] ?? [])
        .map<ClientModel>(
          (e) {

            final client = ClientModel.fromJson(e);


            // Map sites with client id
            client.sites = siteList.where(
              (site) =>
                  site.code.toString() ==
                  client.id.toString(),
            ).toList();


            return client;

          },
        )
        .toList();



    return WorkOrderStatusModel(

      locations: (json["Locations"] ?? [])
          .map<DropdownItemModel>(
            (e) => DropdownItemModel.fromJson(e),
          )
          .toList(),


      productGroups: (json["ProductGroups"] ?? [])
          .map<ProductGroupModel>(
            (e) => ProductGroupModel.fromJson(e),
          )
          .toList(),


      products: (json["Products"] ?? [])
          .map<ProductModel>(
            (e) => ProductModel.fromJson(e),
          )
          .toList(),


      clients: clientList,


      sites: siteList,


      equipmentTypes: (json["EqTypes"] ?? [])
          .map<DropdownItemModel>(
            (e) => DropdownItemModel.fromJson(e),
          )
          .toList(),


      units: (json["Units"] ?? [])
          .map<DropdownItemModel>(
            (e) => DropdownItemModel.fromJson(e),
          )
          .toList(),


      statuses: (json["StatusList"] ?? [])
          .map<DropdownItemModel>(
            (e) => DropdownItemModel.fromJson(e),
          )
          .toList(),

    );
  }
}




class DropdownItemModel {

  final int id;
  final String name;
  final String code;


  DropdownItemModel({
    required this.id,
    required this.name,
    required this.code,
  });


  factory DropdownItemModel.fromJson(Map<String,dynamic> json){

    return DropdownItemModel(
      id: json["_ID"] ?? 0,
      name: json["_Name"] ?? "",
      code: json["_Code"] ?? "",
    );

  }

}




class ClientModel {

  final int id;
  final String name;
  final String code;

  List<SiteModel> sites = [];


  ClientModel({
    required this.id,
    required this.name,
    required this.code,
  });



  factory ClientModel.fromJson(Map<String,dynamic> json){

    return ClientModel(
      id: json["_ID"] ?? 0,
      name: json["_Name"] ?? "",
      code: json["_Code"] ?? "",
    );

  }

}




class SiteModel {

  final int siteId;
  final String name;
  final String code;


  SiteModel({
    required this.siteId,
    required this.name,
    required this.code,
  });



  factory SiteModel.fromJson(Map<String,dynamic> json){

    return SiteModel(

      siteId: json["_ID"] ?? 0,

      name: json["_Name"] ?? "",

      code: json["_Code"] ?? "",

    );

  }

}




class ProductGroupModel {

  final int id;
  final String name;
  final String code;


  ProductGroupModel({
    required this.id,
    required this.name,
    required this.code,
  });


  factory ProductGroupModel.fromJson(Map<String,dynamic> json){

    return ProductGroupModel(
      id: json["_ID"] ?? 0,
      name: json["_Name"] ?? "",
      code: json["_Code"] ?? "",
    );

  }

}




class ProductModel {

  final int id;
  final String name;
  final String code;


  ProductModel({
    required this.id,
    required this.name,
    required this.code,
  });



  factory ProductModel.fromJson(Map<String,dynamic> json){

    return ProductModel(

      id: json["_ID"] ?? 0,

      name: json["_Name"] ?? "",

      code: json["_Code"] ?? "",

    );

  }

}
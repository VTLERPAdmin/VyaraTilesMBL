import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'dart:async';
import '../models/product_model.dart';
import '../services/api_services.dart';
import 'loader_service.dart';

class ProductScreen extends StatefulWidget {

  final String userId;

  const ProductScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProductScreen> createState() =>
      _ProductScreenState();

}
class _ProductScreenState extends State<ProductScreen> {

  List<ProductModel> allProducts = [];

  List<ProductModel> products = [];


  bool isLoading = false;


  final TextEditingController searchController =
      TextEditingController();



  String? selectedGroup;
  String? selectedEqType;
  String? selectedDryMixGroup;
  String? selectedDryMixSubGroup;


  bool hideSeconds = false;



  List<String> productGroups = [];

  List<String> eqTypes = [];

  List<String> dryMixGroups = [];

  List<String> dryMixSubGroups = [];





  @override
  void initState() {

    super.initState();

    loadProducts();

  }
Future<void> loadProducts() async {

  if (!mounted) return;


  final completer = Completer<void>();

  WidgetsBinding.instance.addPostFrameCallback((_) {

    if (!completer.isCompleted) {
      completer.complete();
    }

  });


  await completer.future;


  if (!mounted) return;


  final loaderToken = LoaderService.showTracked(
    context,
    title: "Loading Products",
    subtitle: "Fetching product list...",
  );


  try {


    final data = await ApiService.getProducts(
      widget.userId,
    );


    if (!mounted) return;


    setState(() {

      allProducts = data;

      products = data;

      buildDropdownData();

    });



    debugPrint(
      "PRODUCT COUNT => ${products.length}",
    );


  }

  catch(e){

    debugPrint(
      "PRODUCT ERROR => $e",
    );


    if(mounted){

      ScaffoldMessenger.of(context)
      .showSnackBar(

        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),

      );

    }

  }


  finally{


    LoaderService.hideIfCurrent(
      loaderToken,
    );


    if(mounted){

      setState((){

        isLoading=false;

      });

    }
  }
}
  void buildDropdownData(){
    productGroups =
        allProducts
            .map(
              (e)=>e.productGroup,
        )
            .where(
              (e)=>e.isNotEmpty,
        )
            .toSet()
            .toList();
    eqTypes =
        allProducts
            .map(
              (e)=>e.eqType,
        )
            .where(
              (e)=>e.isNotEmpty,
        )
            .toSet()
            .toList();




    dryMixGroups =
        allProducts
            .map(
              (e)=>e.dmmGroup,
        )
            .where(
              (e)=>e.isNotEmpty,
        )
            .toSet()
            .toList();




    dryMixSubGroups =
        allProducts
            .map(
              (e)=>e.dmmSubGroup,
        )
            .where(
              (e)=>e.isNotEmpty,
        )
            .toSet()
            .toList();


  }






  void applyFilter(){


    List<ProductModel> temp =
        List.from(allProducts);



    if(searchController.text.isNotEmpty){

      final search =
          searchController.text
              .toLowerCase();


      temp =
          temp.where(

              (e)=>

          e.productName
              .toLowerCase()
              .contains(search)

      ).toList();

    }





    if(selectedGroup!=null){

      temp =
          temp.where(
              (e)=>
          e.productGroup ==
              selectedGroup

      ).toList();

    }





    if(selectedEqType!=null){

      temp =
          temp.where(
              (e)=>
          e.eqType ==
              selectedEqType

      ).toList();

    }





    if(selectedDryMixGroup!=null){

      temp =
          temp.where(
              (e)=>
          e.dmmGroup ==
              selectedDryMixGroup

      ).toList();

    }





    if(selectedDryMixSubGroup!=null){

      temp =
          temp.where(
              (e)=>
          e.dmmSubGroup ==
              selectedDryMixSubGroup

      ).toList();

    }





    if(hideSeconds){

      temp =
          temp.where(
              (e)=>
          e.productGroup
              .toLowerCase()
              !=
              "seconds"

      ).toList();

    }





    setState(() {

      products = temp;

    });


  }







  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor:
      const Color(0xffF2F3F7),



      appBar:
      AppBar(

        backgroundColor:
        const Color(0xff06275B),

        foregroundColor:
        Colors.white,


        title:
        const Text(
          "Products",
        ),


        actions:[

          IconButton(

            icon:
            const Icon(
              Icons.filter_alt,
            ),


            onPressed:
            showFilterSheet,

          )

        ],

      ),






      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = width < 360 ? 10.0 : 14.0;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 10,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search Product Name",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            applyFilter();
                          },
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (_) => applyFilter(),
                    ),
                  ),





                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : products.isEmpty
                            ? const Center(
                                child: Text(
                                  "No Product Found",
                                  style: TextStyle(fontSize: 14),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  return buildProductCard(
                                    context,
                                    products[index],
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        ),
      ),



    );


  }
// ================= PRODUCT CARD =================


Widget buildProductCard(BuildContext context, ProductModel item) {


  return Container(

    margin:
    const EdgeInsets.symmetric(
      horizontal:12,
      vertical:8,
    ),


    decoration:
    BoxDecoration(

      color:
      Colors.white,

      borderRadius:
      BorderRadius.circular(14),


      boxShadow:[

        BoxShadow(

          color:
          Colors.black.withOpacity(0.08),

          blurRadius:8,

          offset:
          const Offset(0,3),

        )

      ],

    ),



    child:
    Padding(

      padding:
      const EdgeInsets.all(14),


      child:
      Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,


        children:[



          Text(

            item.productName,

            maxLines:2,

            overflow:
            TextOverflow.ellipsis,


            style:
            const TextStyle(

              fontSize:16,

              fontWeight:
              FontWeight.bold,

              color:
              Color(0xff06275B),

            ),

          ),



          const SizedBox(height:8),



          Container(

            padding:
            const EdgeInsets.symmetric(
              horizontal:10,
              vertical:5,
            ),


            decoration:
            BoxDecoration(

              color:
              const Color(0xffE8F0FF),

              borderRadius:
              BorderRadius.circular(20),

            ),


            child:
            Text(

              item.productGroup,


              style:
              const TextStyle(

                color:
                Color(0xff06275B),

                fontSize:12,

                fontWeight:
                FontWeight.w600,

              ),

            ),

          ),



          const SizedBox(height:15),




          GridView.count(


            shrinkWrap:true,


            physics:
            const NeverScrollableScrollPhysics(),


            crossAxisCount:2,


            childAspectRatio:3,


            children:[


              infoItem(
                  "Design",
                  item.design
              ),


              infoItem(
                  "Color",
                  item.color
              ),


              infoItem(
                  "Size",
                  item.thicknessOrSize
              ),


              infoItem(
                  "Weight",
                  item.Weight
              ),


              infoItem(
                  "PCS/SQMT",
                  item.pcsPerSqMt.toString()
              ),


              infoItem(
                  "Cement",
                  item.cementType
              ),

              /*
              infoItem(
                  "Weight",
                  item.Weight
              ), */


            ],

          ),




          const Divider(),




          Row(

            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,


            children:[



              Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,


                children:[


                  const Text(

                    "MRP",

                    style:
                    TextStyle(

                      color:
                      Colors.grey,

                      fontSize:12,

                    ),

                  ),



                  Text(

                    "₹${item.mrp.toStringAsFixed(2)}",


                    style:
                    const TextStyle(

                      fontSize:22,

                      fontWeight:
                      FontWeight.bold,

                      color:
                      Color(0xff06275B),

                    ),

                  ),



                ],
                

              ),




              ElevatedButton.icon(

                style:
                ElevatedButton.styleFrom(

                  backgroundColor:
                  const Color(0xff06275B),

                  foregroundColor:
                  Colors.white,

                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(25),

                  ),

                ),


                icon:
                const Icon(
                  Icons.visibility,
                ),


                label:
                const Text(
                  "Details",
                ),



                onPressed:(){

                  showProductDetails(item);

                },


              )



            ],

          )


        ],

      ),

    ),

  );


}







Widget infoItem(
    String title,
    String value
){


  return Column(

    crossAxisAlignment:
    CrossAxisAlignment.start,


    children:[


      Text(

        title,

        style:
        const TextStyle(

          fontSize:11,

          color:
          Colors.grey,

        ),

      ),



      Text(

        value.isEmpty
            ?
        "-"
            :
        value,


        overflow:
        TextOverflow.ellipsis,


        style:
        const TextStyle(

          fontWeight:
          FontWeight.w600,

          fontSize:13,

        ),

      )



    ],

  );


}






// ================= FILTER SHEET =================


void showFilterSheet(){


  showModalBottomSheet(

    context:context,
    backgroundColor:Colors.white,

    isScrollControlled:true,


    shape:
    const RoundedRectangleBorder(

      borderRadius:
      BorderRadius.vertical(

        top:
        Radius.circular(20),

      ),

    ),



    builder:(context){


      return StatefulBuilder(

        builder:(context,setModalState){



          return Padding(

            padding:
            const EdgeInsets.all(16),


            child:
            SingleChildScrollView(


              child:
              Column(

                children:[



                  const Text(

                    "Product Filter",

                    style:
                    TextStyle(

                      fontSize:20,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),



                  const SizedBox(height:20),



                  filterDropdown(

                    "Product Group",

                    selectedGroup,

                    productGroups,

                        (v){

                      setModalState((){

                        selectedGroup=v;

                      });

                    },

                  ),



                  const SizedBox(height:12),



                  filterDropdown(

                    "Equipment",

                    selectedEqType,

                    eqTypes,

                        (v){

                      setModalState((){

                        selectedEqType=v;

                      });

                    },

                  ),




                  const SizedBox(height:12),



                  filterDropdown(

                    "DryMix Group",

                    selectedDryMixGroup,

                    dryMixGroups,

                        (v){

                      setModalState((){

                        selectedDryMixGroup=v;

                      });

                    },

                  ),




                  const SizedBox(height:12),



                  filterDropdown(

                    "DryMix Sub Group",

                    selectedDryMixSubGroup,

                    dryMixSubGroups,

                        (v){

                      setModalState((){

                        selectedDryMixSubGroup=v;

                      });

                    },

                  ),




                 


                  const SizedBox(height:12),

                  ElevatedButton(

                    style:
                    ElevatedButton.styleFrom(

                      backgroundColor:
                      const Color(0xff06275B),

                    ),


                    onPressed:(){

                      Navigator.pop(context);

                      applyFilter();

                    },


                    child:
                    const Text(

                      "APPLY",

                      style:
                      TextStyle(
                        color:Colors.white,
                      ),

                    ),

                  )



                ],

              ),

            ),

          );

        },

      );


    },

  );


}







Widget filterDropdown(

String label,

String? value,

List<String> items,

Function(String?) onChanged,

){


return DropdownSearch<String>(

  selectedItem: value,

  items: (filter, _) => items,

  onChanged: onChanged,

  compareFn: (a, b) => a == b,

  decoratorProps: DropDownDecoratorProps(
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),

  popupProps: PopupProps.menu(
    showSearchBox: true,
    searchFieldProps: TextFieldProps(
      decoration: InputDecoration(
        hintText: "Search $label",
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    emptyBuilder: (context, searchEntry) => const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text("No results found"),
      ),
    ),
  ),

  suffixProps: const DropdownSuffixProps(
    clearButtonProps: ClearButtonProps(
      isVisible: true,
    ),
  ),

);


}







// ================= DETAILS =================


void showProductDetails(
ProductModel item
){


showModalBottomSheet(

context:context,

isScrollControlled:true,


builder:(context){


return Padding(

padding:
const EdgeInsets.all(18),


child:
SingleChildScrollView(


child:
Column(

crossAxisAlignment:
CrossAxisAlignment.start,


children:[


Text(

item.productName,


style:
const TextStyle(

fontSize:20,

fontWeight:
FontWeight.bold,

color:
Color(0xff06275B),

),

),



const SizedBox(height:20),



detailRow(
"Business",
item.businessDiv
),


detailRow(
"Product Group",
item.productGroup
),


detailRow(
"Design",
item.design
),


detailRow(
"Color",
item.color
),


detailRow(
"Size",
item.thicknessOrSize
),


detailRow(
"Equipment",
item.eqType
),


detailRow(
"DryMix Group",
item.dmmGroup
),


detailRow(
"DryMix Sub Group",
item.dmmSubGroup
),


detailRow(
"Cement",
item.cementType
),


detailRow(
  "Weight",
  item.Weight
),  


detailRow(
"MRP",
"₹${item.mrp}"
),


],

),

),

);


},


);


}






Widget detailRow(
String title,
String value
){


return Padding(

padding:
const EdgeInsets.only(
bottom:12,
),


child:
Row(

children:[


SizedBox(

width:130,

child:
Text(

title,

style:
const TextStyle(

fontWeight:
FontWeight.bold,

),

),

),



Expanded(

child:
Text(value),

)



],

),

);


}

}
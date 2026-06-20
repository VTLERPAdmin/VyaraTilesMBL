import 'package:flutter/material.dart';
import '../models/dispatch_plan_filter_model.dart';
import '../services/api_services.dart';
import 'dart:async';
import '../screens/loader_service.dart';
import '../screens/dispatchplan_detail_screen.dart';
class DispatchPlanScreen extends StatefulWidget { 
    final String userId;

        
    const DispatchPlanScreen({
    super.key,
    required this.userId,
    
  });

  @override
  State<DispatchPlanScreen> createState() => _DispatchPlanScreenState();
  
}


class _DispatchPlanScreenState extends State<DispatchPlanScreen> {
  int? selectedIndex;

  final TextEditingController soPoController = TextEditingController();

FactoryModel? selectedFactory;
MktPersonModel? selectedMktPerson;
ClientModel? selectedClient;
SiteModel? selectedSite;
ProductModel? selectedProduct;
String? selectedClientGroup;

List<DispatchPlanRowModel> allRecords = [];
List<DispatchPlanRowModel> records = [];
bool isLoading = false;
   
DispatchPlanModel? filterData;
bool isFilterLoading = false;


   @override

@override
void initState() {
  super.initState();
  loadData();
}

Future<void> loadData() async {
  // Overlay.of(...).insert(...) cannot run while Flutter is still building
  // the current frame (which is the case here, since loadData() is called
  // from initState()). We wait for the frame to finish using a Completer
  // tied to addPostFrameCallback, THEN start the actual fetch — so show()
  // is guaranteed to succeed before any network call begins, and hide()
  // in finally always matches a loader that's actually on screen.
  if (!mounted) return;

  final frameDone = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!frameDone.isCompleted) frameDone.complete();
  });
  await frameDone.future;

  if (!mounted) return;

  LoaderService.show(
    context,
    title: "Loading Dispatch Plan",
    subtitle: "Fetching data from server...",
  );

  try {
    final data = await ApiService.getDispatchPlanList(widget.userId);

    if (!mounted) return;

    setState(() {
      allRecords = data;
      records = data;
      filterData = _buildFiltersFromRecords(data);
    });
  } catch (e) {
    debugPrint("LOAD ERROR: $e");
  } finally {
    LoaderService.hide();
  }
}

// Derives filter dropdown data (factories, marketing persons, client
// groups, clients + their sites, products) directly from the dispatch
// plan list itself. Replaces the old getDispatchPlanFilters() call, which
// hit the same DPlanData endpoint as the list and got back list-shaped
// JSON (no Factories/MktPersons/Clients/Products keys), causing
// DispatchPlanModel.fromJson() to fail silently and hang the loader.
DispatchPlanModel _buildFiltersFromRecords(List<DispatchPlanRowModel> data) {
  final factoryNames = <String>{};
  final factories = <FactoryModel>[];
  for (final row in data) {
    if (row.factory.isNotEmpty && factoryNames.add(row.factory)) {
      factories.add(FactoryModel(id: factories.length + 1, name: row.factory));
    }
  }

  final mktNames = <String>{};
  final mktPersons = <MktPersonModel>[];
  for (final row in data) {
    if (row.mktPerson.isNotEmpty && mktNames.add(row.mktPerson)) {
      mktPersons.add(MktPersonModel(id: mktPersons.length + 1, name: row.mktPerson));
    }
  }

  final clientGroups = <String>{};
  for (final row in data) {
    if (row.clientGroup.isNotEmpty) {
      clientGroups.add(row.clientGroup);
    }
  }

  final mktIdByName = <String, int>{
    for (final m in mktPersons) m.name: m.id,
  };

  final clientOrder = <String>[];
  final clientGroupByName = <String, String>{};
  final clientMktNameByName = <String, String>{};
  final clientSites = <String, Set<String>>{};

  for (final row in data) {
    if (row.client.isEmpty) continue;

    if (!clientSites.containsKey(row.client)) {
      clientOrder.add(row.client);
      clientGroupByName[row.client] = row.clientGroup;
      clientMktNameByName[row.client] = row.mktPerson;
      clientSites[row.client] = {};
    }

    if (row.site.isNotEmpty) {
      clientSites[row.client]!.add(row.site);
    }
  }

  final clients = <ClientModel>[];
  for (int i = 0; i < clientOrder.length; i++) {
    final name = clientOrder[i];
    final sites = clientSites[name]!
        .map((siteName) => SiteModel(siteId: 0, siteName: siteName))
        .toList();

    clients.add(ClientModel(
      id: i + 1,
      name: name,
      clientGroup: clientGroupByName[name] ?? "",
      mktPersonId: mktIdByName[clientMktNameByName[name]] ?? 0,
      sites: sites,
    ));
  }

  final productNames = <String>{};
  final products = <ProductModel>[];
  for (final row in data) {
    if (row.product.isNotEmpty && productNames.add(row.product)) {
      products.add(ProductModel(id: products.length + 1, productName: row.product));
    }
  }

  return DispatchPlanModel(
    factories: factories,
    mktPersons: mktPersons,
    clientGroups: clientGroups.toList(),
    clients: clients,
    products: products,
  );
}

Future<void> fetchDispatchPlans() async {
  setState(() => isLoading = true);

  try {
    final data = await ApiService.getDispatchPlanList(widget.userId);

    setState(() {
      allRecords = data;
      records = data;
      isLoading = false;
    });
  } catch (e) {
    setState(() => isLoading = false);
    debugPrint("ERROR: $e");
  }
}

Future<void> fetchFilters() async {
  // NOTE: filters are now derived locally from allRecords via
  // _buildFiltersFromRecords(), not fetched from a separate endpoint —
  // DPlanData only returns the list, not filter-shaped data.
  setState(() {
    filterData = _buildFiltersFromRecords(allRecords);
  });
}
Future<void> fetchPlans() async {
  setState(() => isLoading = true);

  final data = await ApiService.getDispatchPlanList(
    widget.userId,
  );

  setState(() {
    allRecords = data;
    isLoading = false;
  });
}
List<ClientModel> get filteredClients {
  if (filterData == null) return [];

  return filterData!.clients.where((client) {
    bool groupMatch =
        selectedClientGroup == null ||
        selectedClientGroup!.isEmpty ||
        client.clientGroup == selectedClientGroup;

    bool mktMatch =
        selectedMktPerson == null ||
        client.mktPersonId == selectedMktPerson!.id;

    return groupMatch && mktMatch;
  }).toList();
}
void applyLocalFilter() {
  List<DispatchPlanRowModel> temp = List.from(allRecords);

  if (selectedFactory != null && selectedFactory!.name != "All") {
    temp = temp.where((e) => e.factory == selectedFactory!.name).toList();
  }

  if (selectedMktPerson != null&& selectedMktPerson!.name != "All") {
    temp = temp.where((e) => e.mktPerson == selectedMktPerson!.name).toList();
  }

  if (selectedClientGroup != null && selectedClientGroup!.isNotEmpty&& selectedClientGroup != "All") {
    temp = temp.where((e) => e.clientGroup == selectedClientGroup).toList();
  }

  if (selectedClient != null&& selectedClient!.name != "All") {
    temp = temp.where((e) => e.client == selectedClient!.name).toList();
  }

  if (selectedSite != null) {
    temp = temp.where((e) => e.site == selectedSite!.siteName).toList();
  }

  if (selectedProduct != null&& selectedProduct!.productName != "All") {
    temp = temp.where((e) => e.product == selectedProduct!.productName).toList();
  }

  final searchText = soPoController.text.trim();
  if (searchText.isNotEmpty) {
    temp = temp.where((e) => e.soNo.contains(searchText)||e.poNo.toLowerCase().contains(searchText)).toList();
  }

  setState(() {
    records = temp;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F3F7),

      appBar: AppBar(
        backgroundColor: const Color(0xff06275B),
        foregroundColor: Colors.white,
        title: const Text("Dispatch Planning"),
        centerTitle: false,
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff06275B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
          onPressed: selectedIndex == null
    ? null
    : () {
        final selected = records[selectedIndex!];

        print("SOLocID => ${selected.solocId}");
      print("SOID => ${selected.soId}");
      print("SOSrNo => ${selected.soSrNo}");

       if (selected.solocId == 0 ||
            selected.soId == 0 ||
            selected.soSrNo == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Invalid composite key received from API",
              ),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DispatchPlanedScreen(
              soId: selected.soId,
              soSrNo: selected.soSrNo,
              solocId: selected.solocId,
              userId: widget.userId,
            ),
          ),
        );
      },
        child: const Text(
          "NEXT",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
                 
            ),
          ),
        ),
      ),

      body: isLoading
    ? const Center(
        child: CircularProgressIndicator(),
      ) 
      
      
       : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildFilters(),

                  const SizedBox(height: 15),


                  const SizedBox(height: 20),

                  _buildHeader(),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),

                    child: records.isEmpty
                  ? SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          "No data matching your filters",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
   
                   :ListView.separated(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: records.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = records[index];

                        return SizedBox(
                          height: 55,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 45,
                                child: Radio<int>(
                                  value: index,
                                  groupValue: selectedIndex,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedIndex = value;
                                    });
                                  },
                                ),
                              ),

                              

                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.soNo,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),

                              Expanded(
                                flex: 6,
                                child: Text(
                                  item.product,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),

                              SizedBox(
                                width: 45,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                     _showDetailsFromModel(item);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildFilters() {
  return Column(
    children: [
      // ================= FACTORY =================
      _dropdown(
        "Factory",
        selectedFactory?.name,
      [
    "All", // 👈 NEW RESET OPTION
    ...?filterData?.factories.map((e) => e.name).toList(),
  ],
        (v) {
          setState(() {
            selectedFactory = filterData!.factories
                .firstWhere((e) => e.name == v);

            // RESET DEPENDENTS
            selectedMktPerson = null;
            selectedClientGroup = null;
            selectedClient = null;
            selectedSite = null;
            selectedProduct = null;
          });

           applyLocalFilter();
        },
      ),

      const SizedBox(height: 12),

      // ================= MARKETING PERSON =================
      _dropdown(
        "Marketing Person",
        selectedMktPerson?.name,
      [
        "All",
        ...?filterData?.mktPersons.map((e) => e.name),
      ],
              (v) {
          setState(() {
            selectedMktPerson = filterData!.mktPersons
                .firstWhere((e) => e.name == v);

            // RESET DEPENDENTS
            selectedClientGroup = null;
            selectedClient = null;
            selectedSite = null;
            selectedProduct = null;
          });

           applyLocalFilter();
        },
      ),

      const SizedBox(height: 12),

      // ================= SO / PO =================
      TextFormField(
  controller: soPoController,
  decoration: InputDecoration(
    labelText: "SO / PO No",
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
    ),
  ),
  onChanged: (value) {
     applyLocalFilter();
  },
),
      const SizedBox(height: 12),

      // ================= CLIENT GROUP =================
      _dropdown(
        "Client Group",
        selectedClientGroup,
         [
        "All",
        ...?filterData?.clientGroups,
         ],
        (v) {
          setState(() {
            selectedClientGroup = v;

            // RESET DEPENDENTS
            selectedClient = null;
            selectedSite = null;
            selectedProduct = null;
          });

            applyLocalFilter();
        },
      ),

      const SizedBox(height: 12),

      // ================= CLIENT =================
    _dropdown(
        "Client",
        selectedClient?.name,
       [
        "All",
        ...?filterData?.clients.map((e) => e.name),
      ],
        (v) {
          setState(() {
            selectedClient = filteredClients.firstWhere(
              (e) => e.name == v,
            );

            selectedSite = null;
            selectedProduct = null;
          });

          applyLocalFilter();
        },
),

      const SizedBox(height: 12),

      // ================= SITE =================
            _dropdown(
        "Site",
        selectedSite?.siteName,
        selectedClient?.sites
                .map((e) => e.siteName)
                .toList() ??
            [],
        (v) {
          setState(() {
            selectedSite = selectedClient!.sites.firstWhere(
              (e) => e.siteName == v,
            );

            selectedProduct = null;
          });

           applyLocalFilter();
        },
),

      const SizedBox(height: 12),

      // ================= PRODUCT =================
      _dropdown(
        "Product",
        selectedProduct?.productName,
       [
        "All",
        ...?filterData?.products.map((e) => e.productName),
      ],
        (v) {
          setState(() {
            selectedProduct = filterData!.products
                .firstWhere((e) => e.productName == v);
          });

           applyLocalFilter();
        },
      ),
    ],
  );
}

  Widget _dropdown(
  String label,
  String? value,
  List<String> items,
  Function(String?) onChanged,
) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
            suffixIcon: value != null && value != "All"
          ? IconButton(
              icon: const Icon(Icons.clear),
             onPressed: () {
    setState(() {
      selectedFactory = null;

      selectedMktPerson = null;
      selectedClientGroup = null;
      selectedClient = null;
      selectedSite = null;
      selectedProduct = null;
    });

    applyLocalFilter(); // reset to all
              },
            )
          : null,

          contentPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.03,
            vertical: MediaQuery.of(context).size.height * 0.015,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      );
    },
  );
}
  Widget _buildHeader() {
    return Container(
      height: 45,
      color: const Color(0xff06275B),
      child: const Row(
       children: [
  const SizedBox(width: 45),

  Expanded(
    flex: 2,
    child: Text(
      "SO No",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  Expanded(
    flex: 3,
    child: Text(
      "Product",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    ),
  ),

  const SizedBox(width: 45),
],
      ),
    );
  }

void _showDetailsFromModel(DispatchPlanRowModel item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
            
                const Text(
                  "Dispatch Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 2, 11, 59),
                  ),
                ),

                Text(
            item.site,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),

                const SizedBox(height: 20),                
                _detail("Site Name", item.site),
                _detail("PO No", item.poNo),
                _detail("Product", item.product),
                _detail("Grade", item.grade),
                _detail("Finish", item.finish),
                _detail("Lot No", item.lotNo),
                _detail("Unit", item.unit),
                _detail("Order Qty", item.orderQty),
                _detail("Pending Qty", item.pendingQty),
                _detail("Plan Qty", item.planQty),
                _detail("Factory", item.factory),
              ],
            ),
          ),
        ),
      );
    },
  );
}
  

  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
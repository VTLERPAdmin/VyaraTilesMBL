import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/dispatch_plan_detail_model.dart';
// import '../screens/loader_service.dart';

class DispatchPlanedScreen extends StatefulWidget {
  final int soId;
  final int soSrNo;
  final String userId;
  final int solocId;

  const DispatchPlanedScreen({
    super.key,
    required this.soId,
    required this.soSrNo,
    required this.userId,
    required this.solocId,
  });

  @override
  State<DispatchPlanedScreen> createState() => _DispatchPlaneScreenState();
}

class _DispatchPlaneScreenState extends State<DispatchPlanedScreen> {
  bool isLoading = false;
  bool isEditing = false;

  String selectedPlanType = "A";

  String originalDate = "";
  String originalType = "A";
  String originalAddLess = "0.0";

  final dateController = TextEditingController();
  final addLessController = TextEditingController(text: "0.0");

  static const primaryBlue = Color(0xff06275B);
  static const dispatchGrey = Color(0xFFE9EDF2);

  DispatchPlanDetailModel? model;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

Future<void> _pickDate() async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  if (picked != null) {
    setState(() {
      dateController.text = picked.toString().split(" ").first;
    });
  }
}



Future<void> savePlan() async {
  try {
    final url = Uri.parse("https://vyaratiles.co.in/Api/Dplan");

    final body = {
      "UserID": widget.userId,
      "PlanID": 0,
      "PlanDate": dateController.text,
      "PlanType": selectedPlanType,
      "PlannedQty": model?.ordQty ?? 0,
      "SaleQty": model?.saleQty ?? 0,
      "PendingPlanQty": model?.pendSaleQty ?? 0,
      "AddLessQty": double.tryParse(addLessController.text) ?? 0,
      "NetPlanQty": (model?.ordQty ?? 0) - (model?.saleQty ?? 0),
      "TotalPlanQty": model?.ordQty ?? 0,

      "StatusCode": 200,
      "Message": "OK",

      "PendSaleQty": model?.pendSaleQty ?? 0,
      "StockQty": model?.stockQty ?? 0,
      "Grade": model?.grade ?? "",
      "Finish": model?.finish ?? "",
      "MaxPlanQty": model?.maxPlanQty ?? 0,

      "DispatchLocID": model?.DispatchLocID ??0,
      "PlanLocID": widget.solocId,
      "SOLocID": widget.solocId,
      "SOID": widget.soId,
      "SOSrNo": widget.soSrNo,

      "UoMCode": model?.uom ?? "",
      "Rate": model?.rate ?? 0,

      "ClientID": model?.clientId ?? 0,
      "ClientName": model?.clientName ?? "",
      "SiteID": model?.siteId ?? 0,
      "SiteName": model?.siteName ?? "",
      "ProductID": model?.productId ?? 0,
      "ProductName": model?.productName ?? "",
      "MktPersonID": 0,
        
       "CreditLimit": model?.CreditLimit ??0,
       "BalAmt": model?.BalAmt ??0, 
      "OrdQty": model?.ordQty ?? 0,
      "AvailableBal": model?.availableBal ?? 0,
    };

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);

    if (data["StatusCode"] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plan Saved Successfully")),
      );

      setState(() {
        isEditing = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["Message"] ?? "Save Failed")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}


  Future<void> fetchData() async {
   /*  LoaderService.show(
    context,
    title: "Loading Details",
    subtitle: "Fetching dispatch data...",
     ); */

    try {
      final uri = Uri.parse(
        "https://vyaratiles.co.in/Api/DPlanSO",
      ).replace(queryParameters: {
        "UserID": widget.userId,
        "SOLocID": widget.solocId.toString(),
        "SOID": widget.soId.toString(),
        "SOSrNo": widget.soSrNo.toString(),
      });

      final res = await http.get(uri);
      final decoded = jsonDecode(res.body);

      if (decoded["StatusCode"] != 200) {
        setState(() => isLoading = false);
        return;
      }

      model = DispatchPlanDetailModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );

      dateController.text = DateTime.now().toString().split(" ").first;
      selectedPlanType = "A";
      addLessController.text = "0.0";

      originalDate = dateController.text;
      originalType = selectedPlanType;
      originalAddLess = addLessController.text;
    } catch (e) {
      debugPrint("ERROR: $e");
    }/*finally {
    LoaderService.hide();
  } */

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      appBar: AppBar(
        backgroundColor: Color(0xff06275B),
        foregroundColor: Colors.white,
        title: const Text("Dispatch Planning"),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.03,
          vertical: h * 0.015,
        ),
        child: Column(
          children: [
            _dispatchCard(w),
            SizedBox(height: h * 0.015),
            _planningCard(w),
            SizedBox(height: h * 0.015),
            _summaryCard(w),
          ],
        ),
      ),
    );
  }

  // ================= DISPATCH =================
  Widget _dispatchCard(double w) {
    return Card(
      elevation: 0,
      color: dispatchGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          _header("Dispatch Details"),
          Padding(
            padding: EdgeInsets.all(w * 0.03),
            child: Column(
              children: [
                _box("Client", model?.clientName),
                _gap(),
                _box("Site", model?.siteName),
                _gap(),
                _box("Product", model?.productName),

                _gap(),

                // ERP STYLE 3 GRID
                Row(
                  children: [
                    Expanded(child: _mini("Grade", model?.grade)),
                    _sp(),
                    Expanded(child: _mini("Finish", model?.finish)),
                    _sp(),
                    Expanded(child: _mini("Lot No.", model?.lotNo)),
                  ],
                ),

                _gap(),

                Row(
                  children: [
                    Expanded(child: _mini("UOM", model?.uom ?? "-")),
                    const SizedBox(width: 10),
                    Expanded(child: _mini("Rate", model?.rate.toString())),
                   // _sp(),
                    //Expanded(child: _mini("Credit", model?.availableBal.toString())),
                  ],
                ),                

                _gap(),

                Row(
                  children: [
                    Expanded(child: _mini("Order Qty", model?.ordQty.toString())),
                    _sp(),
                    Expanded(child: _mini("Pending Qty", model?.pendSaleQty.toString())),
                  ],
                ),

                _gap(),

                Row(
                  children: [
                    Expanded(child: _mini("Credit Limit", model?.CreditLimit.toString())),
                    const SizedBox(width: 10),
                    Expanded(child: _mini("Current Bal", model?.BalAmt.toString())),
                    
                  ],
                ),

                _gap(),

                Row(
                  children: [                  
                    
                    Expanded(child: _mini("Avail. Bal", model?.availableBal.toString())),
                    _sp(),
                    Expanded(child: _mini("Max Qty", model?.maxPlanQty.toString() ?? "0")),
                    
                  ],
                ),



              ],
            ),
          )
        ],
      ),
    );
  }

  // ================= PLANNING =================
  Widget _planningCard(double w) {
    return Card(
      elevation: 0,
      color: dispatchGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(w * 0.03),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Planning Details",
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xff06275B)),
                  ),
                ),
                if (!isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xff06275B)),
                    onPressed: () => setState(() => isEditing = true),
                  )
              ],
            ),

            const Divider(),

             const SizedBox(height: 10),

          // ================= DATE =================
          isEditing
              ? TextField(
                  controller: dateController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: "Date",
                    border: OutlineInputBorder(),
                  ),
                )
              : _box("Date", dateController.text),

          const SizedBox(height: 10),

          // ================= TYPE =================
          isEditing
              ? DropdownButtonFormField<String>(
                  value: selectedPlanType,
                  items: const [
                    DropdownMenuItem(value: "A", child: Text("A")),
                    DropdownMenuItem(value: "B", child: Text("B")),
                    DropdownMenuItem(value: "C", child: Text("C")),
                    DropdownMenuItem(value: "D", child: Text("D")),
                  ],
                  onChanged: (v) =>
                      setState(() => selectedPlanType = v ?? "A"),
                  decoration: const InputDecoration(
                    labelText: "Plan Type",
                    border: OutlineInputBorder(),
                  ),
                )
              : _box("Plan Type", selectedPlanType),

          const SizedBox(height: 10),

          // ================= ADD / LESS =================
          isEditing
              ? TextField(
                  controller: addLessController,
                  keyboardType: TextInputType.number,
                   onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: "Add / Less",
                    border: OutlineInputBorder(),
                  ),
                )
              : _box("Add/Less", addLessController.text),

          const SizedBox(height: 12),

            
           /* Row(
              children: [
                Expanded(child: _mini("Org", model?.ordQty.toString())),
                _sp(),
                Expanded(child: _mini("Sale", model?.saleQty.toString())),
              ],
            ),

            _gap(),

            Row(
              children: [
                Expanded(
                  child: _mini(
                    "Curr Plan",
                    ((model?.ordQty ?? 0) - (model?.saleQty ?? 0)).toString(),
                  ),
                ),
                _sp(),
                Expanded(
                    child: _mini("Total", model?.ordQty.toString())),
              ],
            ), */

            _gap(),

            if (isEditing)
              Row(
  children: [
    Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            isEditing = false;
            dateController.text = originalDate;
            selectedPlanType = originalType;
            addLessController.text = originalAddLess;
          });
        },
        child: const Text(
          "CANCEL",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff06275B),
        ),
        onPressed: () {
          setState(() {
            isEditing = false;
          });
        },
        child: const Text(
          "SAVE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ],
)
          ],
        ),
      ),
    );
  }

  // ================= SUMMARY =================
 Widget _summaryCard(double w) {
  return Card(
    elevation: 0,
    color: dispatchGrey,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(
      padding: EdgeInsets.all(w * 0.03),
      child: Column(
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xff06275B),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: const Text(
              "Summary",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 10),

         /* Row(
            children: [
              
              const SizedBox(width: 10),
              Expanded(child: _mini("Planned", model?.ordQty.toString() ?? "0")),
            ],
          ), */

          const SizedBox(height: 10),

         Row(
  children: [
    Expanded(
      child: _mini(
        "Planned Amt.",
        (
          (double.tryParse(addLessController.text) ?? 0.0) *
          (model?.rate ?? 0.0)
        ).toStringAsFixed(2),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _mini(
        "Bal Amt.",
        (
          (model?.availableBal ?? 0.0) -
          ((double.tryParse(addLessController.text) ?? 0.0) *
           (model?.rate ?? 0.0))
        ).toStringAsFixed(2),
      ),
    ),
  ],
),
          const SizedBox(height: 16),

          /// BUTTONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    print("CANCEL CLICKED");
                  },
                  child: const Text(
                    "CANCEL",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                  ),
                  onPressed: () {
                    print("PLAN SAVED SUCCESFULLY ");
                    savePlan();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("PLAN SAVED SUCCESFULLY")),
                    );
                  },
                  child: const Text(
                    "SAVE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  // ================= WIDGETS =================
  Widget _header(String t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xff06275B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      );

  Widget _box(String k, String? v) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text("$k : ${v?.isNotEmpty == true ? v : "-"}"),
      );

 Widget _mini(String k, String? v) => Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: const Color(0xff06275B), // ERP dark blue tile
    borderRadius: BorderRadius.circular(10),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        k,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        (v == null || v.isEmpty || v == "null") ? "-" : v,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
);
  Widget _gap() => const SizedBox(height: 10);
  Widget _sp() => const SizedBox(width: 10);
}
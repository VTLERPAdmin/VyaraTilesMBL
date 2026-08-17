// ===============================
// FILE: api_services.dart
// ===============================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vyara_erp/models/sample_request_models.dart';
import '../models/so_status_model.dart' hide ProductModel;
import '../models/work_order_status_model.dart' hide ProductModel;
import '../models/ledger_model.dart';
import '../models/so_approval_model.dart';
import '../models/so_acknowledgement_model.dart';
import '../models/ev_model.dart';
import '../config/app_config.dart';
import '../models/dispatch_plan_filter_model.dart' hide ProductModel;
import '../models/ev_detail_model.dart';
import '../models/product_model.dart';



class ApiService {
  static const String baseUrl = "https://vyaratiles.co.in/API/";

  // LOGIN
 static Future<Map<String, dynamic>> login(
  String userId,
  String password,
) async {
  try {
    final Uri url = Uri.parse("${baseUrl}ERPAuth").replace(
      queryParameters: {
        "UserID": userId.trim(),
        "UserPwd": password.trim(),
        "VerNo": AppConfig.verNo.toString(),
      },
    );

    final response = await http.get(url);

    print("LOGIN RESPONSE => ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // ✅ FIX HERE
    } else {
      throw Exception("Login failed: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Login Error: $e");
  }
}

  // =========================
  // GET SO FILTERS
  // =========================

static Future<SoStatusModel> getSOFilters(
  String userId,
  String userPwd,
  String token,
) async {

  try {

    final url =
        "${baseUrl}SOStatusFilter"
        "?UserID=${Uri.encodeComponent(userId)}"
        "&UserPwd=${Uri.encodeComponent(userPwd)}"
        "&VerNo=${AppConfig.verNo}"
        "&Token=$token";

    print("================================");
    print("SO FILTER API");
    print("URL => $url");

    final response = await http.get(
      Uri.parse(url),
    );

    print("STATUS CODE => ${response.statusCode}");

    print("RESPONSE =>");
    print(response.body);

    print("================================");

    if (response.statusCode == 200) {

      final Map<String, dynamic> data =
          jsonDecode(response.body);

      return SoStatusModel.fromJson(data);

    } else {

      throw Exception(
        "HTTP ${response.statusCode}\n${response.body}",
      );
    }

  } catch (e) {

    print("SO FILTER ERROR => $e");

    throw Exception(
      "SO FILTER ERROR : $e",
    );
  }
}

// =========================
// POST SO STATUS REPORT
// =========================
static Future<String> getSOStatusReport({
  required String userId,
  required String userPwd,
  required String token,
  required Map<String, dynamic> body,
}) async {
  print("🔵 USERID: $userId");
  print("🔵 TOKEN: $token");
  print("🔵 BODY: $body");

  try {

    final url = "${baseUrl}SOStatus";

    // ADD USER INTO BODY
    body["UserID"] = userId;
    body["UserPwd"] = userPwd;
    body["VerNo"] = AppConfig.verNo;
    body["Token"] = token;

    print("================================");
    print("SO STATUS API");
    print("URL => $url");

    print("BODY =>");
    print(jsonEncode(body));

    final response = await http.post(
      Uri.parse(url),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode(body),
    );

    print("STATUS CODE => ${response.statusCode}");

    print("RESPONSE =>");
    print(response.body);

    print("================================");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data["StatusCode"] == 200) {

      return data["Message"] ?? "";

    } else {
      
      final message = (data["Message"] ?? "").toString();

if (message.contains("No data to display report")) {
  throw Exception("No Record Found");
}

throw Exception(
  message.isEmpty ? "Unknown Error" : message,
);

    }

  } catch (e) {

    print("SO STATUS ERROR => $e");

    throw Exception(
      "SO STATUS ERROR : $e",
    );
  }
}

// =========================
// LEDGER FILTERS
// =========================


static Future<LedgerFilterModel> getLedgerFilters(
  String userId,
  String userpwd,
  int verno,
) async {

  try {

    print("LEDGER USER ID => $userId");
    print("LEDGER PASSWORD LENGTH => ${userpwd.length}");
    print("LEDGER VERNO => $verno");

    final url =
        "${baseUrl}LedgerFilter?UserID=${Uri.encodeComponent(userId)}"
        "&UserPwd=${Uri.encodeComponent(userpwd)}"
        "&VerNo=${verno}";

    print("LEDGER FILTER API CALLED");

    final response = await http.get(
      Uri.parse(url),
    );

    print("LEDGER FILTER RESPONSE => ${response.body}");

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return LedgerFilterModel.fromJson(data);

    } else {

      throw Exception(
        "HTTP ${response.statusCode}",
      );
    }

  } catch (e) {

    throw Exception(
      "LEDGER FILTER ERROR : $e",
    );
  }
}





// =========================
// LEDGER REPORT
// =========================
static Future getLedgerReport({
  required String clientIds,
  required String fromDate,
  required String toDate,
  required bool mergeClients,
  required bool grandTotal,
  required String userId,
  required String userPwd,
}) async {
  try {
    final url = Uri.parse("${baseUrl}Ledger");

    final body = {
      "ClientID": clientIds,
      "FromDate": fromDate,
      "ToDate": toDate,
      "MergeClients": mergeClients,
      "GrandTotal": grandTotal,
      "UserID": userId,
      "UserPwd": userPwd,
      "VerNo": AppConfig.verNo,
    };

    print("================================");
    print("LEDGER REPORT API");
    print("URL => $url");
    print("BODY => ${jsonEncode(body)}");
    print("================================");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(body),
    );

    print("LEDGER STATUS => ${response.statusCode}");
    print("LEDGER RESPONSE => ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data["StatusCode"] == 200) {
      return data["Message"] ?? "";
    }

    final message = (data["Message"] ?? "Failed").toString();

    throw Exception(message);
  } catch (e) {
    print("LEDGER REPORT ERROR => $e");

    throw Exception(
      "LEDGER REPORT ERROR : $e",
    );
  }
}


// ================== Pdf API =======================

static Future<String> getSOPrint(
  String userId,
  String userPwd,
  int locId,
  int soId,
) async {
  try {

    final url =
        "${baseUrl}SOPrint?"
        "UserID=$userId"
        "&UserPwd=${Uri.encodeComponent(userPwd)}"
        "&VerNo=${AppConfig.verNo}"
        "&LocID=$locId"
        "&SOID=$soId";

    final response = await http.get(
      Uri.parse(url),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data["StatusCode"] == 200) {

      String pdf =
          data["PDFPath"] ?? "";

      pdf = pdf.replaceAll("//https://", "https://");

      return pdf;
    }

    throw Exception(
      data["Message"] ?? "Failed",
    );
  } catch (e) {
    throw Exception(
      "SO PRINT ERROR : $e",
    );
  }
}

// =========================
// SO PDF
// =========================

static Future<String> getSOPdf({
  required String userId,
  required String userPwd,
  required int locId,
  required int soId,
}) async {

  try {

    final url =
        "${baseUrl}SOPrint"
        "?UserID=${Uri.encodeComponent(userId)}"
        "&UserPwd=${Uri.encodeComponent(userPwd)}"
        "&VerNo=${AppConfig.verNo}"
        "&LocID=$locId"
        "&SOID=$soId";

    print("SO PDF URL => $url");

    final response = await http.get(
      Uri.parse(url),
    );

    print(response.body);

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data["StatusCode"] == 200) {

      return data["PDFPath"] ?? "";

    } else {

      throw Exception(
        data["Message"] ?? "Failed",
      );
    }

  } catch (e) {

    throw Exception(
      "SO PDF ERROR : $e",
    );
  }
}



// ===============================
// SO APPROVAL LIST (FINAL)
// ===============================

static Future<List<SOApprovalModel>> getSOApprovalList({
  required String userId,
  required String userPwd,
}) async {
  try {
    final url =
        "https://vyaratiles.co.in/API/SOApprList"
        "?UserID=$userId"
        "&UserPwd=${Uri.encodeComponent(userPwd)}"
        "&VerNo=${AppConfig.verNo}";

    print("SO APPROVAL URL => $url");

    final response = await http.get(Uri.parse(url));

    print("SO APPROVAL RESPONSE => ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["StatusCode"] == 200) {
      final List list = data["SOList"] ?? [];

      return list
          .map((e) => SOApprovalModel.fromJson(e))
          .toList();
    }

    throw Exception(data["Message"] ?? "Failed to load SO list");
  } catch (e) {
    throw Exception("SO APPROVAL ERROR: $e");
  }
}
// =========================
// SO APPROVAL POST (NEW)
// =========================
static Future<String> approveSO({
  required String userId,
  required String userPwd,
  required int locId,
  required int soId,
  required String notes,
}) async {
  try {
    final url = "${baseUrl}SOAppr";

    final body = {
      "UserID": userId,
      "UserPwd": userPwd,
      "VerNo": AppConfig.verNo,
      "LocID": locId,
      "SOID": soId,
      "Notes": notes,
    };

    print("SO APPROVE REQUEST => $body");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("SO APPROVE RESPONSE => ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["StatusCode"] == 200) {
      return data["Message"] ?? "Approved Successfully";
    }

    throw Exception(data["Message"] ?? "Approval Failed");
  } catch (e) {
    throw Exception("SO APPROVAL ERROR: $e");
  }
}

// =========================
// SO ACKNOWLEDGE LIST (with new model)
// =========================
static Future<List<SOAcknowledgementModel>> getSOAcknowledgementList({
  required String userId,
  required String userPwd,
}) async {
  try {
    final url =
        "https://vyaratiles.co.in/API/SOAckList"
        "?UserID=$userId"
        "&UserPwd=${Uri.encodeComponent(userPwd)}"
        "&VerNo=${AppConfig.verNo}";

    print("================================");
    print("📋 SO ACKNOWLEDGEMENT LIST REQUEST");
    print("URL => $url");
    print("UserID => $userId");
    print("================================");

    final response = await http.get(Uri.parse(url));

    print("SO ACKNOWLEDGEMENT RESPONSE STATUS => ${response.statusCode}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["StatusCode"] == 200) {
      final List list = data["SOList"] ?? [];
      print("📊 Total SOs received: ${list.length}");
      return list.map((e) => SOAcknowledgementModel.fromJson(e)).toList();
    }

    throw Exception(data["Message"] ?? "Failed to load SO acknowledgement list");
  } catch (e) {
    print("❌ SO ACKNOWLEDGEMENT ERROR => $e");
    throw Exception("SO ACKNOWLEDGEMENT ERROR: $e");
  }
}

// =========================
// SO ACKNOWLEDGE LIST (Legacy - deprecated)
// =========================
static Future<List<SOApprovalModel>> getSOAcknowledgeList({
  required String userId,
  required String userPwd,
}) async {
  try {
    final url =
        "https://vyaratiles.co.in/API/SOAckList"
        "?UserID=$userId"
        "&UserPwd=${Uri.encodeComponent(userPwd)}"
        "&VerNo=${AppConfig.verNo}";

    print("SO ACKNOWLEDGE URL => $url");

    final response = await http.get(Uri.parse(url));

    print("SO ACKNOWLEDGE RESPONSE => ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["StatusCode"] == 200) {
      final List list = data["SOList"] ?? [];
      return list.map((e) => SOApprovalModel.fromJson(e)).toList();
    }

    throw Exception(data["Message"] ?? "Failed to load SO acknowledgement list");
  } catch (e) {
    throw Exception("SO ACKNOWLEDGE ERROR: $e");
  }
}

// =========================
// SO ACKNOWLEDGE POST
// =========================
static Future<String> acknowledgeSO({
  required String userId,
  required String userPwd,
  required int locId,
  required int soId,
  required String notes,
}) async {
  try {
    final url = "${baseUrl}SOAck";

    final body = {
      "UserID": userId,
      "UserPwd": userPwd,
      "VerNo": AppConfig.verNo,
      "LocID": locId,
      "SOID": soId,
      "Notes": notes,
    };

    print("================================");
    print("🚀 SO ACKNOWLEDGE REQUEST");
    print("URL => $url");
    print("BODY => ${jsonEncode(body)}");
    print("Raw Values:");
    print("  UserID: $userId");
    print("  LocID: $locId");
    print("  SOID: $soId");
    print("  Notes: $notes");
    print("================================");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("SO ACKNOWLEDGE RESPONSE => ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["StatusCode"] == 200) {
      return data["Message"] ?? "Acknowledged Successfully";
    }

    throw Exception(data["Message"] ?? "Acknowledgement Failed");
  } catch (e) {
    throw Exception("SO ACKNOWLEDGE ERROR: $e");
  }
}

// =========================
// WORK ORDER FILTERS
// =========================
static Future<WorkOrderStatusModel> getWOFilters(
  String userId,
  String userPwd,
  String token,
) async {
  try {
    final url =
        "${baseUrl}WOStatusFilter"
        "?UserID=${Uri.encodeComponent(userId)}"
        "&UserPwd=${Uri.encodeComponent(userPwd)}"
        "&VerNo=${AppConfig.verNo}"
        "&Token=$token";

    print("================================");
    print("WO FILTER API");
    print("URL => $url");

    final response = await http.get(
      Uri.parse(url),
    );

    print("STATUS CODE => ${response.statusCode}");
    print("RESPONSE =>");
    print(response.body);
    print("================================");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return WorkOrderStatusModel.fromJson(data);
    } else {
      throw Exception(
        "HTTP ${response.statusCode}\n${response.body}",
      );
    }
  } catch (e) {
    print("WO FILTER ERROR => $e");
    throw Exception(
      "WO FILTER ERROR : $e",
    );
  }
}

// =========================
static Future<List<WorkOrderStatusModel>> getWorkOrderList({
  required String userId,
  required String userPwd,
}) async {
  try {
    final url =
        "https://vyaratiles.co.in/API/WOStatusFilter"
        "?UserID=$userId"
        "&UserPwd=${Uri.encodeComponent(userPwd)}"
        "&VerNo=${AppConfig.verNo}";

    print("================================");
    print("📦 WORK ORDER LIST REQUEST");
    print("URL => $url");
    print("UserID => $userId");
    print("================================");

    final response = await http.get(Uri.parse(url));

    print("WORK ORDER RESPONSE STATUS => ${response.statusCode}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["StatusCode"] == 200) {
      final List list = data["WOList"] ?? data["SOList"] ?? [];
      print("📊 Total Work Orders received: ${list.length}");
      return list.map((e) => WorkOrderStatusModel.fromJson(e)).toList();
    }

    throw Exception(data["Message"] ?? "Failed to load work order list");
  } catch (e) {
    print("❌ WORK ORDER ERROR => $e");
    throw Exception("WORK ORDER ERROR: $e");
  }
}

// =========================
// WORK ORDER REPORT
// =========================
static Future<String> getWorkOrderReport({
  required String userId,
  required String userPwd,
  required String token,
  required Map<String, dynamic> body,
  required int reportType,
}) async {
  print("🔵 WORK ORDER REPORT REQUEST");
  print("USERID: $userId");
  print("REPORT TYPE: $reportType");
  print("BODY: $body");

  try {
    final url = "${baseUrl}WOStatus";

    // ADD USER INTO BODY
    body["UserID"] = userId;
    body["UserPwd"] = userPwd;
    body["VerNo"] = AppConfig.verNo;
    body["Token"] = token;

    print("================================");
    print("WORK ORDER REPORT API");
    print("URL => $url");
    print("BODY =>");
    print(jsonEncode(body));
    print("================================");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("STATUS CODE => ${response.statusCode}");
    print("RESPONSE =>");
    print(response.body);
    print("================================");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["StatusCode"] == 200) {
      return data["Message"] ?? "";
    } else {
      final message = (data["Message"] ?? "").toString();

      if (message.contains("No data to display report")) {
        throw Exception("No Record Found");
      }

      throw Exception(
        message.isEmpty ? "Unknown Error" : message,
      );
    }
  } catch (e) {
    print("❌ WORK ORDER REPORT ERROR => $e");
    throw Exception(e.toString());
  }
}

// ================= EV LIST =================
static Future<List<EVModel>> getEVList(
  String userId,
  String userPwd,
) async {
  final url =
      "https://vyaratiles.co.in/API/EVMast"
      "?UserID=$userId"
      "&UserPwd=${Uri.encodeComponent(userPwd)}"
      "&VerNo=${AppConfig.verNo}";

  final response = await http.get(Uri.parse(url));
  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data["StatusCode"] == 200) {
    final List list = data["EVList"] ?? [];
    return list.map((e) => EVModel.fromJson(e)).toList();
  }

  throw Exception(data["Message"] ?? "EV List Failed");
}

// ================= EV DETAILS =================
static Future<EVDetailModel> getEVDetails({
  required String userId,
  required String userPwd,
  required int eqId,
}) async {
  final url =
      "https://vyaratiles.co.in/API/EVDetails"
      "?UserID=$userId"
      "&UserPwd=${Uri.encodeComponent(userPwd)}"
      "&VerNo=${AppConfig.verNo}"
      "&EqID=$eqId";

  final response = await http.get(Uri.parse(url));
  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data["StatusCode"] == 200) {
    return EVDetailModel.fromJson(data);
  }

  throw Exception(data["Message"] ?? "EV Details Failed");
}

// ================= START CHARGE =================
static Future<String> startCharge(Map body) async {
  final url = "https://vyaratiles.co.in/API/EVStartChrg";

  body["VerNo"] = AppConfig.verNo;

  final response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data["StatusCode"] == 200) {
    return data["Message"] ?? "Started";
  }

  throw Exception(data["Message"] ?? "Start Failed");
}

// ================= END CHARGE =================
static Future<String> endCharge(Map body) async {
  final url = "https://vyaratiles.co.in/API/EVEndChrg";

  body["VerNo"] = AppConfig.verNo;

  final response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data["StatusCode"] == 200) {
    return data["Message"] ?? "Ended";
  }

  throw Exception(data["Message"] ?? "End Failed");
}

// =================== Dispatch Plan Data List =============

// ============ dispatch plan =========

static Future<DispatchPlanModel> getDispatchPlanFilters(
  String userId,
  String userPwd,
) async {
  try {
    final url =
        "https://vyaratiles.co.in/Api/DPlanData"
        "?UserID=$userId"
        "&UserPwd=${Uri.encodeComponent(userPwd)}"
        "&VerNo=${AppConfig.verNo}";

    print("DISPATCH FILTER URL => $url");

    final response = await http.get(Uri.parse(url));

    print("FILTER RESPONSE => ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return DispatchPlanModel.fromJson(data);
    }

    throw Exception("Failed to load filters");
  } catch (e) {
    throw Exception("FILTER API ERROR: $e");
  }
}
   // ======================= dispatch plan list =================
static Future<List<DispatchPlanRowModel>> getDispatchPlanList(
  String userId,
  String userPwd, {
  String? factory,
  String? marketingPerson,
  String? clientGroup,
  String? client,
  String? site,
  String? product,
  String? soNo,
}) async {
  try {
    String url = 
        "https://vyaratiles.co.in/Api/DPlanData"
        "?UserID=$userId"
        "&UserPwd=${Uri.encodeComponent(userPwd)}"
        "&VerNo=${AppConfig.verNo}";

    if (factory != null && factory.isNotEmpty) {
      url += "&Factory=$factory";
    }
    if (marketingPerson != null && marketingPerson.isNotEmpty) {
      url += "&MktPerson=$marketingPerson";
    }
    if (clientGroup != null && clientGroup.isNotEmpty) {
      url += "&ClientGroup=$clientGroup";
    }
    if (client != null && client.isNotEmpty) {
      url += "&Client=$client";
    }
    if (site != null && site.isNotEmpty) {
      url += "&Site=$site";
    }
    if (product != null && product.isNotEmpty) {
      url += "&Product=$product";
    }
    if (soNo != null && soNo.isNotEmpty) {
      url += "&SONo=$soNo";
    }

    print("🔥 FINAL URL => $url");

    final response = await http.get(Uri.parse(url));

    print("🔥 STATUS => ${response.statusCode}");
    print("🔥 BODY => ${response.body}");

    final data = jsonDecode(response.body);

    // ✅ THIS IS THE REAL FIX
    final List list = data["SOList"] ?? [];

    print("🔥 RECORD COUNT => ${list.length}");

    return list
        .map((e) => DispatchPlanRowModel.fromJson(e))
        .toList();

  } catch (e) {
    throw Exception("DISPATCH ERROR: $e");
  }
}

// ============== dispatch detail ================
static Future<List<DispatchPlanRowModel>> getDispatchPlanListDynamic(
  Map<String, String?> params,
) async {
  try {
    final cleanedParams = <String, String>{};

    params.forEach((key, value) {
      if (value != null && value.trim().isNotEmpty) {
        cleanedParams[key] = Uri.encodeComponent(value.trim());
      }
    });

    // Ensure version number is always present
    cleanedParams["VerNo"] = AppConfig.verNo.toString();

    final uri = Uri.https(
      "vyaratiles.co.in",
      "/Api/DPlanData",
      cleanedParams,
    );

    print("🔥 FINAL URL => $uri");

    final response = await http.get(uri);

    print("🔥 STATUS => ${response.statusCode}");
    print("🔥 BODY => ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("API failed with status ${response.statusCode}");
    }

    final data = jsonDecode(response.body);

    final List list = data["SOList"] ?? [];

    print("🔥 RECORD COUNT => ${list.length}");

    return list
        .map((e) => DispatchPlanRowModel.fromJson(e))
        .toList();

  } catch (e) {
    throw Exception("DISPATCH ERROR: $e");
  }
}



 // ================= GET DETAIL =================
  static Future<Map<String, dynamic>> getDispatchPlan({
    required String userId,
    required String userPwd,
    required int solocId,
    required int soId,
    required int sosrNo,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/DPlanSO"
      "?UserID=$userId"
      "&UserPwd=${Uri.encodeComponent(userPwd)}"
      "&VerNo=${AppConfig.verNo}"
      "&SOLocID=$solocId"
      "&SOID=$soId"
      "&SOSrNo=$sosrNo",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load data");
    }
  }

  /// =========================
  /// SAVE DISPATCH PLAN
  /// =========================
  static Future<bool> saveDispatchPlan(
      Map<String, dynamic> body) async {
    final uri = Uri.parse("$baseUrl/DispPlan");

    body["VerNo"] = AppConfig.verNo;

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode(body),
    );

    return response.statusCode == 200;
  }



//================== PRODUCTS  List ==================
// =========================
// PRODUCTS LIST
// =========================

static Future<List<ProductModel>> getProducts(
  String userId,
  String userPwd,
) async {
  try {
    final url =
        "${baseUrl}Products"
        "?UserID=${Uri.encodeComponent(userId)}"
        "&UserPwd=${Uri.encodeComponent(userPwd)}"
        "&VerNo=${AppConfig.verNo}";
    print("==============================");
    print("PRODUCT API");
    print("URL => $url");
    final response = await http.get(
      Uri.parse(url),
    );
    print("STATUS => ${response.statusCode}");
    print("RESPONSE => ${response.body}");
    print("==============================");
    if (response.statusCode == 200) {
      final Map<String,dynamic> data =
          jsonDecode(response.body);
      final List list =
          data["ProductList"] ?? [];
      print(
        "TOTAL PRODUCTS => ${list.length}",
      );
      return list
          .map(
            (e)=>ProductModel.fromJson(e),
          )
          .toList();
    }
    throw Exception(
      "HTTP ${response.statusCode}",
    );
  }
  catch(e){
    print(
      "PRODUCT API ERROR => $e",
    );
    throw Exception(
      "PRODUCT ERROR : $e",
    );
  }
}


// ============================================================
// SAMPLE REQUEST MASTER DATA
// ============================================================

static Future<SampleRequestMasterModel> getSampleRequestData(
  String userId,
  String userPwd,
) async {
  try {
    final url =
        "${baseUrl}SampleReqData"
        "?UserID=${Uri.encodeComponent(userId)}"
        "&UserPwd=${Uri.encodeComponent(userPwd)}"
        "&VerNo=${AppConfig.verNo}";

    print("================================");
    print("SAMPLE REQUEST MASTER API");
    print("URL => $url");
    print("================================");

    final response = await http.get(
      Uri.parse(url),
    );

    print(
      "SAMPLE REQUEST STATUS => ${response.statusCode}",
    );

    print(
      "SAMPLE REQUEST RESPONSE => ${response.body}",
    );

    if (response.statusCode != 200) {
      throw Exception(
        "HTTP ${response.statusCode}",
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (data["StatusCode"] != 200) {
      throw Exception(
        data["Message"] ??
            "Failed to load Sample Request data",
      );
    }

    return SampleRequestMasterModel.fromJson(
      data,
    );
  } catch (e) {
    print(
      "SAMPLE REQUEST MASTER ERROR => $e",
    );

    throw Exception(
      "SAMPLE REQUEST ERROR : $e",
    );
  }
}

static Future<Map<String, dynamic>> saveSampleRequest({
  required String userId,
  required String userPwd,
  required Map<String, dynamic> body,
}) async {
  try {
    final uri = Uri.parse(
      'https://vyaratiles.co.in/API/SampleReq',
    ).replace(
      queryParameters: {
        'UserID': 'Sys',
      },
    );

    body['UserPwd'] = userPwd;
    body['VerNo'] = AppConfig.verNo;

    print('================ SAMPLE REQUEST POST ================');
    print('URL: $uri');
    print('BODY: ${jsonEncode(body)}');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('STATUS: ${response.statusCode}');
    print('RESPONSE: ${response.body}');
    print('======================================================');

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (response.body.trim().isEmpty) {
        return {
          'success': true,
          'message': 'Sample Request saved successfully.',
        };
      }

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }

        return {
          'success': true,
          'data': decoded,
        };
      } catch (_) {
        return {
          'success': true,
          'message': response.body,
        };
      }
    }

    String message = 'Failed to save Sample Request.';

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        message =
            decoded['message']?.toString() ??
            decoded['Message']?.toString() ??
            decoded['error']?.toString() ??
            decoded['Error']?.toString() ??
            message;
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) {
        message = response.body;
      }
    }

    throw Exception(
      'HTTP ${response.statusCode}: $message',
    );
  } catch (e) {
    print('SAMPLE REQUEST SAVE ERROR: $e');

    throw Exception(
      'Unable to save Sample Request: $e',
    );
  }
}
}
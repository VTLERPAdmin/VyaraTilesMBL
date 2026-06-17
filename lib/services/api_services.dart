// ===============================
// FILE: api_services.dart
// ===============================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/so_status_model.dart';
import '../models/ledger_model.dart';
import '../models/so_approval_model.dart';
import '../models/ev_model.dart';
import '../models/dispatch_plan_filter_model.dart';
import '../models/ev_detail_model.dart';


class ApiService {
  static const String baseUrl = "https://vyaratiles.co.in/Api/";

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
  // =========================
// GET SO FILTERS
// =========================

static Future<SoStatusModel> getSOFilters(
  String userId,
  String token,
) async {

  try {

    final url =
        "${baseUrl}SOStatusFilter?UserID=${Uri.encodeComponent(userId)}&Token=$token";

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
) async {

  try {

    final url =
        "${baseUrl}LedgerFilter?UserID=${Uri.encodeComponent(userId)}";

    print("LEDGER FILTER URL => $url");

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


static Future<String> getLedgerReport({
  required String clientIds,
  required String fromDate,
  required String toDate,
  required bool mergeClients,
  required bool grandTotal,
}) async {

  try {

    final url =
        "${baseUrl}Ledger?"
        "ClientID=$clientIds"
        "&FromDate=$fromDate"
        "&ToDate=$toDate"
        "&MergeClients=$mergeClients"
        "&GrandTotal=$grandTotal";

    print("LEDGER REPORT URL => $url");

    final response = await http.get(
      Uri.parse(url),
    );

    print("LEDGER REPORT RESPONSE => ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data["StatusCode"] == 200) {

      return data["Message"] ?? "";

    } else {

      throw Exception(
        data["Message"] ?? "Failed",
      );
    }

  } catch (e) {

    throw Exception(
      "LEDGER REPORT ERROR : $e",
    );
  }
}


// ================== Pdf API =======================

static Future<String> getSOPrint(
  String userId,
  int locId,
  int soId,
) async {
  try {

    final url =
        "${baseUrl}SOPrint?"
        "UserID=$userId"
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
  required int locId,
  required int soId,
}) async {

  try {

    final url =
        "${baseUrl}SOPrint"
        "?UserID=$userId"
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
}) async {
  try {
    final url =
        "https://vyaratiles.co.in/API/SOApprList?UserID=$userId";

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
  required int locId,
  required int soId,
  required String notes,
}) async {
  try {
    final url = "${baseUrl}SOAppr";

    final body = {
      "UserID": userId,
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

// ================= EV LIST =================
static Future<List<EVModel>> getEVList(String userId) async {
  final url = "https://vyaratiles.co.in/API/EVMast?UserID=$userId";

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
  required int eqId,
}) async {
  final url =
      "https://vyaratiles.co.in/API/EVDetails?UserID=$userId&EqID=$eqId";

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

// =================== Dispatch Paln Data List =============



// ============ dispatch plan =========

static Future<DispatchPlanModel> getDispatchPlanFilters(
  String userId,
) async {
  try {
    final url =
        "https://vyaratiles.co.in/Api/DPlanData?UserID=$userId";

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
  String userId, {
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
        "https://vyaratiles.co.in/Api/DPlanData?UserID=$userId";

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
    required int solocId,
    required int soId,
    required int sosrNo,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/DPlanSO"
      "?UserID=$userId"
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

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode(body),
    );

    return response.statusCode == 200;
  }
}




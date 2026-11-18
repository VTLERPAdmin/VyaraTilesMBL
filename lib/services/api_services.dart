// ===============================
// FILE: api_services.dart
// ===============================

import 'dart:convert';
import 'dart:typed_data';
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
import '../models/stock_report_model.dart';
import '../models/sale_quotation_model.dart';
import '../models/credit_limit_model.dart';
import '../models/inv_print_model.dart';
import '../models/movable_asset_model.dart';
import '../models/movable_asset_receive_model.dart';

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

      final response = await http.get(Uri.parse(url));

      print("STATUS CODE => ${response.statusCode}");

      print("RESPONSE =>");
      print(response.body);

      print("================================");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        return SoStatusModel.fromJson(data);
      } else {
        throw Exception("HTTP ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      print("SO FILTER ERROR => $e");

      throw Exception("SO FILTER ERROR : $e");
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

        headers: {"Content-Type": "application/json"},

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

        throw Exception(message.isEmpty ? "Unknown Error" : message);
      }
    } catch (e) {
      print("SO STATUS ERROR => $e");

      throw Exception("SO STATUS ERROR : $e");
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

      final response = await http.get(Uri.parse(url));

      print("LEDGER FILTER RESPONSE => ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return LedgerFilterModel.fromJson(data);
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("LEDGER FILTER ERROR : $e");
    }
  }

  // =========================
  // LEDGER REPORT
  // =========================

static Future<Uint8List> getLedgerReport({
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

    final response = await http
        .post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/pdf, application/json",
          },
          body: jsonEncode(body),
        )
        // Large ledgers can take ~30 s on the server.
        .timeout(const Duration(minutes: 3));

    final bytes = response.bodyBytes;

    print("LEDGER STATUS => ${response.statusCode}");
    print("LEDGER CONTENT-TYPE => ${response.headers['content-type']}");
    print("LEDGER SIZE => ${bytes.length} bytes");

    // A real PDF always starts with "%PDF".
    final isPdf = bytes.length > 4 &&
        bytes[0] == 0x25 && // %
        bytes[1] == 0x50 && // P
        bytes[2] == 0x44 && // D
        bytes[3] == 0x46; //   F

    if (response.statusCode == 200 && isPdf) {
      return bytes;
    }

    // Not a PDF: the server sent an error, usually as JSON
    // {"StatusCode": ..., "Message": "..."}.
    String message = "Failed to generate ledger.";
    try {
      final data = jsonDecode(utf8.decode(bytes));
      if (data is Map && data["Message"] != null) {
        message = data["Message"].toString();
      }
    } catch (_) {
      final text = utf8.decode(bytes, allowMalformed: true).trim();
      if (text.isNotEmpty && text.length < 300) message = text;
    }

    if (message.contains("No data to display report")) {
      message = "No Record Found";
    }

    throw Exception(message);
  
  } catch (e) {
    print("LEDGER REPORT ERROR => $e");
    throw Exception(e.toString().replaceFirst("Exception: ", ""));
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

      final response = await http.get(Uri.parse(url));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["StatusCode"] == 200) {
        String pdf = data["PDFPath"] ?? "";

        pdf = pdf.replaceAll("//https://", "https://");

        return pdf;
      }

      throw Exception(data["Message"] ?? "Failed");
    } catch (e) {
      throw Exception("SO PRINT ERROR : $e");
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
      if (userId.trim().isEmpty || userPwd.trim().isEmpty) {
        throw Exception("User authentication details are missing.");
      }

      final uri = Uri.parse("${baseUrl}SOPrint").replace(
        queryParameters: {
          "UserID": userId,
          "UserPwd": userPwd,
          "VerNo": AppConfig.verNo.toString(),
          "LocID": locId.toString(),
          "SOID": soId.toString(),
        },
      );

      print("SO PDF REQUEST => LocID: $locId, SOID: $soId");

      final response = await http.get(uri);

      print(response.body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["StatusCode"] == 200) {
        return data["PDFPath"] ?? "";
      } else {
        throw Exception(data["Message"] ?? "Failed");
      }
    } catch (e) {
      throw Exception("SO PDF ERROR : $e");
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

        return list.map((e) => SOApprovalModel.fromJson(e)).toList();
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
        headers: {"Content-Type": "application/json"},
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

      throw Exception(
        data["Message"] ?? "Failed to load SO acknowledgement list",
      );
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

      throw Exception(
        data["Message"] ?? "Failed to load SO acknowledgement list",
      );
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
        headers: {"Content-Type": "application/json"},
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

      final response = await http.get(Uri.parse(url));

      print("STATUS CODE => ${response.statusCode}");
      print("RESPONSE =>");
      print(response.body);
      print("================================");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return WorkOrderStatusModel.fromJson(data);
      } else {
        throw Exception("HTTP ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      print("WO FILTER ERROR => $e");
      throw Exception("WO FILTER ERROR : $e");
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
        headers: {"Content-Type": "application/json"},
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

        throw Exception(message.isEmpty ? "Unknown Error" : message);
      }
    } catch (e) {
      print("❌ WORK ORDER REPORT ERROR => $e");
      throw Exception(e.toString());
    }
  }

  // ================= EV LIST =================
  static Future<List<EVModel>> getEVList(String userId, String userPwd) async {
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

      return list.map((e) => DispatchPlanRowModel.fromJson(e)).toList();
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

      return list.map((e) => DispatchPlanRowModel.fromJson(e)).toList();
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
  static Future<bool> saveDispatchPlan(Map<String, dynamic> body) async {
    final uri = Uri.parse("$baseUrl/DispPlan");

    body["VerNo"] = AppConfig.verNo;

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
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
      final response = await http.get(Uri.parse(url));
      print("STATUS => ${response.statusCode}");
      print("RESPONSE => ${response.body}");
      print("==============================");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List list = data["ProductList"] ?? [];
        print("TOTAL PRODUCTS => ${list.length}");
        return list.map((e) => ProductModel.fromJson(e)).toList();
      }
      throw Exception("HTTP ${response.statusCode}");
    } catch (e) {
      print("PRODUCT API ERROR => $e");
      throw Exception("PRODUCT ERROR : $e");
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

      final response = await http.get(Uri.parse(url));

      print("SAMPLE REQUEST STATUS => ${response.statusCode}");

      print("SAMPLE REQUEST RESPONSE => ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("HTTP ${response.statusCode}");
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data["StatusCode"] != 200) {
        throw Exception(
          data["Message"] ?? "Failed to load Sample Request data",
        );
      }

      return SampleRequestMasterModel.fromJson(data);
    } catch (e) {
      print("SAMPLE REQUEST MASTER ERROR => $e");

      throw Exception("SAMPLE REQUEST ERROR : $e");
    }
  }

  static Future<Map<String, dynamic>> saveSampleRequest({
    required String userId,
    required String userPwd,
    required Map<String, dynamic> body,
  }) async {
    try {
      final uri = Uri.parse('https://vyaratiles.co.in/API/SampleReq').replace(
        /* queryParameters: {
        'UserID': 'Sys',
      }, */
      );

      body['UserPwd'] = userPwd;
      body['VerNo'] = AppConfig.verNo;

      print('================ SAMPLE REQUEST POST ================');
      print('URL: https://vyaratiles.co.in/API/SampleReq');
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

      if (response.statusCode >= 200 && response.statusCode < 300) {
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

          return {'success': true, 'data': decoded};
        } catch (_) {
          return {'success': true, 'message': response.body};
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

      throw Exception('HTTP ${response.statusCode}: $message');
    } catch (e) {
      print('SAMPLE REQUEST SAVE ERROR: $e');

      throw Exception('Unable to save Sample Request: $e');
    }
  }

  // ===============================
  // PATCH: api_services.dart
  // ===============================
  //
  // Two changes needed in your existing api_services.dart:
  //
  // 1) Add this import near the top with the other model imports:
  //
  //      import '../models/stock_report_models.dart';
  //
  // 2) Replace the existing getStockReportFilters() method (the one at the
  //    bottom of the file, under "STOCK REPORT FILTER API") with the version
  //    below. Same URL, same param names, same error handling pattern as the
  //    rest of the file — the only change is that it now returns a typed
  //    StockReportFilterModel instead of a raw Map<String, dynamic>.

  static Future<StockReportFilterModel> getStockReportFilters(
    String userId,
    String userPwd,
  ) async {
    try {
      final url =
          "${baseUrl}MktLotStockRptFilter"
          "?UserID=${Uri.encodeComponent(userId)}"
          "&UserPwd=${Uri.encodeComponent(userPwd)}"
          "&VerNo=${AppConfig.verNo}";

      print("========================================");
      print("STOCK REPORT FILTER API");
      print("USER ID => $userId");
      print("VER NO => ${AppConfig.verNo}");
      print("========================================");

      final response = await http.get(Uri.parse(url));

      print("STOCK REPORT FILTER STATUS => ${response.statusCode}");

      print("STOCK REPORT FILTER RESPONSE => ${response.body}");

      if (response.statusCode != 200) {
        throw Exception(
          "Stock Report Filter API failed: "
          "HTTP ${response.statusCode}",
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data["StatusCode"] != 200) {
        throw Exception(
          data["Message"] ?? "Failed to load Stock Report filters.",
        );
      }

      return StockReportFilterModel.fromJson(data);
    } catch (e) {
      print("STOCK REPORT FILTER ERROR => $e");

      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  static Future<String> generateStockReport({
    required String userId,
    required String userPwd,
    required int locId,
    required int productGroupId,
    required int productId,
    int eqTypeId = 0,
    int secMixTypeId = 0,
  }) async {
    try {
      final url = "${baseUrl}MktLotStockRpt";

      final body = {
        "EqTypeID": eqTypeId,
        "LocID": locId,
        "ProductGroupID": productGroupId,
        "ProductID": productId,
        "SecMixTypeID": secMixTypeId,
        "UserID": userId,
        "UserPwd": userPwd,
        "VerNo": AppConfig.verNo,
      };

      print("================================");
      print("STOCK REPORT GENERATE API");
      print("URL => $url");
      print("BODY => ${jsonEncode(body)}");
      print("================================");

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("STOCK REPORT GENERATE STATUS => ${response.statusCode}");
      print("STOCK REPORT GENERATE RESPONSE => ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["StatusCode"] == 200) {
        final pdfUrl = (data["Message"] ?? "").toString().trim();

        if (pdfUrl.isEmpty) {
          throw Exception("Report generated but PDF path is empty.");
        }

        return pdfUrl;
      }

      throw Exception(
        (data["Message"] ?? "Failed to generate Stock Report").toString(),
      );
    } catch (e) {
      print("STOCK REPORT GENERATE ERROR => $e");

      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  // ===============================
  // PATCH: api_services.dart
  // ===============================
  //
  // 1) Add this import near the top with the other model imports:
  //
  //      import '../models/sale_quotation_model.dart';
  //
  // 2) Add these two methods anywhere inside the ApiService class.

  // ------------------------------------------------------------
  // SALE QUOTATION LIST
  // Endpoint: GET https://vyaratiles.co.in/Api/QuotList
  // Returns: MktPersons[], Clients[], Sites[], QuotList[], StatusCode, Message
  // ------------------------------------------------------------
  static Future<QuotListModel> getQuotList({
    required String userId,
    required String userPwd,
  }) async {
    try {
      final uri = Uri.parse("${baseUrl}QuotList").replace(
        queryParameters: {
          "UserID": userId,
          "UserPwd": userPwd,
          "VerNo": AppConfig.verNo.toString(),
        },
      );

      print("========================================");
      print("QUOTATION LIST API");
      print("USER ID => $userId");
      print("========================================");

      final response = await http.get(uri);

      print("QUOTATION LIST STATUS => ${response.statusCode}");

      if (response.statusCode != 200) {
        throw Exception(
          "Quotation List API failed: HTTP ${response.statusCode}",
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data["StatusCode"] != 200) {
        throw Exception(data["Message"] ?? "Failed to load quotations.");
      }

      return QuotListModel.fromJson(data);
    } catch (e) {
      print("QUOTATION LIST ERROR => $e");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  // ------------------------------------------------------------
  // SALE QUOTATION PRINT
  // Endpoint: GET https://vyaratiles.co.in/Api/QuotPrint
  // Query: UserID, UserPwd, VerNo, LocID, ID, SaleType
  // Response: { "StatusCode": 200, "Message": "<PDF URL>" }
  // ------------------------------------------------------------
  static Future<String> getQuotPrint({
    required String userId,
    required String userPwd,
    required int locId,
    required int id,
    required int saleType,
  }) async {
    try {
      final uri = Uri.parse("${baseUrl}QuotPrint").replace(
        queryParameters: {
          "UserID": userId,
          "UserPwd": userPwd,
          "VerNo": AppConfig.verNo.toString(),
          "LocID": locId.toString(),
          "ID": id.toString(),
          "SaleType": saleType.toString(),
        },
      );

      print("========================================");
      print("QUOTATION PRINT API");
      print("URL => $uri");
      print("========================================");

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      print("QUOTATION PRINT RESPONSE => ${response.body}");

      if (response.statusCode == 200 && data["StatusCode"] == 200) {
        final pdfUrl = (data["Message"] ?? "").toString().trim();

        if (pdfUrl.isEmpty) {
          throw Exception("Quotation generated but PDF path is empty.");
        }

        return pdfUrl;
      }

      throw Exception(
        (data["Message"] ?? "Failed to generate Quotation PDF").toString(),
      );
    } catch (e) {
      print("QUOTATION PRINT ERROR => $e");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  // ------------------------------------------------------------
  // TEMPORARY CREDIT LIMITS - LIST
  // Endpoint: GET https://vyaratiles.co.in/Api/CrLimitData
  // Returns: Clients[] (credit-limit records), MktPersons[],
  //          AuthPersons[], StatusCode, Message
  // ------------------------------------------------------------
  static Future<CrLimitDataModel> getCrLimitData({
    required String userId,
    required String userPwd,
  }) async {
    try {
      final uri = Uri.parse("${baseUrl}CrLimitData").replace(
        queryParameters: {
          "UserID": userId,
          "UserPwd": userPwd,
          "VerNo": AppConfig.verNo.toString(),
        },
      );

      print("========================================");
      print("CREDIT LIMIT LIST API");
      print("USER ID => $userId");
      print("========================================");

      final response = await http.get(uri);

      print("CREDIT LIMIT LIST STATUS => ${response.statusCode}");

      if (response.statusCode != 200) {
        throw Exception(
          "Credit Limit List API failed: HTTP ${response.statusCode}",
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data["StatusCode"] != 200) {
        throw Exception(data["Message"] ?? "Failed to load credit limits.");
      }

      return CrLimitDataModel.fromJson(data);
    } catch (e) {
      print("CREDIT LIMIT LIST ERROR => $e");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  // ------------------------------------------------------------
  // TEMPORARY CREDIT LIMITS - SAVE
  // Endpoint: POST https://vyaratiles.co.in/Api/CrLimit
  // Sends only the affected credit-limit record in Clients[].
  // ------------------------------------------------------------
  static Future<void> saveCrLimit({
    required String userId,
    required String userPwd,
    required CrLimitRecordModel record,
  }) async {
    try {
      final url = Uri.parse("${baseUrl}CrLimit");

      final body = {
        "UserID": userId,
        "UserPwd": userPwd,
        "VerNo": AppConfig.verNo,
        "id": record.id,
        "ClientID": record.clientId,
        "client": record.client,
        "CrLimit": record.crLimit,
        "MktPersonID": record.mktPersonId,
        "effFrom": formatIsoMidnight(record.effFrom),
        "effTill": formatIsoMidnight(record.effTill),
        "crlimitAuthID": record.crLimitAuthId,
        "crlimitRef": record.crLimitRef,
      };

      print("========================================");
      print("CREDIT LIMIT SAVE API");
      print("========================================");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("CREDIT LIMIT SAVE STATUS => ${response.statusCode}");
      print("CREDIT LIMIT SAVE RESPONSE => ${response.body}");

      final data = jsonDecode(response.body);

      if (!(response.statusCode == 200 && data["StatusCode"] == 200)) {
        throw Exception(
          (data["Message"] ?? "Failed to save credit limit.").toString(),
        );
      }
    } catch (e) {
      print("CREDIT LIMIT SAVE ERROR => $e");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  // ------------------------------------------------------------
  // INV. PRINT - LIST
  // Endpoint: GET https://vyaratiles.co.in/Api/InvPrintData
  // Returns: InvList[], StatusCode, Message
  // ------------------------------------------------------------
  static Future<InvPrintListModel> getInvPrintData({
    required String userId,
    required String userPwd,
  }) async {
    try {
      final uri = Uri.parse("${baseUrl}InvPrintData").replace(
        queryParameters: {
          "UserID": userId,
          "UserPwd": userPwd,
          "VerNo": AppConfig.verNo.toString(),
        },
      );

      print("========================================");
      print("INV PRINT LIST API");
      print("USER ID => $userId");
      print("========================================");

      final response = await http.get(uri);

      print("INV PRINT LIST STATUS => ${response.statusCode}");

      if (response.statusCode != 200) {
        throw Exception(
          "Inv. Print List API failed: HTTP ${response.statusCode}",
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data["StatusCode"] != 200) {
        throw Exception(data["Message"] ?? "Failed to load invoices.");
      }

      return InvPrintListModel.fromJson(data);
    } catch (e) {
      print("INV PRINT LIST ERROR => $e");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  // ------------------------------------------------------------
  // INV. PRINT - REPORT
  // Endpoint: GET https://vyaratiles.co.in/Api/InvPrint
  // Query: UserID, UserPwd, VerNo, LocID, ID
  //   + PreSigned (ONLY sent when true) -- this param name/shape
  //     is a best guess for the "Pre-Signed (Logged Employee)"
  //     toggle; confirm with the backend and adjust if different.
  // Response: { "StatusCode": 200, "Message": "<PDF URL>" }
  // ------------------------------------------------------------
  static Future<String> getInvPrintReport({
    required String userId,
    required String userPwd,
    required int locId,
    required int id,
    bool preSigned = false,
  }) async {
    try {
      final params = <String, String>{
        "UserID": userId,
        "UserPwd": userPwd,
        "VerNo": AppConfig.verNo.toString(),
        "LocID": locId.toString(),
        "ID": id.toString(),
        "UseSign": preSigned.toString(),
      };

      if (preSigned) {
        params["PreSigned"] = "true";
      }

      final uri = Uri.parse(
        "${baseUrl}InvPrint",
      ).replace(queryParameters: params);

      print("========================================");
      print("INV PRINT REPORT API");
      print("URL => $uri");
      print("========================================");

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      print("INV PRINT REPORT RESPONSE => ${response.body}");

      if (response.statusCode == 200 && data["StatusCode"] == 200) {
        final pdfUrl = (data["Message"] ?? "").toString().trim();

        if (pdfUrl.isEmpty) {
          throw Exception("Invoice generated but PDF path is empty.");
        }

        return pdfUrl;
      }

      throw Exception(
        (data["Message"] ?? "Failed to generate Invoice PDF").toString(),
      );
    } catch (e) {
      print("INV PRINT REPORT ERROR => $e");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }
  

  // ===============================
  // PATCH: api_services.dart
  // ===============================
  //
  // 1) Make sure this import is near the top with the other model imports:
  //
  //      import '../models/movable_asset_model.dart';
  //
  // 2) Replace BOTH Movable Asset methods you added earlier with the two
  //    below (the save method changed completely: new URL, new body).
  //    `jsonEncode` / `base64Encode` come from dart:convert, which this
  //    file already imports.

  // ------------------------------------------------------------
  // MOVABLE ASSET - LOOKUPS
  // Endpoint: GET https://vyaratiles.co.in/Api/MovableAsset
  // Returns: LocList[], Client[], Site[], Agencys[], Emps[], Assets[],
  //          Items[], Taxes[], UOM[], StatusCode, Message
  // ------------------------------------------------------------
  static Future<MovableAssetLookups> getMovableAssetData({
    required String userId,
    required String userPwd,
  }) async {
    try {
      final uri = Uri.parse("${baseUrl}MovableAsset").replace(
        queryParameters: {
          "UserID": userId,
          "UserPwd": userPwd,
          "VerNo": AppConfig.verNo.toString(),
        },
      );

      print("========================================");
      print("MOVABLE ASSET LOOKUPS API");
      print("USER ID => $userId");
      print("========================================");

      final response = await http.get(uri);

      print("MOVABLE ASSET LOOKUPS STATUS => ${response.statusCode}");

      if (response.statusCode != 200) {
        throw Exception(
          "Movable Asset API failed: HTTP ${response.statusCode}",
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data["StatusCode"] != 200) {
        throw Exception(
          data["Message"] ?? "Failed to load movable asset data.",
        );
      }

      return MovableAssetLookups.fromJson(data);
    } catch (e) {
      print("MOVABLE ASSET LOOKUPS ERROR => $e");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  // ------------------------------------------------------------
  // MOVABLE ASSET - SAVE
  // Endpoint: POST https://vyaratiles.co.in/Api/MovableAssetsave
  //
  // The header, GSTAmts and the asset row (Details[]) follow your real
  // sample. These parts are STILL GUESSES (no sample had them filled):
  //   * the shape of a SubItems[] element (each item under an asset) —
  //     assumed to mirror the asset row: ItemID, ItemName, HsnCode,
  //     UoMCode, Qty, Rate, BasicAmt, GST, GrossAmt, Remarks
  //   * the asset row's own Qty / UoMCode: sent as 1 / "NOS"
  //   * the asset row's GST: the tax picked for the asset (GST.ID)
  //   * an asset with no items is sent with "SubItems": []
  //   * the amount maths (see _gstObj / the totals below)
  //   * GST.Mode: 12 for an IGST tax, 11 otherwise (inferred from your
  //     sample: header 11, IGST row 12)
  //   * the format of AssetImage (assumed: plain base64 text, no
  //     "data:image/..." prefix)
  // If a name is wrong the server may ignore it and save a blank value
  // without an error, so test with a throw-away voucher and check the
  // saved record in the ERP.
  //
  // Returns the text to show the user: the server's "Message", plus
  // the Vou. No. if the response carries it in a "VouNo" field.
  // ------------------------------------------------------------
  static Future<String> saveMovableAsset({
    required String userId,
    required String userPwd,
    required DateTime vouDate,
    required MaLookupItem? location,
    required MaLookupItem? client,
    required MaLookupItem? site,
    required MaLookupItem? agency,
    required MaLookupItem emp,
    required String notes,
    required List<MaAssetLine> lines,
  }) async {
    try {
      final uri = Uri.parse("${baseUrl}MovableAssetsave").replace(
        queryParameters: {
          "UserID": userId,
          "UserPwd": userPwd,
          "VerNo": AppConfig.verNo.toString(),
        },
      );

      String two(int n) => n.toString().padLeft(2, '0');
      final vouDateStr =
          "${two(vouDate.day)}/${two(vouDate.month)}/${vouDate.year}";

     

      Map<String, dynamic> gstObj({
        int id = 0,
        String heading = "",
        double rate = 0,
        int mode = 11,
        bool noCalc = false,
      }) => {
       
        "ID": id,
        
      };

      // Tax percentage is read from the tax name, e.g. "...-18%)..." -> 18
      double taxRate(String name) {
        final m = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(name);
        return m == null ? 0.0 : double.tryParse(m.group(1)!) ?? 0.0;
      }

      final locId = location?.id ?? 0;

      double basicTotal = 0;
      double grossTotal = 0;

      final details = <Map<String, dynamic>>[];

      for (var i = 0; i < lines.length; i++) {
        final l = lines[i];

        // Asset row: one unit at the asset's own rate.
        const assetQty = 1.0;
        final assetBasic = assetQty * l.asset.rate;

        final subItems = <Map<String, dynamic>>[];
        double subItemAmt = 0;

        for (var j = 0; j < l.items.length; j++) {
          final e = l.items[j];
          final itemBasic = e.qty * e.item.rate;
          subItemAmt += itemBasic;

          subItems.add({
            "LocID": locId,
            "ID": 0,
            "SrNo": j + 1,
            "ItemID": e.item.id,
            "ItemName": e.item.name,
            "HsnCode": e.hsnCode,
            "UoMCode": e.uom.name,
            "Qty": e.qty,
            "Rate": e.item.rate,
            "BasicAmt": itemBasic,
            "GST": gstObj(
              id: e.tax.id,
              heading: e.tax.name,
              rate: taxRate(e.tax.name),
              mode: e.tax.name.toUpperCase().contains("IGST") ? 12 : 11,
              noCalc: true,
            ),
            "GrossAmt": itemBasic,
            "Remarks": e.remarks,
          });
        }

        final rowGross = assetBasic + subItemAmt;
        basicTotal += assetBasic;
        grossTotal += rowGross;

        details.add({
          "LocID": locId,
          "ID": 0,
          "SrNo": i + 1,
          "AssetID": l.asset.id,
          "AssetNo": l.asset.assetCode,
          "AssetName": l.asset.name,
          "HsnCode": l.hsnCode,
          "UoMCode": "NOS",
          "Qty": assetQty,
          "Rate": l.asset.rate,
          "BasicAmt": assetBasic,
          // GST picked for the asset itself.
          "GST": l.tax == null
              ? gstObj()
              : gstObj(
                  id: l.tax!.id,
                  heading: l.tax!.name,
                  rate: taxRate(l.tax!.name),
                  mode: l.tax!.name.toUpperCase().contains("IGST") ? 12 : 11,
                  noCalc: true,
                ),
          "GrossAmt": rowGross,
          "AssetImage": base64Encode(l.photoBytes),
          "Image": null,
          "SubItems": subItems,
          "SubItemAmt": subItemAmt,
        });
      }

      final body = {
        "UserID": userId,
        "UserPWd": userPwd,
        "VerNo": AppConfig.verNo,        
        "VouNo": "", // generated by the server
        "VouDate": vouDateStr,
        "ClientID": client?.id ?? 0,
        "Client": client?.name ?? "",
        "SiteID": site?.id ?? 0,
        "AgencyID": agency?.id ?? 0,
        "Agency": agency?.name ?? "",
        "RefLocID": location?.id ?? 0,        
        "EmpID": emp.id,        
        "VehicleNo": "",
        "BasicAmt": basicTotal,
        "GSTAmts": gstObj(),
        "GrossAmt": grossTotal,
        "Remarks": notes,
        "Outwards": true,
        "Details": details,
      };

      print("========================================");
      print("MOVABLE ASSET SAVE API");
      print("URL => $uri");
      // The photos are large — log the body without them.
      print(
        "BODY (photos hidden) => "
                "${jsonEncode(body, toEncodable: (o) => o)}"
            .replaceAll(RegExp(r'"AssetImage":"[^"]*"'), '"AssetImage":"..."'),
      );
      print("========================================");

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("MOVABLE ASSET SAVE STATUS => ${response.statusCode}");
      print("MOVABLE ASSET SAVE RESPONSE => ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["StatusCode"] == 200) {
        final message = (data["Message"] ?? "").toString().trim();
        final vouNo = (data["VouNo"] ?? "").toString().trim();

        if (vouNo.isNotEmpty && !message.contains(vouNo)) {
          return message.isEmpty
              ? "Vou. No.: $vouNo"
              : "$message\nVou. No.: $vouNo";
        }
        return message;
      }

      throw Exception(
        (data["Message"] ?? "Failed to save movable asset.").toString(),
      );
    } catch (e) {
      print("MOVABLE ASSET SAVE ERROR => $e");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

// ===============================
// PATCH: api_services.dart
// ===============================
//
// 1) Add this import near the top with the other model imports:
//
//      import '../models/movable_asset_receive_model.dart';
//
// 2) Paste the two methods below inside the ApiService class.

// ------------------------------------------------------------
// MOVABLE ASSET RECEIVE - PENDING LIST
// GET https://vyaratiles.co.in/api/movableAssetReceive
// ------------------------------------------------------------
static Future<List<MaReceiveRow>> getMovableAssetReceiveList({
  required String userId,
  required String userPwd,
}) async {
  try {
    final uri = Uri.parse("${baseUrl}movableAssetReceive").replace(
      queryParameters: {
        "UserID": userId,
        "UserPwd": userPwd,
        "VerNo": AppConfig.verNo.toString(),
      },
    );

    print("========================================");
    print("MOVABLE ASSET RECEIVE LIST API");
    print("USER ID => $userId");
    print("========================================");

    final response = await http.get(uri);

    print("MA RECEIVE LIST STATUS => ${response.statusCode}");
    print("MA RECEIVE LIST RESPONSE => ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Receive list failed: HTTP ${response.statusCode}");
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (data["StatusCode"] != 200) {
      throw Exception(
        (data["Message"] ?? "Failed to load assets to receive.").toString(),
      );
    }

    final List list = data["RAssets"] as List? ?? [];

    return list
        .whereType<Map>()
        .map((e) => MaReceiveRow.fromJson(Map<String, dynamic>.from(e)))
        // Only rows still waiting to be received.
        .where((r) => !r.isReceived)
        .toList();
  } catch (e) {
    print("MA RECEIVE LIST ERROR => $e");
    throw Exception(e.toString().replaceFirst("Exception: ", ""));
  }
}

// ------------------------------------------------------------
// MOVABLE ASSET RECEIVE - SAVE ONE ROW
// POST https://vyaratiles.co.in/api/movableAssetReceivedsave
// Body: the row as received from the GET, with UserID / UserPwd /
// VerNo filled in and isReceived = true.
// Returns the server Message.
// ------------------------------------------------------------
static Future<String> receiveMovableAsset({
  required String userId,
  required String userPwd,
  required MaReceiveRow row,
}) async {
  try {
    final uri = Uri.parse("${baseUrl}movableAssetReceivedsave").replace(
      queryParameters: {
        "UserID": userId,
        "UserPwd": userPwd,
        "VerNo": AppConfig.verNo.toString(),
      },
    );

    final body = row.toSaveJson(
      userId: userId,
      userPwd: userPwd,
      verNo: AppConfig.verNo,
    );

    print("========================================");
    print("MOVABLE ASSET RECEIVE SAVE API");
    print("ROW => ${row.key}");
    print("========================================");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("MA RECEIVE SAVE STATUS => ${response.statusCode}");
    print("MA RECEIVE SAVE RESPONSE => ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["StatusCode"] == 200) {
      return (data["Message"] ?? "").toString();
    }

    throw Exception(
      (data["Message"] ?? "Failed to receive asset.").toString(),
    );
  } catch (e) {
    print("MA RECEIVE SAVE ERROR => $e");
    throw Exception(e.toString().replaceFirst("Exception: ", ""));
  }
}

}

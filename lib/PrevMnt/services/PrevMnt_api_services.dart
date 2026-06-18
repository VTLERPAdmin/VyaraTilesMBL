import 'dart:convert';
import 'package:http/http.dart' as http;

class PrevMntApiService {

  // ================= LOGIN (PrevMntAuth) =================
  static Future<Map<String, dynamic>> login(
      String user,
      String pass,
  ) async {
    final response = await http.get(
      Uri.parse(
        "https://vyaratiles.co.in/API/PrevMntAuth?UserID=$user&UserPwd=$pass",
      ),
    );

    return jsonDecode(response.body);
  }

  // ================= EQUIPMENT DETAILS =================
  static Future<Map<String, dynamic>> getEquipmentList(
      int empId,
      int eqTypeId,
  ) async {
    final response = await http.get(
      Uri.parse(
        "https://vyaratiles.co.in/API/PrevMntEqType?EmpID=$empId&EqTypeID=$eqTypeId",
      ),
    );

    return jsonDecode(response.body);
  }

  // ================= TASK DETAILS =================
  static Future<Map<String, dynamic>> getTaskList(
    int empId,
    int eqId,
  ) async {
    final response = await http.get(
      Uri.parse(
        "https://vyaratiles.co.in/API/PrevMntEq?EmpID=$empId&EqID=$eqId",
      ),
    );

    return jsonDecode(response.body);
  }

  // ================= SAVE TASK =================
  static Future<Map<String, dynamic>> saveTask(
      List<dynamic> taskList,
  ) async {
    final url = Uri.parse(
      "https://vyaratiles.co.in/API/PrevMntTask",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(taskList),
    );

    return jsonDecode(response.body);
  }

  // ================= PREV MNT TASK (FIXED) =================
  static Future<dynamic> getPrevMntTask() async {
  final response = await http.post(
    Uri.parse("https://vyaratiles.co.in/API/PrevMntTask"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({}),
  );

  return jsonDecode(response.body);
}
}
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  // =========================
  // SAVE LOGIN SESSION
  // =========================
  static Future<void> saveSession({
    required String userId,
    required String password,
    required dynamic userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("userId", userId);
    await prefs.setString("password", password);
    await prefs.setString("userData", jsonEncode(userData));

    // Optional fallback
    await prefs.setString("lastUserId", userId);

    final name = userData["Message"]?.toString() ?? "";
    await prefs.setString("userName", name);

    // ERP access control menus
    final menus = List<String>.from(
      userData["Menus"] ?? [],
    );

    await prefs.setStringList("menus", menus);

    print("✅ SESSION SAVED");
    print("USER ID => $userId");
    print("USER NAME => $name");
    print("MENUS => $menus");
  }

  // =========================
  // GET FULL SESSION
  // =========================
  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString("userId");
    final password = prefs.getString("password");
    final userDataString = prefs.getString("userData");

    print("📦 GET SESSION");
    print("USER => $userId");

    if (userId == null || password == null) {
      print("❌ SESSION NULL");
      return null;
    }

    print("✅ SESSION FOUND");

    return {
      "userId": userId,
      "password": password,
      "userData": jsonDecode(userDataString ?? "{}"),
    };
  }

  // =========================
  // GET USER ID
  // =========================
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("userId") ?? "";
  }

  // =========================
  // GET PASSWORD
  // =========================
  static Future<String> getPassword() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("password") ?? "";
  }

  // =========================
  // GET USER NAME
  // =========================
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("userName") ?? "";
  }

  // =========================
  // CLEAR SESSION
  // =========================
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("userId");
    await prefs.remove("password");
    await prefs.remove("userData");
    await prefs.remove("userName");
    await prefs.remove("menus");

    print("SESSION CLEARED COMPLETELY");
  }
}
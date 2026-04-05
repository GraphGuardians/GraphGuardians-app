import 'dart:convert';
import 'dart:developer';
import 'package:graph_guard/repomodel.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../dashboard/dashboard_model.dart';
import '../vulnerabilities/vulnerabilities_screen.dart';
import '../alerts/alerts_screen.dart';

class ApiService {
  static const String baseUrl = "https://graphguardians-backend.onrender.com";

  static final box = GetStorage();

  static String? get token => box.read("token");

  static Map<String, String> get headers {
    final t = token;
    return {
      "Content-Type": "application/json",
      if (t != null) "Authorization": "Bearer $t",
    };
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        box.write("token", data["token"]);
        box.write("user", data["user"]);
        return data;
      } else {
        throw Exception(data["message"] ?? "Login failed");
      }
    } catch (e) {
      throw Exception("Login Error: $e");
    }
  }

  static Future<List<RepoModel>> getRepos() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/repos"),
        headers: headers,
      );
      log("==== API DEBUG START ====");
      log("STATUS CODE: ${res.statusCode}");
      log("RESPONSE BODY: ${res.body}");
      log("TOKEN USED: $token");
      log("==== API DEBUG END ====");

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final parsed = data is List ? data : data["data"];
        return (parsed as List).map((e) => RepoModel.fromJson(e)).toList();
      } else {
        throw Exception(data["message"] ?? "Failed to fetch repos");
      }
    } catch (e) {
      throw Exception("Repo Error: $e");
    }
  }

  static Future<DashboardModel?> getDashboard(String repoId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/dashboard/$repoId"),
        headers: headers,
      );
      log("==== DASHBOARD API DEBUG START ====");
      log("URL: $baseUrl/api/dashboard/$repoId");
      log("STATUS CODE: ${res.statusCode}");
      log("RESPONSE BODY: ${res.body}");
      log("TOKEN USED: $token");
      log("==== DASHBOARD API DEBUG END ====");

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return DashboardModel.fromJson(data);
      } else {
        throw Exception(data["message"] ?? "Failed to fetch dashboard");
      }
    } catch (e) {
      log("Dashboard Error: $e");
      return null;
    }
  }

  static Future<List<dynamic>> getVulnerabilities(String repoId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/vulnerabilities/$repoId"),
        headers: headers,
      );
      log("==== VULN API DEBUG START ====");
      log("STATUS CODE: ${res.statusCode}");
      log("RESPONSE BODY: ${res.body}");
      log("==== VULN API DEBUG END ====");

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data['vulnerabilities'] ?? data ?? [];
      } else {
        throw Exception(data["message"] ?? "Failed to fetch vulnerabilities");
      }
    } catch (e) {
      log("Vulnerabilities Error: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getAlerts(String repoId) async {
    try {
      final uri = Uri.parse(
        "$baseUrl/api/alerts",
      ).replace(queryParameters: {"repo": repoId});

      final res = await http.get(uri, headers: headers);

      log("==== ALERTS API DEBUG START ====");
      log("URL: $uri");
      log("STATUS CODE: ${res.statusCode}");
      log("RESPONSE BODY: ${res.body}");
      log("==== ALERTS API DEBUG END ====");

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return data['alerts'] ?? data ?? [];
      } else {
        throw Exception(data["msg"] ?? "Failed to fetch alerts");
      }
    } catch (e) {
      log("Alerts Error: $e");
      return [];
    }
  }

  static Future<void> saveDeviceToken(String fcmToken) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/user/save-device-token"),
        headers: headers,
        body: jsonEncode({"token": fcmToken}),
      );
      if (res.statusCode != 200) {
        throw Exception("Failed to save FCM token");
      }
    } catch (e) {
      log("FCM Save Error: $e");
    }
  }

  static void logout() {
    box.remove("token");
    box.remove("user");
  }
}

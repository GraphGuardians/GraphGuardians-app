import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get_storage/get_storage.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';

class LoginController extends GetxController {
  var isLoading = false.obs;
  final box = GetStorage();

  // 🔥 GitHub Login
  Future<void> loginWithGithub() async {
    try {
      isLoading(true);

      final url = Uri.parse(
        "https://graphguardians-backend.onrender.com/api/auth/github?state=app",
      );

      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar("Error", "Failed to open GitHub login");
    } finally {
      isLoading(false);
    }
  }

  // 🔥 Callback Handler (FIXED)
  Future<void> handleGithubCallback(Uri uri) async {
    try {
      final token = uri.queryParameters['token'];

      if (token == null) {
        Get.snackbar("Error", "Token not found");
        return;
      }

      box.write("token", token);

      String? fcmToken = await FCMService.getToken();

      if (fcmToken != null) {
        await ApiService.saveDeviceToken(fcmToken);
      }

      Get.offAllNamed("/repos");
    } catch (e) {
      Get.snackbar("Error", "Login failed");
    }
  }
}

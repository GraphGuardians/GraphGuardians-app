import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';

import 'package:graph_guard/modules/auth/login_controller.dart';
import 'routes/app_routes.dart';
import 'modules/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();

  await FCMService.init();

  final loginController = Get.put(LoginController());

  // 🔥 INIT DEEP LINKS (NEW WAY)
  await initDeepLinks(loginController);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/splash",
      getPages: AppRoutes.routes,
    );
  }
}

/// 🔥 UPDATED DEEP LINK HANDLER (app_links)
Future<void> initDeepLinks(LoginController controller) async {
  final appLinks = AppLinks();

  try {
    // 🔹 Cold start
    final Uri? initialUri = await appLinks.getInitialAppLink();
    if (initialUri != null) {
      log("📥 Initial URI: $initialUri");
      controller.handleGithubCallback(initialUri);
    }
  } catch (e) {
    log("❌ Initial URI Error: $e");
  }

  // 🔹 Background / running app
  appLinks.uriLinkStream.listen(
    (Uri uri) {
      log("🔗 Incoming URI: $uri");
      controller.handleGithubCallback(uri);
    },
    onError: (err) {
      log("❌ Deep Link Error: $err");
    },
  );
}

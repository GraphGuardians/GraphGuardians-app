import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SplashController extends GetxController {
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    checkLogin();
  }

  void checkLogin() async {
    await Future.delayed(Duration(seconds: 2));

    String? token = box.read("token");

    if (token != null) {
      Get.offAllNamed("/repos");
    } else {
      Get.offAllNamed("/login");
    }
    _checkPendingNotification();
  }

  void _checkPendingNotification() {
    final repoId = box.read<String>('pending_notif_repo_id');
    if (repoId == null || repoId.isEmpty) return;

    box.remove('pending_notif_repo_id'); // ek baar use karo, hatao

    // offAllNamed settle hone ka thoda wait
    Future.delayed(Duration(milliseconds: 600), () {
      Get.toNamed('/alert-detail', arguments: repoId);
    });
  }
}

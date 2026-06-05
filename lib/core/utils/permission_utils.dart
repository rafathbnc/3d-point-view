import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  PermissionUtils._();

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestPhotoLibrary() async {
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  static Future<bool> hasPhotoPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted || status.isLimited;
  }

  static Future<void> openSettings() => openAppSettings();
}

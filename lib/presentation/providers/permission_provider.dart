import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/permission_utils.dart';

class PermissionStatus {
  final bool camera;
  final bool photos;

  const PermissionStatus({required this.camera, required this.photos});

  bool get allGranted => camera && photos;

  static const unknown = PermissionStatus(camera: false, photos: false);
}

class PermissionNotifier extends Notifier<PermissionStatus> {
  @override
  PermissionStatus build() => PermissionStatus.unknown;

  Future<void> checkAll() async {
    final camera = await PermissionUtils.hasCameraPermission();
    final photos = await PermissionUtils.hasPhotoPermission();
    state = PermissionStatus(camera: camera, photos: photos);
  }

  Future<void> requestAll() async {
    final camera = await PermissionUtils.requestCamera();
    final photos = await PermissionUtils.requestPhotoLibrary();
    state = PermissionStatus(camera: camera, photos: photos);
  }
}

final permissionProvider =
    NotifierProvider<PermissionNotifier, PermissionStatus>(
  PermissionNotifier.new,
);

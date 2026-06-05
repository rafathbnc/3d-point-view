import 'package:go_router/go_router.dart';
import '../../domain/entities/saved_capture.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/camera/camera_screen.dart';
import '../../presentation/screens/point_cloud/point_cloud_screen.dart';
import '../../presentation/screens/gallery/gallery_screen.dart';
import '../../presentation/screens/capture_viewer/capture_viewer_screen.dart';

class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String camera = '/camera';
  static const String pointCloud = '/point-cloud';
  static const String gallery = '/gallery';
  static const String captureViewer = '/capture-viewer';

  static final GoRouter router = GoRouter(
    initialLocation: camera,
    routes: [
      GoRoute(path: home, builder: (ctx, state) => const HomeScreen()),
      GoRoute(path: camera, builder: (ctx, state) => const CameraScreen()),
      GoRoute(
        path: pointCloud,
        builder: (ctx, state) => const PointCloudScreen(),
      ),
      GoRoute(path: gallery, builder: (ctx, state) => const GalleryScreen()),
      GoRoute(
        path: captureViewer,
        builder: (ctx, state) => CaptureViewerScreen(
          capture: state.extra! as SavedCapture,
        ),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/channel_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/ar_session_provider.dart';
import '../../providers/capture_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import 'widgets/camera_controls_overlay.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  late final ARSessionNotifier _arNotifier;

  @override
  void initState() {
    super.initState();
    _arNotifier = ref.read(arSessionProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _arNotifier.start();
    });
  }

  @override
  void dispose() {
    _arNotifier.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(arSessionProvider);
    final captureState = ref.watch(captureProvider);

    // When the point cloud screen pops, it stops the session. Restart it here.
    ref.listen(arSessionProvider, (_, next) {
      if (next.status == ARSessionStatus.idle && mounted) {
        _arNotifier.start();
      }
    });

    final isLoading = sessionState.status == ARSessionStatus.starting;
    final isSaving = captureState.status == CaptureStatus.saving;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Native AR camera preview
          UiKitView(
            viewType: ChannelConstants.metalViewType,
            creationParams: const {'mode': 'camera'},
            creationParamsCodec: const StandardMessageCodec(),
          ),

          // Controls overlay (back, flash, shutter)
          const CameraControlsOverlay(),

          // Loading state
          if (isLoading)
            const LoadingOverlay(message: 'Starting camera...'),

          // Saving state
          if (isSaving)
            const LoadingOverlay(message: 'Saving capture...'),

          // Error state
          if (sessionState.status == ARSessionStatus.error)
            Positioned(
              bottom: 120,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  sessionState.errorMessage ?? 'Camera error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

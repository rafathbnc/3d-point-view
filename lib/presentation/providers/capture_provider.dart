import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/saved_capture.dart';
import '../../domain/repositories/file_storage_repository.dart';
import 'providers.dart';
import 'gallery_provider.dart';

enum CaptureStatus { idle, capturing, saving, done, error }

class CaptureState {
  final CaptureStatus status;
  final SavedCapture? lastCapture;
  final String? errorMessage;

  const CaptureState({
    required this.status,
    this.lastCapture,
    this.errorMessage,
  });

  static const idle = CaptureState(status: CaptureStatus.idle);
}

class CaptureNotifier extends Notifier<CaptureState> {
  @override
  CaptureState build() => CaptureState.idle;

  Future<void> captureAndSave({
    ExportFormat format = ExportFormat.both,
    String? name,
  }) async {
    state = const CaptureState(status: CaptureStatus.capturing);

    final captureUseCase = ref.read(captureFrameUseCaseProvider);
    final frameResult = await captureUseCase();

    if (frameResult.isLeft()) {
      state = CaptureState(
        status: CaptureStatus.error,
        errorMessage: frameResult.getLeft().toNullable()?.message,
      );
      return;
    }

    final frame = frameResult.getRight().toNullable()!;
    state = const CaptureState(status: CaptureStatus.saving);

    final label = name ??
        'Capture ${DateTime.now().toLocal().toString().substring(0, 16)}';
    final saveUseCase = ref.read(savePointCloudUseCaseProvider);
    final saveResult = await saveUseCase(
      frame: frame,
      name: label,
      format: format,
    );

    saveResult.fold(
      (f) => state =
          CaptureState(status: CaptureStatus.error, errorMessage: f.message),
      (capture) {
        state = CaptureState(status: CaptureStatus.done, lastCapture: capture);
        ref.read(galleryProvider.notifier).refresh();
      },
    );
  }

  void reset() => state = CaptureState.idle;
}

final captureProvider = NotifierProvider<CaptureNotifier, CaptureState>(
  CaptureNotifier.new,
);

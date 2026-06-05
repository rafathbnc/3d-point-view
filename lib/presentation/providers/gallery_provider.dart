import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/saved_capture.dart';
import 'providers.dart';

class GalleryNotifier extends AsyncNotifier<List<SavedCapture>> {
  @override
  Future<List<SavedCapture>> build() async {
    final useCase = ref.read(loadSavedCapturesUseCaseProvider);
    final result = await useCase();
    return result.fold((_) => [], (list) => list);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(loadSavedCapturesUseCaseProvider);
      final result = await useCase();
      return result.fold((_) => <SavedCapture>[], (list) => list);
    });
  }

  Future<void> delete(String id) async {
    final repo = ref.read(fileStorageRepositoryProvider);
    await repo.deleteCapture(id);
    await refresh();
  }

  Future<void> rename(String id, String newName) async {
    final repo = ref.read(fileStorageRepositoryProvider);
    await repo.renameCapture(id, newName);
    await refresh();
  }
}

final galleryProvider =
    AsyncNotifierProvider<GalleryNotifier, List<SavedCapture>>(
  GalleryNotifier.new,
);

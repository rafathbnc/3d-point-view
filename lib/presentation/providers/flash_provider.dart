import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';

final flashProvider = StateProvider<bool>((_) => false);

// Toggles flash and syncs with native layer.
Future<void> toggleFlash(WidgetRef ref) async {
  final current = ref.read(flashProvider);
  ref.read(flashProvider.notifier).state = !current;
  final repo = ref.read(arSessionRepositoryProvider);
  await repo.setFlash(on: !current);
}

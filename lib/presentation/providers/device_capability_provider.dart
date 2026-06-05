import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';

class DeviceCapability {
  final bool hasLiDAR;
  const DeviceCapability({required this.hasLiDAR});
}

final deviceCapabilityProvider = FutureProvider<DeviceCapability>((ref) async {
  final repo = ref.read(arSessionRepositoryProvider);
  final result = await repo.checkLiDARAvailability();
  return result.fold(
    (_) => const DeviceCapability(hasLiDAR: false),
    (hasLiDAR) => DeviceCapability(hasLiDAR: hasLiDAR),
  );
});

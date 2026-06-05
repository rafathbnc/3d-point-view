import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/point_cloud.dart';
import 'providers.dart';

// Streams live point cloud frames from the EventChannel.
final pointCloudStreamProvider = StreamProvider<PointCloud>((ref) {
  final repo = ref.watch(pointCloudRepositoryProvider);
  return repo.pointCloudStream.where((e) => e.isRight()).map((e) => e.getRight().toNullable()!);
});

// Latest delivered point cloud for rendering.
final latestPointCloudProvider = Provider<PointCloud?>((ref) {
  return ref.watch(pointCloudStreamProvider).valueOrNull;
});

// Exposed point count for the HUD overlay.
final pointCountProvider = Provider<int>((ref) {
  return ref.watch(latestPointCloudProvider)?.pointCount ?? 0;
});

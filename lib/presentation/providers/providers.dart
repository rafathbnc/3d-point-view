// Central DI barrel — all Riverpod providers live or are re-exported from here.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ar_session_datasource.dart';
import '../../data/datasources/file_storage_datasource.dart';
import '../../data/datasources/point_cloud_event_datasource.dart';
import '../../data/repositories/ar_session_repository_impl.dart';
import '../../data/repositories/file_storage_repository_impl.dart';
import '../../data/repositories/point_cloud_repository_impl.dart';
import '../../domain/repositories/ar_session_repository.dart';
import '../../domain/repositories/file_storage_repository.dart';
import '../../domain/repositories/point_cloud_repository.dart';
import '../../domain/usecases/capture_frame_usecase.dart';
import '../../domain/usecases/load_saved_captures_usecase.dart';
import '../../domain/usecases/save_point_cloud_usecase.dart';
import '../../domain/usecases/start_ar_session_usecase.dart';
import '../../domain/usecases/stop_ar_session_usecase.dart';

// ── Data sources ─────────────────────────────────────────────────────────────

final arSessionDataSourceProvider = Provider<ARSessionDataSource>(
  (_) => ARSessionDataSource(),
);

final pointCloudEventDataSourceProvider = Provider<PointCloudEventDataSource>(
  (_) => PointCloudEventDataSource(),
);

final fileStorageDataSourceProvider = Provider<FileStorageDataSource>(
  (_) => FileStorageDataSource(),
);

// ── Repositories ──────────────────────────────────────────────────────────────

final arSessionRepositoryProvider = Provider<ARSessionRepository>(
  (ref) => ARSessionRepositoryImpl(ref.read(arSessionDataSourceProvider)),
);

final pointCloudRepositoryProvider = Provider<PointCloudRepository>(
  (ref) =>
      PointCloudRepositoryImpl(ref.read(pointCloudEventDataSourceProvider)),
);

final fileStorageRepositoryProvider = Provider<FileStorageRepository>(
  (ref) =>
      FileStorageRepositoryImpl(ref.read(fileStorageDataSourceProvider)),
);

// ── Use cases ─────────────────────────────────────────────────────────────────

final startARSessionUseCaseProvider = Provider<StartARSessionUseCase>(
  (ref) => StartARSessionUseCase(ref.read(arSessionRepositoryProvider)),
);

final stopARSessionUseCaseProvider = Provider<StopARSessionUseCase>(
  (ref) => StopARSessionUseCase(ref.read(arSessionRepositoryProvider)),
);

final captureFrameUseCaseProvider = Provider<CaptureFrameUseCase>(
  (ref) => CaptureFrameUseCase(ref.read(arSessionRepositoryProvider)),
);

final savePointCloudUseCaseProvider = Provider<SavePointCloudUseCase>(
  (ref) => SavePointCloudUseCase(ref.read(fileStorageRepositoryProvider)),
);

final loadSavedCapturesUseCaseProvider = Provider<LoadSavedCapturesUseCase>(
  (ref) =>
      LoadSavedCapturesUseCase(ref.read(fileStorageRepositoryProvider)),
);

import 'package:fpdart/fpdart.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/captured_frame.dart';
import '../../domain/repositories/ar_session_repository.dart';
import '../datasources/ar_session_datasource.dart';
import '../models/captured_frame_model.dart';

class ARSessionRepositoryImpl implements ARSessionRepository {
  final ARSessionDataSource _dataSource;
  ARSessionRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, bool>> checkLiDARAvailability() =>
      _dataSource.checkLiDARAvailability();

  @override
  Future<Either<Failure, void>> startSession() => _dataSource.startSession();

  @override
  Future<Either<Failure, void>> stopSession() => _dataSource.stopSession();

  @override
  Future<Either<Failure, CapturedFrame>> captureFrame() async {
    final result = await _dataSource.captureFrame();
    return result.map(CapturedFrameModel.fromMap);
  }

  @override
  Future<Either<Failure, void>> setFlash({required bool on}) =>
      _dataSource.setFlash(on: on);
}

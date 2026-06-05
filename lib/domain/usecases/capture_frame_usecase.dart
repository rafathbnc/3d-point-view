import 'package:fpdart/fpdart.dart';
import '../entities/captured_frame.dart';
import '../repositories/ar_session_repository.dart';
import '../../core/errors/failures.dart';

class CaptureFrameUseCase {
  final ARSessionRepository _repository;
  CaptureFrameUseCase(this._repository);

  Future<Either<Failure, CapturedFrame>> call() => _repository.captureFrame();
}

import 'package:fpdart/fpdart.dart';
import '../entities/captured_frame.dart';
import '../../core/errors/failures.dart';

abstract class ARSessionRepository {
  Future<Either<Failure, bool>> checkLiDARAvailability();
  Future<Either<Failure, void>> startSession();
  Future<Either<Failure, void>> stopSession();
  Future<Either<Failure, CapturedFrame>> captureFrame();
  Future<Either<Failure, void>> setFlash({required bool on});
}

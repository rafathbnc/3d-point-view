import 'package:fpdart/fpdart.dart';
import '../repositories/ar_session_repository.dart';
import '../../core/errors/failures.dart';

class StopARSessionUseCase {
  final ARSessionRepository _repository;
  StopARSessionUseCase(this._repository);

  Future<Either<Failure, void>> call() => _repository.stopSession();
}

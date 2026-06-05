import 'package:fpdart/fpdart.dart';
import '../repositories/ar_session_repository.dart';
import '../../core/errors/failures.dart';

class StartARSessionUseCase {
  final ARSessionRepository _repository;
  StartARSessionUseCase(this._repository);

  Future<Either<Failure, void>> call() => _repository.startSession();
}

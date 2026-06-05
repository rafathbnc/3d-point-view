import 'package:fpdart/fpdart.dart';
import '../entities/saved_capture.dart';
import '../repositories/file_storage_repository.dart';
import '../../core/errors/failures.dart';

class LoadSavedCapturesUseCase {
  final FileStorageRepository _repository;
  LoadSavedCapturesUseCase(this._repository);

  Future<Either<Failure, List<SavedCapture>>> call() =>
      _repository.loadAllCaptures();
}

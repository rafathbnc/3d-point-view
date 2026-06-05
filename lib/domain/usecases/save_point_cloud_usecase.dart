import 'package:fpdart/fpdart.dart';
import '../entities/captured_frame.dart';
import '../entities/saved_capture.dart';
import '../repositories/file_storage_repository.dart';
import '../../core/errors/failures.dart';

class SavePointCloudUseCase {
  final FileStorageRepository _repository;
  SavePointCloudUseCase(this._repository);

  Future<Either<Failure, SavedCapture>> call({
    required CapturedFrame frame,
    required String name,
    required ExportFormat format,
  }) =>
      _repository.saveCapture(frame: frame, name: name, format: format);
}

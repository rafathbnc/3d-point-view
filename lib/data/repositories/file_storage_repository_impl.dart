import 'package:fpdart/fpdart.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/file_utils.dart';
import '../../domain/entities/captured_frame.dart';
import '../../domain/entities/saved_capture.dart';
import '../../domain/repositories/file_storage_repository.dart';
import '../datasources/file_storage_datasource.dart';

class FileStorageRepositoryImpl implements FileStorageRepository {
  final FileStorageDataSource _dataSource;
  FileStorageRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, SavedCapture>> saveCapture({
    required CapturedFrame frame,
    required String name,
    required ExportFormat format,
  }) async {
    try {
      final id = FileUtils.generateId();
      final capture = await _dataSource.saveCapture(
        frame: frame,
        name: name,
        format: format,
        id: id,
      );
      return Right(capture);
    } catch (e) {
      return Left(FileIOFailure('Save failed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SavedCapture>>> loadAllCaptures() async {
    try {
      final captures = await _dataSource.loadAllCaptures();
      return Right(captures);
    } catch (e) {
      return Left(FileIOFailure('Load failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCapture(String id) async {
    try {
      await _dataSource.deleteCapture(id);
      return const Right(null);
    } catch (e) {
      return Left(FileIOFailure('Delete failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> renameCapture(
      String id, String newName) async {
    try {
      await _dataSource.renameCapture(id, newName);
      return const Right(null);
    } catch (e) {
      return Left(FileIOFailure('Rename failed: $e'));
    }
  }
}

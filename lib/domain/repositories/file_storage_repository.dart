import 'package:fpdart/fpdart.dart';
import '../entities/captured_frame.dart';
import '../entities/saved_capture.dart';
import '../../core/errors/failures.dart';

enum ExportFormat { ply, xyz, both }

abstract class FileStorageRepository {
  Future<Either<Failure, SavedCapture>> saveCapture({
    required CapturedFrame frame,
    required String name,
    required ExportFormat format,
  });
  Future<Either<Failure, List<SavedCapture>>> loadAllCaptures();
  Future<Either<Failure, void>> deleteCapture(String id);
  Future<Either<Failure, void>> renameCapture(String id, String newName);
}

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

class FileUtils {
  FileUtils._();

  static const _uuid = Uuid();

  static String generateId() => _uuid.v4();

  static Future<Directory> getCapturesDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, AppConstants.capturesDirectoryName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> getCapturesMetadataFile() async {
    final dir = await getCapturesDirectory();
    return File(p.join(dir.path, AppConstants.metadataFileName));
  }

  static String plyPath(Directory dir, String id) => p.join(dir.path, '$id.ply');
  static String xyzPath(Directory dir, String id) => p.join(dir.path, '$id.xyz');
  static String objPath(Directory dir, String id) => p.join(dir.path, '$id.obj');
  static String thumbnailPath(Directory dir, String id) =>
      p.join(dir.path, '${id}_thumb.jpg');
}

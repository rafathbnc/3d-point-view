import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../core/utils/file_utils.dart';
import '../../domain/entities/captured_frame.dart';
import '../../domain/entities/saved_capture.dart';
import '../../domain/repositories/file_storage_repository.dart';
import '../models/saved_capture_model.dart';

class FileStorageDataSource {
  Future<SavedCapture> saveCapture({
    required CapturedFrame frame,
    required String name,
    required ExportFormat format,
    required String id,
  }) async {
    final dir = await FileUtils.getCapturesDirectory();

    // Generate thumbnail from RGBA image
    final thumbPath = FileUtils.thumbnailPath(dir, id);
    await _writeThumbnail(
      frame.rgbaImage,
      frame.imageWidth,
      frame.imageHeight,
      thumbPath,
    );

    String? plyFilePath;
    String? xyzFilePath;

    if (format == ExportFormat.ply || format == ExportFormat.both) {
      plyFilePath = FileUtils.plyPath(dir, id);
      await _writePLY(frame, plyFilePath);
    }

    if (format == ExportFormat.xyz || format == ExportFormat.both) {
      xyzFilePath = FileUtils.xyzPath(dir, id);
      await _writeXYZ(frame, xyzFilePath);
    }

    final objFilePath = FileUtils.objPath(dir, id);
    await _writeOBJ(frame, objFilePath);

    final capture = SavedCaptureModel(
      id: id,
      name: name,
      thumbnailPath: thumbPath,
      plyPath: plyFilePath,
      xyzPath: xyzFilePath,
      objPath: objFilePath,
      pointCount: frame.pointCloud.pointCount,
      savedAt: frame.timestamp,
    );

    await _appendMetadata(capture);
    return capture;
  }

  Future<List<SavedCapture>> loadAllCaptures() async {
    final metaFile = await FileUtils.getCapturesMetadataFile();
    if (!await metaFile.exists()) return [];
    final content = await metaFile.readAsString();
    final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
    return jsonList
        .cast<Map<String, dynamic>>()
        .map(SavedCaptureModel.fromJson)
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> deleteCapture(String id) async {
    final dir = await FileUtils.getCapturesDirectory();
    for (final path in [
      FileUtils.plyPath(dir, id),
      FileUtils.xyzPath(dir, id),
      FileUtils.objPath(dir, id),
      FileUtils.thumbnailPath(dir, id),
    ]) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    await _removeMetadata(id);
  }

  Future<void> _writeThumbnail(
    Uint8List rgba,
    int width,
    int height,
    String path,
  ) async {
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgba.buffer,
      format: img.Format.uint8,
      numChannels: 4,
    );
    final resized = img.copyResize(image, width: 320);
    final jpeg = img.encodeJpg(resized, quality: 75);
    await File(path).writeAsBytes(jpeg);
  }

  Future<void> _writePLY(CapturedFrame frame, String path) async {
    final points = frame.pointCloud.points;
    final count = frame.pointCloud.pointCount;

    final header = 'ply\r\n'
        'format binary_little_endian 1.0\r\n'
        'element vertex $count\r\n'
        'property float x\r\n'
        'property float y\r\n'
        'property float z\r\n'
        'property uchar red\r\n'
        'property uchar green\r\n'
        'property uchar blue\r\n'
        'end_header\r\n';

    final headerBytes = ascii.encode(header);
    // 15 bytes per vertex: 3×float32 (12) + 3×uint8 (3)
    final vertexData = ByteData(count * 15);
    int offset = 0;
    for (int i = 0; i < count * 6; i += 6) {
      vertexData.setFloat32(offset, points[i], Endian.little);
      offset += 4;
      vertexData.setFloat32(offset, points[i + 1], Endian.little);
      offset += 4;
      vertexData.setFloat32(offset, points[i + 2], Endian.little);
      offset += 4;
      vertexData.setUint8(offset, (points[i + 3] * 255).clamp(0, 255).toInt());
      offset++;
      vertexData.setUint8(offset, (points[i + 4] * 255).clamp(0, 255).toInt());
      offset++;
      vertexData.setUint8(offset, (points[i + 5] * 255).clamp(0, 255).toInt());
      offset++;
    }

    final sink = File(path).openWrite();
    sink.add(headerBytes);
    sink.add(vertexData.buffer.asUint8List());
    await sink.close();
  }

  Future<void> _writeOBJ(CapturedFrame frame, String path) async {
    final points = frame.pointCloud.points;
    final count = frame.pointCloud.pointCount;
    final buf = StringBuffer();
    buf.writeln('# NemiVision point cloud OBJ');
    buf.writeln('# Points: $count');
    for (int i = 0; i < count * 6; i += 6) {
      final r = (points[i + 3] * 255).clamp(0, 255).toInt();
      final g = (points[i + 4] * 255).clamp(0, 255).toInt();
      final b = (points[i + 5] * 255).clamp(0, 255).toInt();
      buf.writeln(
        'v ${points[i].toStringAsFixed(6)} ${points[i + 1].toStringAsFixed(6)} ${points[i + 2].toStringAsFixed(6)} '
        '${(r / 255.0).toStringAsFixed(4)} ${(g / 255.0).toStringAsFixed(4)} ${(b / 255.0).toStringAsFixed(4)}',
      );
    }
    await File(path).writeAsString(buf.toString(), encoding: ascii);
  }

  Future<void> _writeXYZ(CapturedFrame frame, String path) async {
    final points = frame.pointCloud.points;
    final count = frame.pointCloud.pointCount;
    final buf = StringBuffer();
    buf.writeln('# PointCloud Capture - ${frame.timestamp.toIso8601String()}');
    buf.writeln('# Points: $count');
    buf.writeln('x y z r g b');
    for (int i = 0; i < count * 6; i += 6) {
      final r = (points[i + 3] * 255).clamp(0, 255).toInt();
      final g = (points[i + 4] * 255).clamp(0, 255).toInt();
      final b = (points[i + 5] * 255).clamp(0, 255).toInt();
      buf.writeln(
        '${points[i].toStringAsFixed(6)} ${points[i + 1].toStringAsFixed(6)} ${points[i + 2].toStringAsFixed(6)} $r $g $b',
      );
    }
    await File(path).writeAsString(buf.toString(), encoding: ascii);
  }

  Future<void> _appendMetadata(SavedCaptureModel capture) async {
    final file = await FileUtils.getCapturesMetadataFile();
    List<dynamic> existing = [];
    if (await file.exists()) {
      try {
        existing = jsonDecode(await file.readAsString()) as List<dynamic>;
      } catch (_) {
        existing = [];
      }
    }
    existing.add(capture.toJson());
    await file.writeAsString(jsonEncode(existing));
  }

  Future<void> renameCapture(String id, String newName) async {
    final file = await FileUtils.getCapturesMetadataFile();
    if (!await file.exists()) return;
    final List<dynamic> list =
        jsonDecode(await file.readAsString()) as List<dynamic>;
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      if (m['id'] == id) {
        m['name'] = newName;
        break;
      }
    }
    await file.writeAsString(jsonEncode(list));
  }

  Future<void> _removeMetadata(String id) async {
    final file = await FileUtils.getCapturesMetadataFile();
    if (!await file.exists()) return;
    final List<dynamic> list =
        jsonDecode(await file.readAsString()) as List<dynamic>;
    list.removeWhere((e) => (e as Map<String, dynamic>)['id'] == id);
    await file.writeAsString(jsonEncode(list));
  }
}

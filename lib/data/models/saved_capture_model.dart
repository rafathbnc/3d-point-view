import '../../domain/entities/saved_capture.dart';

class SavedCaptureModel extends SavedCapture {
  const SavedCaptureModel({
    required super.id,
    required super.name,
    required super.thumbnailPath,
    super.plyPath,
    super.xyzPath,
    super.objPath,
    required super.pointCount,
    required super.savedAt,
  });

  factory SavedCaptureModel.fromJson(Map<String, dynamic> json) {
    return SavedCaptureModel(
      id: json['id'] as String,
      name: json['name'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      plyPath: json['plyPath'] as String?,
      xyzPath: json['xyzPath'] as String?,
      objPath: json['objPath'] as String?,
      pointCount: json['pointCount'] as int,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'thumbnailPath': thumbnailPath,
        'plyPath': plyPath,
        'xyzPath': xyzPath,
        'objPath': objPath,
        'pointCount': pointCount,
        'savedAt': savedAt.toIso8601String(),
      };
}

class SavedCapture {
  final String id;
  final String name;
  final String thumbnailPath;
  final String? plyPath;
  final String? xyzPath;
  final String? objPath;
  final int pointCount;
  final DateTime savedAt;

  const SavedCapture({
    required this.id,
    required this.name,
    required this.thumbnailPath,
    this.plyPath,
    this.xyzPath,
    this.objPath,
    required this.pointCount,
    required this.savedAt,
  });
}

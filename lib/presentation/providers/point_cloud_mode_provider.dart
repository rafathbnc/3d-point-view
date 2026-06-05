import 'package:flutter_riverpod/flutter_riverpod.dart';

// true = point cloud mode, false = regular camera preview
final pointCloudModeProvider = StateProvider<bool>((_) => false);

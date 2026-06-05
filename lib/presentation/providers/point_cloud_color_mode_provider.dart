import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 0 = camera RGB (photorealistic), 1 = depth rainbow (blue=far, red=near)
final pointCloudColorModeProvider = StateProvider<int>((ref) => 0);

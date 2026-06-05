import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true while the user is long-pressing the capture button to accumulate frames
final accumulatingProvider = StateProvider<bool>((ref) => false);

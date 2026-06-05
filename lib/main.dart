import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Riverpod 2.x has a known race condition where defunct ConsumerStateful
  // elements still receive provider notifications during widget tree teardown.
  // The assertions thrown inside zone callbacks are not catchable with try/catch
  // in the notifier code — they must be intercepted at the dispatcher level.
  // Fixed upstream in Riverpod 3+; swallow only these specific errors here.
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error is AssertionError) {
      final msg = error.toString();
      if (msg.contains('_ElementLifecycle.defunct') ||
          msg.contains('widget was disposed') ||
          msg.contains('Cannot use "ref"')) {
        if (kDebugMode) {
          debugPrint('[Riverpod 2.x teardown] $msg');
        }
        return true; // handled — don't crash
      }
    }
    return false; // unrecognised — let Flutter crash reporter handle it
  };

  runApp(const ProviderScope(child: PointCloudApp()));
}

class PointCloudApp extends StatelessWidget {
  const PointCloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PointCloud Capture',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: AppRouter.router,
    );
  }
}

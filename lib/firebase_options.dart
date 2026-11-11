// PLACEHOLDER. `flutterfire configure` overwrites this file with your
// project's config. While it is a placeholder the app runs in demo mode.
//
// After running flutterfire, stop git from tracking your keys:
//   git update-index --skip-worktree lib/firebase_options.dart
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Firebase is not configured (lib/firebase_options.dart is the placeholder). '
        'Run `flutterfire configure` to connect a project.',
      );
}

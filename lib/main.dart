import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/backend.dart';
import 'data/demo_backend.dart';
import 'data/firebase_backend.dart';
import 'firebase_options.dart';
import 'state/app_state.dart';

/// Backend selection, e.g. `flutter run -d chrome --dart-define=BACKEND=demo`
///   auto     (default) Firebase if lib/firebase_options.dart is configured, else demo
///   demo     always the in-browser demo backend
///   firebase Firebase; fails loudly (with a banner) if it can't start
const _backendMode = String.fromEnvironment('BACKEND', defaultValue: 'auto');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (backend, error) = await _startBackend();
  final state = AppState(backend, firebaseError: error);
  // Stay signed in across page reloads / deep links.
  try {
    await state.restoreSession().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Session restore skipped: $e');
  }
  runApp(HungryHasteApp(state: state));
}

Future<(Backend, String?)> _startBackend() async {
  if (_backendMode == 'demo') return (await DemoBackend.create(), null);
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    return (FirebaseBackend(), null);
  } catch (e) {
    final reason = e is UnsupportedError ? e.message : '$e';
    debugPrint('Firebase unavailable, using demo backend: $reason');
    return (await DemoBackend.create(), _backendMode == 'firebase' ? reason : null);
  }
}

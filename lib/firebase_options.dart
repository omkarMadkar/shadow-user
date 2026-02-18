// ─── PLACEHOLDER — replace by running: flutterfire configure ───
// This file will be overwritten when you configure a real Firebase project.
// Until then the app runs in demo mode (no network calls).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '${defaultTargetPlatform.name} — run `flutterfire configure`.',
        );
    }
  }

  // TODO: Replace these with real values from `flutterfire configure`
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'PLACEHOLDER',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'shadow-sentinel-placeholder',
  );
}

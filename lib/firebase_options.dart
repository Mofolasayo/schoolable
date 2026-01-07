import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration generated from your platform config files.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported for this app');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAv29GwCzFypAHRFfD6Zx3h6TpZMwtxpqA',
    appId: '1:430702711255:android:c993fe580a218d7c1bbb92',
    messagingSenderId: '430702711255',
    projectId: 'spotify-clone-4d0ba',
    storageBucket: 'spotify-clone-4d0ba.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBshACjrxq0HdKbwz9vuga6u-ZsWjfmIS4',
    appId: '1:430702711255:ios:bfa27f7473ed41ff1bbb92',
    messagingSenderId: '430702711255',
    projectId: 'spotify-clone-4d0ba',
    storageBucket: 'spotify-clone-4d0ba.appspot.com',
    iosBundleId: 'com.schoolable.app',
  );

  static const FirebaseOptions macos = ios;
}

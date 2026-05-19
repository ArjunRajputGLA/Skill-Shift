import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyApWKbiiUbbMJ_w7tJZxaxNpZzw_oP8WxI',
    appId: '1:408596836150:web:d7a8e8093cc8f8303f8a4e', // fallback placeholder
    messagingSenderId: '408596836150',
    projectId: 'skillshift-7dd6a',
    storageBucket: 'skillshift-7dd6a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyApWKbiiUbbMJ_w7tJZxaxNpZzw_oP8WxI',
    appId: '1:408596836150:android:1ce2872c3a9cc4885ccd97',
    messagingSenderId: '408596836150',
    projectId: 'skillshift-7dd6a',
    storageBucket: 'skillshift-7dd6a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyApWKbiiUbbMJ_w7tJZxaxNpZzw_oP8WxI',
    appId: '1:408596836150:ios:placeholder', // fallback placeholder
    messagingSenderId: '408596836150',
    projectId: 'skillshift-7dd6a',
    storageBucket: 'skillshift-7dd6a.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyApWKbiiUbbMJ_w7tJZxaxNpZzw_oP8WxI',
    appId: '1:408596836150:ios:placeholder', // fallback placeholder
    messagingSenderId: '408596836150',
    projectId: 'skillshift-7dd6a',
    storageBucket: 'skillshift-7dd6a.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyApWKbiiUbbMJ_w7tJZxaxNpZzw_oP8WxI',
    appId: '1:408596836150:web:d7a8e8093cc8f8303f8a4e', // typical fallback for windows
    messagingSenderId: '408596836150',
    projectId: 'skillshift-7dd6a',
    storageBucket: 'skillshift-7dd6a.firebasestorage.app',
  );
}
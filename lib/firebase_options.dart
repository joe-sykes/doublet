import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
    apiKey: 'AIzaSyBvMAaIUvGYGdbb395XwZ0xDCdcfdVzwns',
    appId: '1:799401530846:web:b20e1ac1287c4b07a1394f',
    messagingSenderId: '799401530846',
    projectId: 'doublet-a7665',
    authDomain: 'doublet-a7665.firebaseapp.com',
    storageBucket: 'doublet-a7665.firebasestorage.app',
    measurementId: 'G-WLQ2EPM872',
  );

  // TODO: Configure these after running `flutterfire configure` for each platform
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBvMAaIUvGYGdbb395XwZ0xDCdcfdVzwns',
    appId: '1:799401530846:web:b20e1ac1287c4b07a1394f',
    messagingSenderId: '799401530846',
    projectId: 'doublet-a7665',
    storageBucket: 'doublet-a7665.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBvMAaIUvGYGdbb395XwZ0xDCdcfdVzwns',
    appId: '1:799401530846:web:b20e1ac1287c4b07a1394f',
    messagingSenderId: '799401530846',
    projectId: 'doublet-a7665',
    storageBucket: 'doublet-a7665.firebasestorage.app',
    iosBundleId: 'com.example.doublet',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBvMAaIUvGYGdbb395XwZ0xDCdcfdVzwns',
    appId: '1:799401530846:web:b20e1ac1287c4b07a1394f',
    messagingSenderId: '799401530846',
    projectId: 'doublet-a7665',
    storageBucket: 'doublet-a7665.firebasestorage.app',
    iosBundleId: 'com.example.doublet',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBvMAaIUvGYGdbb395XwZ0xDCdcfdVzwns',
    appId: '1:799401530846:web:b20e1ac1287c4b07a1394f',
    messagingSenderId: '799401530846',
    projectId: 'doublet-a7665',
    storageBucket: 'doublet-a7665.firebasestorage.app',
  );
}

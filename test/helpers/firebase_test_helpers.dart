import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';

class _TestFirebasePlatform extends FirebasePlatform {
  _TestFirebasePlatform()
      : _app = FirebaseAppPlatform(
          defaultFirebaseAppName,
          const FirebaseOptions(
            apiKey: 'test',
            appId: 'test',
            messagingSenderId: 'test',
            projectId: 'test',
          ),
        );

  final FirebaseAppPlatform _app;

  @override
  List<FirebaseAppPlatform> get apps => const [];

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return _app;
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return _app;
  }
}

void setupFirebaseCoreMocks() {
  Firebase.delegatePackingProperty = _TestFirebasePlatform();
  FirebaseMessagingPlatform.instance = _TestFirebaseMessagingPlatform();
}

class _TestFirebaseMessagingPlatform extends FirebaseMessagingPlatform {
  _TestFirebaseMessagingPlatform({FirebaseApp? app})
      : super(appInstance: app);

  bool _isAutoInitEnabled = true;

  @override
  FirebaseMessagingPlatform delegateFor({required FirebaseApp app}) {
    return _TestFirebaseMessagingPlatform(app: app);
  }

  @override
  FirebaseMessagingPlatform setInitialValues({bool? isAutoInitEnabled}) {
    _isAutoInitEnabled = isAutoInitEnabled ?? true;
    return this;
  }

  @override
  bool get isAutoInitEnabled => _isAutoInitEnabled;

  @override
  void registerBackgroundMessageHandler(BackgroundMessageHandler handler) {}
}

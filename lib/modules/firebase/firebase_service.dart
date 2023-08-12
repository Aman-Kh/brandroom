import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../models/entities/firebase_error_exception.dart';
import '../../models/entities/user.dart';
import '../../services/base_firebase_services.dart';
import '../../services/services.dart';
import 'dynamic_link_service.dart';
import 'firebase_analytics_service.dart';
import 'firebase_auth_service.dart';
import 'firebase_remote_service.dart';
import 'firebase_service_factory.dart';
import 'realtime_chat/chat_screen.dart';
import 'realtime_chat/list_chat_screen.dart';
import 'realtime_chat/vendor_chat_screen.dart';

class FirebaseServices extends BaseFirebaseServices {
  static final FirebaseServices _instance = FirebaseServices._internal();

  factory FirebaseServices() => _instance;

  FirebaseServices._internal() {
    firebaseAnalyticsService =
        FirebaseServiceFactory.create<FirebaseAnalyticsService>()!..init();
  }

  bool _isEnabled = false;

  @override
  bool get isEnabled => _isEnabled;

  @override
  Future<void> init() async {
    var startTime = DateTime.now();
    await Firebase.initializeApp();
    _isEnabled = kAdvanceConfig.enableFirebase;

    /// Not require Play Services
    /// https://firebase.google.com/docs/android/android-play-services
    _auth = FirebaseServiceFactory.create<FirebaseAuthService>();

    _firestore = FirebaseFirestore.instance;

    if (!kIsWeb) {
      _remoteConfig = FirebaseServiceFactory.create<FirebaseRemoteServices>();
    }

    /// Require Play Services
    const message = '[FirebaseServices] Init successfully';
    if (GmsCheck().isGmsAvailable) {
      _messaging = FirebaseMessaging.instance;
      _dynamicLinks = FirebaseServiceFactory.create<DynamicLinkService>();
      printLog(message, startTime);
    } else {
      printLog('$message (without Google Play Services)', startTime);
    }
  }

  late FirebaseAnalyticsService firebaseAnalyticsService;

  /// Firebase Auth
  FirebaseAuthService? _auth;

  FirebaseAuthService? get auth => _auth;

  /// Firebase Cloud Firestore
  FirebaseFirestore? _firestore;

  FirebaseFirestore? get firestore => _firestore;

  /// Firebase Dynamic Links
  DynamicLinkService? _dynamicLinks;

  DynamicLinkService? get dynamicLinks => _dynamicLinks;

  /// Firebase Remote Config
  FirebaseRemoteServices? _remoteConfig;

  FirebaseRemoteServices? get remoteConfig => _remoteConfig;

  FirebaseMessaging? _messaging;

  FirebaseMessaging? get messaging => _messaging;

  @override
  void deleteAccount() {
    _messaging?.deleteToken();
    _auth?.deleteAccount();
  }

  @override
  void loginFirebaseApple({authorizationCode, identityToken}) {
    if (FirebaseServices().isEnabled) {
      _auth?.loginFirebaseApple(
          authorizationCode: authorizationCode, identityToken: identityToken);
    }
  }

  @override
  void loginFirebaseFacebook({token}) async {
    if (FirebaseServices().isEnabled) {
      _auth?.loginFirebaseFacebook(token: token);
    }
  }

  @override
  void loginFirebaseGoogle({token}) async {
    if (FirebaseServices().isEnabled) {
      _auth?.loginFirebaseGoogle(token: token);
    }
  }

  @override
  void loginFirebaseEmail({email, password}) async {
    if (FirebaseServices().isEnabled) {
      _auth?.loginFirebaseEmail(email: email, password: password);
    }
  }

  @override
  Future<User?>? loginFirebaseCredential({credential}) {
    return _auth!.loginFirebaseCredential(credential: credential);
  }

  @override
  void saveUserToFirestore({user}) async {
    final token = await FirebaseServices().messaging!.getToken();
    printLog('token: $token');
    await FirebaseServices()
        .firestore!
        .collection('users')
        .doc(user!.email)
        .set(
      {'deviceToken': token, 'isOnline': true},
      SetOptions(merge: true),
    );
    if (GmsCheck().isGmsAvailable) {
      try {
        await Services()
            .api
            .updateUserInfo({'deviceToken': token}, user!.cookie);
      } catch (e) {
        printLog(e);
      }
    }
  }

  @override
  dynamic getFirebaseCredential({verificationId, smsCode}) {
    return _auth?.getFirebaseCredential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  @override
  StreamController<dynamic>? getFirebaseStream() {
    return _auth!.getFirebaseStream();
  }

  @override
  Future<void> verifyPhoneNumber({
    phoneNumber,
    codeAutoRetrievalTimeout,
    codeSent,
    required void Function(String?) verificationCompleted,
    void Function(FirebaseErrorException error)? verificationFailed,
    forceResendingToken,
  }) async {
    await _auth!.verifyPhoneNumber(
        phoneNumber: phoneNumber!,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        codeSent: codeSent,
        timeout: const Duration(seconds: 120),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        forceResendingToken: forceResendingToken);
  }

  @override
  Widget renderListChatScreen() {
    return ListChatScreen();
  }

  @override
  Widget renderVendorListChatScreen({user}) {
    return VendorListChatScreen(user: user);
  }

  @override
  Widget renderChatScreen({senderUser, receiverEmail, receiverName}) {
    return ChatScreen(
      senderUser: senderUser,
      receiverEmail: receiverEmail,
      receiverName: receiverName,
    );
  }

  @override
  void createUserWithEmailAndPassword({email, password}) {
    if (isEnabled) {
      _auth?.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  }

  // @override
  // User? getCurrentUser() {
  //   try {
  //     return FirebaseServices().auth?.currentUser;
  //   } catch (e) {
  //     printLog('[Tabbar] getCurrentUser error ${e.toString()}');
  //   }
  // }

  @override
  Future<String?> getMessagingToken() async {
    return await messaging!.getToken();
  }

  @override
  void initDynamicLinkService(context) {
    _dynamicLinks?.initDynamicLinks(context);
  }

  @override
  Future<bool> loadRemoteConfig() {
    return _remoteConfig?.loadRemoteConfig() ?? Future.value(false);
  }

  @override
  String getRemoteConfigString(String key) {
    return _remoteConfig?.getString(key) ?? '';
  }

  @override
  void shareDynamicLinkProduct({itemUrl}) {
    _dynamicLinks?.shareProductLink(
      productUrl: itemUrl,
    );
  }

  @override
  Future<void> signOut() async {
    if (isEnabled) {
      _auth?.signOut();
    }
  }

  @override
  List<NavigatorObserver> getMNavigatorObservers() {
    return firebaseAnalyticsService.getMNavigatorObservers();
  }
}

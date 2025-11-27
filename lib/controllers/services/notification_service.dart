import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenSubscription;
  bool _localNotificationsReady = false;
  String? _activeUserId;
  String? _currentToken;

  Future<void> startForUser(String userId) async {
    if (_activeUserId == userId) return;
    _activeUserId = userId;

    await _initializeLocalNotifications();
    await _ensureForegroundPresentationOptions();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      announcement: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[NotificationService] Permission denied');
      return;
    }

    await _syncToken(userId);

    _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen(
      (token) => _saveToken(userId, token),
    );

    _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[NotificationService] Launch via notification payload: '
          '${initialMessage.data}');
    }

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => debugPrint(
        '[NotificationService] Notification opened app: ${message.data}',
      ),
    );
  }

  Future<void> stop() async {
    _foregroundSubscription?.cancel();
    _foregroundSubscription = null;

    _tokenSubscription?.cancel();
    _tokenSubscription = null;

    if (_activeUserId != null && _currentToken != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_activeUserId)
            .collection('deviceTokens')
            .doc(_currentToken)
            .update({
          'active': false,
          'signedOutAt': FieldValue.serverTimestamp(),
        });
      } catch (error) {
        debugPrint('[NotificationService] Failed to mark token inactive: '
            '$error');
      }
    }

    _activeUserId = null;
  }

  Future<void> dispose() async {
    await stop();
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsReady || kIsWeb) return;

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();

    final initializationSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _localNotifications.initialize(initializationSettings);

    const androidChannel = AndroidNotificationChannel(
      'studyearly_general',
      'Studyearly Alerts',
      description: 'General notifications about materials, quizzes, and chat.',
      importance: Importance.high,
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(androidChannel);

    _localNotificationsReady = true;
  }

  Future<void> _ensureForegroundPresentationOptions() async {
    if (kIsWeb) return;
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _syncToken(String userId) async {
    final token = await _messaging.getToken();
    if (token == null) {
      debugPrint('[NotificationService] No FCM token returned');
      return;
    }

    _currentToken = token;
    await _saveToken(userId, token);
  }

  Future<void> _saveToken(String userId, String token) async {
    _currentToken = token;
    final platform = _platformLabel();
    final data = {
      'token': token,
      'platform': platform,
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('deviceTokens')
        .doc(token)
        .set(data, SetOptions(merge: true));
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) {
      debugPrint('[NotificationService] Data-only message: ${message.data}');
      return;
    }

    if (_localNotificationsReady && !kIsWeb) {
      final androidDetails = AndroidNotificationDetails(
        'studyearly_general',
        'Studyearly Alerts',
        channelDescription:
            'General notifications about materials, quizzes, and chat.',
        importance: Importance.high,
        priority: Priority.high,
      );

      const darwinDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
        payload: message.data.isEmpty ? null : message.data.toString(),
      );
    }
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}


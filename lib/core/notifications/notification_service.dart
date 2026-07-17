import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/auth/models/user_model.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _userNotificationSub;
  static UserModel? _currentUser;
  static final Set<String> _shownNotificationIds = <String>{};

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'important_events',
        'Important events',
        description: 'Booking, employee, assignment, and job updates.',
        importance: Importance.high,
      );

  static Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(initializationSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onMessage.listen(_showRemoteMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessage(initialMessage);
    }
  }

  static Future<void> syncUser(UserModel? user) async {
    _currentUser = user;
    await _tokenRefreshSub?.cancel();
    await _userNotificationSub?.cancel();

    if (user == null || user.docId == null) return;

    await _saveCurrentToken(user.docId!);
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      _saveToken(user.docId!, token);
    });
    _listenForAppNotifications(user);
  }

  static Future<void> _saveCurrentToken(String userDocId) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _saveToken(userDocId, token);
  }

  static Future<void> _saveToken(String userDocId, String token) async {
    await _firestore.collection('users').doc(userDocId).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static void _listenForAppNotifications(UserModel user) {
    if (user.uid == null) return;

    _userNotificationSub = _firestore
        .collection('notifications')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .snapshots()
        .listen(
          (snapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type != DocumentChangeType.added) continue;
              final data = change.doc.data();
              if (data == null || !_isForUser(data, user)) continue;
              if (!_shownNotificationIds.add(change.doc.id)) continue;

              final title = data['title']?.toString() ?? 'Lakshya Aerotech';
              final message = data['message']?.toString() ?? '';
              if (message.isEmpty) continue;
              showLocalNotification(title: title, message: message);
            }
          },
          onError: (error) {
            debugPrint('Notification listener error: $error');
          },
        );
  }

  static bool _isForUser(Map<String, dynamic> data, UserModel user) {
    final recipientUid = data['recipientUid']?.toString();
    final recipientRole = data['recipientRole']?.toString();
    return recipientUid == user.uid || recipientRole == user.role.name;
  }

  static Future<void> _showRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null || body == null) return;
    await showLocalNotification(title: title, message: body);
  }

  static void _handleRemoteMessage(RemoteMessage message) {
    debugPrint('Opened notification: ${message.messageId}');
  }

  static Future<void> showLocalNotification({
    required String title,
    required String message,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'important_events',
      'Important events',
      channelDescription: 'Booking, employee, assignment, and job updates.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
    );
  }

  static UserModel? get currentUser => _currentUser;
}

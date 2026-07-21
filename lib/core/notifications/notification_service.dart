import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/models/user_model.dart';
import '../../features/booking/models/booking_model.dart';

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
  static GoRouter? _router;
  static final Set<String> _shownNotificationIds = <String>{};
  static final Set<String> _processedNotificationKeys = <String>{};

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'important_events',
    'Important events',
    description: 'Booking, employee, assignment, and job updates.',
    importance: Importance.high,
  );

  static void setRouter(GoRouter router) {
    _router = router;
  }

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

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
    );
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

  static void _handleLocalNotificationResponse(NotificationResponse response) {
    final payloadStr = response.payload;
    if (payloadStr == null || payloadStr.isEmpty) return;

    try {
      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      _processNotificationRoute(payload);
    } catch (e) {
      debugPrint('Error parsing local notification payload: $e');
    }
  }

  static void _processNotificationRoute(Map<String, dynamic> data) {
    if (_router == null || _currentUser == null) {
      debugPrint('Router or current user not initialized. Cannot navigate.');
      return;
    }

    final type = data['type']?.toString();
    final bookingId = data['bookingId']?.toString();
    final userRole = _currentUser?.role.name ?? '';

    debugPrint('Processing route for notification: type=$type, bookingId=$bookingId, role=$userRole');

    if (bookingId != null && bookingId.isNotEmpty) {
      _navigateToBookingDetails(bookingId, userRole);
      return;
    }

    // Role-specific and generic routes
    switch (type) {
      case 'NEW_FARMER_REGISTERED':
      case 'NEW_RETAILER_REGISTERED':
      case 'NEW_PILOT_REGISTERED':
      case 'SYSTEM_ERROR':
        if (userRole == 'admin') {
          _router!.push('/admin');
        }
        break;
      case 'RETAILER_APPROVED':
        _router!.push('/retailer');
        break;
      case 'RETAILER_REJECTED':
        _router!.push('/retailer-status');
        break;
      case 'COUPON_ASSIGNED':
      case 'COUPON_EXPIRING_SOON':
        if (userRole == 'retailer') {
          _router!.push('/retailer/coupons');
        }
        break;
      default:
        // Fallback to role-specific dashboard
        if (userRole == 'farmer') {
          _router!.push('/my-bookings');
        } else if (userRole == 'retailer') {
          _router!.push('/retailer/bookings');
        } else if (userRole == 'pilot') {
          _router!.push('/pilot');
        } else if (userRole == 'operations') {
          _router!.push('/operations');
        } else if (userRole == 'admin') {
          _router!.push('/admin');
        }
    }
  }

  static Future<void> _navigateToBookingDetails(String bookingId, String userRole) async {
    if (_router == null) return;

    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!doc.exists) return;
      final booking = BookingModel.fromMap(doc.data()!, doc.id);

      if (userRole == 'pilot') {
        _router!.push('/pilot/job-details', extra: booking);
      } else if (userRole == 'operations') {
        _router!.push('/ops-booking-details', extra: booking);
      } else {
        _router!.push('/booking-details', extra: booking);
      }
    } catch (e) {
      debugPrint('Failed to load booking for navigation: $e');
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
          final type = data['type']?.toString();
          final bookingId = data['bookingId']?.toString();

          if (message.isEmpty) continue;

          // Prevent duplicates
          final key = '${bookingId ?? ''}_${title}_$message';
          if (_processedNotificationKeys.contains(key)) continue;
          _processedNotificationKeys.add(key);
          Timer(const Duration(seconds: 10), () => _processedNotificationKeys.remove(key));

          final payload = {
            'type': type,
            'bookingId': bookingId,
          };

          showLocalNotification(
            title: title,
            message: message,
            payload: jsonEncode(payload),
          );
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
    final title = notification?.title ?? message.data['title']?.toString() ?? 'Lakshya Aerotech';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';
    final type = message.data['type']?.toString();
    final bookingId = message.data['bookingId']?.toString();

    if (body.isEmpty) return;

    // Prevent duplicates
    final key = '${bookingId ?? ''}_${title}_$body';
    if (_processedNotificationKeys.contains(key)) return;
    _processedNotificationKeys.add(key);
    Timer(const Duration(seconds: 10), () => _processedNotificationKeys.remove(key));

    final payload = {
      'type': type,
      'bookingId': bookingId,
    };

    await showLocalNotification(
      title: title,
      message: body,
      payload: jsonEncode(payload),
    );
  }

  static void _handleRemoteMessage(RemoteMessage message) {
    debugPrint('Opened remote message: ${message.messageId}');
    final type = message.data['type']?.toString();
    final bookingId = message.data['bookingId']?.toString();

    _processNotificationRoute({
      'type': type,
      'bookingId': bookingId,
    });
  }

  static Future<void> showLocalNotification({
    required String title,
    required String message,
    String? payload,
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
      payload: payload,
    );
  }

  static UserModel? get currentUser => _currentUser;
}

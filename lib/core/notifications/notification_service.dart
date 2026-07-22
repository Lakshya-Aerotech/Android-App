import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/models/user_model.dart';
import '../../features/booking/models/booking_model.dart';

import 'notification_model.dart';

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
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('NotificationService: FCM requestPermission failed: $e');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    } catch (e) {
      debugPrint('NotificationService: LocalNotifications initialize failed: $e');
    }

    FirebaseMessaging.onMessage.listen(_showRemoteMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);

    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessage(initialMessage);
      }
    } catch (e) {
      debugPrint('NotificationService: getInitialMessage failed: $e');
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

  static void handleNotificationClick(NotificationModel notification, [String? roleOverride]) {
    final data = {
      'type': notification.type,
      'bookingId': notification.bookingId,
      if (roleOverride != null) 'roleOverride': roleOverride,
    };
    _processNotificationRoute(data);
  }

  static void _processNotificationRoute(Map<String, dynamic> data) {
    if (_router == null) {
      debugPrint('NotificationService: Router not initialized. Cannot navigate.');
      return;
    }

    final type = data['type']?.toString();
    final bookingId = data['bookingId']?.toString();
    final roleOverride = data['roleOverride']?.toString();
    
    // Use override, then stored _currentUser, then fallback to empty string
    final userRole = roleOverride ?? _currentUser?.role.name ?? '';

    debugPrint('NotificationService: Processing route. Type: $type, BookingId: $bookingId, Role: $userRole');

    if (bookingId != null && bookingId.isNotEmpty) {
      _navigateToBookingDetails(bookingId, userRole);
      return;
    }

    if (_currentUser == null && roleOverride == null) {
      debugPrint('NotificationService: User not initialized. Navigation might be restricted.');
    }

    try {
      // Handle navigation based on type and role
      switch (type) {
        case 'NEW_FARMER_REGISTERED':
        case 'NEW_PILOT_REGISTERED':
        case 'NEW_EXTERNAL_PILOT_REGISTERED':
        case 'SYSTEM_ERROR':
          if (userRole == 'admin') {
            _router!.push('/admin/employees');
            return;
          }
          break;
        case 'NEW_RETAILER_REGISTERED':
        case 'REGISTRATION_SUBMITTED':
          if (userRole == 'admin') {
            _router!.push('/admin/retailers');
            return;
          } else if (userRole == 'retailer') {
            _router!.push('/retailer-status');
            return;
          }
          break;
        case 'REGISTRATION_APPROVED':
        case 'RETAILER_APPROVED':
          if (userRole == 'retailer') {
            _router!.push('/retailer');
            return;
          }
          break;
        case 'REGISTRATION_REJECTED':
        case 'RETAILER_REJECTED':
          if (userRole == 'retailer') {
            _router!.push('/retailer-status');
            return;
          }
          break;
        case 'PILOT_ARRIVED':
        case 'PILOT_EN_ROUTE':
        case 'MISSION_STARTED':
        case 'MISSION_COMPLETED':
        case 'PAYMENT_RECORDED':
        case 'PAYMENT_CONFIRMED':
        case 'PAYMENT_REJECTED':
          if (userRole == 'farmer') {
            _router!.push('/my-bookings');
            return;
          } else if (userRole == 'admin') {
            _router!.push('/admin/payments');
            return;
          } else if (userRole == 'operations') {
            _router!.push('/operations');
            return;
          } else if (userRole == 'pilot' || userRole == 'externalPilot') {
            _router!.push('/pilot');
            return;
          }
          break;
        case 'COUPON_VERIFIED':
        case 'COUPON_VERIFICATION_REQUIRED':
          if (userRole == 'admin') {
            _router!.push('/admin/coupons');
            return;
          } else if (userRole == 'retailer') {
            _router!.push('/retailer/coupons');
            return;
          } else if (userRole == 'pilot' || userRole == 'externalPilot') {
            _router!.push('/pilot');
            return;
          }
          break;
        case 'CASH_DEPOSITED':
        case 'CASH_COLLECTION_REQUIRED':
        case 'CASH_DEPOSIT_REMINDER':
          if (userRole == 'admin') {
            _router!.push('/admin/payments');
            return;
          } else if (userRole == 'pilot' || userRole == 'externalPilot') {
            _router!.push('/pilot');
            return;
          }
          break;
        case 'COUPON_ASSIGNED':
        case 'COUPON_EXPIRING_SOON':
          if (userRole == 'retailer') {
            _router!.push('/retailer/coupons');
            return;
          }
          break;
      }

      // Fallback if no specific route matched or returned
      debugPrint('NotificationService: No specific route for type: $type. Falling back to dashboard.');
      if (userRole == 'farmer') {
        _router!.push('/farmer');
      } else if (userRole == 'retailer') {
        _router!.push('/retailer');
      } else if (userRole == 'pilot' || userRole == 'externalPilot') {
        _router!.push('/pilot');
      } else if (userRole == 'operations') {
        _router!.push('/operations');
      } else if (userRole == 'admin') {
        _router!.push('/admin');
      } else {
        _router!.push('/');
      }
    } catch (e) {
      debugPrint('NotificationService: Navigation error: $e');
    }
  }

  static Future<void> _navigateToBookingDetails(String bookingId, String userRole) async {
    if (_router == null) return;

    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!doc.exists) {
        debugPrint('Booking document not found: $bookingId');
        return;
      }
      final booking = BookingModel.fromMap(doc.data()!, doc.id);

      if (userRole == 'pilot' || userRole == 'externalPilot') {
        _router!.push('/pilot/job-details', extra: booking);
      } else if (userRole == 'operations' || userRole == 'admin') {
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

    // Don't block notification listening on FCM token retrieval
    _saveCurrentToken(user.docId!).catchError((e) {
      debugPrint('FCM Token sync failed: $e');
    });

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      _saveToken(user.docId!, token);
    });

    _listenForAppNotifications(user);
  }

  static Future<void> _saveCurrentToken(String userDocId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _saveToken(userDocId, token);
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      // Continue without token - likely a configuration error (DEVELOPER_ERROR)
    }
  }

  static Future<void> _saveToken(String userDocId, String token) async {
    await _firestore.collection('users').doc(userDocId).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static void _listenForAppNotifications(UserModel user) {
    if (user.uid == null) return;

    // Use a small offset to account for server/client time drift
    final startTime = DateTime.now().subtract(const Duration(seconds: 5));

    _userNotificationSub = _firestore
        .collection('notifications')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startTime))
        .where(
          Filter.or(
            Filter('recipientUid', isEqualTo: user.uid),
            Filter('recipientRole', isEqualTo: user.role.name),
          ),
        )
        .snapshots()
        .listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          final data = change.doc.data();
          if (data == null) continue;
          if (!_shownNotificationIds.add(change.doc.id)) continue;

          final title = data['title']?.toString() ?? 'Lakshya Smartguard systems';
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



  static Future<void> _showRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString() ?? 'Lakshya Smartguard systems';
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

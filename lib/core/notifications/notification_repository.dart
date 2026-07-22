import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/models/user_model.dart';
import 'notification_model.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createForUser({
    required String recipientUid,
    required String eventKey,
    required String title,
    required String message,
    String? bookingId,
    String? employeeId,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    await _writeNotification(
      documentId: '$eventKey-user-$recipientUid',
      payload: {
        'recipientUid': recipientUid,
        'title': title,
        'message': message,
        'bookingId': bookingId,
        'employeeId': employeeId,
        'type': type,
        'data': data ?? const <String, dynamic>{},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> createForRole({
    required UserRole role,
    required String eventKey,
    required String title,
    required String message,
    String? bookingId,
    String? employeeId,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    await _writeNotification(
      documentId: '$eventKey-role-${role.name}',
      payload: {
        'recipientRole': role.name,
        'title': title,
        'message': message,
        'bookingId': bookingId,
        'employeeId': employeeId,
        'type': type,
        'data': data ?? const <String, dynamic>{},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _writeNotification({
    required String documentId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // Use set() with merge: true to avoid "Permission Denied" on get() 
      // if the current user isn't the recipient.
      // We use a specific documentId to prevent duplicate notifications for the same event.
      await _firestore.collection('notifications').doc(documentId).set(
        payload,
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('NotificationRepository: Failed to write notification: $e');
      // Fallback to add() if set() with specific ID fails due to permissions
      try {
        await _firestore.collection('notifications').add(payload);
      } catch (e2) {
        debugPrint('NotificationRepository: Fallback add() also failed: $e2');
      }
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream(
    String uid,
    UserRole role,
  ) {
    return _firestore
        .collection('notifications')
        .where(
          Filter.or(
            Filter('recipientUid', isEqualTo: uid),
            Filter('recipientRole', isEqualTo: role.name),
          ),
        )
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();

          // Sort in memory to avoid complex composite indexes
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
      'isRead': true,
    });
  }

  Future<void> markAllAsRead(String uid, UserRole role) async {
    final batch = _firestore.batch();
    
    // Fetch user-specific unread notifications
    final userSnapshots = await _firestore
        .collection('notifications')
        .where('recipientUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in userSnapshots.docs) {
      batch.update(doc.reference, {
        'read': true,
        'isRead': true,
      });
    }

    // Fetch role-specific unread notifications
    final roleSnapshots = await _firestore
        .collection('notifications')
        .where('recipientRole', isEqualTo: role.name)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in roleSnapshots.docs) {
      batch.update(doc.reference, {
        'read': true,
        'isRead': true,
      });
    }

    await batch.commit();
  }
}

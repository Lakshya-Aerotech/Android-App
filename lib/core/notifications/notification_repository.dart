import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/auth/models/user_model.dart';

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
    final docRef = _firestore.collection('notifications').doc(documentId);
    final snapshot = await docRef.get();
    if (snapshot.exists) return;

    await docRef.set(payload);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? id;
  final String? recipientUid;
  final String? recipientRole;
  final String title;
  final String message;
  final String? bookingId;
  final String? employeeId;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;
  final String? type;

  NotificationModel({
    this.id,
    this.recipientUid,
    this.recipientRole,
    required this.title,
    required this.message,
    this.bookingId,
    this.employeeId,
    this.data = const {},
    this.read = false,
    required this.createdAt,
    this.type,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      recipientUid: map['recipientUid'] ?? map['recipientId'],
      recipientRole: map['recipientRole'],
      title: map['title'] ?? '',
      message: map['body'] ?? map['message'] ?? '',
      bookingId: map['bookingId'] ?? map['referenceId'],
      employeeId: map['employeeId'],
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : {},
      read: map['isRead'] ?? map['read'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (recipientUid != null) 'recipientUid': recipientUid,
      if (recipientUid != null) 'recipientId': recipientUid,
      if (recipientRole != null) 'recipientRole': recipientRole,
      'title': title,
      'message': message,
      'body': message,
      'bookingId': bookingId,
      'referenceId': bookingId,
      if (employeeId != null) 'employeeId': employeeId,
      'data': data,
      'read': read,
      'isRead': read,
      'createdAt': FieldValue.serverTimestamp(),
      'sentAt': FieldValue.serverTimestamp(),
      'type': type,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/notifications/notification_repository.dart';
import '../../../core/services/api_auth_headers.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/models/activity_model.dart';
import '../../../shared/repositories/activity_repository.dart';
import '../../../shared/enums/booking_status.dart';
import '../models/booking_model.dart';

abstract class BookingRepository {
  Stream<List<BookingModel>> getFarmerBookingsStream(String farmerUid);
  Stream<List<BookingModel>> getRetailerBookingsStream(String retailerUid);
  Future<String> createBooking(BookingModel booking);
  Future<void> cancelBooking(String docId, StatusHistoryEntry historyEntry);
  Future<BookingModel?> getBookingById(String docId);
  Stream<BookingModel?> getBookingStream(String docId);
  Future<void> confirmService(String docId, StatusHistoryEntry historyEntry);
  Future<void> submitRating(String docId, double rating, String feedback);
  Future<void> reportIssue(
    String docId,
    String category,
    String description,
    StatusHistoryEntry historyEntry,
  );
  Future<void> requestPayment({
    required String docId,
    required String method,
    String? pilotId,
  });
}

class BookingRepositoryImpl implements BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  final NotificationRepository _notifications = NotificationRepository();

  @override
  Stream<List<BookingModel>> getFarmerBookingsStream(String farmerUid) {
    return _firestore
        .collection('bookings')
        .where('farmerUid', isEqualTo: farmerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Stream<List<BookingModel>> getRetailerBookingsStream(String retailerUid) {
    return _firestore
        .collection('bookings')
        .where('createdByRetailerId', isEqualTo: retailerUid)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  @override
  Future<String> createBooking(BookingModel booking) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AppConfig.bookingBaseUrl,
        data: {
          'farmerUid': booking.farmerUid,
          'farmId': booking.farmId,
          'serviceType': booking.serviceType,
          'bookingDate':
              '${booking.bookingDate.year.toString().padLeft(4, '0')}-'
              '${booking.bookingDate.month.toString().padLeft(2, '0')}-'
              '${booking.bookingDate.day.toString().padLeft(2, '0')}',
          'preferredTime': booking.preferredTime,
          'estimatedArea': booking.estimatedArea,
          'remarks': booking.remarks,
          'couponId': booking.couponId,
        },
        options: Options(headers: await ApiAuthHeaders.create()),
      );
      final data = response.data?['data'];
      final bookingId = data is Map ? data['bookingId']?.toString() : null;
      if (response.statusCode == 201 && bookingId != null && bookingId.isNotEmpty) {
        return bookingId;
      }
      throw Exception('The server did not create the booking.');
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['error'] ?? data['message'] : null;
      throw Exception(message?.toString() ?? 'Unable to create booking.');
    }
  }

  @override
  Future<void> cancelBooking(
    String docId,
    StatusHistoryEntry historyEntry,
  ) async {
    final booking = await getBookingById(docId);
    await _firestore.collection('bookings').doc(docId).update({
      'status': BookingStatus.cancelled.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });

    if (booking == null) return;
    await _notifications.createForUser(
      recipientUid: booking.farmerUid,
      eventKey: 'booking-cancelled-farmer-$docId',
      title: 'Booking cancelled',
      message:
          'Your booking ${booking.bookingId} for ${booking.farmName} was cancelled.',
      bookingId: docId,
      type: 'BOOKING_CANCELLED',
    );
    await _notifications.createForRole(
      role: UserRole.operations,
      eventKey: 'booking-cancelled-operations-$docId',
      title: 'Booking cancelled',
      message:
          '${booking.farmerName ?? 'A farmer'} cancelled booking ${booking.bookingId}.',
      bookingId: docId,
      type: 'BOOKING_CANCELLED',
    );
    if (booking.assignedPilotId != null) {
      await _notifications.createForUser(
        recipientUid: booking.assignedPilotId!,
        eventKey: 'farmer-cancelled-booking-$docId',
        title: 'Farmer cancelled booking',
        message:
            '${booking.farmerName ?? 'The farmer'} cancelled booking ${booking.bookingId}.',
        bookingId: docId,
        type: 'BOOKING_CANCELLED',
      );
    }
  }

  @override
  Future<BookingModel?> getBookingById(String docId) async {
    final doc = await _firestore.collection('bookings').doc(docId).get();
    if (doc.exists) {
      return BookingModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Stream<BookingModel?> getBookingStream(String docId) {
    return _firestore
        .collection('bookings')
        .doc(docId)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? BookingModel.fromMap(doc.data()!, doc.id) : null,
        );
  }

  @override
  Future<void> confirmService(
    String docId,
    StatusHistoryEntry historyEntry,
  ) async {
    await _firestore.collection('bookings').doc(docId).update({
      'status': BookingStatus.farmerConfirmed.toFirestore(),
      'confirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });

    // Log Activity
    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.farmerConfirmedService,
        description: 'Farmer confirmed service for booking: $docId',
        userName: historyEntry.updatedBy,
        timestamp: DateTime.now(),
        metadata: {'bookingId': docId},
      ),
    );
  }

  @override
  Future<void> submitRating(
    String docId,
    double rating,
    String feedback,
  ) async {
    await _firestore.collection('bookings').doc(docId).update({
      'rating': rating,
      'feedback': feedback,
      'feedbackCreatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> reportIssue(
    String docId,
    String category,
    String description,
    StatusHistoryEntry historyEntry,
  ) async {
    await _firestore.collection('bookings').doc(docId).update({
      'status': BookingStatus.issueReported.toFirestore(),
      'issueCategory': category,
      'issueDescription': description,
      'issueReportedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });
  }

  @override
  Future<void> requestPayment({
    required String docId,
    required String method,
    String? pilotId,
  }) async {
    if (method != 'Cash' || pilotId == null || pilotId.isEmpty) {
      throw StateError('Only authenticated pilot cash collection is supported.');
    }
    final updates = <String, dynamic>{
      'paymentMethod': 'Cash',
      'paymentStatus': 'Cash Collected by Pilot',
      'paymentRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'cashCollected': true,
      'cashCollectedBy': pilotId,
      'cashCollectedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('bookings').doc(docId).update(updates);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/notifications/notification_repository.dart';
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
    required double originalAmount,
    required double finalAmount,
    double? discountAmount,
  });
}

class BookingRepositoryImpl implements BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    final historyEntry = StatusHistoryEntry(
      status: BookingStatus.pending,
      updatedBy: booking.createdByRole == 'retailer'
          ? 'Retailer'
          : booking.farmerName ?? 'Farmer',
      updatedByRole: booking.createdByRole ?? 'farmer',
      timestamp: DateTime.now(),
      remarks: 'Booking submitted successfully.',
    );

    final bookingData = booking.toMap();
    bookingData['statusHistory'] = [historyEntry.toMap()];

    final docRef = await _firestore.collection('bookings').add(bookingData);

    // Log Activity
    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.bookingCreated,
        description: 'New booking created: ${booking.bookingId}',
        userId: booking.farmerUid,
        userName: booking.farmerName,
        timestamp: DateTime.now(),
        metadata: {'bookingId': docRef.id},
      ),
    );

    await _notifications.createForUser(
      recipientUid: booking.farmerUid,
      eventKey: 'booking-submitted-${docRef.id}',
      title: 'Booking submitted',
      message:
          'Your booking ${booking.bookingId} for ${booking.farmName} has been submitted.',
      bookingId: docRef.id,
    );
    if (booking.createdByRetailerId != null) {
      await _notifications.createForUser(
        recipientUid: booking.createdByRetailerId!,
        eventKey: 'retailer-booking-submitted-${docRef.id}',
        title: 'Booking submitted',
        message:
            'Booking ${booking.bookingId} for ${booking.farmerName ?? 'farmer'} has been submitted.',
        bookingId: docRef.id,
      );
    }
    await _notifications.createForRole(
      role: UserRole.operations,
      eventKey: 'new-booking-request-${docRef.id}',
      title: 'New booking request',
      message:
          '${booking.farmerName ?? 'A farmer'} requested ${booking.serviceType} for ${booking.farmName}.',
      bookingId: docRef.id,
    );

    return docRef.id;
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
    );
    await _notifications.createForRole(
      role: UserRole.operations,
      eventKey: 'booking-cancelled-operations-$docId',
      title: 'Booking cancelled',
      message:
          '${booking.farmerName ?? 'A farmer'} cancelled booking ${booking.bookingId}.',
      bookingId: docId,
    );
    if (booking.assignedPilotId != null) {
      await _notifications.createForUser(
        recipientUid: booking.assignedPilotId!,
        eventKey: 'farmer-cancelled-booking-$docId',
        title: 'Farmer cancelled booking',
        message:
            '${booking.farmerName ?? 'The farmer'} cancelled booking ${booking.bookingId}.',
        bookingId: docId,
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
    required double originalAmount,
    required double finalAmount,
    double? discountAmount,
  }) async {
    final status = method == 'Cash' ? 'Pending Cash Collection' : 'Pending Online Payment';
    await _firestore.collection('bookings').doc(docId).update({
      'paymentMethod': method,
      'paymentStatus': status,
      'originalAmount': originalAmount,
      'finalAmount': finalAmount,
      if (discountAmount != null) 'couponDiscountAmount': discountAmount,
      'paymentRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

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
    String? pilotId,
  });
  Future<void> selectPaymentMethod({
    required String docId,
    required String method,
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

    String bookingDocId;

    if (booking.couponId != null) {
      bookingDocId = await _firestore.runTransaction<String>((transaction) async {
        final couponRef = _firestore.collection('coupons').doc(booking.couponId);
        final couponSnapshot = await transaction.get(couponRef);

        if (!couponSnapshot.exists) {
          throw Exception('Coupon does not exist.');
        }

        final couponData = couponSnapshot.data()!;
        final isActive = couponData['isActive'] ?? false;
        if (!isActive) {
          throw Exception('Coupon is inactive.');
        }

        final Timestamp validFromTimestamp = couponData['validFrom'] as Timestamp;
        final Timestamp validUntilTimestamp = couponData['validUntil'] as Timestamp;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final start = DateTime(
          validFromTimestamp.toDate().year,
          validFromTimestamp.toDate().month,
          validFromTimestamp.toDate().day,
        );
        final end = DateTime(
          validUntilTimestamp.toDate().year,
          validUntilTimestamp.toDate().month,
          validUntilTimestamp.toDate().day,
        );

        if (today.isBefore(start) || today.isAfter(end)) {
          throw Exception('Coupon is outside its validity period.');
        }

        final remainingUsage = (couponData['remainingUsage'] as num?)?.toInt() ?? 0;
        if (remainingUsage <= 0) {
          throw Exception('Coupon usage limit reached.');
        }

        // Retailer assignment check
        final assignedRetailerIds = List<String>.from(couponData['assignedRetailerIds'] ?? []);
        if (booking.createdByRole == 'retailer' && assignedRetailerIds.isNotEmpty) {
          if (!assignedRetailerIds.contains(booking.createdByRetailerId)) {
            throw Exception('Not eligible for this coupon.');
          }
        }

        // Region (state) check
        final applicableRegion = ((couponData['applicableRegion'] as String?) ?? '').trim().toLowerCase();
        final bookingState = (booking.state ?? '').trim().toLowerCase();
        final regionMatch = applicableRegion.isEmpty ||
            applicableRegion == 'all' ||
            applicableRegion == 'global' ||
            applicableRegion == 'any' ||
            applicableRegion == bookingState;

        if (!regionMatch) {
          throw Exception('Coupon is not applicable in this region.');
        }

        // Service Type check
        final eligibleService = (couponData['eligibleService'] as String?) ?? '';
        if (eligibleService.trim().toLowerCase() != booking.serviceType.trim().toLowerCase()) {
          throw Exception('Coupon is not applicable to the selected service.');
        }

        // Perform updates
        transaction.update(couponRef, {
          'remainingUsage': remainingUsage - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final newBookingRef = _firestore.collection('bookings').doc();
        transaction.set(newBookingRef, bookingData);

        return newBookingRef.id;
      });
    } else {
      final docRef = await _firestore.collection('bookings').add(bookingData);
      bookingDocId = docRef.id;
    }

    // Log Activity
    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.bookingCreated,
        description: 'New booking created: ${booking.bookingId}',
        userId: booking.farmerUid,
        userName: booking.farmerName,
        timestamp: DateTime.now(),
        metadata: {'bookingId': bookingDocId},
      ),
    );

    await _notifications.createForUser(
      recipientUid: booking.farmerUid,
      eventKey: 'booking-submitted-$bookingDocId',
      title: 'Booking submitted',
      message:
          'Your booking ${booking.bookingId} for ${booking.farmName} has been submitted.',
      bookingId: bookingDocId,
      type: 'BOOKING_SUBMITTED',
    );
    if (booking.createdByRetailerId != null) {
      await _notifications.createForUser(
        recipientUid: booking.createdByRetailerId!,
        eventKey: 'retailer-booking-submitted-$bookingDocId',
        title: 'Booking submitted',
        message:
            'Booking ${booking.bookingId} for ${booking.farmerName ?? 'farmer'} has been submitted.',
        bookingId: bookingDocId,
        type: 'BOOKING_CREATED',
      );
    }
    await _notifications.createForRole(
      role: UserRole.operations,
      eventKey: 'new-booking-request-$bookingDocId',
      title: 'New booking request',
      message:
          '${booking.farmerName ?? 'A farmer'} requested ${booking.serviceType} for ${booking.farmName}.',
      bookingId: bookingDocId,
      type: 'BOOKING_CREATED',
    );

    return bookingDocId;
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
    required double originalAmount,
    required double finalAmount,
    double? discountAmount,
    String? pilotId,
  }) async {
    final status = method == 'Cash' ? 'Cash Collected by Pilot' : 'SUCCESS';
    final updates = <String, dynamic>{
      'paymentMethod': method,
      'paymentStatus': status,
      'originalAmount': originalAmount,
      'payableAmount': finalAmount,
      if (discountAmount != null) 'discountAmount': discountAmount,
      'paymentRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (method == 'UPI') {
      updates['paymentVerifiedByAdmin'] = true;
      updates['status'] = BookingStatus.closed.toFirestore();
    }

    if (method == 'Cash' && pilotId != null) {
      updates['cashCollected'] = true;
      updates['cashCollectedBy'] = pilotId;
      updates['cashCollectedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('bookings').doc(docId).update(updates);
  }

  @override
  Future<void> selectPaymentMethod({
    required String docId,
    required String method,
  }) async {
    final updates = <String, dynamic>{
      'paymentMethod': method,
      'paymentStatus': method.toUpperCase() == 'CASH' ? 'Awaiting Cash Collection' : 'PAYMENT_PENDING',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('bookings').doc(docId).update(updates);
  }
}

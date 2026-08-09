import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/notifications/notification_repository.dart';
import '../../../shared/models/activity_model.dart';
import '../../../shared/repositories/activity_repository.dart';
import '../../booking/models/booking_model.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/enums/booking_status.dart';

abstract class PilotJobsRepository {
  Stream<List<BookingModel>> getJobsByStatus(
    String pilotId,
    List<BookingStatus> statuses,
  );
  Stream<List<BookingModel>> getAllPilotJobsStream(String pilotId);
  Future<void> updateJobStatus(
    String bookingDocId,
    BookingStatus status,
    StatusHistoryEntry historyEntry, {
    Map<String, dynamic>? additionalUpdates,
  });
  Future<void> completeMission({
    required String bookingDocId,
    required String pilotId,
    required Map<String, dynamic> completionData,
    required StatusHistoryEntry historyEntry,
  });
  Stream<BookingModel> getJobStream(String bookingDocId);
  Future<double> getAverageRating(String pilotId);
  Future<void> verifyCoupon(String docId, String pilotId);
  Future<void> collectCash(String docId, String pilotId);
  Future<void> markCashDeposited(String docId, String pilotId);
  Future<void> startNavigation(String docId, StatusHistoryEntry historyEntry);
}

class PilotJobsRepositoryImpl implements PilotJobsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notifications = NotificationRepository();

  @override
  Stream<List<BookingModel>> getJobsByStatus(
    String pilotId,
    List<BookingStatus> statuses,
  ) {
    return _getAssignedOrCopilotJobsStream(
      pilotId: pilotId,
      statuses: statuses,
      orderByUpdatedAt: true,
    );
  }

  @override
  Stream<List<BookingModel>> getAllPilotJobsStream(String pilotId) {
    return _getAssignedOrCopilotJobsStream(
      pilotId: pilotId,
      orderByUpdatedAt: false,
    );
  }

  @override
  Future<void> updateJobStatus(
    String bookingDocId,
    BookingStatus status,
    StatusHistoryEntry historyEntry, {
    Map<String, dynamic>? additionalUpdates,
  }) async {
    if (bookingDocId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Booking Document ID cannot be empty.',
      );
    }

    // Fetch booking BEFORE update to ensure we have the data for notifications
    final booking = await _bookingSnapshot(bookingDocId);

    final Map<String, dynamic> updates = {
      'status': status.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
      if (additionalUpdates != null) ...additionalUpdates,
    };

    await _firestore.collection('bookings').doc(bookingDocId).update(updates);

    // Log Activity if mission started
    if (status == BookingStatus.inProgress) {
      await ActivityRepository.logActivity(
        ActivityModel(
          type: ActivityType.missionStarted,
          description: 'Mission started for booking: $bookingDocId',
          userName: historyEntry.updatedBy,
          timestamp: DateTime.now(),
          metadata: {'bookingId': bookingDocId},
        ),
      );
    }

    if (booking != null) {
      final farmerUid = booking.farmerUid;
      final bookingId = booking.bookingId;
      final farmName = booking.farmName;
      final pilotName = booking.assignedPilotName ?? 'Your pilot';

      if (status == BookingStatus.enRoute) {
        await _notifications.createForUser(
          recipientUid: farmerUid,
          eventKey: 'pilot-en-route-$bookingDocId',
          title: 'Pilot en route',
          message: '$pilotName is on the way to your farm for booking $bookingId.',
          bookingId: bookingDocId,
          type: 'PILOT_EN_ROUTE',
        );
        await _notifications.createForRole(
          role: UserRole.operations,
          eventKey: 'pilot-en-route-ops-$bookingDocId',
          title: 'Pilot en route',
          message: 'Pilot $pilotName is en route to $farmName for booking $bookingId.',
          bookingId: bookingDocId,
          type: 'PILOT_EN_ROUTE',
        );
      } else if (status == BookingStatus.arrived) {
        await _notifications.createForUser(
          recipientUid: farmerUid,
          eventKey: 'pilot-arrived-$bookingDocId',
          title: 'Pilot arrived',
          message: '$pilotName arrived at $farmName for booking $bookingId.',
          bookingId: bookingDocId,
          type: 'PILOT_ARRIVED',
        );
        if (booking.hasCoupon && !booking.couponVerified) {
          await _notifications.createForUser(
            recipientUid: booking.assignedPilotId!,
            eventKey: 'coupon-verification-required-$bookingDocId',
            title: 'Coupon verification required',
            message: 'Please verify the retailer coupon for booking $bookingId before starting the mission.',
            bookingId: bookingDocId,
            type: 'COUPON_VERIFICATION_REQUIRED',
          );
        }
      } else if (status == BookingStatus.inProgress) {
        await _notifications.createForUser(
          recipientUid: farmerUid,
          eventKey: 'spraying-started-$bookingDocId',
          title: 'Spraying started',
          message: 'Spraying has started for booking $bookingId at $farmName.',
          bookingId: bookingDocId,
          type: 'MISSION_STARTED',
        );
        await _notifications.createForRole(
          role: UserRole.operations,
          eventKey: 'spraying-started-ops-$bookingDocId',
          title: 'Mission started',
          message: 'Pilot $pilotName started mission for booking $bookingId.',
          bookingId: bookingDocId,
          type: 'MISSION_STARTED',
        );
      }
    }
  }

  @override
  Future<void> completeMission({
    required String bookingDocId,
    required String pilotId,
    required Map<String, dynamic> completionData,
    required StatusHistoryEntry historyEntry,
  }) async {
    if (bookingDocId.isEmpty || pilotId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Booking or Pilot ID cannot be empty.',
      );
    }

    final bookingRef = _firestore.collection('bookings').doc(bookingDocId);
    await _firestore.runTransaction((transaction) async {
      transaction.update(bookingRef, {
        ...completionData,
        'status': BookingStatus.completed.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
      });
    });

    // Log Activity
    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.missionCompleted,
        description: 'Mission completed for booking: $bookingDocId',
        userName: historyEntry.updatedBy,
        timestamp: DateTime.now(),
        metadata: {'bookingId': bookingDocId},
      ),
    );

    final booking = await _bookingSnapshot(bookingDocId);
    if (booking != null) {
      await _notifications.createForUser(
        recipientUid: booking.farmerUid,
        eventKey: 'job-completed-farmer-$bookingDocId',
        title: 'Job completed',
        message:
            'Spraying is complete for booking ${booking.bookingId} at ${booking.farmName}.',
        bookingId: bookingDocId,
        type: 'MISSION_COMPLETED',
      );
      await _notifications.createForRole(
        role: UserRole.operations,
        eventKey: 'job-completed-ops-$bookingDocId',
        title: 'Mission completed',
        message:
            'Pilot ${booking.assignedPilotName ?? 'assigned'} completed mission for booking ${booking.bookingId}.',
        bookingId: bookingDocId,
        type: 'MISSION_COMPLETED',
      );
      await _notifications.createForRole(
        role: UserRole.admin,
        eventKey: 'booking-completed-admin-$bookingDocId',
        title: 'Booking completed',
        message:
            'Booking ${booking.bookingId} for ${booking.farmName} has been completed.',
        bookingId: bookingDocId,
        type: 'MISSION_COMPLETED',
      );
      if (booking.createdByRetailerId != null) {
        await _notifications.createForUser(
          recipientUid: booking.createdByRetailerId!,
          eventKey: 'retailer-service-completed-$bookingDocId',
          title: 'Service completed',
          message:
              'Service for booking ${booking.bookingId} (${booking.farmerName}) has been completed.',
          bookingId: bookingDocId,
          type: 'MISSION_COMPLETED',
        );
      }
      await _notifications.createForUser(
        recipientUid: booking.assignedPilotId!,
        eventKey: 'cash-collection-required-$bookingDocId',
        title: 'Cash collection required',
        message:
            'Please collect ₹${booking.payableAmount?.toStringAsFixed(2) ?? '0.00'} from the farmer for booking ${booking.bookingId}.',
        bookingId: bookingDocId,
        type: 'CASH_COLLECTION_REQUIRED',
      );
    }
  }

  @override
  Stream<BookingModel> getJobStream(String bookingDocId) {
    return _firestore
        .collection('bookings')
        .doc(bookingDocId)
        .snapshots()
        .map((doc) => BookingModel.fromMap(doc.data()!, doc.id));
  }

  @override
  Future<double> getAverageRating(String pilotId) async {
    final query = await _firestore
        .collection('bookings')
        .where('assignedPilotId', isEqualTo: pilotId)
        .where('status', isEqualTo: BookingStatus.closed.toFirestore())
        .get();

    if (query.docs.isEmpty) return 0.0;

    double total = 0;
    int count = 0;
    for (var doc in query.docs) {
      final rating = doc.data()['rating'];
      if (rating != null) {
        total += (rating as num).toDouble();
        count++;
      }
    }

    return count > 0 ? total / count : 0.0;
  }

  @override
  Future<void> verifyCoupon(String docId, String pilotId) async {
    final docRef = _firestore.collection('bookings').doc(docId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Booking not found');

      final data = snapshot.data()!;
      final status = data['status'];
      final isVerified = data['couponVerified'] ?? false;
      final assignedPilotId = data['assignedPilotId'];

      if (status == 'cancelled') {
        throw Exception('Cannot verify coupon for a cancelled booking');
      }
      if (isVerified) throw Exception('Coupon is already verified');
      if (assignedPilotId != pilotId) {
        throw Exception('Only the assigned pilot can verify the coupon');
      }

      transaction.update(docRef, {
        'couponVerified': true,
        'couponVerificationStatus': 'Verified',
        'couponVerifiedBy': data['assignedPilotName'] ?? pilotId,
        'couponVerifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final booking = await _bookingSnapshot(docId);
    if (booking != null) {
      await _notifications.createForRole(
        role: UserRole.admin,
        eventKey: 'coupon-verified-admin-$docId',
        title: 'Coupon verified',
        message:
            'Pilot ${booking.assignedPilotName} verified coupon ${booking.couponCode} for booking ${booking.bookingId}.',
        bookingId: docId,
        type: 'COUPON_VERIFIED',
      );
      if (booking.createdByRetailerId != null) {
        await _notifications.createForUser(
          recipientUid: booking.createdByRetailerId!,
          eventKey: 'retailer-coupon-verified-$docId',
          title: 'Coupon verified',
          message:
              'Pilot ${booking.assignedPilotName} verified your coupon ${booking.couponCode} for booking ${booking.bookingId}.',
          bookingId: docId,
          type: 'COUPON_VERIFIED',
        );
      }
    }
  }

  @override
  Future<void> collectCash(String docId, String pilotId) async {
    await _firestore.collection('bookings').doc(docId).update({
      'cashCollected': true,
      'cashCollectedBy': pilotId,
      'cashCollectedAt': FieldValue.serverTimestamp(),
      'paymentStatus': 'Cash Collected by Pilot',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final booking = await _bookingSnapshot(docId);
    if (booking != null) {
      await _notifications.createForUser(
        recipientUid: booking.farmerUid,
        eventKey: 'payment-recorded-$docId',
        title: 'Payment recorded',
        message:
            'Cash payment of ₹${booking.payableAmount?.toStringAsFixed(2) ?? '0.00'} has been recorded for booking ${booking.bookingId}.',
        bookingId: docId,
        type: 'PAYMENT_RECORDED',
      );
      await _notifications.createForRole(
        role: UserRole.operations,
        eventKey: 'cash-collected-ops-$docId',
        title: 'Cash collected',
        message:
            'Pilot ${booking.assignedPilotName} collected cash for booking ${booking.bookingId}.',
        bookingId: docId,
        type: 'CASH_COLLECTED',
      );
      await _notifications.createForUser(
        recipientUid: pilotId,
        eventKey: 'cash-deposit-reminder-$docId',
        title: 'Cash deposit reminder',
        message:
            'Please deposit the collected cash of ₹${booking.payableAmount?.toStringAsFixed(2) ?? '0.00'} at the office.',
        bookingId: docId,
        type: 'CASH_DEPOSIT_REMINDER',
      );
    }
  }

  @override
  Future<void> markCashDeposited(String docId, String pilotId) async {
    await _firestore.collection('bookings').doc(docId).update({
      'cashDeposited': true,
      'cashDepositedBy': pilotId,
      'cashDepositedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final booking = await _bookingSnapshot(docId);
    if (booking != null) {
      await _notifications.createForRole(
        role: UserRole.admin,
        eventKey: 'deposit-awaiting-confirmation-$docId',
        title: 'Deposit awaiting confirmation',
        message:
            'Pilot ${booking.assignedPilotName} has marked cash as deposited for booking ${booking.bookingId}.',
        bookingId: docId,
        type: 'CASH_DEPOSITED',
      );
      await _notifications.createForRole(
        role: UserRole.operations,
        eventKey: 'cash-deposited-ops-$docId',
        title: 'Cash deposited',
        message:
            'Pilot ${booking.assignedPilotName} deposited cash for booking ${booking.bookingId}.',
        bookingId: docId,
        type: 'CASH_DEPOSITED',
      );
    }
  }

  @override
  Future<void> startNavigation(String docId, StatusHistoryEntry historyEntry) async {
    await updateJobStatus(docId, BookingStatus.enRoute, historyEntry);
  }

  Future<BookingModel?> _bookingSnapshot(String bookingDocId) async {
    final doc = await _firestore.collection('bookings').doc(bookingDocId).get();
    if (!doc.exists || doc.data() == null) return null;
    return BookingModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<BookingModel>> _getAssignedOrCopilotJobsStream({
    required String pilotId,
    List<BookingStatus>? statuses,
    required bool orderByUpdatedAt,
  }) {
    final statusValues = statuses?.map((e) => e.toFirestore()).toList();
    final orderField = orderByUpdatedAt ? 'updatedAt' : 'createdAt';

    Query<Map<String, dynamic>> primaryQuery = _firestore
        .collection('bookings')
        .where('assignedPilotId', isEqualTo: pilotId);
    Query<Map<String, dynamic>> copilotQuery = _firestore
        .collection('bookings')
        .where('copilotId', isEqualTo: pilotId);

    if (statusValues != null) {
      primaryQuery = primaryQuery.where('status', whereIn: statusValues);
    }

    primaryQuery = primaryQuery.orderBy(orderField, descending: true);

    return Stream.multi((controller) {
      final jobsById = <String, BookingModel>{};
      Set<String> primaryIds = {};
      Set<String> copilotIds = {};

      void emit() {
        if (controller.isClosed) return;
        final activeIds = {...primaryIds, ...copilotIds};
        final jobs =
            activeIds
                .map((id) => jobsById[id])
                .whereType<BookingModel>()
                .toList()
              ..sort((a, b) {
                final left = orderByUpdatedAt ? a.updatedAt : a.createdAt;
                final right = orderByUpdatedAt ? b.updatedAt : b.createdAt;
                return right.compareTo(left);
              });
        controller.add(jobs);
      }

      void applySnapshot(
        QuerySnapshot<Map<String, dynamic>> snapshot,
        bool isPrimary,
      ) {
        final ids = <String>{};
        for (final doc in snapshot.docs) {
          if (!isPrimary &&
              statusValues != null &&
              !statusValues.contains(doc.data()['status'])) {
            continue;
          }
          ids.add(doc.id);
          jobsById[doc.id] = BookingModel.fromMap(doc.data(), doc.id);
        }

        final staleIds = (isPrimary ? primaryIds : copilotIds).difference(ids);
        if (isPrimary) {
          primaryIds = ids;
        } else {
          copilotIds = ids;
        }

        for (final id in staleIds) {
          if (!primaryIds.contains(id) && !copilotIds.contains(id)) {
            jobsById.remove(id);
          }
        }
        emit();
      }

      final primarySub = primaryQuery.snapshots().listen(
        (snapshot) => applySnapshot(snapshot, true),
        onError: controller.addError,
      );
      final copilotSub = copilotQuery.snapshots().listen(
        (snapshot) => applySnapshot(snapshot, false),
        onError: controller.addError,
      );

      controller.onCancel = () async {
        await Future.wait([primarySub.cancel(), copilotSub.cancel()]);
      };
    });
  }
}

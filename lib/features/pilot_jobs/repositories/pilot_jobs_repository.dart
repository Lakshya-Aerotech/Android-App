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
    required String droneDocId,
    required String pilotId,
    required Map<String, dynamic> completionData,
    required StatusHistoryEntry historyEntry,
  });
  Stream<BookingModel> getJobStream(String bookingDocId);
  Future<double> getAverageRating(String pilotId);
  Future<void> verifyCoupon(String docId, String pilotId);
  Future<void> collectCash(String docId, String pilotId);
  Future<void> markCashDeposited(String docId, String pilotId);
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

    final Map<String, dynamic> updates = {
      'status': status.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
      if (additionalUpdates != null) ...additionalUpdates,
    };

    await _firestore.collection('bookings').doc(bookingDocId).update(updates);

    final booking = await _bookingSnapshot(bookingDocId);

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

    if (booking != null && status == BookingStatus.arrived) {
      await _notifications.createForUser(
        recipientUid: booking.farmerUid,
        eventKey: 'pilot-arrived-$bookingDocId',
        title: 'Pilot arrived',
        message:
            '${booking.assignedPilotName ?? 'Your pilot'} arrived for booking ${booking.bookingId}.',
        bookingId: bookingDocId,
      );
    }

    if (booking != null && status == BookingStatus.inProgress) {
      await _notifications.createForUser(
        recipientUid: booking.farmerUid,
        eventKey: 'spraying-started-$bookingDocId',
        title: 'Spraying started',
        message:
            'Spraying has started for booking ${booking.bookingId} at ${booking.farmName}.',
        bookingId: bookingDocId,
      );
    }
  }

  @override
  Future<void> completeMission({
    required String bookingDocId,
    required String droneDocId,
    required String pilotId,
    required Map<String, dynamic> completionData,
    required StatusHistoryEntry historyEntry,
  }) async {
    if (bookingDocId.isEmpty || droneDocId.isEmpty || pilotId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Booking, Drone, or Pilot ID cannot be empty.',
      );
    }

    final bookingRef = _firestore.collection('bookings').doc(bookingDocId);
    final droneRef = _firestore.collection('drones').doc(droneDocId);
    final pilotRef = _firestore.collection('users').doc(pilotId);

    await _firestore.runTransaction((transaction) async {
      // 1. Get current pilot data for stats
      final pilotDoc = await transaction.get(pilotRef);
      if (!pilotDoc.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Pilot profile not found in database.',
        );
      }

      final pilotData = pilotDoc.data() ?? {};

      // Ensure numeric fields exist and handle potential type mismatches
      final int currentMinutes = (pilotData['totalFlightMinutes'] ?? 0) is int
          ? (pilotData['totalFlightMinutes'] ?? 0)
          : (pilotData['totalFlightMinutes'] as num?)?.toInt() ?? 0;

      final newMinutes =
          currentMinutes +
          (completionData['flightDurationMinutes'] as int? ?? 0);
      final newHours = double.parse((newMinutes / 60.0).toStringAsFixed(2));

      // 2. Update Booking
      transaction.update(bookingRef, {
        ...completionData,
        'status': BookingStatus.completed.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
      });

      // 3. Release Drone
      transaction.update(droneRef, {
        'status': 'available',
        'assignedBookingId': null,
        'assignedPilotId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Update Pilot Stats
      transaction.update(pilotRef, {
        'completedMissions': FieldValue.increment(1),
        'totalAcresCovered': FieldValue.increment(
          completionData['actualAreaCovered'] as num? ?? 0,
        ),
        'totalFlightMinutes': newMinutes,
        'totalFlightHours': newHours,
        'updatedAt': FieldValue.serverTimestamp(),
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
      );
      await _notifications.createForRole(
        role: UserRole.admin,
        eventKey: 'booking-completed-admin-$bookingDocId',
        title: 'Booking completed',
        message:
            'Booking ${booking.bookingId} for ${booking.farmName} has been completed.',
        bookingId: bookingDocId,
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
    await _firestore.collection('bookings').doc(docId).update({
      'couponVerified': true,
      'couponVerifiedBy': pilotId,
      'couponVerifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
  }

  @override
  Future<void> markCashDeposited(String docId, String pilotId) async {
    await _firestore.collection('bookings').doc(docId).update({
      'cashDeposited': true,
      'cashDepositedBy': pilotId,
      'cashDepositedAt': FieldValue.serverTimestamp(),
      'paymentStatus': 'Awaiting Admin Confirmation',
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/notifications/notification_repository.dart';
import '../../../shared/models/activity_model.dart';
import '../../../shared/repositories/activity_repository.dart';
import 'package:lakshya_aerotech/features/booking/models/booking_model.dart';
import 'package:lakshya_aerotech/features/auth/models/user_model.dart';
import 'package:lakshya_aerotech/features/operations/models/operations_models.dart';
import 'package:lakshya_aerotech/shared/enums/booking_status.dart';

abstract class OperationsRepository {
  Stream<List<BookingModel>> getBookingsByStatus(List<BookingStatus> statuses);
  Future<void> updateBookingStatus(
    String docId,
    BookingStatus status,
    StatusHistoryEntry historyEntry, {
    OperationsRemark? remark,
  });
  Stream<List<BookingModel>> getAllBookingsStream();
  Stream<List<BookingModel>> getRecentBookingsStream({int limit = 10});
  Stream<Map<String, dynamic>> getDashboardStatsStream();
  Stream<List<BookingModel>> getApprovedUnassignedBookingsStream();
  Stream<List<OpsPilotResource>> getAvailablePilotsStream();
  Stream<List<OpsDroneResource>> getDronesStream();
  Future<void> assignPilot(
    String bookingDocId,
    String pilotId,
    String pilotName,
    StatusHistoryEntry historyEntry,
  );
  Future<void> assignDrone(
    String bookingDocId,
    String droneId,
    String droneName,
    StatusHistoryEntry historyEntry,
  );
  Future<void> assignPilotAndDrone(
    OpsAssignmentRequest request,
    StatusHistoryEntry historyEntry,
  );
}

class OperationsRepositoryImpl implements OperationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notifications = NotificationRepository();

  @override
  Stream<List<BookingModel>> getBookingsByStatus(List<BookingStatus> statuses) {
    return _firestore
        .collection('bookings')
        .where('status', whereIn: statuses.map((e) => e.toFirestore()).toList())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Future<void> updateBookingStatus(
    String docId,
    BookingStatus status,
    StatusHistoryEntry historyEntry, {
    OperationsRemark? remark,
    BookingModel? booking, // Add optional booking for better logging
  }) async {
    final updates = <String, dynamic>{
      'status': status.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    };
    if (remark != null) {
      updates['operationsRemarks'] = FieldValue.arrayUnion([remark.toMap()]);
    }
    await _firestore.collection('bookings').doc(docId).update(updates);

    // Log Activity
    final isApproved = status == BookingStatus.reviewed;
    final bookingId = booking?.bookingId ?? docId;
    await ActivityRepository.logActivity(
      ActivityModel(
        type: isApproved
            ? ActivityType.bookingApproved
            : ActivityType.bookingRejected,
        description:
            'Booking ${isApproved ? 'approved' : 'rejected'}: $bookingId',
        userName: historyEntry.updatedBy,
        timestamp: DateTime.now(),
        metadata: {'bookingId': docId},
      ),
    );

    if (booking != null) {
      await _notifications.createForUser(
        recipientUid: booking.farmerUid,
        eventKey:
            '${isApproved ? 'booking-approved' : 'booking-rejected'}-$docId',
        title: isApproved ? 'Booking approved' : 'Booking rejected',
        message: isApproved
            ? 'Your booking ${booking.bookingId} for ${booking.farmName} has been approved.'
            : 'Your booking ${booking.bookingId} for ${booking.farmName} has been rejected.',
        bookingId: docId,
      );
    }
  }

  @override
  Stream<List<BookingModel>> getAllBookingsStream() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Stream<List<BookingModel>> getRecentBookingsStream({int limit = 10}) {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Stream<Map<String, dynamic>> getDashboardStatsStream() {
    return _firestore.collection('bookings').snapshots().map((bookingSnapshot) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      int pending = 0;
      int reviewed = 0;
      int pilotAssigned = 0;
      int droneAssigned = 0;
      int activeMissions = 0;
      int completedToday = 0;

      double acresScheduledToday = 0;
      double acresCompletedToday = 0;

      for (var doc in bookingSnapshot.docs) {
        final data = doc.data();
        final status = BookingStatus.fromString(data['status'] as String?);
        final bookingDateTs = data['bookingDate'] as Timestamp?;
        final bookingDate = bookingDateTs?.toDate();
        final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
        final estArea = (data['estimatedArea'] as num?)?.toDouble() ?? 0.0;
        final actArea = (data['actualAreaCovered'] as num?)?.toDouble() ?? 0.0;

        if (status == BookingStatus.pending) pending++;
        if (status == BookingStatus.reviewed) reviewed++;
        if (status == BookingStatus.pilotAssigned) pilotAssigned++;
        if (status == BookingStatus.droneAssigned) droneAssigned++;

        if ([
          BookingStatus.accepted,
          BookingStatus.enRoute,
          BookingStatus.arrived,
          BookingStatus.inProgress,
        ].contains(status)) {
          activeMissions++;
        }

        if (bookingDate != null &&
            bookingDate.year == now.year &&
            bookingDate.month == now.month &&
            bookingDate.day == now.day &&
            status != BookingStatus.cancelled) {
          acresScheduledToday += estArea;
        }

        if (status == BookingStatus.completed &&
            updatedAt != null &&
            updatedAt.isAfter(todayStart)) {
          completedToday++;
          acresCompletedToday += actArea;
        }
      }

      return {
        'pending': pending,
        'reviewed': reviewed,
        'pilotAssigned': pilotAssigned,
        'droneAssigned': droneAssigned,
        'activeMissions': activeMissions,
        'completedToday': completedToday,
        'acresScheduledToday': acresScheduledToday,
        'acresCompletedToday': acresCompletedToday,
      };
    });
  }

  @override
  Stream<List<BookingModel>> getApprovedUnassignedBookingsStream() {
    return _firestore
        .collection('bookings')
        .where(
          'status',
          whereIn: [BookingStatus.reviewed.toFirestore(), 'approved'],
        )
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .where((doc) => _isAwaitingAssignment(doc.data()))
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();

          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  @override
  Stream<List<OpsPilotResource>> getAvailablePilotsStream() {
    return Stream.multi((controller) {
      QuerySnapshot<Map<String, dynamic>>? usersSnapshot;
      QuerySnapshot<Map<String, dynamic>>? operatorSnapshot;

      void emit() {
        final users = usersSnapshot;
        if (users == null || controller.isClosed) return;

        final operatorDetails = <String, Map<String, dynamic>>{};
        for (final doc
            in operatorSnapshot?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
          final data = doc.data();
          final uid =
              (data['uid'] ?? data['userId'] ?? data['operatorId'] ?? doc.id)
                  .toString();
          operatorDetails[uid] = data;
        }

        final pilots =
            users.docs
                .map((doc) => _pilotFromDoc(doc, operatorDetails))
                .where((pilot) => pilot != null && pilot.canSelect)
                .cast<OpsPilotResource>()
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));

        controller.add(pilots);
      }

      final usersSub = _firestore.collection('users').snapshots().listen((
        snapshot,
      ) {
        usersSnapshot = snapshot;
        emit();
      }, onError: controller.addError);

      final operatorsSub = _firestore
          .collection('drone_operators')
          .snapshots()
          .listen(
            (snapshot) {
              operatorSnapshot = snapshot;
              emit();
            },
            onError: (_) {
              operatorSnapshot = null;
              emit();
            },
          );

      controller.onCancel = () async {
        await usersSub.cancel();
        await operatorsSub.cancel();
      };
    });
  }

  @override
  Stream<List<OpsDroneResource>> getDronesStream() {
    return _firestore.collection('drones').snapshots().map((snapshot) {
      final drones = snapshot.docs.map((doc) => _droneFromDoc(doc)).toList()
        ..sort((a, b) => a.code.compareTo(b.code));
      return drones;
    });
  }

  @override
  Future<void> assignPilot(
    String bookingDocId,
    String pilotId,
    String pilotName,
    StatusHistoryEntry historyEntry,
  ) async {
    await _firestore.collection('bookings').doc(bookingDocId).update({
      'assignedPilotId': pilotId,
      'assignedPilotName': pilotName,
      'status': BookingStatus.pilotAssigned.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });

    // Log Activity
    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.pilotAssigned,
        description: 'Pilot $pilotName assigned to booking: $bookingDocId',
        userName: historyEntry.updatedBy,
        timestamp: DateTime.now(),
        metadata: {'bookingId': bookingDocId},
      ),
    );

    final booking = await _bookingSnapshot(bookingDocId);
    if (booking != null) {
      await _notifications.createForUser(
        recipientUid: booking.farmerUid,
        eventKey: 'pilot-assigned-farmer-$bookingDocId',
        title: 'Pilot assigned',
        message:
            'Pilot $pilotName has been assigned to booking ${booking.bookingId}.',
        bookingId: bookingDocId,
      );
      await _notifications.createForUser(
        recipientUid: pilotId,
        eventKey: 'new-job-assigned-$bookingDocId-$pilotId',
        title: 'New job assigned',
        message:
            'You have a new job for ${booking.farmName} on ${booking.bookingId}.',
        bookingId: bookingDocId,
      );
    }
  }

  @override
  Future<void> assignDrone(
    String bookingDocId,
    String droneId,
    String droneName,
    StatusHistoryEntry historyEntry,
  ) async {
    await _firestore.collection('bookings').doc(bookingDocId).update({
      'assignedDroneId': droneId,
      'assignedDroneName': droneName,
      'status': BookingStatus.droneAssigned.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });

    // Log Activity
    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.droneAssigned,
        description: 'Drone $droneName assigned to booking: $bookingDocId',
        userName: historyEntry.updatedBy,
        timestamp: DateTime.now(),
        metadata: {'bookingId': bookingDocId},
      ),
    );
  }

  @override
  Future<void> assignPilotAndDrone(
    OpsAssignmentRequest request,
    StatusHistoryEntry historyEntry,
  ) async {
    final copilot = request.copilot;
    if (copilot != null && copilot.uid == request.pilot.uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Pilot and Copilot must be different employees.',
      );
    }

    final bookingRef = _firestore
        .collection('bookings')
        .doc(request.bookingDocId);
    final droneRef = _firestore.collection('drones').doc(request.drone.id);
    final pilotRef = _firestore
        .collection('users')
        .doc(request.pilot.documentId);
    final copilotRef = copilot == null
        ? null
        : _firestore.collection('users').doc(copilot.documentId);
    final assignmentRef = _firestore
        .collection('job_assignments')
        .doc(request.bookingDocId);

    await _firestore.runTransaction((transaction) async {
      final timestamp = FieldValue.serverTimestamp();

      final bookingDoc = await transaction.get(bookingRef);
      if (!bookingDoc.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Booking no longer exists.',
        );
      }

      final bookingData = bookingDoc.data() ?? const <String, dynamic>{};
      final bookingStatus = BookingStatus.fromString(
        bookingData['status']?.toString(),
      );
      final alreadyAssigned =
          bookingData['assignedPilotId'] != null ||
          bookingData['assignedDroneId'] != null;
      if (alreadyAssigned || bookingStatus != BookingStatus.reviewed) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'This booking has already been assigned.',
        );
      }

      final pilotDoc = await transaction.get(pilotRef);
      if (!pilotDoc.exists || !_isPilotSelectableData(pilotDoc.data())) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'Selected pilot is no longer available.',
        );
      }

      if (copilotRef != null) {
        final copilotDoc = await transaction.get(copilotRef);
        if (!copilotDoc.exists || !_isPilotSelectableData(copilotDoc.data())) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'failed-precondition',
            message: 'Selected copilot is no longer available.',
          );
        }
      }

      final droneDoc = await transaction.get(droneRef);
      if (!droneDoc.exists || !_isDroneSelectableData(droneDoc.data())) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'Selected drone is no longer available.',
        );
      }

      final bookingUpdates = <String, dynamic>{
        'assignedPilotId': request.pilot.uid,
        'assignedPilotName': request.pilot.name,
        'assignedDroneId': request.drone.id,
        'assignedDroneName': request.drone.name,
        'status': BookingStatus.droneAssigned.toFirestore(),
        'updatedAt': timestamp,
        'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
      };
      if (copilot != null) {
        bookingUpdates.addAll({
          'copilotId': copilot.uid,
          'copilotName': copilot.name,
          'assignedCopilotAt': timestamp,
        });
      }
      transaction.update(bookingRef, bookingUpdates);

      final assignmentUpdates = <String, dynamic>{
        'bookingId': request.bookingDocId,
        'assignedPilotId': request.pilot.uid,
        'assignedPilotName': request.pilot.name,
        'assignedDroneId': request.drone.id,
        'assignedDroneName': request.drone.name,
        'status': BookingStatus.droneAssigned.toFirestore(),
        'updatedAt': timestamp,
      };
      if (copilot != null) {
        assignmentUpdates.addAll({
          'copilotId': copilot.uid,
          'copilotName': copilot.name,
          'assignedCopilotAt': timestamp,
        });
      }
      transaction.set(
        assignmentRef,
        assignmentUpdates,
        SetOptions(merge: true),
      );

      transaction.update(droneRef, {
        'status': 'busy',
        'assignedBookingId': request.bookingDocId,
        'assignedPilotId': request.pilot.uid,
        'updatedAt': timestamp,
      });
    });

    // Log Activity
    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.pilotAssigned,
        description:
            'Pilot ${request.pilot.name} assigned to booking: ${request.bookingDocId}',
        userName: historyEntry.updatedBy,
        timestamp: DateTime.now(),
        metadata: {'bookingId': request.bookingDocId},
      ),
    );

    final booking = await _bookingSnapshot(request.bookingDocId);
    if (booking != null) {
      await _notifications.createForUser(
        recipientUid: booking.farmerUid,
        eventKey: 'pilot-assigned-farmer-${request.bookingDocId}',
        title: 'Pilot assigned',
        message:
            'Pilot ${request.pilot.name} has been assigned to booking ${booking.bookingId}.',
        bookingId: request.bookingDocId,
      );
      await _notifications.createForUser(
        recipientUid: request.pilot.uid,
        eventKey:
            'new-job-assigned-${request.bookingDocId}-${request.pilot.uid}',
        title: 'New job assigned',
        message:
            'You have a new job for ${booking.farmName} with drone ${request.drone.name}.',
        bookingId: request.bookingDocId,
      );
      if (request.copilot != null) {
        await _notifications.createForUser(
          recipientUid: request.copilot!.uid,
          eventKey:
              'new-job-assigned-${request.bookingDocId}-${request.copilot!.uid}',
          title: 'New job assigned',
          message:
              'You have a co-pilot job for ${booking.farmName} with drone ${request.drone.name}.',
          bookingId: request.bookingDocId,
        );
      }
      await _notifications.createForRole(
        role: UserRole.operations,
        eventKey: 'assignment-completed-${request.bookingDocId}',
        title: 'Assignment completed',
        message:
            '${request.pilot.name} and ${request.drone.name} were assigned to booking ${booking.bookingId}.',
        bookingId: request.bookingDocId,
      );
    }
  }

  Future<BookingModel?> _bookingSnapshot(String bookingDocId) async {
    final doc = await _firestore.collection('bookings').doc(bookingDocId).get();
    if (!doc.exists || doc.data() == null) return null;
    return BookingModel.fromMap(doc.data()!, doc.id);
  }

  bool _isAwaitingAssignment(Map<String, dynamic> data) {
    final statusText = data['status']?.toString();
    final status = BookingStatus.fromString(statusText);

    final isValidForAssignment =
        status == BookingStatus.reviewed ||
        status == BookingStatus.pilotAssigned;

    final isDeleted = data['isDeleted'] == true;
    final isCancelled = status == BookingStatus.cancelled;

    final assignedPilot = data['assignedPilotId'];
    final assignedDrone = data['assignedDroneId'];

    return isValidForAssignment &&
        !isDeleted &&
        !isCancelled &&
        (assignedPilot == null || assignedDrone == null);
  }

  OpsPilotResource? _pilotFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, Map<String, dynamic>> operatorDetails,
  ) {
    final data = doc.data();
    if (data == null) return null;

    final role = (data['role'] ?? '').toString();
    const pilotRoles = {'pilot', 'drone_operator', 'droneOperator', 'externalPilot'};
    if (!pilotRoles.contains(role)) return null;

    final isDeleted = data['isDeleted'] == true || data['deleted'] == true;
    if (isDeleted) return null;

    final uid = (data['uid'] ?? doc.id).toString();
    final details = operatorDetails[uid] ?? const <String, dynamic>{};
    final active = data['isActive'] != false;
    final availableValue =
        details['isAvailable'] ??
        data['isAvailableForJobs'] ??
        data['isAvailable'];
    final availability = (details['availability'] ?? data['availability'] ?? '')
        .toString()
        .toLowerCase();
    final activeBookingId =
        details['currentBookingId'] ??
        details['activeBookingId'] ??
        data['currentBookingId'];
    final isAvailable =
        availableValue != false &&
        availability != 'unavailable' &&
        availability != 'assigned' &&
        (activeBookingId == null || activeBookingId.toString().isEmpty);

    return OpsPilotResource(
      uid: uid,
      documentId: doc.id,
      name: (data['name'] ?? data['displayName'] ?? 'Pilot').toString(),
      phoneNumber: (data['phoneNumber'] ?? data['phone'])?.toString(),
      profileImageUrl: data['profileImageUrl']?.toString(),
      role: role,
      isActive: active,
      isAvailable: isAvailable,
      currentWorkload:
          (details['currentWorkload'] as num?)?.toInt() ??
          (data['currentWorkload'] as num?)?.toInt(),
      details: details,
    );
  }

  bool _isPilotSelectableData(Map<String, dynamic>? data) {
    if (data == null) return false;

    final role = (data['role'] ?? '').toString();
    const pilotRoles = {'pilot', 'drone_operator', 'droneOperator', 'externalPilot'};
    if (!pilotRoles.contains(role)) return false;

    final isDeleted = data['isDeleted'] == true || data['deleted'] == true;
    if (isDeleted || data['isActive'] == false) return false;

    final availability = (data['availability'] ?? '').toString().toLowerCase();
    final activeBookingId = data['currentBookingId'] ?? data['activeBookingId'];
    return data['isAvailableForJobs'] != false &&
        data['isAvailable'] != false &&
        availability != 'unavailable' &&
        availability != 'assigned' &&
        (activeBookingId == null || activeBookingId.toString().isEmpty);
  }

  OpsDroneResource _droneFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final availability =
        (data['availability'] ?? data['availabilityStatus'] ?? '')
            .toString()
            .toLowerCase();
    final status = (data['operationalStatus'] ?? data['status'] ?? 'available')
        .toString();
    final activeBookingId =
        data['currentBookingId'] ??
        data['activeBookingId'] ??
        data['assignedBookingId'];

    return OpsDroneResource(
      id: doc.id,
      code:
          (data['droneCode'] ?? data['code'] ?? data['serialNumber'] ?? doc.id)
              .toString(),
      name: (data['droneName'] ?? data['name'] ?? data['model'] ?? 'Drone')
          .toString(),
      batteryPercentage:
          (data['batteryPercentage'] as num?)?.toInt() ??
          (data['battery'] as num?)?.toInt(),
      operationalStatus: status,
      isActive: data['isActive'] != false && status.toLowerCase() != 'inactive',
      isAvailable:
          data['isAvailable'] != false &&
          availability != 'assigned' &&
          availability != 'unavailable' &&
          availability != 'maintenance',
      isDeleted: data['isDeleted'] == true || data['deleted'] == true,
      activeBookingId: activeBookingId?.toString(),
    );
  }

  bool _isDroneSelectableData(Map<String, dynamic>? data) {
    if (data == null) return false;

    final availability =
        (data['availability'] ?? data['availabilityStatus'] ?? '')
            .toString()
            .toLowerCase();
    final status = (data['operationalStatus'] ?? data['status'] ?? 'available')
        .toString()
        .toLowerCase();
    final activeBookingId =
        data['currentBookingId'] ??
        data['activeBookingId'] ??
        data['assignedBookingId'];

    return data['isActive'] != false &&
        data['isDeleted'] != true &&
        data['deleted'] != true &&
        data['isAvailable'] != false &&
        status != 'inactive' &&
        status != 'busy' &&
        availability != 'assigned' &&
        availability != 'unavailable' &&
        availability != 'maintenance' &&
        (activeBookingId == null || activeBookingId.toString().isEmpty);
  }
}

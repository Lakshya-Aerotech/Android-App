import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakshya_aerotech/features/booking/models/booking_model.dart';
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
  Future<void> assignPilot(String bookingDocId, String pilotId, String pilotName, StatusHistoryEntry historyEntry);
  Future<void> assignDrone(String bookingDocId, String droneId, String droneName, StatusHistoryEntry historyEntry);
  Future<void> assignPilotAndDrone(OpsAssignmentRequest request, StatusHistoryEntry historyEntry);
}

class OperationsRepositoryImpl implements OperationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        
        if ([BookingStatus.accepted, BookingStatus.enRoute, BookingStatus.arrived, BookingStatus.inProgress].contains(status)) {
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
  Future<void> assignPilot(String bookingDocId, String pilotId, String pilotName, StatusHistoryEntry historyEntry) async {
    await _firestore.collection('bookings').doc(bookingDocId).update({
      'assignedPilotId': pilotId,
      'assignedPilotName': pilotName,
      'status': BookingStatus.pilotAssigned.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });
  }

  @override
  Future<void> assignDrone(String bookingDocId, String droneId, String droneName, StatusHistoryEntry historyEntry) async {
    await _firestore.collection('bookings').doc(bookingDocId).update({
      'assignedDroneId': droneId,
      'assignedDroneName': droneName,
      'status': BookingStatus.droneAssigned.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });
  }

  @override
  Future<void> assignPilotAndDrone(OpsAssignmentRequest request, StatusHistoryEntry historyEntry) async {
    final bookingRef = _firestore.collection('bookings').doc(request.bookingDocId);
    final droneRef = _firestore.collection('drones').doc(request.drone.id);
    final assignmentRef = _firestore.collection('job_assignments').doc(request.bookingDocId);

    await _firestore.runTransaction((transaction) async {
      final timestamp = FieldValue.serverTimestamp();
      
      transaction.update(bookingRef, {
        'assignedPilotId': request.pilot.uid,
        'assignedPilotName': request.pilot.name,
        'assignedDroneId': request.drone.id,
        'assignedDroneName': request.drone.name,
        'status': BookingStatus.droneAssigned.toFirestore(),
        'updatedAt': timestamp,
        'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
      });

      transaction.set(assignmentRef, {
        'bookingId': request.bookingDocId,
        'assignedPilotId': request.pilot.uid,
        'assignedPilotName': request.pilot.name,
        'assignedDroneId': request.drone.id,
        'assignedDroneName': request.drone.name,
        'status': BookingStatus.droneAssigned.toFirestore(),
        'updatedAt': timestamp,
      }, SetOptions(merge: true));

      transaction.update(droneRef, {
        'status': 'busy',
        'updatedAt': timestamp,
      });
    });
  }

  bool _isAwaitingAssignment(Map<String, dynamic> data) {
    final statusText = data['status']?.toString();
    final status = BookingStatus.fromString(statusText);
    
    final isValidForAssignment = status == BookingStatus.reviewed || 
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
    const pilotRoles = {'pilot', 'drone_operator', 'droneOperator'};
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
}

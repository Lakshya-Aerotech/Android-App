import 'package:cloud_firestore/cloud_firestore.dart';
import '../../booking/models/booking_model.dart';
import '../../../shared/enums/booking_status.dart';

abstract class PilotJobsRepository {
  Stream<List<BookingModel>> getJobsByStatus(String pilotId, List<BookingStatus> statuses);
  Stream<List<BookingModel>> getAllPilotJobsStream(String pilotId);
  Future<void> updateJobStatus(String bookingDocId, BookingStatus status, StatusHistoryEntry historyEntry, {Map<String, dynamic>? additionalUpdates});
  Future<void> completeMission({
    required String bookingDocId,
    required String droneDocId,
    required String pilotId,
    required Map<String, dynamic> completionData,
    required StatusHistoryEntry historyEntry,
  });
  Stream<BookingModel> getJobStream(String bookingDocId);
}

class PilotJobsRepositoryImpl implements PilotJobsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<BookingModel>> getJobsByStatus(String pilotId, List<BookingStatus> statuses) {
    return _firestore
        .collection('bookings')
        .where('assignedPilotId', isEqualTo: pilotId)
        .where('status', whereIn: statuses.map((e) => e.toFirestore()).toList())
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<BookingModel>> getAllPilotJobsStream(String pilotId) {
    return _firestore
        .collection('bookings')
        .where('assignedPilotId', isEqualTo: pilotId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> updateJobStatus(String bookingDocId, BookingStatus status, StatusHistoryEntry historyEntry, {Map<String, dynamic>? additionalUpdates}) async {
    final Map<String, dynamic> updates = {
      'status': status.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
      if (additionalUpdates != null) ...additionalUpdates,
    };

    await _firestore.collection('bookings').doc(bookingDocId).update(updates);
  }

  @override
  Future<void> completeMission({
    required String bookingDocId,
    required String droneDocId,
    required String pilotId,
    required Map<String, dynamic> completionData,
    required StatusHistoryEntry historyEntry,
  }) async {
    final bookingRef = _firestore.collection('bookings').doc(bookingDocId);
    final droneRef = _firestore.collection('drones').doc(droneDocId);
    final pilotRef = _firestore.collection('users').doc(pilotId);

    await _firestore.runTransaction((transaction) async {
      // 1. Get current pilot data for stats
      final pilotDoc = await transaction.get(pilotRef);
      final pilotData = pilotDoc.data() ?? {};
      
      final currentMinutes = (pilotData['totalFlightMinutes'] ?? 0) as int;
      final newMinutes = currentMinutes + (completionData['flightDurationMinutes'] as int? ?? 0);
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
        'totalAcresCovered': FieldValue.increment(completionData['actualAreaCovered'] as num? ?? 0),
        'totalFlightMinutes': newMinutes,
        'totalFlightHours': newHours,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Stream<BookingModel> getJobStream(String bookingDocId) {
    return _firestore
        .collection('bookings')
        .doc(bookingDocId)
        .snapshots()
        .map((doc) => BookingModel.fromMap(doc.data()!, doc.id));
  }
}

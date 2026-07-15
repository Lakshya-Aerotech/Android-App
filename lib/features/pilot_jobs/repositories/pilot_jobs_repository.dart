import 'package:cloud_firestore/cloud_firestore.dart';
import '../../booking/models/booking_model.dart';
import '../../../shared/enums/booking_status.dart';

abstract class PilotJobsRepository {
  Stream<List<BookingModel>> getJobsByStatus(String pilotId, List<BookingStatus> statuses);
  Stream<List<BookingModel>> getAllPilotJobsStream(String pilotId);
  Future<void> updateJobStatus(String bookingDocId, BookingStatus status, StatusHistoryEntry historyEntry, {String? rejectionReason});
  Future<void> completeMission(String bookingDocId, Map<String, dynamic> completionData, String droneDocId, StatusHistoryEntry historyEntry);
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
  Future<void> updateJobStatus(String bookingDocId, BookingStatus status, StatusHistoryEntry historyEntry, {String? rejectionReason}) async {
    final Map<String, dynamic> updates = {
      'status': status.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    };

    if (rejectionReason != null) {
      updates['pilotRejectionReason'] = rejectionReason;
    }

    await _firestore.collection('bookings').doc(bookingDocId).update(updates);
  }

  @override
  Future<void> completeMission(String bookingDocId, Map<String, dynamic> completionData, String droneDocId, StatusHistoryEntry historyEntry) async {
    final batch = _firestore.batch();

    // 1. Update Booking
    final bookingRef = _firestore.collection('bookings').doc(bookingDocId);
    batch.update(bookingRef, {
      ...completionData,
      'status': BookingStatus.completed.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });

    // 2. Release Drone
    final droneRef = _firestore.collection('drones').doc(droneDocId);
    batch.update(droneRef, {
      'status': 'available',
      'assignedBookingId': null,
      'assignedPilotId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
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

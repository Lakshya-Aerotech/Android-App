import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakshya_aerotech/features/booking/models/booking_model.dart';
import 'package:lakshya_aerotech/shared/enums/booking_status.dart';

abstract class OperationsRepository {
  Stream<List<BookingModel>> getBookingsByStatus(List<BookingStatus> statuses);
  Future<void> updateBookingStatus(String docId, BookingStatus status, {OperationsRemark? remark});
  Stream<List<BookingModel>> getAllBookingsStream();
  Stream<List<BookingModel>> getRecentBookingsStream({int limit = 10});
  Stream<Map<String, int>> getDashboardStatsStream();
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
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> updateBookingStatus(String docId, BookingStatus status, {OperationsRemark? remark}) async {
    final updates = <String, dynamic>{
      'status': status.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
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
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<BookingModel>> getRecentBookingsStream({int limit = 10}) {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<Map<String, int>> getDashboardStatsStream() {
    return _firestore.collection('bookings').snapshots().map((snapshot) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      
      int pending = 0;
      int reviewed = 0;
      int pilotAssigned = 0;
      int completedToday = 0;
      int cancelled = 0;
      int todayBookings = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = BookingStatus.fromString(data['status'] as String?);
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

        if (status == BookingStatus.pending) pending++;
        if (status == BookingStatus.reviewed) reviewed++;
        if (status == BookingStatus.pilotAssigned) pilotAssigned++;
        if (status == BookingStatus.cancelled) cancelled++;
        
        if (createdAt != null && createdAt.isAfter(todayStart)) {
          todayBookings++;
        }
        
        if (status == BookingStatus.completed && updatedAt != null && updatedAt.isAfter(todayStart)) {
          completedToday++;
        }
      }

      return {
        'pending': pending,
        'reviewed': reviewed,
        'pilotAssigned': pilotAssigned,
        'completedToday': completedToday,
        'cancelled': cancelled,
        'todayBookings': todayBookings,
      };
    });
  }
}

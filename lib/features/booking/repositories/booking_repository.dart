import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/enums/booking_status.dart';
import '../models/booking_model.dart';

abstract class BookingRepository {
  Stream<List<BookingModel>> getFarmerBookingsStream(String farmerUid);
  Future<String> createBooking(BookingModel booking);
  Future<void> cancelBooking(String docId, StatusHistoryEntry historyEntry);
  Future<BookingModel?> getBookingById(String docId);
  Stream<BookingModel?> getBookingStream(String docId);
  Future<void> confirmService(String docId, StatusHistoryEntry historyEntry);
  Future<void> submitRating(String docId, double rating, String feedback);
  Future<void> reportIssue(String docId, String category, String description, StatusHistoryEntry historyEntry);
}

class BookingRepositoryImpl implements BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<BookingModel>> getFarmerBookingsStream(String farmerUid) {
    return _firestore
        .collection('bookings')
        .where('farmerUid', isEqualTo: farmerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<String> createBooking(BookingModel booking) async {
    final historyEntry = StatusHistoryEntry(
      status: BookingStatus.pending,
      updatedBy: booking.farmerName ?? 'Farmer',
      updatedByRole: 'farmer',
      timestamp: DateTime.now(),
      remarks: 'Booking submitted successfully.',
    );

    final bookingData = booking.toMap();
    bookingData['statusHistory'] = [historyEntry.toMap()];

    final docRef = await _firestore.collection('bookings').add(bookingData);
    return docRef.id;
  }

  @override
  Future<void> cancelBooking(String docId, StatusHistoryEntry historyEntry) async {
    await _firestore.collection('bookings').doc(docId).update({
      'status': BookingStatus.cancelled.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });
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
        .map((doc) => doc.exists ? BookingModel.fromMap(doc.data()!, doc.id) : null);
  }

  @override
  Future<void> confirmService(String docId, StatusHistoryEntry historyEntry) async {
    await _firestore.collection('bookings').doc(docId).update({
      'status': BookingStatus.farmerConfirmed.toFirestore(),
      'confirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });
  }

  @override
  Future<void> submitRating(String docId, double rating, String feedback) async {
    await _firestore.collection('bookings').doc(docId).update({
      'rating': rating,
      'feedback': feedback,
      'feedbackCreatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> reportIssue(String docId, String category, String description, StatusHistoryEntry historyEntry) async {
    await _firestore.collection('bookings').doc(docId).update({
      'status': BookingStatus.issueReported.toFirestore(),
      'issueCategory': category,
      'issueDescription': description,
      'issueReportedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });
  }
}

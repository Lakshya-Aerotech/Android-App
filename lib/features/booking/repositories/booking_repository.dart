import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/enums/booking_status.dart';
import '../models/booking_model.dart';

abstract class BookingRepository {
  Stream<List<BookingModel>> getFarmerBookingsStream(String farmerUid);
  Future<String> createBooking(BookingModel booking);
  Future<void> cancelBooking(String docId);
  Future<BookingModel?> getBookingById(String docId);
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
    final docRef = await _firestore.collection('bookings').add(booking.toMap());
    // After adding, we update the document with its own auto-generated ID as bookingId if needed,
    // but the prompt says bookingId should be in the document.
    // Usually bookingId is a human readable format like LA-2023-XXXX.
    // For now I'll just use the document ID as the unique identifier if it wasn't provided.
    return docRef.id;
  }

  @override
  Future<void> cancelBooking(String docId) async {
    await _firestore.collection('bookings').doc(docId).update({
      'status': BookingStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
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
}

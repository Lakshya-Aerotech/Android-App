import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lakshya_aerotech/features/operations/models/operations_models.dart';
import 'package:lakshya_aerotech/features/booking/models/booking_model.dart';
import 'package:lakshya_aerotech/shared/enums/booking_status.dart';

abstract class OperationsRepository {
  Future<List<OperationsStatistic>> getStatistics();
  Future<List<ActiveService>> getActiveServices();
  Future<List<PendingAssignment>> getPendingAssignments();
  Future<List<OperationsActivity>> getRecentActivities();
  
  Stream<List<BookingModel>> getBookingsByStatus(List<BookingStatus> statuses);
  Future<void> updateBookingStatus(String docId, BookingStatus status, {OperationsRemark? remark});
  Stream<List<BookingModel>> getAllBookingsStream();
}

class OperationsRepositoryImpl implements OperationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<OperationsStatistic>> getStatistics() async {
    return [
      const OperationsStatistic(icon: Icons.pending_actions, iconColor: Colors.orange, title: 'Pending Bookings', value: '12'),
      const OperationsStatistic(icon: Icons.rate_review_outlined, iconColor: Colors.blue, title: 'Under Review', value: '5'),
      const OperationsStatistic(icon: Icons.assignment_ind_outlined, iconColor: Colors.purple, title: 'Assigned Jobs', value: '28'),
      const OperationsStatistic(icon: Icons.run_circle_outlined, iconColor: Colors.green, title: 'Active Services', value: '8'),
      const OperationsStatistic(icon: Icons.person_search_outlined, iconColor: Colors.teal, title: 'Available Pilots', value: '15'),
      const OperationsStatistic(icon: Icons.precision_manufacturing_outlined, iconColor: Colors.indigo, title: 'Available Drones', value: '10'),
      const OperationsStatistic(icon: Icons.task_alt, iconColor: Colors.green, title: 'Today Completed', value: '18'),
      const OperationsStatistic(icon: Icons.report_problem_outlined, iconColor: Colors.red, title: 'Issues Reported', value: '2'),
    ];
  }

  @override
  Future<List<ActiveService>> getActiveServices() async {
    return [
      const ActiveService(bookingId: 'BK-1024', farmerName: 'Ramesh Babu', pilotName: 'Suresh Kumar', droneId: 'DR-007', village: 'Kothapalli', status: 'In Progress', statusColor: Colors.orange),
      const ActiveService(bookingId: 'BK-1025', farmerName: 'Venkatesh Rao', pilotName: 'Anil Kumar', droneId: 'DR-012', village: 'Peddapalli', status: 'Started', statusColor: Colors.green),
    ];
  }

  @override
  Future<List<PendingAssignment>> getPendingAssignments() async {
    return [
      const PendingAssignment(bookingId: 'BK-1030', farmerName: 'Mahesh Reddy', serviceName: 'Precision Spraying', preferredDate: '24 Oct 2023', area: '5.5 Acres'),
    ];
  }

  @override
  Future<List<OperationsActivity>> getRecentActivities() async {
    return [
      const OperationsActivity(title: 'Pilot Suresh Assigned to BK-1024', time: '10 mins ago', icon: Icons.assignment_ind, iconColor: Colors.blue),
    ];
  }

  @override
  Stream<List<BookingModel>> getBookingsByStatus(List<BookingStatus> statuses) {
    return _firestore
        .collection('bookings')
        .where('status', whereIn: statuses.map((e) => e.name).toList())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> updateBookingStatus(String docId, BookingStatus status, {OperationsRemark? remark}) async {
    final updates = <String, dynamic>{
      'status': status.name,
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
}

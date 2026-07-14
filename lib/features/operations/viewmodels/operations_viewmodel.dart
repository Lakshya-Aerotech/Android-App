import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/operations_models.dart';
import '../repositories/operations_repository.dart';
import '../../booking/models/booking_model.dart';
import '../../../shared/enums/booking_status.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

final operationsRepositoryProvider = Provider<OperationsRepository>((ref) {
  return OperationsRepositoryImpl();
});

final dashboardStatsStreamProvider = StreamProvider<List<OperationsStatistic>>((ref) {
  return ref.watch(operationsRepositoryProvider).getDashboardStatsStream().map((stats) {
    return [
      OperationsStatistic(
        icon: Icons.pending_actions,
        iconColor: Colors.orange,
        title: 'Pending Bookings',
        value: stats['pending'].toString(),
      ),
      OperationsStatistic(
        icon: Icons.rate_review_outlined,
        iconColor: Colors.blue,
        title: 'Under Review',
        value: stats['reviewed'].toString(),
      ),
      OperationsStatistic(
        icon: Icons.assignment_ind_outlined,
        iconColor: Colors.purple,
        title: 'Pilot Assigned',
        value: stats['pilotAssigned'].toString(),
      ),
      OperationsStatistic(
        icon: Icons.task_alt,
        iconColor: Colors.green,
        title: 'Completed Today',
        value: stats['completedToday'].toString(),
      ),
      OperationsStatistic(
        icon: Icons.cancel_outlined,
        iconColor: Colors.red,
        title: 'Cancelled',
        value: stats['cancelled'].toString(),
      ),
      OperationsStatistic(
        icon: Icons.today,
        iconColor: Colors.teal,
        title: "Today's Bookings",
        value: stats['todayBookings'].toString(),
      ),
    ];
  });
});

final recentBookingsStreamProvider = StreamProvider<List<BookingModel>>((ref) {
  return ref.watch(operationsRepositoryProvider).getRecentBookingsStream(limit: 5);
});

final pendingBookingsStreamProvider = StreamProvider<List<BookingModel>>((ref) {
  return ref.watch(operationsRepositoryProvider).getBookingsByStatus([BookingStatus.pending]);
});

class OperationsViewModel extends StateNotifier<AsyncValue<void>> {
  final OperationsRepository _repository;
  final Ref _ref;

  OperationsViewModel(this._repository, this._ref) : super(const AsyncData(null));

  Future<void> approveBooking(String docId, {String? remarkMessage}) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(userModelProvider);
      OperationsRemark? remark;
      if (remarkMessage != null && remarkMessage.isNotEmpty) {
        remark = OperationsRemark(
          message: remarkMessage,
          createdBy: user?.name ?? 'Operations',
          timestamp: DateTime.now(),
        );
      }
      await _repository.updateBookingStatus(docId, BookingStatus.reviewed, remark: remark);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> rejectBooking(String docId, String remarkMessage) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(userModelProvider);
      final remark = OperationsRemark(
        message: remarkMessage,
        createdBy: user?.name ?? 'Operations',
        timestamp: DateTime.now(),
      );
      await _repository.updateBookingStatus(docId, BookingStatus.cancelled, remark: remark);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> requestChanges(String docId, String remarkMessage) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(userModelProvider);
      final remark = OperationsRemark(
        message: remarkMessage,
        createdBy: user?.name ?? 'Operations',
        timestamp: DateTime.now(),
      );
      await _repository.updateBookingStatus(docId, BookingStatus.pending, remark: remark);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final operationsViewModelProvider = StateNotifierProvider<OperationsViewModel, AsyncValue<void>>((ref) {
  return OperationsViewModel(ref.watch(operationsRepositoryProvider), ref);
});

/// A specialized provider to ensure even legacy bookings have complete information
final hydratedBookingProvider = FutureProvider.family<BookingModel, BookingModel>((ref, booking) async {
  // If snapshot is already complete, return as is
  if (booking.farmerName != null && booking.latitude != null) {
    return booking;
  }
  
  String? farmerName = booking.farmerName;
  String? farmerPhone = booking.farmerPhone;
  double? latitude = booking.latitude;
  double? longitude = booking.longitude;
  String? village = booking.village;
  String? district = booking.district;

  try {
    // Fetch missing Farmer Info
    if (farmerName == null) {
      final farmerDoc = await FirebaseFirestore.instance.collection('users').doc(booking.farmerUid).get();
      if (farmerDoc.exists) {
        final data = farmerDoc.data()!;
        farmerName = data['name'];
        farmerPhone = data['phoneNumber'];
      }
    }

    // Fetch missing Farm Info
    if (latitude == null) {
      final farmDoc = await FirebaseFirestore.instance.collection('farms').doc(booking.farmId).get();
      if (farmDoc.exists) {
        final data = farmDoc.data()!;
        latitude = (data['latitude'] as num?)?.toDouble();
        longitude = (data['longitude'] as num?)?.toDouble();
        village ??= data['village'];
        district ??= data['district'];
      }
    }

    return booking.copyWith(
      farmerName: farmerName,
      farmerPhone: farmerPhone,
      latitude: latitude,
      longitude: longitude,
      village: village,
      district: district,
    );
  } catch (e) {
    debugPrint('Error hydrating legacy booking: $e');
    return booking;
  }
});

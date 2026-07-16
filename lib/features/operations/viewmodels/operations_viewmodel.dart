import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakshya_aerotech/core/theme/app_colors.dart';
import '../models/operations_models.dart';
import '../repositories/operations_repository.dart';
import '../../booking/models/booking_model.dart';
import '../../../shared/enums/booking_status.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

final operationsRepositoryProvider = Provider<OperationsRepository>((ref) {
  return OperationsRepositoryImpl();
});

final dashboardStatsStreamProvider = StreamProvider<List<OperationsStatistic>>((
  ref,
) {
  return ref.watch(operationsRepositoryProvider).getDashboardStatsStream().map((
    stats,
  ) {
    return [
      OperationsStatistic(
        icon: Icons.pending_actions,
        iconColor: Colors.orange,
        title: 'Pending Review',
        value: stats['pending'].toString(),
      ),
      OperationsStatistic(
        icon: Icons.rate_review_outlined,
        iconColor: Colors.blue,
        title: 'Approved',
        value: stats['reviewed'].toString(),
      ),
      OperationsStatistic(
        icon: Icons.assignment_ind_outlined,
        iconColor: Colors.purple,
        title: 'Pilot Assigned',
        value: stats['pilotAssigned'].toString(),
      ),
      OperationsStatistic(
        icon: Icons.precision_manufacturing_outlined,
        iconColor: Colors.indigo,
        title: 'Drone Assigned',
        value: stats['droneAssigned'].toString(),
      ),
      OperationsStatistic(
        icon: Icons.run_circle_outlined,
        iconColor: AppColors.accent,
        title: 'Active Missions',
        value: stats['activeMissions'].toString(),
      ),
      OperationsStatistic(
        icon: Icons.task_alt,
        iconColor: Colors.green,
        title: 'Completed Today',
        value: stats['completedToday'].toString(),
      ),
      OperationsStatistic(
        icon: Icons.calendar_today,
        iconColor: Colors.teal,
        title: 'Acres Scheduled',
        value: (stats['acresScheduledToday'] as num?)?.toStringAsFixed(1) ?? '0.0',
      ),
      OperationsStatistic(
        icon: Icons.done_all,
        iconColor: Colors.green.shade800,
        title: 'Acres Completed',
        value: (stats['acresCompletedToday'] as num?)?.toStringAsFixed(1) ?? '0.0',
      ),
    ];
  });
});

final recentBookingsStreamProvider = StreamProvider<List<BookingModel>>((ref) {
  return ref
      .watch(operationsRepositoryProvider)
      .getRecentBookingsStream(limit: 5);
});

final pendingBookingsStreamProvider = StreamProvider<List<BookingModel>>((ref) {
  return ref.watch(operationsRepositoryProvider).getBookingsByStatus([
    BookingStatus.pending,
  ]);
});

final reportedIssuesStreamProvider = StreamProvider<List<BookingModel>>((ref) {
  return ref.watch(operationsRepositoryProvider).getBookingsByStatus([
    BookingStatus.issueReported,
  ]);
});

final approvedUnassignedBookingsStreamProvider =
    StreamProvider<List<BookingModel>>((ref) {
      return ref
          .watch(operationsRepositoryProvider)
          .getApprovedUnassignedBookingsStream();
    });

final availablePilotsStreamProvider = StreamProvider<List<OpsPilotResource>>((
  ref,
) {
  return ref.watch(operationsRepositoryProvider).getAvailablePilotsStream();
});

final dronesStreamProvider = StreamProvider<List<OpsDroneResource>>((ref) {
  return ref.watch(operationsRepositoryProvider).getDronesStream();
});

class OperationsViewModel extends StateNotifier<AsyncValue<void>> {
  final OperationsRepository _repository;
  final Ref _ref;

  OperationsViewModel(this._repository, this._ref)
    : super(const AsyncData(null));

  Future<void> approveBooking(String docId, {String? remarkMessage}) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(userModelProvider);
      
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.reviewed,
        updatedBy: user?.name ?? 'Operations',
        updatedByRole: 'operations',
        timestamp: DateTime.now(),
        remarks: remarkMessage ?? 'Booking approved by operations.',
      );

      OperationsRemark? remark;
      if (remarkMessage != null && remarkMessage.isNotEmpty) {
        remark = OperationsRemark(
          message: remarkMessage,
          createdBy: user?.name ?? 'Operations',
          timestamp: DateTime.now(),
        );
      }
      await _repository.updateBookingStatus(
        docId,
        BookingStatus.reviewed,
        historyEntry,
        remark: remark,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> rejectBooking(String docId, String remarkMessage) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(userModelProvider);

      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.cancelled,
        updatedBy: user?.name ?? 'Operations',
        updatedByRole: 'operations',
        timestamp: DateTime.now(),
        remarks: remarkMessage,
      );

      final remark = OperationsRemark(
        message: remarkMessage,
        createdBy: user?.name ?? 'Operations',
        timestamp: DateTime.now(),
      );
      await _repository.updateBookingStatus(
        docId,
        BookingStatus.cancelled,
        historyEntry,
        remark: remark,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> assignPilot(String bookingId, String pilotId, String pilotName) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(userModelProvider);
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.pilotAssigned,
        updatedBy: user?.name ?? 'Operations',
        updatedByRole: 'operations',
        timestamp: DateTime.now(),
        remarks: 'Pilot $pilotName assigned to job.',
      );
      await _repository.assignPilot(bookingId, pilotId, pilotName, historyEntry);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> assignDrone(String bookingId, String droneId, String droneName) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(userModelProvider);
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.droneAssigned,
        updatedBy: user?.name ?? 'Operations',
        updatedByRole: 'operations',
        timestamp: DateTime.now(),
        remarks: 'Drone $droneName assigned to job.',
      );
      await _repository.assignDrone(bookingId, droneId, droneName, historyEntry);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String?> assignPilotAndDrone(OpsAssignmentRequest request) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(userModelProvider);
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.droneAssigned,
        updatedBy: user?.name ?? 'Operations',
        updatedByRole: 'operations',
        timestamp: DateTime.now(),
        remarks: 'Pilot ${request.pilot.name} and Drone ${request.drone.name} assigned.',
      );
      await _repository.assignPilotAndDrone(request, historyEntry);
      state = const AsyncData(null);
      return null;
    } on FirebaseException catch (e, st) {
      state = AsyncError(e, st);
      return _friendlyFirebaseMessage(e);
    } catch (e, st) {
      state = AsyncError(e, st);
      return 'Assignment failed. Please try again.';
    }
  }

  String _friendlyFirebaseMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to assign this job.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Network is unavailable. Check your connection and try again.';
      case 'not-found':
        return 'One of the selected records no longer exists.';
      case 'aborted':
      case 'already-exists':
        return 'This booking changed while assigning. Refresh and try again.';
      default:
        return 'Assignment failed. Please refresh and try again.';
    }
  }
}

final operationsViewModelProvider =
    StateNotifierProvider<OperationsViewModel, AsyncValue<void>>((ref) {
      return OperationsViewModel(ref.watch(operationsRepositoryProvider), ref);
    });

/// A specialized provider to ensure even legacy bookings have complete information
final hydratedBookingProvider =
    FutureProvider.family<BookingModel, BookingModel>((ref, booking) async {
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
          final farmerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(booking.farmerUid)
              .get();
          if (farmerDoc.exists) {
            final data = farmerDoc.data()!;
            farmerName = data['name'];
            farmerPhone = data['phoneNumber'];
          }
        }

        // Fetch missing Farm Info
        if (latitude == null) {
          final farmDoc = await FirebaseFirestore.instance
              .collection('farms')
              .doc(booking.farmId)
              .get();
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

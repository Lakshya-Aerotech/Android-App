import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakshya_aerotech/core/services/location_tracking_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../booking/models/booking_model.dart';
import '../../../shared/enums/booking_status.dart';
import '../repositories/pilot_jobs_repository.dart';

final pilotJobsRepositoryProvider = Provider<PilotJobsRepository>((ref) {
  return PilotJobsRepositoryImpl();
});

final assignedJobsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return Stream.value([]);
  if (user.role != UserRole.pilot && user.role != UserRole.externalPilot) return Stream.value([]);
  return ref.watch(pilotJobsRepositoryProvider).getJobsByStatus(user.uid!, [
    BookingStatus.pilotAssigned,
  ]);
});

final inProgressJobsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return Stream.value([]);
  if (user.role != UserRole.pilot && user.role != UserRole.externalPilot) return Stream.value([]);
  return ref.watch(pilotJobsRepositoryProvider).getJobsByStatus(user.uid!, [
    BookingStatus.enRoute,
    BookingStatus.arrived,
    BookingStatus.inProgress,
  ]);
});

final pilotCashCollectionProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('bookings')
      .where('assignedPilotId', isEqualTo: user.uid)
      .where('paymentStatus', isEqualTo: 'Cash Collected by Pilot')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList());
});

final pilotDashboardStatsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return Stream.value({});
  if (user.role != UserRole.pilot && user.role != UserRole.externalPilot) return Stream.value({});

  return ref
      .watch(pilotJobsRepositoryProvider)
      .getAllPilotJobsStream(user.uid!)
      .map((jobs) {
        final now = DateTime.now();

        int pending = 0;
        int completedCount = 0;
        int todayAssignments = 0;

        for (var job in jobs) {
          if ([
            BookingStatus.enRoute,
            BookingStatus.arrived,
            BookingStatus.inProgress,
          ].contains(job.status)) {
            pending++;
          }

          if ([
            BookingStatus.completed,
            BookingStatus.farmerConfirmed,
            BookingStatus.closed,
          ].contains(job.status)) {
            completedCount++;
          }

          if (job.bookingDate.year == now.year &&
              job.bookingDate.month == now.month &&
              job.bookingDate.day == now.day) {
            todayAssignments++;
          }
        }

        return {
          'todayAssignments': todayAssignments,
          'pendingJobs': pending,
          'completedJobs': completedCount,
          'totalAcresCovered': user.totalAcresCovered,
          'totalFlightHours': user.totalFlightHours,
        };
      });
});

class PilotJobsViewModel extends StateNotifier<AsyncValue<void>> {
  final PilotJobsRepository _repository;
  final Ref _ref;

  PilotJobsViewModel(this._repository, this._ref)
    : super(const AsyncData(null));

  void _startStatusListener(String docId) {
    _ref.listen(pilotJobDetailsProvider(docId), (previous, next) {
      next.whenData((job) {
        if ([BookingStatus.completed, BookingStatus.cancelled, BookingStatus.closed]
            .contains(job.status)) {
          _ref.read(locationTrackingServiceProvider).stopTracking();
        }
      });
    });
  }

  Future<void> startNavigation(String docId) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    try {
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.enRoute,
        updatedBy: user?.name ?? 'Pilot',
        updatedByRole: 'pilot',
        timestamp: DateTime.now(),
        remarks: 'Pilot started navigation to farm.',
      );
      await _repository.startNavigation(docId, historyEntry);
      
      // Start real-time tracking
      _ref.read(locationTrackingServiceProvider).startTracking(docId);
      
      // Monitor status to stop tracking if cancelled or completed elsewhere
      _startStatusListener(docId);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markArrived(String docId) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    try {
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.arrived,
        updatedBy: user?.name ?? 'Pilot',
        updatedByRole: 'pilot',
        timestamp: DateTime.now(),
        remarks: 'Pilot arrived at farm.',
      );
      await _repository.updateJobStatus(
        docId,
        BookingStatus.arrived,
        historyEntry,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> startMission(String docId) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    try {
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.inProgress,
        updatedBy: user?.name ?? 'Pilot',
        updatedByRole: 'pilot',
        timestamp: DateTime.now(),
        remarks: 'Pilot started drone mission.',
      );
      await _repository.updateJobStatus(
        docId,
        BookingStatus.inProgress,
        historyEntry,
        additionalUpdates: {'missionStartedAt': FieldValue.serverTimestamp()},
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> completeMission({required BookingModel job}) async {
    if (job.docId == null) {
      state = AsyncError(
        'Invalid job information.',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);

    if (user == null || user.docId == null) {
      state = AsyncError('User profile not found.', StackTrace.current);
      return;
    }

    try {
      final now = DateTime.now();
      final startTime = job.missionStartedAt ?? now;

      final durationMinutes = now.difference(startTime).inMinutes;
      final durationHours = double.parse(
        (durationMinutes / 60.0).toStringAsFixed(2),
      );

      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.completed,
        updatedBy: user.name ?? 'Pilot',
        updatedByRole: 'pilot',
        timestamp: now,
        remarks: 'Mission completed. Duration: $durationMinutes mins.',
      );

      final completionData = {
        'missionCompletedAt': Timestamp.fromDate(now),
        'actualAreaCovered': job.estimatedArea,
        'flightDurationMinutes': durationMinutes,
        'flightDurationHours': durationHours,
      };

      await _repository.completeMission(
        bookingDocId: job.docId!,
        pilotId: user.docId!,
        completionData: completionData,
        historyEntry: historyEntry,
      );

      // Stop tracking when mission is complete
      _ref.read(locationTrackingServiceProvider).stopTracking();

      state = const AsyncData(null);
    } catch (e, st) {
      debugPrint('Error completing mission: $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> verifyCoupon(String docId) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    try {
      await _repository.verifyCoupon(docId, user?.uid ?? 'unknown');
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> collectCash(String docId) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    try {
      await _repository.collectCash(docId, user?.uid ?? 'unknown');
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markCashDeposited(String docId) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    try {
      await _repository.markCashDeposited(docId, user?.uid ?? 'unknown');
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final pilotJobsViewModelProvider =
    StateNotifierProvider<PilotJobsViewModel, AsyncValue<void>>((ref) {
      return PilotJobsViewModel(ref.watch(pilotJobsRepositoryProvider), ref);
    });

final pilotJobDetailsProvider = StreamProvider.family<BookingModel, String>((
  ref,
  bookingDocId,
) {
  return ref.watch(pilotJobsRepositoryProvider).getJobStream(bookingDocId);
});

final pilotJobHistoryProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return Stream.value([]);
  if (user.role != UserRole.pilot && user.role != UserRole.externalPilot) return Stream.value([]);
  return ref.watch(pilotJobsRepositoryProvider).getJobsByStatus(user.uid!, [
    BookingStatus.completed,
    BookingStatus.farmerConfirmed,
    BookingStatus.closed,
  ]);
});

final pilotAverageRatingProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return 0.0;
  if (user.role != UserRole.pilot && user.role != UserRole.externalPilot) return 0.0;
  return ref.watch(pilotJobsRepositoryProvider).getAverageRating(user.uid!);
});

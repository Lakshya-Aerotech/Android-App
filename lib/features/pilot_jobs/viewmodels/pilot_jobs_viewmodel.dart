import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../booking/models/booking_model.dart';
import '../../../shared/enums/booking_status.dart';
import '../repositories/pilot_jobs_repository.dart';

final pilotJobsRepositoryProvider = Provider<PilotJobsRepository>((ref) {
  return PilotJobsRepositoryImpl();
});

final assignedJobsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(pilotJobsRepositoryProvider).getJobsByStatus(user.uid!, [BookingStatus.droneAssigned]);
});

final acceptedJobsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(pilotJobsRepositoryProvider).getJobsByStatus(user.uid!, [BookingStatus.accepted]);
});

final inProgressJobsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(pilotJobsRepositoryProvider).getJobsByStatus(user.uid!, [
    BookingStatus.accepted,
    BookingStatus.enRoute,
    BookingStatus.arrived,
    BookingStatus.inProgress
  ]);
});

final singleJobStreamProvider = StreamProvider.family<BookingModel, String>((ref, bookingId) {
  return ref.watch(pilotJobsRepositoryProvider).getJobStream(bookingId);
});

/// A provider that listens to real-time updates and ensures data is hydrated
final pilotJobDetailsProvider = StreamProvider.family<BookingModel, String>((ref, bookingDocId) {
  final repo = ref.watch(pilotJobsRepositoryProvider);
  
  return repo.getJobStream(bookingDocId).asyncMap((booking) async {
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
      return booking;
    }
  });
});

final completedTodayJobsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null) return Stream.value([]);
  // Filter by today in stream map if needed, or rely on simple list for now
  return ref.watch(pilotJobsRepositoryProvider).getJobsByStatus(user.uid!, [BookingStatus.completed]);
});

final pilotJobHistoryProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(pilotJobsRepositoryProvider).getJobsByStatus(user.uid!, [
    BookingStatus.completed,
    BookingStatus.farmerConfirmed,
    BookingStatus.closed
  ]);
});

final pilotDashboardStatsProvider = StreamProvider<Map<String, int>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null) return Stream.value({});
  
  return ref.watch(pilotJobsRepositoryProvider).getAllPilotJobsStream(user.uid!).map((jobs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int assigned = 0;
    int accepted = 0;
    int inProgress = 0;
    int completedToday = 0;
    int upcoming = 0;

    for (var job in jobs) {
      if (job.status == BookingStatus.droneAssigned) {
        assigned++;
      }
      if (job.status == BookingStatus.accepted) {
        accepted++;
      }
      if (job.status == BookingStatus.enRoute || 
          job.status == BookingStatus.arrived || 
          job.status == BookingStatus.inProgress) {
        inProgress++;
      }
          
      if (job.status == BookingStatus.completed && job.updatedAt.isAfter(today)) {
        completedToday++;
      }
      
      if (job.bookingDate.isAfter(today) && job.status != BookingStatus.cancelled) {
        upcoming++;
      }
    }

    return {
      'assigned': assigned,
      'accepted': accepted,
      'inProgress': inProgress,
      'completedToday': completedToday,
      'upcoming': upcoming,
      'totalToday': jobs.where((j) => j.bookingDate.year == now.year && j.bookingDate.month == now.month && j.bookingDate.day == now.day).length,
    };
  });
});

class PilotJobsViewModel extends StateNotifier<AsyncValue<void>> {
  final PilotJobsRepository _repository;
  final Ref _ref;

  PilotJobsViewModel(this._repository, this._ref) : super(const AsyncData(null));

  Future<void> acceptJob(String docId) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    try {
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.accepted,
        updatedBy: user?.name ?? 'Pilot',
        updatedByRole: 'pilot',
        timestamp: DateTime.now(),
        remarks: 'Pilot accepted the assignment.',
      );
      await _repository.updateJobStatus(docId, BookingStatus.accepted, historyEntry);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> rejectJob(String docId, String reason) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    try {
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.reviewed,
        updatedBy: user?.name ?? 'Pilot',
        updatedByRole: 'pilot',
        timestamp: DateTime.now(),
        remarks: 'Pilot rejected assignment: $reason',
      );
      // User says: Reject status = reviewed (returns to operations)
      await _repository.updateJobStatus(docId, BookingStatus.reviewed, historyEntry, rejectionReason: reason);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
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
      await _repository.updateJobStatus(docId, BookingStatus.enRoute, historyEntry);
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
      await _repository.updateJobStatus(docId, BookingStatus.arrived, historyEntry);
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
      await _repository.updateJobStatus(docId, BookingStatus.inProgress, historyEntry);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> completeMission({
    required String bookingDocId,
    required String droneDocId,
    required String notes,
    required double areaCovered,
    required String duration,
    String? chemical,
  }) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    try {
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.completed,
        updatedBy: user?.name ?? 'Pilot',
        updatedByRole: 'pilot',
        timestamp: DateTime.now(),
        remarks: 'Mission completed by pilot. Area: $areaCovered, Duration: $duration',
      );
      final data = {
        'missionNotes': notes,
        'actualAreaCovered': areaCovered,
        'flightDuration': duration,
        'chemicalUsed': chemical,
      };
      await _repository.completeMission(bookingDocId, data, droneDocId, historyEntry);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final pilotJobsViewModelProvider = StateNotifierProvider<PilotJobsViewModel, AsyncValue<void>>((ref) {
  return PilotJobsViewModel(ref.watch(pilotJobsRepositoryProvider), ref);
});

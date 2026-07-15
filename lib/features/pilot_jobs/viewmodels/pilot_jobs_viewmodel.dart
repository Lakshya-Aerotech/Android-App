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
    BookingStatus.enRoute,
    BookingStatus.arrived,
    BookingStatus.inProgress
  ]);
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

  PilotJobsViewModel(this._repository) : super(const AsyncData(null));

  Future<void> acceptJob(String docId) async {
    state = const AsyncLoading();
    try {
      await _repository.updateJobStatus(docId, BookingStatus.accepted);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> rejectJob(String docId, String reason) async {
    state = const AsyncLoading();
    try {
      // User says: Reject status = reviewed (returns to operations)
      await _repository.updateJobStatus(docId, BookingStatus.reviewed, rejectionReason: reason);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> startNavigation(String docId) async {
    state = const AsyncLoading();
    try {
      await _repository.updateJobStatus(docId, BookingStatus.enRoute);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markArrived(String docId) async {
    state = const AsyncLoading();
    try {
      await _repository.updateJobStatus(docId, BookingStatus.arrived);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> startMission(String docId) async {
    state = const AsyncLoading();
    try {
      await _repository.updateJobStatus(docId, BookingStatus.inProgress);
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
    try {
      final data = {
        'missionNotes': notes,
        'actualAreaCovered': areaCovered,
        'flightDuration': duration,
        'chemicalUsed': chemical,
      };
      await _repository.completeMission(bookingDocId, data, droneDocId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final pilotJobsViewModelProvider = StateNotifierProvider<PilotJobsViewModel, AsyncValue<void>>((ref) {
  return PilotJobsViewModel(ref.watch(pilotJobsRepositoryProvider));
});

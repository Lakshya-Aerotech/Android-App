import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/operations_models.dart';
import '../repositories/operations_repository.dart';
import '../../booking/models/booking_model.dart';
import '../../../shared/enums/booking_status.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

final operationsRepositoryProvider = Provider<OperationsRepository>((ref) {
  return OperationsRepositoryImpl();
});

final operationsStatisticsProvider = FutureProvider<List<OperationsStatistic>>((ref) async {
  return ref.watch(operationsRepositoryProvider).getStatistics();
});

final activeServicesProvider = FutureProvider<List<ActiveService>>((ref) async {
  return ref.watch(operationsRepositoryProvider).getActiveServices();
});

final pendingAssignmentsProvider = FutureProvider<List<PendingAssignment>>((ref) async {
  return ref.watch(operationsRepositoryProvider).getPendingAssignments();
});

final recentActivitiesProvider = FutureProvider<List<OperationsActivity>>((ref) async {
  return ref.watch(operationsRepositoryProvider).getRecentActivities();
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

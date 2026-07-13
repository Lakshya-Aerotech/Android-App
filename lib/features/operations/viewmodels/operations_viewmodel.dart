import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/operations_models.dart';
import '../repositories/operations_repository.dart';

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

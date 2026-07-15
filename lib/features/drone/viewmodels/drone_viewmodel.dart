import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drone_model.dart';
import '../repositories/drone_repository.dart';

final dronesStreamProvider = StreamProvider<List<DroneModel>>((ref) {
  final repo = ref.watch(droneRepositoryProvider);
  // Trigger auto-population in background
  repo.populateSampleDrones();
  return repo.getDronesStream();
});

class DroneViewModel extends StateNotifier<AsyncValue<void>> {
  DroneViewModel() : super(const AsyncData(null));

  // Future operations like changing drone status can be added here
}

final droneViewModelProvider = StateNotifierProvider<DroneViewModel, AsyncValue<void>>((ref) {
  return DroneViewModel();
});

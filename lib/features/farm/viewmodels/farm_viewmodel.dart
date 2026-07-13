import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../models/farm_model.dart';
import '../repositories/farm_repository.dart';

final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  return FarmRepositoryImpl();
});

final farmsStreamProvider = StreamProvider<List<FarmModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return Stream.value([]);
  return ref.watch(farmRepositoryProvider).getFarmsStream(user.uid!);
});

class FarmViewModel extends StateNotifier<AsyncValue<void>> {
  final FarmRepository _repository;
  final Ref _ref;

  FarmViewModel(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> addFarm({
    required String farmName,
    required String cropType,
    required double area,
    required String unit,
    required String village,
    required String district,
    required String stateName,
    required double latitude,
    required double longitude,
  }) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    if (user == null || user.uid == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return;
    }

    final farm = FarmModel(
      farmerUid: user.uid!,
      farmName: farmName,
      cropType: cropType,
      area: area,
      unit: unit,
      village: village,
      district: district,
      state: stateName,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.addFarm(farm);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateFarm(FarmModel farm) async {
    state = const AsyncLoading();
    try {
      await _repository.updateFarm(farm);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteFarm(String docId) async {
    state = const AsyncLoading();
    try {
      await _repository.softDeleteFarm(docId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final farmViewModelProvider = StateNotifierProvider<FarmViewModel, AsyncValue<void>>((ref) {
  return FarmViewModel(ref.watch(farmRepositoryProvider), ref);
});

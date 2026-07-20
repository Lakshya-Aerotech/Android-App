import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/user_model.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../repositories/retailer_repository.dart';

final retailerRepositoryProvider = Provider<RetailerRepository>((ref) {
  return RetailerRepositoryImpl();
});

final retailerFarmersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user?.uid == null) return Stream.value([]);
  return ref
      .watch(retailerRepositoryProvider)
      .getRetailerFarmersStream(user!.uid!);
});

class RetailerViewModel extends StateNotifier<AsyncValue<UserModel?>> {
  final RetailerRepository _repository;
  final Ref _ref;

  RetailerViewModel(this._repository, this._ref) : super(const AsyncData(null));

  Future<UserModel?> createFarmer({
    required String name,
    required String mobileNumber,
    required String village,
    required String district,
    required String stateName,
    String? email,
  }) async {
    final retailer = _ref.read(userModelProvider);
    if (retailer?.uid == null) {
      state = AsyncError('Retailer not authenticated', StackTrace.current);
      return null;
    }

    state = const AsyncLoading();
    try {
      final farmer = await _repository.createFarmerForRetailer(
        retailerUid: retailer!.uid!,
        name: name,
        mobileNumber: mobileNumber,
        village: village,
        district: district,
        stateName: stateName,
        email: email,
      );
      state = AsyncData(farmer);
      return farmer;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> updateFarmer(UserModel farmer) async {
    state = const AsyncLoading();
    try {
      await _repository.updateFarmer(farmer);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final retailerViewModelProvider =
    StateNotifierProvider<RetailerViewModel, AsyncValue<UserModel?>>((ref) {
      return RetailerViewModel(ref.watch(retailerRepositoryProvider), ref);
    });

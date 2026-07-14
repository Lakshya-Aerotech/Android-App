import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/enums/booking_status.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl();
});

final farmerBookingsStreamProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return Stream.value([]);
  return ref.watch(bookingRepositoryProvider).getFarmerBookingsStream(user.uid!);
});

class BookingViewModel extends StateNotifier<AsyncValue<String?>> {
  final BookingRepository _repository;
  final Ref _ref;

  BookingViewModel(this._repository, this._ref) : super(const AsyncData(null));

  Future<void> createBooking({
    required String farmId,
    required String farmName,
    required String cropType,
    required String serviceType,
    required DateTime bookingDate,
    required String preferredTime,
    required double estimatedArea,
    required String? village,
    required String? district,
    required double? latitude,
    required double? longitude,
    String? remarks,
  }) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    if (user == null || user.uid == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return;
    }

    final bookingId = _generateBookingId();

    final booking = BookingModel(
      bookingId: bookingId,
      farmerUid: user.uid!,
      farmerName: user.name,
      farmId: farmId,
      farmName: farmName,
      village: village,
      district: district,
      cropType: cropType,
      serviceType: serviceType,
      bookingDate: bookingDate,
      preferredTime: preferredTime,
      estimatedArea: estimatedArea,
      status: BookingStatus.pending,
      remarks: remarks,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.createBooking(booking);
      state = AsyncData(bookingId);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> cancelBooking(String docId) async {
    state = const AsyncLoading();
    try {
      await _repository.cancelBooking(docId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  String _generateBookingId() {
    final now = DateTime.now();
    final random = Random().nextInt(9000) + 1000;
    return 'LA-${DateFormat('yyyyMMdd').format(now)}-$random';
  }
}

final bookingViewModelProvider = StateNotifierProvider<BookingViewModel, AsyncValue<String?>>((ref) {
  return BookingViewModel(ref.watch(bookingRepositoryProvider), ref);
});

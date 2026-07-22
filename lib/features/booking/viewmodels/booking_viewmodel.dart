import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/enums/booking_status.dart';
import '../../auth/models/user_model.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl();
});

final singleBookingStreamProvider =
    StreamProvider.family<BookingModel?, String>((ref, docId) {
      return ref.watch(bookingRepositoryProvider).getBookingStream(docId);
    });

final farmerBookingsStreamProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return Stream.value([]);
  return ref
      .watch(bookingRepositoryProvider)
      .getFarmerBookingsStream(user.uid!);
});

final farmerBookingsStreamByUidProvider =
    StreamProvider.family<List<BookingModel>, String>((ref, farmerUid) {
      return ref
          .watch(bookingRepositoryProvider)
          .getFarmerBookingsStream(farmerUid);
    });

final retailerBookingsStreamProvider = StreamProvider<List<BookingModel>>((
  ref,
) {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return Stream.value([]);
  return ref
      .watch(bookingRepositoryProvider)
      .getRetailerBookingsStream(user.uid!);
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
    required String? stateName,
    required double? farmArea,
    required double? latitude,
    required double? longitude,
    String? remarks,
    UserModel? farmerOverride,
    String? couponId,
    String? couponCode,
    String? couponDiscountType,
    double? couponDiscountValue,
    double? originalAmount,
    double? discountAmount,
    double? payableAmount,
  }) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    if (user == null || user.uid == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return;
    }

    final bookingId = _generateBookingId();

    final actingAsRetailer =
        user.role == UserRole.retailer && farmerOverride != null;
    final farmer = farmerOverride ?? user;

    final booking = BookingModel(
      bookingId: bookingId,
      farmerUid: farmer.uid!,
      farmerName: farmer.name,
      farmerPhone: farmer.phoneNumber,
      preferredLanguage: farmer.preferredLanguage,
      farmerId: farmer.uid,
      createdByRole: actingAsRetailer ? 'retailer' : 'farmer',
      createdByRetailerId: actingAsRetailer ? user.uid : null,
      farmId: farmId,
      farmName: farmName,
      village: village,
      district: district,
      state: stateName,
      cropType: cropType,
      farmArea: farmArea,
      latitude: latitude,
      longitude: longitude,
      serviceType: serviceType,
      bookingDate: bookingDate,
      preferredTime: preferredTime,
      estimatedArea: estimatedArea,
      status: BookingStatus.pending,
      remarks: remarks,
      couponId: couponId,
      couponCode: couponCode,
      couponDiscountType: couponDiscountType,
      couponDiscountValue: couponDiscountValue,
      originalAmount: originalAmount,
      discountAmount: discountAmount,
      payableAmount: payableAmount,
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

  Future<void> cancelBooking(String docId, {String? remarks}) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    try {
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.cancelled,
        updatedBy: user?.name ?? 'Farmer',
        updatedByRole: 'farmer',
        timestamp: DateTime.now(),
        remarks: remarks ?? 'Booking cancelled by farmer.',
      );
      await _repository.cancelBooking(docId, historyEntry);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> confirmService(String docId) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    try {
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.farmerConfirmed,
        updatedBy: user?.name ?? 'Farmer',
        updatedByRole: 'farmer',
        timestamp: DateTime.now(),
        remarks: 'Service confirmed as completed by farmer.',
      );
      await _repository.confirmService(docId, historyEntry);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> submitRating(
    String docId,
    double rating,
    String feedback,
  ) async {
    state = const AsyncLoading();
    try {
      await _repository.submitRating(docId, rating, feedback);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> reportIssue(
    String docId,
    String category,
    String description,
  ) async {
    state = const AsyncLoading();
    final user = _ref.read(userModelProvider);
    try {
      final historyEntry = StatusHistoryEntry(
        status: BookingStatus.issueReported,
        updatedBy: user?.name ?? 'Farmer',
        updatedByRole: 'farmer',
        timestamp: DateTime.now(),
        remarks: 'Issue reported: $category - $description',
      );
      await _repository.reportIssue(docId, category, description, historyEntry);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> requestPayment({
    required String docId,
    required String method,
    required double originalAmount,
    required double finalAmount,
    double? discountAmount,
    String? pilotId,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.requestPayment(
        docId: docId,
        method: method,
        originalAmount: originalAmount,
        finalAmount: finalAmount,
        discountAmount: discountAmount,
        pilotId: pilotId,
      );
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

final bookingViewModelProvider =
    StateNotifierProvider<BookingViewModel, AsyncValue<String?>>((ref) {
      return BookingViewModel(ref.watch(bookingRepositoryProvider), ref);
    });

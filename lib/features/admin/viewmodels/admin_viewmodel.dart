import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/activity_model.dart';
import '../../../shared/repositories/activity_repository.dart';
import '../models/admin_statistic.dart';
import '../models/coupon_model.dart';
import '../repositories/admin_repository.dart';
import '../../auth/models/user_model.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../booking/models/booking_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl();
});

final employeesStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getEmployeesStream();
});

final retailersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getRetailersStream();
});

final externalPilotsStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getExternalPilotsStream();
});

final bookingsAwaitingConfirmationProvider = StreamProvider<List<BookingModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getBookingsByPaymentStatus(['Awaiting Admin Confirmation']);
});

final allPaymentsStreamProvider = StreamProvider<List<BookingModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('bookings')
      .where('paymentStatus', isNull: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList());
});

final couponsStreamProvider = StreamProvider<List<CouponModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getCouponsStream();
});

final adminStatisticsStreamProvider = StreamProvider<List<AdminStatistic>>((ref, ) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getDashboardStats().map((stats) {
    return [
      AdminStatistic(
        icon: Icons.engineering,
        iconColor: Colors.purple,
        title: 'Total Employees',
        value: stats['totalEmployees'].toString(),
      ),
      AdminStatistic(
        icon: Icons.agriculture,
        iconColor: Colors.blue,
        title: 'Total Farmers',
        value: stats['totalFarmers'].toString(),
      ),
      AdminStatistic(
        icon: Icons.book_online,
        iconColor: Colors.green,
        title: 'Total Bookings',
        value: stats['totalBookings'].toString(),
      ),
      AdminStatistic(
        icon: Icons.storefront_outlined,
        iconColor: Colors.deepOrange,
        title: 'Total Retailers',
        value: stats['totalRetailers'].toString(),
      ),
      AdminStatistic(
        icon: Icons.task_alt,
        iconColor: Colors.teal,
        title: 'Completed Missions',
        value: stats['completedMissions'].toString(),
      ),
      AdminStatistic(
        icon: Icons.pending_actions,
        iconColor: Colors.red,
        title: 'Pending Bookings',
        value: stats['pendingBookings'].toString(),
      ),
      AdminStatistic(
        icon: Icons.flight,
        iconColor: Colors.orange,
        title: 'Active Pilots',
        value: stats['activePilots'].toString(),
      ),
    ];
  });
});

final recentActivitiesStreamProvider = StreamProvider<List<ActivityModel>>((
  ref,
) {
  return ActivityRepository.getRecentActivities();
});

final allActivitiesStreamProvider = StreamProvider<List<ActivityModel>>((ref) {
  return ActivityRepository.getAllActivities();
});

class AdminViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;
  final Ref _ref;

  AdminViewModel(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<String?> createEmployee({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String language,
    required bool isActive,
    required String createdBy,
  }) async {
    state = const AsyncValue.loading();
    try {
      final exists = await _repository.checkIfEmailExists(email);
      if (exists) {
        state = const AsyncValue.data(null);
        return 'Employee with this email already exists.';
      }

      final employee = UserModel(
        name: name,
        email: email,
        phoneNumber: phone,
        role: role,
        preferredLanguage: language,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: createdBy,
        profileCompleted: true,
        mustChangePassword: true,
        authCreated: false,
        uid: null,
        fcmTokens: [],
      );

      await _repository.createEmployee(employee);
      state = const AsyncValue.data(null);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return e.toString();
    }
  }

  Future<String?> updateEmployee({
    required String docId,
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String language,
    required bool isActive,
  }) async {
    state = const AsyncValue.loading();
    try {
      final exists = await _repository.checkIfEmailExists(
        email,
        excludingDocId: docId,
      );
      if (exists) {
        state = const AsyncValue.data(null);
        return 'Employee with this email already exists.';
      }

      await _repository.updateEmployee(
        docId: docId,
        name: name,
        email: email,
        phone: phone,
        role: role,
        language: language,
        isActive: isActive,
      );
      state = const AsyncValue.data(null);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return _friendlyError(e);
    }
  }

  Future<String?> updateStatus(String docId, bool isActive) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateEmployeeStatus(docId, isActive);
      state = const AsyncValue.data(null);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return _friendlyError(e);
    }
  }

  Future<String?> updateRetailerStatus({
    required String docId,
    required ApprovalStatus approvalStatus,
    required bool isActive,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateRetailerStatus(
        docId: docId,
        approvalStatus: approvalStatus,
        isActive: isActive,
      );
      state = const AsyncValue.data(null);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return _friendlyError(e);
    }
  }

  Future<void> deleteEmployee(String docId) async {
    try {
      await _repository.deleteEmployee(docId);
    } catch (e) {
      // Handle error
    }
  }

  Future<String?> createCoupon(CouponModel coupon) async {
    state = const AsyncValue.loading();
    try {
      final exists = await _repository.checkIfCouponCodeExists(
        coupon.couponCode,
      );
      if (exists) {
        state = const AsyncValue.data(null);
        return 'Coupon code already exists.';
      }

      await _repository.createCoupon(coupon);
      state = const AsyncValue.data(null);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return _friendlyError(e);
    }
  }

  Future<String?> updateCoupon(CouponModel coupon) async {
    state = const AsyncValue.loading();
    try {
      final exists = await _repository.checkIfCouponCodeExists(
        coupon.couponCode,
        excludingDocId: coupon.docId,
      );
      if (exists) {
        state = const AsyncValue.data(null);
        return 'Coupon code already exists.';
      }

      await _repository.updateCoupon(coupon);
      state = const AsyncValue.data(null);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return _friendlyError(e);
    }
  }

  Future<String?> deleteCoupon(String docId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCoupon(docId);
      state = const AsyncValue.data(null);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return _friendlyError(e);
    }
  }

  Future<String?> updateCouponStatus(String docId, bool isActive) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateCouponStatus(docId, isActive);
      state = const AsyncValue.data(null);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return _friendlyError(e);
    }
  }

  Future<void> approveExternalPilot(String docId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateExternalPilotApproval(
        docId: docId,
        status: ApprovalStatus.approved,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectExternalPilot(String docId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateExternalPilotApproval(
        docId: docId,
        status: ApprovalStatus.rejected,
        rejectionReason: reason,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateExternalPilotAccountStatus(
    String docId,
    AccountStatus status,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateExternalPilotAccountStatus(
        docId: docId,
        status: status,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> confirmPayment(String docId) async {
    state = const AsyncValue.loading();
    final user = _ref.read(userModelProvider);
    try {
      await _repository.confirmPaymentDeposit(docId, user?.uid ?? 'admin');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectPayment(String docId, String remarks) async {
    state = const AsyncValue.loading();
    final user = _ref.read(userModelProvider);
    try {
      await _repository.rejectPaymentDeposit(docId, user?.uid ?? 'admin', remarks);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to update this employee.';
        case 'unavailable':
          return 'Network unavailable. Please check your connection and try again.';
        case 'not-found':
          return 'Employee record was not found. It may have been deleted.';
        default:
          return 'Unable to update employee. Please try again.';
      }
    }

    final message = error.toString();
    if (message.contains('not found') || message.contains('deleted')) {
      return 'Employee record was not found. It may have been deleted.';
    }
    return 'Unable to update employee. Please try again.';
  }
}

final adminViewModelProvider =
    StateNotifierProvider<AdminViewModel, AsyncValue<void>>((ref) {
      return AdminViewModel(ref.watch(adminRepositoryProvider), ref);
    });

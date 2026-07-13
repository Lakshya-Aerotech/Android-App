import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_statistic.dart';
import '../repositories/admin_repository.dart';
import '../../auth/models/user_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl();
});

final employeesStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getEmployeesStream();
});

final adminStatisticsProvider = Provider<List<AdminStatistic>>((ref) {
  // This will later be connected to real data from Firestore
  return [
    const AdminStatistic(
      icon: Icons.agriculture,
      iconColor: Colors.blue,
      title: 'Total Farmers',
      value: '0',
    ),
    const AdminStatistic(
      icon: Icons.flight,
      iconColor: Colors.orange,
      title: 'Total Pilots',
      value: '0',
    ),
    const AdminStatistic(
      icon: Icons.engineering,
      iconColor: Colors.purple,
      title: 'Operations Staff',
      value: '0',
    ),
    const AdminStatistic(
      icon: Icons.book_online,
      iconColor: Colors.green,
      title: 'Today\'s Bookings',
      value: '0',
    ),
    const AdminStatistic(
      icon: Icons.pending_actions,
      iconColor: Colors.red,
      title: 'Pending Jobs',
      value: '0',
    ),
    const AdminStatistic(
      icon: Icons.task_alt,
      iconColor: Colors.teal,
      title: 'Completed Jobs',
      value: '0',
    ),
    const AdminStatistic(
      icon: Icons.precision_manufacturing,
      iconColor: Colors.indigo,
      title: 'Available Drones',
      value: '0',
    ),
    const AdminStatistic(
      icon: Icons.payments_outlined,
      iconColor: Colors.amber,
      title: 'Revenue',
      value: '₹0',
    ),
  ];
});

class AdminViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;

  AdminViewModel(this._repository) : super(const AsyncValue.data(null));

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

  Future<void> updateStatus(String docId, bool isActive) async {
    try {
      await _repository.updateEmployeeStatus(docId, isActive);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteEmployee(String docId) async {
    try {
      await _repository.deleteEmployee(docId);
    } catch (e) {
      // Handle error
    }
  }
}

final adminViewModelProvider = StateNotifierProvider<AdminViewModel, AsyncValue<void>>((ref) {
  return AdminViewModel(ref.watch(adminRepositoryProvider));
});

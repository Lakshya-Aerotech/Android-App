import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../payment/data/services/payment_api.dart';
import '../../auth/models/user_model.dart';
import '../../../core/services/api_auth_headers.dart';

class AdminUserApiService {
  AdminUserApiService(this._dio);

  final Dio _dio;

  Future<void> createEmployee({
    required String name,
    required String email,
    required String phoneNumber,
    required UserRole role,
    required String preferredLanguage,
    required bool isActive,
  }) async {
    try {
      await _dio.post(
        '${AppConfig.userBaseUrl}/employees',
        data: {
          'name': name,
          'email': email,
          'phoneNumber': phoneNumber,
          'role': role.value,
          'preferredLanguage': preferredLanguage,
          'isActive': isActive,
        },
        options: Options(headers: await ApiAuthHeaders.create()),
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map
          ? data['error'] ?? data['message']
          : null;
      throw Exception(message ?? 'Unable to create employee account.');
    }
  }

  Future<void> updateEmployee({
    required String documentId,
    String? name,
    String? email,
    String? phoneNumber,
    UserRole? role,
    String? preferredLanguage,
    bool? isActive,
  }) async {
    try {
      await _dio.patch(
        '${AppConfig.userBaseUrl}/employees/$documentId',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (role != null) 'role': role.value,
          if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
          if (isActive != null) 'isActive': isActive,
        },
        options: Options(headers: await ApiAuthHeaders.create()),
      );
    } on DioException catch (error) {
      throw Exception(_message(error, 'Unable to update employee account.'));
    }
  }

  Future<void> deleteEmployee(String documentId) async {
    try {
      await _dio.delete(
        '${AppConfig.userBaseUrl}/employees/$documentId',
        options: Options(headers: await ApiAuthHeaders.create()),
      );
    } on DioException catch (error) {
      throw Exception(_message(error, 'Unable to delete employee account.'));
    }
  }

  String _message(DioException error, String fallback) {
    final data = error.response?.data;
    final message = data is Map ? data['error'] ?? data['message'] : null;
    return message?.toString() ?? fallback;
  }
}

final adminUserApiServiceProvider = Provider<AdminUserApiService>((ref) {
  return AdminUserApiService(ref.watch(dioProvider));
});

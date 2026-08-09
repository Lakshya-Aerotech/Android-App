import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../../features/payment/data/services/payment_api.dart';
import 'api_auth_headers.dart';

class AccountService {
  AccountService(this._dio);

  final Dio _dio;

  Future<void> deleteCurrentAccount() async {
    try {
      await _dio.delete(
        '${AppConfig.userBaseUrl}/me',
        options: Options(headers: await ApiAuthHeaders.create()),
      );
      await FirebaseAuth.instance.signOut();
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map
          ? data['error'] ?? data['message']
          : null;
      throw Exception(message ?? 'Account deletion failed. Please try again.');
    }
  }
}

final accountServiceProvider = Provider<AccountService>((ref) {
  return AccountService(ref.watch(dioProvider));
});

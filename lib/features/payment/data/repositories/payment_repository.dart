import '../models/payment_model.dart';
import '../services/payment_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class PaymentRepository {
  Future<PaymentInitiationResponse> initiatePayment({
    required String bookingId,
    required String userId,
    required double amount,
    required String mobileNumber,
  });

  Future<bool> checkPaymentStatus(String merchantTransactionId);

  Future<bool> isServerReachable();
}

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentApiService _apiService;

  PaymentRepositoryImpl(this._apiService);

  @override
  Future<PaymentInitiationResponse> initiatePayment({
    required String bookingId,
    required String userId,
    required double amount,
    required String mobileNumber,
  }) {
    debugPrint('[PaymentRepository] initiatePayment: bookingId=$bookingId, userId=$userId, amount=$amount');
    return _apiService.createPayment(
      bookingId: bookingId,
      userId: userId,
      amount: amount,
      mobileNumber: mobileNumber,
    );
  }

  @override
  Future<bool> isServerReachable() {
    return _apiService.isServerReachable();
  }

  @override
  Future<bool> checkPaymentStatus(String merchantTransactionId) async {
    debugPrint('[PaymentRepository] checkPaymentStatus: merchantTransactionId=$merchantTransactionId');
    try {
      final responseMap = await _apiService.getPaymentStatus(merchantTransactionId);
      if (responseMap['success'] == true) {
        final gatewayData = responseMap['data'];
        if (gatewayData != null) {
          final success = gatewayData['success'] == true;
          final code = gatewayData['code'] as String?;
          final data = gatewayData['data'];
          final state = data?['state'] as String?;
          
          if (success && (code == 'PAYMENT_SUCCESS' || state == 'COMPLETED' || state == 'SUCCESS')) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('[PaymentRepository] Error checking status: $e');
      return false;
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiService = ref.watch(paymentApiServiceProvider);
  return PaymentRepositoryImpl(apiService);
});

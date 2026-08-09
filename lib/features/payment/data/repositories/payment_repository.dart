import '../models/payment_model.dart';
import '../services/payment_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PaymentVerificationStatus { success, failed, pending }

abstract class PaymentRepository {
  Future<PaymentInitiationResponse> initiatePayment({
    required String bookingId,
  });

  Future<PaymentVerificationStatus> checkPaymentStatus(
    String merchantTransactionId,
  );

  Future<bool> isServerReachable();
}

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentApiService _apiService;

  PaymentRepositoryImpl(this._apiService);

  @override
  Future<PaymentInitiationResponse> initiatePayment({
    required String bookingId,
  }) {
    return _apiService.createPayment(
      bookingId: bookingId,
    );
  }

  @override
  Future<bool> isServerReachable() {
    return _apiService.isServerReachable();
  }

  @override
  Future<PaymentVerificationStatus> checkPaymentStatus(
    String merchantTransactionId,
  ) async {
    try {
      final responseMap = await _apiService.getPaymentStatus(merchantTransactionId);
      if (responseMap['success'] == true) {
        final data = responseMap['data'];
        final state = data is Map
            ? data['paymentState']?.toString().toUpperCase()
            : null;
        if (state == 'SUCCESS') {
          return PaymentVerificationStatus.success;
        }
        if (state == 'FAILED' || state == 'CANCELLED') {
          return PaymentVerificationStatus.failed;
        }
      }
      return PaymentVerificationStatus.pending;
    } catch (_) {
      return PaymentVerificationStatus.pending;
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiService = ref.watch(paymentApiServiceProvider);
  return PaymentRepositoryImpl(apiService);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/payment_repository.dart';

class PaymentState {
  final bool isLoading;
  final String? error;
  final String? paymentUrl;
  final String? merchantTransactionId;
  final bool isSuccess;

  PaymentState({
    this.isLoading = false,
    this.error,
    this.paymentUrl,
    this.merchantTransactionId,
    this.isSuccess = false,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    String? paymentUrl,
    String? merchantTransactionId,
    bool? isSuccess,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      merchantTransactionId: merchantTransactionId ?? this.merchantTransactionId,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class PaymentController extends StateNotifier<PaymentState> {
  final PaymentRepository _repository;

  PaymentController(this._repository) : super(PaymentState());

  Future<void> initiatePayment({
    required String bookingId,
    required String userId,
    required double amount,
    required String mobileNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    final isReachable = await _repository.isServerReachable();
    if (!isReachable) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to connect to payment server. Please try again later.',
        isSuccess: false,
      );
      return;
    }

    try {
      final response = await _repository.initiatePayment(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        mobileNumber: mobileNumber,
      );

      if (response.success && response.paymentUrl.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          paymentUrl: response.paymentUrl,
          merchantTransactionId: response.merchantTransactionId,
          isSuccess: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to initiate payment. Invalid response from gateway.',
          isSuccess: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
        isSuccess: false,
      );
    }
  }

  void reset() {
    state = PaymentState();
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentState>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PaymentController(repository);
});

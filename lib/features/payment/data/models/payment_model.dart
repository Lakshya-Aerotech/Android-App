class PaymentInitiationResponse {
  final bool success;
  final String merchantTransactionId;
  final String orderId;
  final String paymentSessionId;
  final String cfOrderId;
  final String paymentUrl;
  final String status;
  final String environment;

  PaymentInitiationResponse({
    required this.success,
    required this.merchantTransactionId,
    required this.orderId,
    required this.paymentSessionId,
    required this.cfOrderId,
    required this.paymentUrl,
    required this.status,
    required this.environment,
  });

  factory PaymentInitiationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final orderIdVal = data['order_id'] as String? ?? data['merchantTransactionId'] as String? ?? '';
    final paymentSessionVal = data['payment_session_id'] as String? ?? '';

    return PaymentInitiationResponse(
      success: json['success'] as bool? ?? data['success'] as bool? ?? false,
      merchantTransactionId: orderIdVal,
      orderId: orderIdVal,
      paymentSessionId: paymentSessionVal,
      cfOrderId: data['cf_order_id'] as String? ?? '',
      paymentUrl: data['paymentUrl'] as String? ?? (paymentSessionVal.isNotEmpty ? 'https://payments.cashfree.com/order/#$paymentSessionVal' : ''),
      status: data['status'] as String? ?? 'PENDING',
      environment: data['environment'] as String? ?? 'SANDBOX',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'merchantTransactionId': merchantTransactionId,
      'order_id': orderId,
      'payment_session_id': paymentSessionId,
      'cf_order_id': cfOrderId,
      'paymentUrl': paymentUrl,
      'status': status,
      'environment': environment,
    };
  }
}

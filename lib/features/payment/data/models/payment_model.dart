class PaymentInitiationResponse {
  final bool success;
  final String merchantTransactionId;
  final String paymentUrl;
  final String status;

  PaymentInitiationResponse({
    required this.success,
    required this.merchantTransactionId,
    required this.paymentUrl,
    required this.status,
  });

  factory PaymentInitiationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitiationResponse(
      success: json['success'] as bool? ?? false,
      merchantTransactionId: json['merchantTransactionId'] as String? ?? '',
      paymentUrl: json['paymentUrl'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'merchantTransactionId': merchantTransactionId,
      'paymentUrl': paymentUrl,
      'status': status,
    };
  }
}

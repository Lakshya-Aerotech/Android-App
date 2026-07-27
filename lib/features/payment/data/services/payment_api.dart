import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';

class PaymentApiService {
  final Dio _dio;

  PaymentApiService(this._dio);

  static const String _defaultBaseUrl = String.fromEnvironment(
    'PAYMENT_BASE_URL',
    defaultValue: 'http://192.168.1.4:3000/api/payment',
  );

  String _getHealthUrl(String paymentBaseUrl) {
    if (paymentBaseUrl.endsWith('/api/payment')) {
      return paymentBaseUrl.replaceAll('/api/payment', '/health');
    }
    try {
      final uri = Uri.parse(paymentBaseUrl);
      return uri.replace(path: '/health').toString();
    } catch (_) {
      return '$paymentBaseUrl/health';
    }
  }

  Future<bool> isServerReachable() async {
    final healthUrl = _getHealthUrl(_defaultBaseUrl);
    
    debugPrint('--- SERVER CONNECTIVITY CHECK ---');
    debugPrint('Checking connectivity to: $healthUrl');
    debugPrint('Dio Options - connectTimeout: ${_dio.options.connectTimeout}, receiveTimeout: ${_dio.options.receiveTimeout}');
    
    try {
      final response = await _dio.get(
        healthUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      debugPrint('Connectivity Check Status: ${response.statusCode}');
      debugPrint('Connectivity Check Response: ${response.data}');
      debugPrint('---------------------------------');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['success'] == true;
      }
      return false;
    } catch (e, st) {
      debugPrint('Connectivity Check Exception: $e');
      debugPrint('Stack Trace: $st');
      debugPrint('---------------------------------');
      return false;
    }
  }

  Future<PaymentInitiationResponse> createPayment({
    required String bookingId,
    required String userId,
    required double amount,
    required String mobileNumber,
  }) async {
    final endpointUrl = '$_defaultBaseUrl/create';
    final requestBody = {
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'mobileNumber': mobileNumber,
    };

    debugPrint('--- PAYMENT INITIATION DEBUG LOGS ---');
    debugPrint('Base URL: $_defaultBaseUrl');
    debugPrint('Endpoint: $endpointUrl');
    debugPrint('Request Payload: $requestBody');
    debugPrint('Timeout Values - connectTimeout: ${_dio.options.connectTimeout}, receiveTimeout: ${_dio.options.receiveTimeout}, sendTimeout: ${_dio.options.sendTimeout}');

    try {
      final response = await _dio.post(
        endpointUrl,
        data: requestBody,
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.data}');
      debugPrint('-------------------------------------');

      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        final data = response.data['data'];
        if (success && data != null) {
          final paymentResponse = PaymentInitiationResponse.fromJson(data);
          if (paymentResponse.success && paymentResponse.paymentUrl.isNotEmpty) {
            return paymentResponse;
          }
        }
      }
      throw Exception(response.data?['message'] ?? 'Failed to initiate payment. Invalid response.');
    } on DioException catch (e, st) {
      debugPrint('Full Dio Exception: $e');
      debugPrint('Stack Trace: $st');
      debugPrint('-------------------------------------');
      throw Exception(_handleDioError(e));
    } catch (e, st) {
      debugPrint('Unexpected Exception: $e');
      debugPrint('Stack Trace: $st');
      debugPrint('-------------------------------------');
      throw Exception('An unexpected error occurred during payment setup: $e');
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(String merchantTransactionId) async {
    final endpointUrl = '$_defaultBaseUrl/status/$merchantTransactionId';
    
    debugPrint('--- PAYMENT STATUS CHECK LOGS ---');
    debugPrint('Base URL: $_defaultBaseUrl');
    debugPrint('Endpoint: $endpointUrl');
    
    try {
      final response = await _dio.get(endpointUrl);
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.data}');
      debugPrint('----------------------------------');
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      throw Exception(response.data?['message'] ?? 'Failed to check payment status.');
    } on DioException catch (e, st) {
      debugPrint('Full Dio Exception checking status: $e');
      debugPrint('Stack Trace: $st');
      debugPrint('----------------------------------');
      throw Exception(_handleDioError(e));
    } catch (e, st) {
      debugPrint('Unexpected Exception checking status: $e');
      debugPrint('Stack Trace: $st');
      debugPrint('----------------------------------');
      throw Exception('An unexpected error occurred checking payment status: $e');
    }
  }

  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Unable to connect to payment server. Please check your internet or try again later.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. The server took too long to respond. Please try again later.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Failed to send request to payment server. Please try again later.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final data = error.response?.data;
        if (status == 404) {
          return 'Payment API endpoint not found on server (404).';
        } else if (status != null && status >= 500) {
          return 'Server unavailable or encountered an error ($status). Please try again later.';
        }
        return data?['message'] ?? 'HTTP Error ($status): Failed to process request.';
      case DioExceptionType.cancel:
        return 'Payment request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Connection error. Unable to connect to payment server. Please check if the server is running.';
      case DioExceptionType.unknown:
      default:
        final message = error.message ?? '';
        if (message.contains('SocketException') || message.contains('NetworkIsUnreachable')) {
          return 'No internet connection. Please check your network and try again.';
        }
        return 'Network error: $message';
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
});

final paymentApiServiceProvider = Provider<PaymentApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return PaymentApiService(dio);
});

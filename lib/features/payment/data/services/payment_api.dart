import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';

class PaymentApiService {
  final Dio _dio;

  PaymentApiService(this._dio);

  static const String _defaultBaseUrl = String.fromEnvironment(
    'PAYMENT_BASE_URL',
    defaultValue: 'http://192.168.1.3:3000/api/payment',
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

  Future<Options> _getAuthOptions() async {
    final Map<String, String> headers = {};
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $idToken';
        }
      }
    } catch (e) {
      debugPrint('Warning: Could not attach Firebase Auth token: $e');
    }
    return Options(headers: headers);
  }

  Future<bool> isServerReachable() async {
    final healthUrl = _getHealthUrl(_defaultBaseUrl);
    
    debugPrint('--- SERVER CONNECTIVITY CHECK ---');
    debugPrint('Checking connectivity to: $healthUrl');
    
    try {
      final response = await _dio.get(
        healthUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Connectivity Check Exception: $e');
      return false;
    }
  }

  Future<PaymentInitiationResponse> createPayment({
    required String bookingId,
    required String userId,
    required double amount,
    required String mobileNumber,
  }) async {
    final endpointUrl = '$_defaultBaseUrl/create-order';
    final requestBody = {
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'mobileNumber': mobileNumber,
    };

    debugPrint('--- CASHFREE ORDER INITIATION ---');
    debugPrint('Endpoint: $endpointUrl');

    try {
      final authOptions = await _getAuthOptions();
      final response = await _dio.post(
        endpointUrl,
        data: requestBody,
        options: authOptions,
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        final data = response.data['data'];
        if (success && data != null) {
          final paymentResponse = PaymentInitiationResponse.fromJson(data);
          if (paymentResponse.success && (paymentResponse.paymentSessionId.isNotEmpty || paymentResponse.paymentUrl.isNotEmpty)) {
            return paymentResponse;
          }
        }
      }
      throw Exception(response.data?['message'] ?? 'Failed to initiate Cashfree order.');
    } on DioException catch (e, st) {
      debugPrint('Dio Exception initiating payment: $e');
      debugPrint('Stack Trace: $st');
      throw Exception(_handleDioError(e));
    } catch (e, st) {
      debugPrint('Unexpected Exception: $e');
      debugPrint('Stack Trace: $st');
      throw Exception('An unexpected error occurred during payment setup: $e');
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(String merchantTransactionId) async {
    final endpointUrl = '$_defaultBaseUrl/status/$merchantTransactionId';
    
    debugPrint('--- CASHFREE PAYMENT STATUS CHECK ---');
    debugPrint('Endpoint: $endpointUrl');
    
    try {
      final authOptions = await _getAuthOptions();
      final response = await _dio.get(
        endpointUrl,
        options: authOptions,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      throw Exception(response.data?['message'] ?? 'Failed to check Cashfree payment status.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred checking payment status: $e');
    }
  }
  Future<Map<String, dynamic>> confirmCashPayment({
    required String bookingId,
    required String remarks,
  }) async {
    final endpointUrl = '$_defaultBaseUrl/confirm-cash';
    try {
      final authOptions = await _getAuthOptions();
      final response = await _dio.post(
        endpointUrl,
        data: {
          'bookingId': bookingId,
          'remarks': remarks,
        },
        options: authOptions,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      throw Exception(response.data?['message'] ?? 'Failed to confirm cash payment.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred confirming cash payment: $e');
    }
  }

  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Unable to connect to payment server.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. The server took too long to respond.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Failed to send request to server.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final data = error.response?.data;
        if (status == 401) {
          return 'Unauthorized (401): Please login again.';
        } else if (status == 403) {
          return 'Forbidden (403): You are not authorized to pay for this booking.';
        } else if (status == 404) {
          return 'Payment API endpoint not found on server (404).';
        }
        return data?['message'] ?? 'HTTP Error ($status): Failed to process request.';
      case DioExceptionType.cancel:
        return 'Payment request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Connection error. Unable to connect to payment server.';
      case DioExceptionType.unknown:
      default:
        return 'Network error: ${error.message}';
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

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_auth_headers.dart';

class PaymentApiService {
  final Dio _dio;

  PaymentApiService(this._dio);

  String get _baseUrl => AppConfig.paymentBaseUrl;

  Future<Options> _authenticatedOptions() async {
    return Options(headers: await ApiAuthHeaders.create());
  }

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
    final healthUrl = _getHealthUrl(_baseUrl);
    
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
    } catch (_) {
      return false;
    }
  }

  Future<PaymentInitiationResponse> createPayment({
    required String bookingId,
  }) async {
    final endpointUrl = '$_baseUrl/create';
    final requestBody = {
      'bookingId': bookingId,
    };

    try {
      final response = await _dio.post(
        endpointUrl,
        data: requestBody,
        options: await _authenticatedOptions(),
      );

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
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred during payment setup: $e');
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(String merchantTransactionId) async {
    final endpointUrl = '$_baseUrl/status/$merchantTransactionId';
    
    try {
      final response = await _dio.get(
        endpointUrl,
        options: await _authenticatedOptions(),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      throw Exception(response.data?['message'] ?? 'Failed to check payment status.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
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

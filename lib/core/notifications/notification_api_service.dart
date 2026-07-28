import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../features/payment/data/services/payment_api.dart'; // import dioProvider

class NotificationApiService {
  final Dio _dio;

  NotificationApiService(this._dio);

  static const String _paymentBaseUrl = String.fromEnvironment(
    'PAYMENT_BASE_URL',
    defaultValue: 'http://192.168.1.11:3000/api/payment',
  );

  String get _baseUrl {
    if (_paymentBaseUrl.endsWith('/api/payment')) {
      return _paymentBaseUrl.replaceAll('/api/payment', '/api/notifications');
    }
    return _paymentBaseUrl.replaceAll('/payment', '/notifications');
  }

  Future<Options> _getOptions() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return Options(
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  Future<void> sendCustomNotification({
    required String title,
    required String message,
    required List<String> recipientRoles,
    required List<String> recipientUserIds,
  }) async {
    final url = '$_baseUrl/send';
    final options = await _getOptions();
    final requestBody = {
      'title': title,
      'message': message,
      'recipientRoles': recipientRoles,
      'recipientUserIds': recipientUserIds,
    };

    debugPrint('--- [NotificationApiService] SEND CUSTOM NOTIFICATION ---');
    debugPrint('Request URL: $url');
    debugPrint('HTTP Method: POST');
    debugPrint('Request Headers: ${options.headers}');
    debugPrint('Request Body: $requestBody');

    try {
      final response = await _dio.post(
        url,
        data: requestBody,
        options: options,
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.data}');
      debugPrint('------------------------------------------------------');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to send custom notification.');
      }
    } on DioException catch (e, stackTrace) {
      debugPrint('DioException caught during sendCustomNotification:');
      debugPrint('Status Code: ${e.response?.statusCode}');
      debugPrint('Response Data: ${e.response?.data}');
      debugPrint('Message: ${e.message}');
      debugPrint('Stack Trace:\n$stackTrace');
      debugPrint('------------------------------------------------------');
      final errorMsg = _parseDioError(e);
      throw Exception(errorMsg);
    } catch (e, stackTrace) {
      debugPrint('Exception caught during sendCustomNotification: $e');
      debugPrint('Stack Trace:\n$stackTrace');
      debugPrint('------------------------------------------------------');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    final url = '$_baseUrl/history';
    final options = await _getOptions();

    debugPrint('--- [NotificationApiService] GET NOTIFICATION HISTORY ---');
    debugPrint('Request URL: $url');
    debugPrint('HTTP Method: GET');
    debugPrint('Request Headers: ${options.headers}');

    try {
      final response = await _dio.get(
        url,
        options: options,
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.data}');
      debugPrint('------------------------------------------------------');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List historyList = response.data['history'] ?? [];
        return historyList.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      throw Exception(response.data['error'] ?? 'Failed to retrieve notification history.');
    } on DioException catch (e, stackTrace) {
      debugPrint('DioException caught during getNotificationHistory:');
      debugPrint('Status Code: ${e.response?.statusCode}');
      debugPrint('Response Data: ${e.response?.data}');
      debugPrint('Message: ${e.message}');
      debugPrint('Stack Trace:\n$stackTrace');
      debugPrint('------------------------------------------------------');
      final errorMsg = _parseDioError(e);
      throw Exception(errorMsg);
    } catch (e, stackTrace) {
      debugPrint('Exception caught during getNotificationHistory: $e');
      debugPrint('Stack Trace:\n$stackTrace');
      debugPrint('------------------------------------------------------');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  String _parseDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      String? backendError;
      if (data is Map && data.containsKey('error')) {
        backendError = data['error'].toString();
      }

      if (statusCode == 401) {
        return backendError ?? 'Unauthorized: Authentication token is missing or invalid.';
      } else if (statusCode == 403) {
        return backendError ?? 'Forbidden: You do not have permission to send notifications.';
      } else if (statusCode == 404) {
        return 'Incorrect API URL: The requested endpoint was not found on the server.';
      } else if (statusCode == 500) {
        return backendError ?? 'Internal server error: The backend service failed to process the request.';
      }
      
      if (backendError != null) return backendError;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out: The backend server took too long to respond.';
      case DioExceptionType.badResponse:
        return 'Failed to send notification: Server returned status code ${e.response?.statusCode}.';
      default:
        final message = e.message ?? '';
        if (message.contains('SocketException') || 
            message.contains('NetworkIsUnreachable') || 
            message.contains('No route to host')) {
          return 'Backend server unavailable: Could not reach the host. Please check your network connection and server IP address.';
        }
        return 'Network error: $message';
    }
  }
}

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationApiService(dio);
});

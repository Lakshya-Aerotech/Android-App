import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const double bookingRatePerAcre = double.fromEnvironment(
    'BOOKING_RATE_PER_ACRE',
    defaultValue: 800,
  );

  static String get apiBaseUrl {
    final configured = _configuredApiBaseUrl.trim();
    if (configured.isEmpty) {
      if (kReleaseMode) {
        throw StateError(
          'API_BASE_URL must be supplied for release builds using --dart-define.',
        );
      }
      return 'http://10.0.2.2:3000/api';
    }

    final uri = Uri.tryParse(configured);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE_URL must be an absolute URL.');
    }
    if (uri.hasQuery || uri.hasFragment) {
      throw StateError('API_BASE_URL cannot contain a query string or fragment.');
    }
    if (kReleaseMode && uri.scheme != 'https') {
      throw StateError('Release builds require an HTTPS API_BASE_URL.');
    }

    return configured.endsWith('/')
        ? configured.substring(0, configured.length - 1)
        : configured;
  }

  static String get paymentBaseUrl => '$apiBaseUrl/payment';
  static String get notificationBaseUrl => '$apiBaseUrl/notifications';
  static String get userBaseUrl => '$apiBaseUrl/users';
  static String get bookingBaseUrl => '$apiBaseUrl/bookings';
}

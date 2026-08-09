import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_aerotech/core/config/app_config.dart';

void main() {
  test('development API endpoints are composed consistently', () {
    expect(AppConfig.apiBaseUrl, 'http://10.0.2.2:3000/api');
    expect(AppConfig.bookingBaseUrl, '${AppConfig.apiBaseUrl}/bookings');
    expect(AppConfig.paymentBaseUrl, '${AppConfig.apiBaseUrl}/payment');
    expect(AppConfig.userBaseUrl, '${AppConfig.apiBaseUrl}/users');
  });

  test('default customer price is positive', () {
    expect(AppConfig.bookingRatePerAcre, greaterThan(0));
  });
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../booking/models/booking_model.dart';

class PaymentFailedScreen extends StatelessWidget {
  final BookingModel booking;
  final String? errorMessage;

  const PaymentFailedScreen({
    super.key,
    required this.booking,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: Colors.red,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Payment Failed',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage ??
                      'We could not process your transaction. This might be due to a network timeout, incorrect details, or cancellation.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                PrimaryButton(
                  text: 'Retry Payment',
                  onPressed: () => context.go('/online-payment', extra: booking),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  text: 'Return Home',
                  onPressed: () => context.go('/'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/booking-details', extra: booking),
                  child: Text(
                    'View Booking Summary',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

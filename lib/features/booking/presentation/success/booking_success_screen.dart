import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String bookingId;
  const BookingSuccessScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 100,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Booking Submitted Successfully!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Your service request has been received and is currently being reviewed by our operations team.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text('Booking ID', style: AppTextStyles.bodySmall),
                    Text(
                      bookingId,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              PrimaryButton(
                text: 'Go to Booking History',
                onPressed: () => context.go('/my-bookings'),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'Back to Dashboard',
                onPressed: () => context.go('/farmer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

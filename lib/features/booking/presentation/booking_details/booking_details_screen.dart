import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../shared/enums/booking_status.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/booking_viewmodel.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final BookingModel booking;
  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking ID', style: AppTextStyles.bodySmall),
                    Text(
                      booking.bookingId,
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                  ],
                ),
                StatusChip.fromStatus(booking.status),
              ],
            ),
            const Divider(height: 48),
            
            _buildSectionHeader('Farm Information'),
            _buildDetailItem('Farm Name', booking.farmName, Icons.landscape_outlined),
            _buildDetailItem('Crop Type', booking.cropType, Icons.spa_outlined),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Service Details'),
            _buildDetailItem('Service', booking.serviceType, Icons.settings_suggest_outlined),
            _buildDetailItem('Area', '${booking.estimatedArea} Acres', Icons.crop_free),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Schedule'),
            _buildDetailItem('Date', DateFormat('EEEE, dd MMM yyyy').format(booking.bookingDate), Icons.calendar_today_outlined),
            _buildDetailItem('Preferred Time', booking.preferredTime, Icons.access_time_outlined),

            if (booking.remarks != null) ...[
              const SizedBox(height: 24),
              _buildSectionHeader('Additional Notes'),
              Text(booking.remarks!, style: AppTextStyles.bodyMedium),
            ],

            const Divider(height: 64),
            
            if (booking.status == BookingStatus.pending) ...[
              PrimaryButton(
                text: 'Cancel Booking',
                onPressed: () => _showCancelConfirmation(context, ref),
                isLoading: bookingState is AsyncLoading,
              ),
              const SizedBox(height: 16),
            ],
            
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back to History'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
              Text(value, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Cancel Booking',
        content: 'Are you sure you want to cancel this booking? This action cannot be undone.',
        confirmLabel: 'Yes, Cancel',
        onConfirm: () {
          ref.read(bookingViewModelProvider.notifier).cancelBooking(booking.docId!);
          context.pop();
        },
      ),
    );
  }
}

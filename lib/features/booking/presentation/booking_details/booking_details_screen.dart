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
import '../../widgets/booking_summary_card.dart';
import '../../widgets/booking_timeline.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final BookingModel booking;
  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Booking ID', style: AppTextStyles.bodySmall),
                            Text(
                              booking.bookingId,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip.fromStatus(booking.status),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildQuickInfo(context),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Farm & Service', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            BookingSummaryCard(
              label: 'Farm Name',
              value: booking.farmName,
              icon: Icons.landscape_outlined,
            ),
            BookingSummaryCard(
              label: 'Service Type',
              value: booking.serviceType,
              icon: Icons.settings_suggest_outlined,
            ),
            BookingSummaryCard(
              label: 'Estimated Area',
              value: '${booking.estimatedArea} Acres',
              icon: Icons.crop_free,
            ),

            if (booking.assignedPilotName != null || booking.assignedDroneName != null) ...[
              const SizedBox(height: 24),
              Text('Assigned Resources', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (booking.assignedPilotName != null)
                BookingSummaryCard(
                  label: 'Pilot',
                  value: booking.assignedPilotName!,
                  icon: Icons.person_add_alt_1_outlined,
                ),
              if (booking.assignedDroneName != null)
                BookingSummaryCard(
                  label: 'Drone',
                  value: booking.assignedDroneName!,
                  icon: Icons.precision_manufacturing_outlined,
                ),
            ],

            const SizedBox(height: 24),
            Text('Service Status', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: BookingTimeline(currentStatus: booking.status),
            ),

            if (booking.remarks != null) ...[
              const SizedBox(height: 24),
              Text('Additional Notes', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Text(booking.remarks!, style: AppTextStyles.bodyMedium),
              ),
            ],

            const SizedBox(height: 40),
            
            if (booking.status == BookingStatus.pending) ...[
              PrimaryButton(
                text: 'Cancel Booking',
                onPressed: () => _showCancelConfirmation(context, ref),
                isLoading: bookingState is AsyncLoading,
              ),
              const SizedBox(height: 16),
            ],
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoColumn(
          Icons.calendar_today_outlined,
          'Date',
          DateFormat('dd MMM').format(booking.bookingDate),
        ),
        _buildInfoColumn(
          Icons.access_time_outlined,
          'Time',
          booking.preferredTime,
        ),
        _buildInfoColumn(
          Icons.grass_outlined,
          'Crop',
          booking.cropType,
        ),
      ],
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
        Text(value, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
      ],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/confirmation_dialog.dart' as widgets;
import '../../../../shared/enums/booking_status.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../widgets/booking_summary_card.dart';
import '../../widgets/booking_timeline.dart';
import '../../widgets/mission_summary_card.dart';
import '../../widgets/rating_card.dart';
import '../../widgets/issue_report_dialog.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final BookingModel booking;
  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use docId to listen for real-time updates
    final bookingAsync = ref.watch(singleBookingStreamProvider(booking.docId!));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: bookingAsync.when(
        data: (liveBooking) {
          if (liveBooking == null) {
            return const Center(child: Text('Booking not found.'));
          }
          return _buildContent(context, ref, liveBooking);
        },
        loading: () => _buildContent(context, ref, booking), // Show initial data while loading
        error: (e, _) => Center(child: Text('Error loading booking: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, BookingModel b) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(b),
          const SizedBox(height: 24),
          
          if (b.status == BookingStatus.completed) ...[
             _buildPostServiceActions(context, ref, b),
             const SizedBox(height: 24),
          ],

          if (b.status == BookingStatus.farmerConfirmed || b.status == BookingStatus.closed) ...[
            RatingCard(booking: b),
            const SizedBox(height: 24),
          ],

          if (b.actualAreaCovered != null) ...[
            MissionSummaryCard(booking: b),
            const SizedBox(height: 24),
          ],

          Text('Farm & Service', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          BookingSummaryCard(
            label: 'Farm Name',
            value: b.farmName,
            icon: Icons.landscape_outlined,
          ),
          BookingSummaryCard(
            label: 'Service Type',
            value: b.serviceType,
            icon: Icons.settings_suggest_outlined,
          ),
          BookingSummaryCard(
            label: 'Estimated Area',
            value: '${b.estimatedArea} Acres',
            icon: Icons.crop_free,
          ),

          if (b.assignedPilotName != null || b.assignedDroneName != null) ...[
            const SizedBox(height: 24),
            Text('Assigned Resources', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (b.assignedPilotName != null)
              BookingSummaryCard(
                label: 'Pilot',
                value: b.assignedPilotName!,
                icon: Icons.person_add_alt_1_outlined,
              ),
            if (b.assignedDroneName != null)
              BookingSummaryCard(
                label: 'Drone',
                value: b.assignedDroneName!,
                icon: Icons.precision_manufacturing_outlined,
              ),
          ],

          const SizedBox(height: 24),
          Text('Service Progress', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: BookingTimeline(booking: b),
          ),

          if (b.remarks != null || b.operationsRemarks.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Notes', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (b.remarks != null)
              _buildNoteCard('Your Note', b.remarks!),
            ...b.operationsRemarks.map((r) => _buildNoteCard('Ops: ${r.createdBy}', r.message)),
          ],

          const SizedBox(height: 40),
          
          if (b.status == BookingStatus.pending) ...[
            PrimaryButton(
              text: 'Cancel Booking',
              onPressed: () => _showCancelConfirmation(context, ref, b.docId!),
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
            ),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BookingModel b) {
    return Container(
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
                      b.bookingId,
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
              Flexible(child: StatusChip.fromStatus(b.status)),
            ],
          ),
          const Divider(height: 32),
          _buildQuickInfo(b),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(BookingModel b) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildInfoColumn(
            Icons.calendar_today_outlined,
            'Date',
            DateFormat('dd MMM').format(b.bookingDate),
          ),
        ),
        Expanded(
          child: _buildInfoColumn(
            Icons.access_time_outlined,
            'Time',
            b.preferredTime,
          ),
        ),
        Expanded(
          child: _buildInfoColumn(
            Icons.grass_outlined,
            'Crop',
            b.cropType,
          ),
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
        Text(
          value, 
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildNoteCard(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(content, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildPostServiceActions(BuildContext context, WidgetRef ref, BookingModel b) {
    final isLoading = ref.watch(bookingViewModelProvider).isLoading;

    return Column(
      children: [
        PrimaryButton(
          text: 'Confirm Service Completion',
          onPressed: () => _showConfirmServiceDialog(context, ref, b.docId!),
          isLoading: isLoading,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _showIssueReportDialog(context, b.docId!),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Report an Issue'),
        ),
      ],
    );
  }

  void _showConfirmServiceDialog(BuildContext context, WidgetRef ref, String docId) {
    showDialog(
      context: context,
      builder: (context) => widgets.ConfirmationDialog(
        title: 'Confirm Service',
        content: 'Have you verified that the requested service has been completed satisfactorily?',
        confirmLabel: 'Yes, Confirm',
        onConfirm: () {
          ref.read(bookingViewModelProvider.notifier).confirmService(docId);
        },
      ),
    );
  }

  void _showIssueReportDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => IssueReportDialog(bookingDocId: docId),
    );
  }

  void _showCancelConfirmation(BuildContext context, WidgetRef ref, String docId) {
    showDialog(
      context: context,
      builder: (context) => widgets.ConfirmationDialog(
        title: 'Cancel Booking',
        content: 'Are you sure you want to cancel this booking? This action cannot be undone.',
        confirmLabel: 'Yes, Cancel',
        onConfirm: () {
          ref.read(bookingViewModelProvider.notifier).cancelBooking(docId);
        },
      ),
    );
  }
}

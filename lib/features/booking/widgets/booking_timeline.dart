import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/enums/booking_status.dart';
import '../models/booking_model.dart';

class BookingTimeline extends StatelessWidget {
  final BookingModel booking;

  const BookingTimeline({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final stages = <Map<String, dynamic>>[
      {'label': 'Booking Submitted', 'status': BookingStatus.pending},
      {'label': 'Reviewed', 'status': BookingStatus.reviewed},
      {'label': 'Pilot Assigned', 'status': BookingStatus.pilotAssigned},
      {'label': 'Pilot En Route', 'status': BookingStatus.enRoute},
      {'label': 'Arrived At Farm', 'status': BookingStatus.arrived},
      {'label': 'Mission Started', 'status': BookingStatus.inProgress},
      {'label': 'Mission Completed', 'status': BookingStatus.completed},
      {'label': 'Payment & Closed', 'status': BookingStatus.closed},
    ];

    // Find the latest completed stage from statusHistory
    final history = booking.statusHistory;

    int activeIndex = stages.indexWhere((s) => s['status'] == booking.status);
    if (activeIndex == -1) {
      if (booking.status == BookingStatus.accepted) {
        activeIndex = 2; // Map 'Accepted' to 'Pilot Assigned' stage
      } else if (booking.status == BookingStatus.farmerConfirmed) {
        activeIndex = 6; // Completed stage
      } else if (booking.status == BookingStatus.closed) {
        activeIndex = 7; // Closed stage
      }
    }
    
    return Column(
      children: List.generate(stages.length, (index) {
        final stageStatus = stages[index]['status'] as BookingStatus;
        final isLast = index == stages.length - 1;
        
        // Find if this stage has an entry in history
        final historyEntry = history.cast<StatusHistoryEntry?>().firstWhere(
          (e) => e?.status == stageStatus,
          orElse: () => null,
        );

        final isActive = booking.status == stageStatus;
        final isCompleted = historyEntry != null || (activeIndex != -1 && index < activeIndex);
        final isCancelled = booking.status == BookingStatus.cancelled;
        final isIssueReported = booking.status == BookingStatus.issueReported;

        Color color = isCompleted || isActive ? AppColors.accent : AppColors.border;
        if (isCancelled && isActive) color = Colors.red;
        if (isIssueReported && isActive) color = Colors.red.shade700;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, size: 12, color: color)
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? color : Colors.transparent,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted ? AppColors.accent : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stages[index]['label'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                          color: isActive || isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                      if (historyEntry != null)
                        Text(
                          DateFormat('hh:mm a').format(historyEntry.timestamp),
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                        ),
                    ],
                  ),
                  if (isActive) ...[
                    Text(
                      _getStatusSubtitle(booking.status),
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                    ),
                  ],
                  if (historyEntry != null && historyEntry.remarks != null && historyEntry.remarks!.isNotEmpty && isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        historyEntry.remarks!,
                        style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic, color: AppColors.accent),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  String _getStatusSubtitle(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Waiting for operations to review your booking.';
      case BookingStatus.reviewed:
        return 'Booking approved! Assigning pilot.';
      case BookingStatus.pilotAssigned:
        return 'Pilot has been assigned to your booking.';
      case BookingStatus.accepted:
        return 'Pilot has accepted the job.';
      case BookingStatus.enRoute:
        return 'Pilot is on the way to your farm.';
      case BookingStatus.arrived:
        return 'Pilot has arrived at the farm.';
      case BookingStatus.inProgress:
        return 'Mission is currently in progress.';
      case BookingStatus.completed:
        return 'Service completed! Pilot is processing the payment.';
      case BookingStatus.closed:
        return 'Service fully completed and payment verified.';
      case BookingStatus.issueReported:
        return 'An issue has been reported. We will follow up soon.';
      case BookingStatus.cancelled:
        return 'This booking was cancelled.';
      default:
        return 'Current status of your booking.';
    }
  }
}

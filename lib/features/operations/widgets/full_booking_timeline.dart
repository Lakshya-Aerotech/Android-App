import 'package:flutter/material.dart';
import 'package:lakshya_aerotech/core/theme/app_colors.dart';
import 'package:lakshya_aerotech/core/theme/app_text_styles.dart';
import 'package:lakshya_aerotech/shared/enums/booking_status.dart';

class FullBookingTimeline extends StatelessWidget {
  final BookingStatus currentStatus;

  const FullBookingTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final stages = [
      {'label': 'Pending', 'status': BookingStatus.pending},
      {'label': 'Reviewed', 'status': BookingStatus.reviewed},
      {'label': 'Pilot Assigned', 'status': BookingStatus.pilotAssigned},
      {'label': 'En Route', 'status': BookingStatus.enRoute},
      {'label': 'Arrived', 'status': BookingStatus.arrived},
      {'label': 'In Progress', 'status': BookingStatus.inProgress},
      {'label': 'Completed', 'status': BookingStatus.completed},
      {'label': 'Closed', 'status': BookingStatus.closed},
    ];

    int activeIndex = stages.indexWhere((s) => s['status'] == currentStatus);
    
    final isCancelled = currentStatus == BookingStatus.cancelled;
    final isIssueReported = currentStatus == BookingStatus.issueReported;

    if (activeIndex == -1) {
       if (isCancelled || isIssueReported) {
         activeIndex = 0; 
       } else if (currentStatus == BookingStatus.accepted) {
         activeIndex = 2; // Map 'Accepted' to 'Pilot Assigned' stage
       } else if (currentStatus == BookingStatus.farmerConfirmed) {
         activeIndex = 6; // Completed stage
       }
    }

    return Column(
      children: List.generate(stages.length, (index) {
        final isLast = index == stages.length - 1;
        final isCompleted = index < activeIndex;
        final isActive = index == activeIndex;

        Color color =
            isCompleted || isActive ? AppColors.accent : AppColors.border;
        
        if (isActive && isIssueReported) color = Colors.red.shade700;
        if (isActive && isCancelled) color = Colors.red;

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
                    child:
                        isCompleted
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
                    height: 30,
                    color: isCompleted ? AppColors.accent : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive && isIssueReported ? 'Issue Reported' : 
                    isActive && isCancelled ? 'Cancelled' :
                    stages[index]['label'] as String,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight:
                          isActive || isCompleted
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color:
                          isActive || isCompleted
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                    ),
                  ),
                  if (isActive)
                    Text(
                      isCancelled ? 'Booking was cancelled.' : 
                      isIssueReported ? 'Farmer reported an issue.' :
                      'Current stage.',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

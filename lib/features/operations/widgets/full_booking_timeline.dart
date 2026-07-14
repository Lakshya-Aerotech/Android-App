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
      {'label': 'Drone Assigned', 'status': BookingStatus.droneAssigned},
      {'label': 'Accepted', 'status': BookingStatus.accepted},
      {'label': 'En Route', 'status': BookingStatus.enRoute},
      {'label': 'In Progress', 'status': BookingStatus.inProgress},
      {'label': 'Completed', 'status': BookingStatus.completed},
      {'label': 'Farmer Confirmed', 'status': BookingStatus.farmerConfirmed},
    ];

    int activeIndex = stages.indexWhere((s) => s['status'] == currentStatus);
    if (activeIndex == -1 && currentStatus == BookingStatus.cancelled) {
        activeIndex = 0;
    }

    return Column(
      children: List.generate(stages.length, (index) {
        final isLast = index == stages.length - 1;
        final isCompleted = index < activeIndex;
        final isActive = index == activeIndex;
        final isCancelled = currentStatus == BookingStatus.cancelled;

        Color color = isCompleted || isActive ? AppColors.accent : AppColors.border;
        if (isCancelled && isActive) color = Colors.red;

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
                  Text(
                    isCancelled && isActive ? 'Cancelled' : stages[index]['label'] as String,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isActive || isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  if (isActive)
                    Text(
                      isCancelled ? 'Booking was cancelled.' : 'Current stage.',
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

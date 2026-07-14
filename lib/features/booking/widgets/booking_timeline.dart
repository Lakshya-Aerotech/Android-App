import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/enums/booking_status.dart';

class BookingTimeline extends StatelessWidget {
  final BookingStatus currentStatus;

  const BookingTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final stages = [
      {'label': 'Pending', 'status': BookingStatus.pending},
      {'label': 'Reviewed', 'status': null}, // Placeholder for future
      {'label': 'Assigned', 'status': BookingStatus.assigned},
      {'label': 'Accepted', 'status': BookingStatus.accepted},
      {'label': 'In Progress', 'status': BookingStatus.inProgress},
      {'label': 'Completed', 'status': BookingStatus.completed},
    ];

    int activeIndex = _getSelectedIndex(currentStatus, stages);

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
                      isCancelled ? 'Booking was cancelled.' : 'Current status of your booking.',
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

  int _getSelectedIndex(BookingStatus status, List<Map<String, dynamic>> stages) {
    if (status == BookingStatus.cancelled) {
      // Find where it was before cancellation or just mark first if pending
      return 0; 
    }
    for (int i = 0; i < stages.length; i++) {
      if (stages[i]['status'] == status) return i;
    }
    return 0;
  }
}

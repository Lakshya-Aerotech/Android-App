import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_radius.dart';
import '../../shared/enums/booking_status.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  const StatusChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  factory StatusChip.fromStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.assigned:
        return const StatusChip(
          label: 'Assigned',
          backgroundColor: Color(0xFFEBF8FF),
          textColor: Color(0xFF3182CE),
        );
      case BookingStatus.inProgress:
        return const StatusChip(
          label: 'In Progress',
          backgroundColor: Color(0xFFFEFCBF),
          textColor: Color(0xFFB7791F),
        );
      case BookingStatus.completed:
        return const StatusChip(
          label: 'Completed',
          backgroundColor: Color(0xFFF0FFF4),
          textColor: Color(0xFF38A169),
        );
      case BookingStatus.pending:
        return const StatusChip(
          label: 'Pending',
          backgroundColor: Color(0xFFFFF5F5),
          textColor: Color(0xFFE53E3E),
        );
      case BookingStatus.accepted:
        return const StatusChip(
          label: 'Accepted',
          backgroundColor: Color(0xFFE9D8FD),
          textColor: Color(0xFF805AD5),
        );
      case BookingStatus.cancelled:
        return const StatusChip(
          label: 'Cancelled',
          backgroundColor: Color(0xFFEDF2F7),
          textColor: Color(0xFF4A5568),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.accent.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusXs,
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: textColor ?? AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

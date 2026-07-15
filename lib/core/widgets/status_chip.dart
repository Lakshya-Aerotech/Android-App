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
    try {
      return StatusChip(
        label: status.displayName,
        backgroundColor: status.color.withValues(alpha: 0.1),
        textColor: status.color,
      );
    } catch (e) {
      debugPrint('Error in StatusChip.fromStatus: $e');
      return const StatusChip(label: 'Unknown');
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
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

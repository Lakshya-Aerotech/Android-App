import 'package:flutter/material.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/operations_models.dart';

class PendingAssignmentCard extends StatelessWidget {
  final PendingAssignment assignment;
  final VoidCallback onAssignPressed;

  const PendingAssignmentCard({
    super.key,
    required this.assignment,
    required this.onAssignPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.bookingId,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  assignment.farmerName,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${assignment.serviceName} • ${assignment.area}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${assignment.preferredDate}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onAssignPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Assign', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

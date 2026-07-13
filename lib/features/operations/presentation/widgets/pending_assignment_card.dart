import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking #${assignment.bookingId}',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person_outline, 'Farmer', assignment.farmerName),
          _buildInfoRow(Icons.spa_outlined, 'Service', assignment.serviceName),
          _buildInfoRow(Icons.calendar_today_outlined, 'Date', assignment.preferredDate),
          _buildInfoRow(Icons.crop_free, 'Area', assignment.area),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Assign Pilot',
              onPressed: onAssignPressed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

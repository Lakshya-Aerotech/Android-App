import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../models/operations_models.dart';

class ActiveServiceCard extends StatelessWidget {
  final ActiveService service;
  final VoidCallback onActionPressed;

  const ActiveServiceCard({
    super.key,
    required this.service,
    required this.onActionPressed,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking #${service.bookingId}',
                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              StatusChip(
                label: service.status,
                backgroundColor: service.statusColor.withValues(alpha: 0.1),
                textColor: service.statusColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person_outline, 'Farmer', service.farmerName),
          _buildInfoRow(Icons.flight_takeoff, 'Pilot', service.pilotName),
          _buildInfoRow(Icons.precision_manufacturing_outlined, 'Drone', service.droneId),
          _buildInfoRow(Icons.location_on_outlined, 'Village', service.village),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onActionPressed,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Track Job'),
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

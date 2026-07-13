import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/status_chip.dart';
import '../models/farm_model.dart';

class DetailedFarmCard extends StatelessWidget {
  final FarmModel farm;
  final VoidCallback onTap;

  const DetailedFarmCard({
    super.key,
    required this.farm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    farm.farmName,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                StatusChip(
                  label: farm.isActive ? 'Active' : 'Inactive',
                  backgroundColor: (farm.isActive ? AppColors.success : Colors.red).withValues(alpha: 0.1),
                  textColor: farm.isActive ? AppColors.success : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.spa_outlined, 'Crop', farm.cropType),
            _buildInfoRow(Icons.crop_free, 'Area', '${farm.area} ${farm.unit}'),
            _buildInfoRow(Icons.location_on_outlined, 'Location', '${farm.village}, ${farm.district}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Added on ${DateFormat('d MMM yyyy').format(farm.createdAt)}',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: AppTextStyles.bodySmall),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

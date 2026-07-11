  import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_radius.dart';

class FarmCard extends StatelessWidget {
  final String farmName;
  final String village;
  final String area;
  final bool isSelected;
  final VoidCallback onTap;

  const FarmCard({
    super.key,
    required this.farmName,
    required this.village,
    required this.area,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmName,
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Village: $village',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    '$area Acres',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.textTertiary,
                  width: 2,
                ),
                color: isSelected ? AppColors.accent : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

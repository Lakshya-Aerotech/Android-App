import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_radius.dart';
import '../../shared/enums/booking_status.dart';
import 'status_chip.dart';

class BookingCard extends StatelessWidget {
  final String dateTime;
  final String farmName;
  final String cropInfo;
  final BookingStatus status;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.dateTime,
    required this.farmName,
    required this.cropInfo,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateTime,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StatusChip.fromStatus(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  farmName,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.grass_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  cropInfo,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lakshya_aerotech/core/constants/app_radius.dart';
import 'package:lakshya_aerotech/core/theme/app_colors.dart';
import 'package:lakshya_aerotech/core/theme/app_text_styles.dart';
import 'package:lakshya_aerotech/core/widgets/status_chip.dart';
import 'package:lakshya_aerotech/features/booking/models/booking_model.dart';

class OpsBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const OpsBookingCard({
    super.key,
    required this.booking,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.bookingId,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Farmer: ${booking.farmerName ?? 'Not Provided'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (booking.farmerPhone != null)
                      Text(
                        booking.farmerPhone!,
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                      ),
                  ],
                ),
                StatusChip.fromStatus(booking.status),
              ],
            ),
            const Divider(height: 24),
            Text(
              booking.serviceType,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.landscape_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${booking.farmName} (${booking.village ?? 'N/A'}, ${booking.district ?? 'N/A'})',
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(Icons.calendar_today_outlined, DateFormat('dd MMM').format(booking.bookingDate)),
                const SizedBox(width: 16),
                _buildInfoItem(Icons.access_time_outlined, booking.preferredTime),
                const SizedBox(width: 16),
                _buildInfoItem(Icons.crop_free, '${booking.estimatedArea} Ac'),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
              ],
            ),
            if (booking.remarks != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Note: ${booking.remarks}',
                  style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

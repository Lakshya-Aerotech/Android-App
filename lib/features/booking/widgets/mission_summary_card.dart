import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_radius.dart';
import '../models/booking_model.dart';

class MissionSummaryCard extends StatelessWidget {
  final BookingModel booking;

  const MissionSummaryCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text('Mission Summary', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          _buildDetailRow('Actual Area Covered', '${booking.actualAreaCovered ?? 0} Acres'),
          _buildDetailRow('Flight Duration', '${booking.flightDuration ?? '0'} Mins'),
          _buildDetailRow('Chemical Used', booking.chemicalUsed ?? 'N/A'),
          _buildDetailRow('Completed At', booking.confirmedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(booking.confirmedAt!) : 'Waiting for confirmation'),
          
          if (booking.missionNotes != null && booking.missionNotes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Pilot Notes:', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(booking.missionNotes!, style: AppTextStyles.bodyMedium),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

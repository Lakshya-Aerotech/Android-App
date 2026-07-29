import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/enums/booking_status.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../models/booking_model.dart';

class BookingHistoryCard extends ConsumerWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const BookingHistoryCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Text(
                  booking.bookingId,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppColors.primary,
                  ),
                ),
                StatusChip.fromStatus(booking.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.tr(booking.serviceType),
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
                    booking.farmName,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (booking.farmerName != null && booking.farmerName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_pin_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${context.tr('Farmer: ')}${booking.farmerName}',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (booking.assignedPilotId != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    '${context.tr('Pilot: ')}${booking.assignedPilotName ?? context.tr('N/A')}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (booking.status != BookingStatus.pending && booking.status != BookingStatus.cancelled) ...[
                const SizedBox(height: 4),
                ref.watch(userDetailsProvider(booking.assignedPilotId!)).when(
                  data: (pilot) => Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        '${context.tr('Pilot Contact: ')}${pilot?.phoneNumber ?? context.tr('N/A')}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  loading: () => Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        '${context.tr('Pilot Contact: ')}${context.tr('Loading...')}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ],
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy').format(booking.bookingDate),
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  booking.preferredTime,
                  style: AppTextStyles.bodySmall,
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

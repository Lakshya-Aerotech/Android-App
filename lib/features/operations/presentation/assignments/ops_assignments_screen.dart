import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lakshya_aerotech/core/constants/app_radius.dart';
import 'package:lakshya_aerotech/core/constants/app_sizes.dart';
import 'package:lakshya_aerotech/core/constants/app_spacing.dart';
import 'package:lakshya_aerotech/core/theme/app_colors.dart';
import 'package:lakshya_aerotech/core/theme/app_text_styles.dart';
import 'package:lakshya_aerotech/core/widgets/empty_state.dart';
import 'package:lakshya_aerotech/core/widgets/primary_button.dart';
import 'package:lakshya_aerotech/core/localization/app_localizations.dart';
import 'package:lakshya_aerotech/features/booking/models/booking_model.dart';
import 'package:lakshya_aerotech/features/operations/viewmodels/operations_viewmodel.dart';

class OpsAssignmentsScreen extends ConsumerWidget {
  const OpsAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(approvedUnassignedBookingsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.tr('Assign Pilot')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return EmptyState(
              title: context.tr('No bookings awaiting assignment'),
              message: context.tr('Approved bookings will appear here automatically.'),
              icon: Icons.assignment_turned_in_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(approvedUnassignedBookingsStreamProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => AppSpacing.verticalMd,
              itemBuilder: (context, index) {
                return _AssignmentBookingCard(booking: bookings[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => EmptyState(
          title: context.tr('Unable to load assignments'),
          message: context.tr('Check your connection and try again.'),
          icon: Icons.wifi_off_outlined,
        ),
      ),
    );
  }
}

class _AssignmentBookingCard extends ConsumerWidget {
  final BookingModel booking;

  const _AssignmentBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydratedAsync = ref.watch(hydratedBookingProvider(booking));

    return hydratedAsync.when(
      data: (hydrated) => _BookingCardContent(booking: hydrated),
      loading: () => _BookingCardContent(booking: booking),
      error: (_, __) => _BookingCardContent(booking: booking),
    );
  }
}

class _BookingCardContent extends StatelessWidget {
  final BookingModel booking;

  const _BookingCardContent({required this.booking});

  @override
  Widget build(BuildContext context) {
    final location = [
      booking.village,
      booking.district,
      booking.state,
    ].where((value) => value != null && value.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.bookingId,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      booking.farmerName ?? 'Farmer',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: booking.status.displayName),
            ],
          ),
          AppSpacing.verticalMd,
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(icon: Icons.spa_outlined, label: booking.serviceType),
              _InfoChip(icon: Icons.grass_outlined, label: booking.farmName),
              if (location.isNotEmpty)
                _InfoChip(icon: Icons.location_on_outlined, label: location),
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('dd MMM yyyy').format(booking.bookingDate),
              ),
              _InfoChip(
                icon: Icons.schedule_outlined,
                label: booking.preferredTime,
              ),
              _InfoChip(
                icon: Icons.crop_square_outlined,
                label: '${booking.estimatedArea.toStringAsFixed(1)} ${context.tr('acres')}',
              ),
            ],
          ),
          AppSpacing.verticalLg,
          PrimaryButton(
            text: 'Assign Pilot',
            icon: const Icon(Icons.assignment_ind_outlined, size: 18),
            onPressed: () =>
                context.push('/operations/assignments/assign', extra: booking),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.isEmpty ? context.tr('Not provided') : context.tr(label),
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusSm,
      ),
      child: Text(
        context.tr(label),
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.info),
      ),
    );
  }
}

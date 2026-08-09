import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/status_chip.dart';
import '../models/pilot_dashboard_data.dart';

class PilotAssignmentCard extends StatelessWidget {
  final PilotAssignment assignment;
  final VoidCallback onNavigate;
  final VoidCallback onViewDetails;

  const PilotAssignmentCard({
    super.key,
    required this.assignment,
    required this.onNavigate,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: AppRadius.radiusLg,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Booking: ${assignment.bookingId}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              StatusChip(
                label: assignment.status,
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                textColor: AppColors.accent,
              ),
            ],
          ),
          AppSpacing.verticalMd,
          _AssignmentRow(
            icon: Icons.person_outline,
            label: 'Farmer',
            value: assignment.farmer,
          ),
          _AssignmentRow(
            icon: Icons.spa_outlined,
            label: 'Service',
            value: assignment.service,
          ),
          _AssignmentRow(
            icon: Icons.landscape_outlined,
            label: 'Farm',
            value: assignment.farm,
          ),
          _AssignmentRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: assignment.location,
          ),
          _AssignmentRow(
            icon: Icons.schedule_outlined,
            label: 'Time',
            value: assignment.time,
          ),
          _AssignmentRow(
            icon: Icons.crop_free_outlined,
            label: 'Area',
            value: assignment.area,
          ),
          _AssignmentRow(
            icon: Icons.flight_takeoff_outlined,
            label: 'Drone',
            value: assignment.drone,
          ),
          AppSpacing.verticalMd,
          LayoutBuilder(
            builder: (context, constraints) {
              final useColumn = constraints.maxWidth < 320;
              final buttons = [
                ElevatedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Navigate'),
                ),
                OutlinedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View Details'),
                ),
              ];

              if (useColumn) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [buttons[0], AppSpacing.verticalSm, buttons[1]],
                );
              }

              return Row(
                children: [
                  Expanded(child: buttons[0]),
                  AppSpacing.horizontalMd,
                  Expanded(child: buttons[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AssignmentRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSizeSm, color: AppColors.textMutedDark),
          AppSpacing.horizontalSm,
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMutedDark,
                ),
                children: [
                  TextSpan(text: '$label: '),
                  TextSpan(
                    text: value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

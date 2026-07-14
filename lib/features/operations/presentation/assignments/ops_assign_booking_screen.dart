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
import 'package:lakshya_aerotech/features/booking/models/booking_model.dart';
import 'package:lakshya_aerotech/features/operations/models/operations_models.dart';
import 'package:lakshya_aerotech/features/operations/viewmodels/operations_viewmodel.dart';

class OpsAssignBookingScreen extends ConsumerStatefulWidget {
  final BookingModel booking;

  const OpsAssignBookingScreen({super.key, required this.booking});

  @override
  ConsumerState<OpsAssignBookingScreen> createState() =>
      _OpsAssignBookingScreenState();
}

class _OpsAssignBookingScreenState
    extends ConsumerState<OpsAssignBookingScreen> {
  OpsPilotResource? _selectedPilot;
  OpsDroneResource? _selectedDrone;

  @override
  Widget build(BuildContext context) {
    final pilotsAsync = ref.watch(availablePilotsStreamProvider);
    final dronesAsync = ref.watch(dronesStreamProvider);
    final actionState = ref.watch(operationsViewModelProvider);
    final isSubmitting = actionState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Assign Pilot'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          decoration: const BoxDecoration(
            color: AppColors.lightSurface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: PrimaryButton(
            text: 'Confirm Assignment',
            isLoading: isSubmitting,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            onPressed:
                _selectedPilot != null &&
                    _selectedDrone != null &&
                    !isSubmitting
                ? _confirmAssignment
                : null,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          _BookingSummary(booking: widget.booking),
          AppSpacing.verticalXl,
          _SectionTitle(title: 'Select Pilot'),
          AppSpacing.verticalMd,
          pilotsAsync.when(
            data: (pilots) {
              if (pilots.isEmpty) {
                return const EmptyState(
                  title: 'No available pilots',
                  message: 'Active available pilots will appear here.',
                  icon: Icons.person_off_outlined,
                );
              }
              return Column(
                children: [
                  for (final pilot in pilots) ...[
                    _PilotCard(
                      pilot: pilot,
                      selected: _selectedPilot?.uid == pilot.uid,
                      onTap: pilot.canSelect
                          ? () => setState(() => _selectedPilot = pilot)
                          : null,
                    ),
                    AppSpacing.verticalMd,
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const EmptyState(
              title: 'Unable to load pilots',
              message: 'Check your connection and try again.',
              icon: Icons.wifi_off_outlined,
            ),
          ),
          AppSpacing.verticalLg,
          _SectionTitle(title: 'Select Drone'),
          AppSpacing.verticalMd,
          dronesAsync.when(
            data: (drones) {
              if (drones.isEmpty) {
                return const EmptyState(
                  title: 'No drones found',
                  message: 'Available drones will appear here.',
                  icon: Icons.precision_manufacturing_outlined,
                );
              }
              return Column(
                children: [
                  for (final drone in drones) ...[
                    _DroneCard(
                      drone: drone,
                      selected: _selectedDrone?.id == drone.id,
                      onTap: drone.canSelect
                          ? () => setState(() => _selectedDrone = drone)
                          : null,
                    ),
                    AppSpacing.verticalMd,
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const EmptyState(
              title: 'Unable to load drones',
              message: 'Check your connection and try again.',
              icon: Icons.wifi_off_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAssignment() async {
    final pilot = _selectedPilot;
    final drone = _selectedDrone;
    final docId = widget.booking.docId;
    if (pilot == null || drone == null || docId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogLine(label: 'Booking', value: widget.booking.bookingId),
            _DialogLine(label: 'Pilot', value: pilot.name),
            _DialogLine(label: 'Drone', value: drone.code),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(operationsViewModelProvider.notifier)
        .assignPilotAndDrone(
          OpsAssignmentRequest(
            bookingDocId: docId,
            bookingNumber: widget.booking.bookingId,
            farmerId: widget.booking.farmerUid,
            pilot: pilot,
            drone: drone,
          ),
        );

    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilot and drone assigned successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }
}

class _BookingSummary extends StatelessWidget {
  final BookingModel booking;

  const _BookingSummary({required this.booking});

  @override
  Widget build(BuildContext context) {
    final location = [
      booking.village,
      booking.district,
    ].where((value) => value != null && value.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.bookingId,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textInverted,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.verticalSm,
          Text(
            '${booking.farmerName ?? 'Farmer'} - ${booking.serviceType}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textInverted,
            ),
          ),
          AppSpacing.verticalSm,
          Text(
            [
              booking.farmName,
              if (location.isNotEmpty) location,
              DateFormat('dd MMM yyyy').format(booking.bookingDate),
              booking.preferredTime,
            ].join(' - '),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textInverted.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _PilotCard extends StatelessWidget {
  final OpsPilotResource pilot;
  final bool selected;
  final VoidCallback? onTap;

  const _PilotCard({
    required this.pilot,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = pilot.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Semantics(
      selected: selected,
      label: selected ? '${pilot.name} selected' : pilot.name,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusMd,
        child: _SelectableContainer(
          selected: selected,
          enabled: pilot.canSelect,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                backgroundImage: pilot.profileImageUrl != null
                    ? NetworkImage(pilot.profileImageUrl!)
                    : null,
                child: pilot.profileImageUrl == null
                    ? Text(
                        initials.isEmpty ? 'P' : initials,
                        style: AppTextStyles.labelLarge,
                      )
                    : null,
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pilot.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (pilot.phoneNumber != null) ...[
                      AppSpacing.verticalXs,
                      Text(pilot.phoneNumber!, style: AppTextStyles.bodySmall),
                    ],
                    AppSpacing.verticalXs,
                    Text(
                      pilot.currentWorkload == null
                          ? 'Available'
                          : 'Available - ${pilot.currentWorkload} active jobs',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.success),
            ],
          ),
        ),
      ),
    );
  }
}

class _DroneCard extends StatelessWidget {
  final OpsDroneResource drone;
  final bool selected;
  final VoidCallback? onTap;

  const _DroneCard({
    required this.drone,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reason = drone.unavailableReason;

    return Semantics(
      selected: selected,
      enabled: drone.canSelect,
      label: selected ? '${drone.code} selected' : drone.code,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusMd,
        child: _SelectableContainer(
          selected: selected,
          enabled: drone.canSelect,
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: const Icon(
                  Icons.precision_manufacturing_outlined,
                  color: AppColors.info,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drone.code,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(drone.name, style: AppTextStyles.bodySmall),
                    AppSpacing.verticalXs,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _MiniPill(label: drone.operationalStatus),
                        if (drone.batteryPercentage != null)
                          _MiniPill(
                            label: '${drone.batteryPercentage}% battery',
                          ),
                        _MiniPill(
                          label: reason ?? 'Available',
                          color: reason == null
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.success),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableContainer extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final Widget child;

  const _SelectableContainer({
    required this.selected,
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.lightSurface
            : AppColors.lightSurface.withValues(alpha: 0.55),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: selected ? AppColors.success : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Opacity(opacity: enabled ? 1 : 0.62, child: child),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color? color;

  const _MiniPill({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final pillColor = color ?? AppColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pillColor.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusSm,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: pillColor),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _DialogLine extends StatelessWidget {
  final String label;
  final String value;

  const _DialogLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text('$label: $value', style: AppTextStyles.bodyMedium),
    );
  }
}

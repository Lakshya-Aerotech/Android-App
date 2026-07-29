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
  OpsPilotResource? _selectedCopilot;

  bool get _hasSamePilotAndCopilot =>
      _selectedPilot != null &&
      _selectedCopilot != null &&
      _selectedPilot!.uid == _selectedCopilot!.uid;

  @override
  Widget build(BuildContext context) {
    final pilotsAsync = ref.watch(availablePilotsStreamProvider);
    final actionState = ref.watch(operationsViewModelProvider);
    final isSubmitting = actionState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.tr('Assign Pilot')),
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
                    !_hasSamePilotAndCopilot &&
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
          _SectionTitle(title: 'Pilot Selection (Required)'),
          AppSpacing.verticalMd,
          pilotsAsync.when(
            data: (pilots) {
              if (pilots.isEmpty) {
                return EmptyState(
                  title: context.tr('No available pilots'),
                  message: context.tr('Active available pilots will appear here.'),
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
            error: (_, __) => EmptyState(
              title: context.tr('Unable to load pilots'),
              message: context.tr('Check your connection and try again.'),
              icon: Icons.wifi_off_outlined,
            ),
          ),
          AppSpacing.verticalLg,
          _SectionTitle(title: 'Copilot (Optional)'),
          AppSpacing.verticalXs,
          Text(
            'Leave empty if this booking does not require a Copilot.',
            style: AppTextStyles.bodySmall,
          ),
          AppSpacing.verticalMd,
          pilotsAsync.when(
            data: (pilots) {
              if (pilots.isEmpty) {
                return EmptyState(
                  title: context.tr('No available copilots'),
                  message: context.tr('Active available pilots will appear here.'),
                  icon: Icons.person_off_outlined,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CopilotPlaceholder(
                    selectedCopilot: _selectedCopilot,
                    onClear: _selectedCopilot == null
                        ? null
                        : () => setState(() => _selectedCopilot = null),
                  ),
                  AppSpacing.verticalMd,
                  for (final pilot in pilots) ...[
                    _PilotCard(
                      pilot: pilot,
                      selected: _selectedCopilot?.uid == pilot.uid,
                      onTap: pilot.canSelect
                          ? () => setState(() => _selectedCopilot = pilot)
                          : null,
                    ),
                    AppSpacing.verticalMd,
                  ],
                  if (_hasSamePilotAndCopilot)
                    Text(
                      'Pilot and Copilot must be different employees.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const EmptyState(
              title: 'Unable to load copilots',
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
    final copilot = _selectedCopilot;
    final docId = widget.booking.docId;
    if (pilot == null || docId == null) return;

    if (copilot != null && copilot.uid == pilot.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Pilot and Copilot must be different employees.')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Confirm Assignment')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogLine(label: context.tr('Booking'), value: widget.booking.bookingId),
            _DialogLine(label: context.tr('Pilot'), value: pilot.name),
            if (copilot != null)
              _DialogLine(label: context.tr('Copilot'), value: copilot.name),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(operationsViewModelProvider.notifier)
        .assignPilots(
          OpsAssignmentRequest(
            bookingDocId: docId,
            bookingNumber: widget.booking.bookingId,
            farmerId: widget.booking.farmerUid,
            pilot: pilot,
            copilot: copilot,
          ),
        );

    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Pilot assigned successfully')),
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
            '${booking.farmerName ?? context.tr('Farmer')} - ${context.tr(booking.serviceType)}',
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
                    AppSpacing.verticalXs,
                    Text(
                      pilot.role == 'externalPilot' ? context.tr('External Pilot') : context.tr('Internal Pilot'),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: pilot.role == 'externalPilot' ? Colors.orange : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (pilot.phoneNumber != null) ...[
                      AppSpacing.verticalXs,
                      Text(pilot.phoneNumber!, style: AppTextStyles.bodySmall),
                    ],
                    AppSpacing.verticalXs,
                    Text(
                      pilot.currentWorkload == null
                          ? context.tr('Available')
                          : '${context.tr('Available')} - ${pilot.currentWorkload} ${context.tr('active jobs')}',
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

class _CopilotPlaceholder extends StatelessWidget {
  final OpsPilotResource? selectedCopilot;
  final VoidCallback? onClear;

  const _CopilotPlaceholder({
    required this.selectedCopilot,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return _SelectableContainer(
      selected: selectedCopilot != null,
      enabled: true,
      child: Row(
        children: [
          const Icon(Icons.support_agent_outlined, color: AppColors.primary),
          AppSpacing.horizontalMd,
          Expanded(
            child: Text(
              selectedCopilot?.name ?? context.tr('Select Copilot'),
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: selectedCopilot == null
                    ? FontWeight.normal
                    : FontWeight.w600,
                color: selectedCopilot == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (onClear != null)
            TextButton(onPressed: onClear, child: Text(context.tr('Clear'))),
        ],
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr(title),
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
      child: Text('${context.tr(label)}: ${context.tr(value)}', style: AppTextStyles.bodyMedium),
    );
  }
}

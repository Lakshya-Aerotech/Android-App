import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../shared/enums/booking_status.dart';
import '../../../booking/models/booking_model.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../viewmodels/pilot_jobs_viewmodel.dart';
import '../../../operations/widgets/full_booking_timeline.dart';
import '../../../../core/widgets/confirmation_dialog.dart';

class PilotJobDetailsScreen extends ConsumerStatefulWidget {
  final BookingModel job;
  const PilotJobDetailsScreen({super.key, required this.job});

  @override
  ConsumerState<PilotJobDetailsScreen> createState() =>
      _PilotJobDetailsScreenState();
}

class _PilotJobDetailsScreenState extends ConsumerState<PilotJobDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(pilotJobDetailsProvider(widget.job.docId!));

    // Listen for completion errors
    ref.listen(pilotJobsViewModelProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: switch (jobAsync) {
        AsyncData(:final value) => _buildContent(context, value),
        AsyncError(:final error) => Center(child: Text('Error: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _navigate(BookingModel job) async {
    if (job.latitude == null || job.longitude == null) return;
    await MapsLauncher.launchCoordinates(
      job.latitude!,
      job.longitude!,
      job.farmName,
    );
  }

  void _showCompleteMissionConfirmation(BookingModel job) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Complete Mission',
        content:
            'Are you sure you want to mark this mission as completed? Total acreage of ${job.estimatedArea} Acres will be recorded.',
        confirmLabel: 'Complete Mission',
        onConfirm: () {
          ref
              .read(pilotJobsViewModelProvider.notifier)
              .completeMission(job: job);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, BookingModel job) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeaderCard(job),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Farmer & Farm'),
                _buildInfoCard(
                  items: [
                    {
                      'label': 'Farmer Name',
                      'value': job.farmerName ?? 'N/A',
                      'icon': Icons.person_outline,
                    },
                    {
                      'label': 'Farmer Phone',
                      'value': job.farmerPhone ?? 'N/A',
                      'icon': Icons.phone_android,
                    },
                    {
                      'label': 'Location',
                      'value': '${job.village}, ${job.district}',
                      'icon': Icons.location_on_outlined,
                    },
                  ],
                ),

                if (job.latitude != null && job.longitude != null) ...[
                  const SizedBox(height: 12),
                  _buildMapPreview(job.latitude!, job.longitude!),
                ],

                const SizedBox(height: 24),
                _buildSectionTitle('Drone Assignment'),
                _buildInfoCard(
                  items: [
                    {
                      'label': 'Assigned Pilot',
                      'value': job.assignedPilotName ?? 'N/A',
                      'icon': Icons.person_outline,
                    },
                    if (job.copilotName != null)
                      {
                        'label': 'Copilot',
                        'value': job.copilotName!,
                        'icon': Icons.support_agent_outlined,
                      },
                    {
                      'label': 'Drone Code',
                      'value': job.assignedDroneId ?? 'N/A',
                      'icon': Icons.precision_manufacturing_outlined,
                    },
                    {
                      'label': 'Model',
                      'value': job.assignedDroneName ?? 'N/A',
                      'icon': Icons.model_training,
                    },
                  ],
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('Service Details'),
                _buildInfoCard(
                  items: [
                    {
                      'label': 'Service Type',
                      'value': job.serviceType,
                      'icon': Icons.water_drop_outlined,
                    },
                    {
                      'label': 'Crop Type',
                      'value': job.cropType,
                      'icon': Icons.spa_outlined,
                    },
                    {
                      'label': 'Area',
                      'value': '${job.estimatedArea} Acres',
                      'icon': Icons.crop_free,
                    },
                    {
                      'label': 'Scheduled',
                      'value':
                          '${DateFormat('dd MMM').format(job.bookingDate)} at ${job.preferredTime}',
                      'icon': Icons.calendar_today_outlined,
                    },
                  ],
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('Progress'),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: FullBookingTimeline(currentStatus: job.status),
                ),

                if (job.couponCode != null) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle('Coupon Information'),
                  _buildCouponCard(job),
                ],

                const SizedBox(height: 40),
                _buildActionButtons(job),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(BookingModel job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.couponCode ?? '',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (job.couponVerified)
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                const Row(
                  children: [
                    Icon(Icons.pending, color: Colors.orange, size: 20),
                    SizedBox(width: 4),
                    Text(
                      'Pending Verification',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCouponRow('Retailer', job.retailerName ?? 'N/A'),
          _buildCouponRow(
            'Discount',
            '${job.couponDiscountValue ?? 0} ${job.couponDiscountType == 'percentage' ? '%' : 'INR'}',
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Final Amount to Collect'),
              Text(
                '₹${job.payableAmount?.toStringAsFixed(2) ?? 'N/A'}',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (!job.couponVerified && job.status == BookingStatus.arrived) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirmCouponVerification(job),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Verify Coupon'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCouponRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCouponVerification(BookingModel job) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Verify Coupon',
        content:
            'Confirm that the coupon shown in this booking matches the retailer-issued coupon.',
        confirmLabel: 'Confirm Verification',
        onConfirm: () {
          ref
              .read(pilotJobsViewModelProvider.notifier)
              .verifyCoupon(job.docId!);
        },
      ),
    );
  }

  Widget _buildActionButtons(BookingModel job) {
    final notifier = ref.read(pilotJobsViewModelProvider.notifier);
    final isLoading = ref.watch(pilotJobsViewModelProvider).isLoading;
    final user = ref.watch(userModelProvider);
    final isCopilot =
        user?.uid != null &&
        job.copilotId == user!.uid &&
        job.assignedPilotId != user.uid;

    if (isCopilot) {
      return const Center(
        child: StatusChip(
          label: 'Copilot View',
          backgroundColor: AppColors.info,
          textColor: Colors.white,
        ),
      );
    }

    switch (job.status) {
      case BookingStatus.droneAssigned:
      case BookingStatus.accepted:
      case BookingStatus.enRoute:
        return PrimaryButton(
          text: 'Arrived At Farm',
          onPressed: () => notifier.markArrived(job.docId!),
          isLoading: isLoading,
        );
      case BookingStatus.arrived:
        final needsVerification = job.couponCode != null && !job.couponVerified;
        return Column(
          children: [
            if (needsVerification)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please verify the coupon before starting the mission.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            PrimaryButton(
              text: 'Start Mission',
              icon: const Icon(Icons.play_arrow_outlined, color: Colors.white),
              onPressed:
                  needsVerification
                      ? null
                      : () => notifier.startMission(job.docId!),
              isLoading: isLoading,
            ),
          ],
        );
      case BookingStatus.inProgress:
        return PrimaryButton(
          text: 'Complete Mission',
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          onPressed: () => _showCompleteMissionConfirmation(job),
          isLoading: isLoading,
        );
      case BookingStatus.completed:
        return _buildPaymentActions(job, notifier, isLoading);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPaymentActions(
    BookingModel job,
    PilotJobsViewModel notifier,
    bool isLoading,
  ) {
    if (job.paymentMethod == null) {
      return PrimaryButton(
        text: 'Process Payment',
        icon: const Icon(Icons.payment, color: Colors.white),
        onPressed: () => context.push('/payment', extra: job),
        isLoading: isLoading,
      );
    }

    if (job.paymentMethod == 'Cash') {
      if (!job.cashCollected) {
        return PrimaryButton(
          text: 'Collect Cash',
          icon: const Icon(Icons.money, color: Colors.white),
          onPressed: () => _confirmCashCollection(job),
          isLoading: isLoading,
        );
      }

      if (!job.cashDeposited) {
        return PrimaryButton(
          text: 'Mark as Deposited',
          icon: const Icon(Icons.account_balance, color: Colors.white),
          onPressed: () => _confirmCashDeposit(job),
          isLoading: isLoading,
        );
      }

      return Center(
        child: Column(
          children: [
            StatusChip(
              label: job.paymentVerifiedByAdmin ? 'Paid' : 'Awaiting Confirmation',
              backgroundColor:
                  job.paymentVerifiedByAdmin
                      ? AppColors.success
                      : Colors.orange,
              textColor: Colors.white,
            ),
            if (job.paymentStatus == 'Deposit Rejected') ...[
              const SizedBox(height: 8),
              Text(
                'Rejected: ${job.adminRemarks ?? 'No remarks'}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _confirmCashDeposit(job),
                child: const Text('Retry Deposit'),
              ),
            ],
          ],
        ),
      );
    }

    if (job.paymentMethod == 'UPI') {
      return Center(
        child: StatusChip(
          label: job.paymentStatus ?? 'Pending Payment',
          backgroundColor: Colors.blue,
          textColor: Colors.white,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _confirmCashCollection(BookingModel job) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Collect Cash',
        content: 'Confirm that you have received the cash payment of ₹${job.payableAmount?.toStringAsFixed(2) ?? ''} from the farmer.',
        confirmLabel: 'Confirm Collection',
        onConfirm: () {
          ref.read(pilotJobsViewModelProvider.notifier).collectCash(job.docId!);
        },
      ),
    );
  }

  void _confirmCashDeposit(BookingModel job) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Deposit Cash',
        content: 'Confirm that you have deposited the collected cash of ₹${job.payableAmount?.toStringAsFixed(2) ?? ''} to the office.',
        confirmLabel: 'Confirm Deposit',
        onConfirm: () {
          ref
              .read(pilotJobsViewModelProvider.notifier)
              .markCashDeposited(job.docId!);
        },
      ),
    );
  }

  Widget _buildHeaderCard(BookingModel job) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking ID', style: AppTextStyles.bodySmall),
                Text(
                  job.bookingId,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusChip.fromStatus(job.status),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Map<String, dynamic>> items}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label'] as String,
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                        ),
                        Text(
                          item['value'] as String,
                          style: AppTextStyles.labelLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMapPreview(double lat, double lng) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
            onTap: (_, __) async {
              if (widget.job.status == BookingStatus.droneAssigned ||
                  widget.job.status == BookingStatus.accepted) {
                await ref
                    .read(pilotJobsViewModelProvider.notifier)
                    .startNavigation(widget.job.docId!);
              }
              await _navigate(widget.job);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.lakshya_aerotech.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lng),
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../shared/enums/booking_status.dart';
import '../../../booking/models/booking_model.dart';
import '../../viewmodels/pilot_jobs_viewmodel.dart';
import '../../widgets/mission_completion_dialog.dart';
import '../../../operations/widgets/full_booking_timeline.dart';

class PilotJobDetailsScreen extends ConsumerStatefulWidget {
  final BookingModel job;
  const PilotJobDetailsScreen({super.key, required this.job});

  @override
  ConsumerState<PilotJobDetailsScreen> createState() =>
      _PilotJobDetailsScreenState();
}

class _PilotJobDetailsScreenState extends ConsumerState<PilotJobDetailsScreen> {
  final TextEditingController _rejectionController = TextEditingController();

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  Future<void> _navigate(BookingModel job) async {
    if (job.latitude == null || job.longitude == null) return;
    final url = 'google.navigation:q=${job.latitude},${job.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch Google Maps navigation'),
          ),
        );
      }
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Job Assignment'),
        content: TextField(
          controller: _rejectionController,
          decoration: const InputDecoration(hintText: 'Reason for rejection...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_rejectionController.text.isNotEmpty) {
                ref
                    .read(pilotJobsViewModelProvider.notifier)
                    .rejectJob(widget.job.docId!, _rejectionController.text);
                Navigator.pop(context);
                context.pop();
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => MissionCompletionDialog(
        onConfirm: (notes, area, duration, chemical) {
          ref.read(pilotJobsViewModelProvider.notifier).completeMission(
            bookingDocId: widget.job.docId!,
            droneDocId: widget.job.assignedDroneId!, // Assumed non-null if in_progress
            notes: notes,
            areaCovered: area,
            duration: duration,
            chemical: chemical,
          );
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch real-time stream using docId as family key for stable updates
    final jobAsync = ref.watch(pilotJobDetailsProvider(widget.job.docId!));

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
                      'icon': Icons.settings_suggest_outlined,
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
                  ),
                  child: FullBookingTimeline(currentStatus: job.status),
                ),

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

  Widget _buildActionButtons(BookingModel job) {
    final notifier = ref.read(pilotJobsViewModelProvider.notifier);
    final isLoading = ref.watch(pilotJobsViewModelProvider).isLoading;

    switch (job.status) {
      case BookingStatus.droneAssigned:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : _showRejectDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(0, 56),
                ),
                child: const Text('Reject Job'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                text: 'Accept Job',
                onPressed: () => notifier.acceptJob(job.docId!),
                isLoading: isLoading,
              ),
            ),
          ],
        );
      case BookingStatus.accepted:
        return PrimaryButton(
          text: 'Start Navigation',
          icon: const Icon(Icons.navigation_outlined, color: Colors.white),
          onPressed: () async {
            await notifier.startNavigation(job.docId!);
            await _navigate(job);
          },
          isLoading: isLoading,
        );
      case BookingStatus.enRoute:
        return PrimaryButton(
          text: 'Arrived At Farm',
          onPressed: () => notifier.markArrived(job.docId!),
          isLoading: isLoading,
        );
      case BookingStatus.arrived:
        return PrimaryButton(
          text: 'Start Mission',
          icon: const Icon(Icons.play_arrow_outlined, color: Colors.white),
          onPressed: () => notifier.startMission(job.docId!),
          isLoading: isLoading,
        );
      case BookingStatus.inProgress:
        return PrimaryButton(
          text: 'Complete Mission',
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          onPressed: _showCompletionDialog,
          isLoading: isLoading,
        );
      case BookingStatus.completed:
        return const Center(
          child: StatusChip(
            label: 'Mission Completed',
            backgroundColor: AppColors.success,
            textColor: Colors.white,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
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
      ),
      child: Column(
        children:
            items
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
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                              ),
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
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(lat, lng),
            zoom: 15,
          ),
          markers: {
            Marker(markerId: const MarkerId('farm'), position: LatLng(lat, lng)),
          },
          liteModeEnabled: true,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }
}

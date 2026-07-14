import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lakshya_aerotech/core/theme/app_colors.dart';
import 'package:lakshya_aerotech/core/theme/app_text_styles.dart';
import 'package:lakshya_aerotech/core/widgets/primary_button.dart';
import 'package:lakshya_aerotech/core/widgets/status_chip.dart';
import 'package:lakshya_aerotech/features/booking/models/booking_model.dart';
import 'package:lakshya_aerotech/features/operations/viewmodels/operations_viewmodel.dart';
import 'package:lakshya_aerotech/features/operations/widgets/full_booking_timeline.dart';

class OpsBookingDetailsScreen extends ConsumerStatefulWidget {
  final BookingModel booking;
  const OpsBookingDetailsScreen({super.key, required this.booking});

  @override
  ConsumerState<OpsBookingDetailsScreen> createState() => _OpsBookingDetailsScreenState();
}

class _OpsBookingDetailsScreenState extends ConsumerState<OpsBookingDetailsScreen> {
  final TextEditingController _remarksController = TextEditingController();

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleAction(String action) async {
    final viewModel = ref.read(operationsViewModelProvider.notifier);
    final remark = _remarksController.text.trim();

    if (action == 'reject' && remark.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for rejection in remarks.')),
      );
      return;
    }

    switch (action) {
      case 'approve':
        await viewModel.approveBooking(widget.booking.docId!, remarkMessage: remark);
        break;
      case 'reject':
        await viewModel.rejectBooking(widget.booking.docId!, remark);
        break;
      case 'request_changes':
        await viewModel.requestChanges(widget.booking.docId!, remark);
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking updated: $action'), backgroundColor: AppColors.success),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isLoading = ref.watch(operationsViewModelProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Review Booking'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderCard(booking),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Farmer & Farm Info'),
                  _buildInfoCard(
                    items: [
                      {'label': 'Farmer Name', 'value': booking.farmerName ?? 'N/A', 'icon': Icons.person_outline},
                      {'label': 'Village', 'value': booking.village ?? 'N/A', 'icon': Icons.home_work_outlined},
                      {'label': 'District', 'value': booking.district ?? 'N/A', 'icon': Icons.location_city_outlined},
                    ],
                  ),
                  
                  if (booking.latitude != null && booking.longitude != null) ...[
                    const SizedBox(height: 16),
                    _buildMapPreview(booking.latitude!, booking.longitude!),
                  ],

                  const SizedBox(height: 24),
                  _buildSectionTitle('Service Details'),
                  _buildInfoCard(
                    items: [
                      {'label': 'Service Type', 'value': booking.serviceType, 'icon': Icons.settings_suggest_outlined},
                      {'label': 'Crop Type', 'value': booking.cropType, 'icon': Icons.spa_outlined},
                      {'label': 'Area', 'value': '${booking.estimatedArea} Acres', 'icon': Icons.crop_free},
                      {'label': 'Preferred Date', 'value': DateFormat('EEEE, dd MMM yyyy').format(booking.bookingDate), 'icon': Icons.calendar_today_outlined},
                      {'label': 'Preferred Time', 'value': booking.preferredTime, 'icon': Icons.access_time_outlined},
                    ],
                  ),

                  if (booking.remarks != null) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Farmer Notes'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Text(booking.remarks!, style: AppTextStyles.bodyMedium),
                    ),
                  ],

                  const SizedBox(height: 24),
                  _buildSectionTitle('Booking Timeline'),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: FullBookingTimeline(currentStatus: booking.status),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Review Remarks'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: TextField(
                      controller: _remarksController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add internal remarks or reasons for changes/rejection...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : () => _handleAction('reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          text: 'Approve',
                          onPressed: () => _handleAction('approve'),
                          isLoading: isLoading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: isLoading ? null : () => _handleAction('request_changes'),
                      child: const Text('Request Changes'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking ID', style: AppTextStyles.bodySmall),
              Text(
                booking.bookingId,
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ],
          ),
          StatusChip.fromStatus(booking.status),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildInfoCard({required List<Map<String, dynamic>> items}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Icon(item['icon'] as IconData, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['label'] as String, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                  Text(item['value'] as String, style: AppTextStyles.labelLarge),
                ],
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMapPreview(double lat, double lng) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 15),
          markers: {Marker(markerId: const MarkerId('farm'), position: LatLng(lat, lng))},
          liteModeEnabled: true,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }
}

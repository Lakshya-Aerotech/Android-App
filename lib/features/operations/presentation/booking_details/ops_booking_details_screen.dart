import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:lakshya_aerotech/core/theme/app_colors.dart';
import 'package:lakshya_aerotech/core/theme/app_text_styles.dart';
import 'package:lakshya_aerotech/core/widgets/primary_button.dart';
import 'package:lakshya_aerotech/core/widgets/status_chip.dart';
import 'package:lakshya_aerotech/features/booking/models/booking_model.dart';
import 'package:lakshya_aerotech/features/operations/models/operations_models.dart';
import 'package:lakshya_aerotech/features/operations/viewmodels/operations_viewmodel.dart';
import 'package:lakshya_aerotech/features/operations/widgets/full_booking_timeline.dart';
import 'package:lakshya_aerotech/shared/enums/booking_status.dart';

class OpsBookingDetailsScreen extends ConsumerStatefulWidget {
  final BookingModel booking;
  const OpsBookingDetailsScreen({super.key, required this.booking});

  @override
  ConsumerState<OpsBookingDetailsScreen> createState() => _OpsBookingDetailsScreenState();
}

class _OpsBookingDetailsScreenState extends ConsumerState<OpsBookingDetailsScreen> {
  final TextEditingController _remarksController = TextEditingController();
  
  OpsPilotResource? _selectedPilot;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleReviewAction(String action) async {
    final viewModel = ref.read(operationsViewModelProvider.notifier);
    final remark = _remarksController.text.trim();

    if (action == 'reject' && remark.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for rejection in remarks.')),
      );
      return;
    }

    if (action == 'approve') {
      await viewModel.approveBooking(widget.booking.docId!, remarkMessage: remark.isEmpty ? null : remark);
    } else {
      await viewModel.rejectBooking(widget.booking.docId!, remark);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking ${action == 'approve' ? 'approved' : 'rejected'} successfully'), 
          backgroundColor: action == 'approve' ? AppColors.success : Colors.red,
        ),
      );
      
      if (action == 'approve') {
        // Navigate to dedicated assignment page
        context.pushReplacement('/operations/assignments/assign', extra: widget.booking);
      } else {
        context.pop();
      }
    }
  }

  Future<void> _assignPilot() async {
    if (_selectedPilot == null) return;

    final confirmed = await _showConfirmDialog(
      title: 'Confirm Pilot Assignment',
      items: {
        'Booking ID': widget.booking.bookingId,
        'Pilot Name': _selectedPilot!.name,
        'Farm': widget.booking.farmName,
        'Date': DateFormat('dd MMM yyyy').format(widget.booking.bookingDate),
      },
    );

    if (confirmed) {
      await ref.read(operationsViewModelProvider.notifier).assignPilot(
        widget.booking.docId!,
        _selectedPilot!.uid,
        _selectedPilot!.name,
      );
      if (mounted) context.pop();
    }
  }

  Future<bool> _showConfirmDialog({required String title, required Map<String, String> items}) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                children: [
                  TextSpan(text: '${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: e.value),
                ],
              ),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final hydratedBookingAsync = ref.watch(hydratedBookingProvider(widget.booking));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: hydratedBookingAsync.when(
        data: (booking) => _buildContent(context, booking),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading details: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BookingModel booking) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeaderCard(booking),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Farmer Information'),
                _buildInfoCard(
                  items: [
                    {'label': 'Farmer Name', 'value': booking.farmerName ?? 'N/A', 'icon': Icons.person_outline},
                    {'label': 'Phone Number', 'value': booking.farmerPhone ?? 'N/A', 'icon': Icons.phone_android_outlined},
                  ],
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('Farm Information'),
                _buildInfoCard(
                  items: [
                    {'label': 'Farm Name', 'value': booking.farmName, 'icon': Icons.landscape_outlined},
                    {'label': 'Village', 'value': booking.village ?? 'N/A', 'icon': Icons.home_work_outlined},
                    {'label': 'Area', 'value': '${booking.estimatedArea} Acres', 'icon': Icons.crop_free},
                  ],
                ),
                
                if (booking.latitude != null && booking.longitude != null) ...[
                  const SizedBox(height: 12),
                  _buildMapPreview(booking.latitude!, booking.longitude!),
                ],

                const SizedBox(height: 24),
                _buildSectionTitle('Service Requested'),
                _buildInfoCard(
                  items: [
                    {'label': 'Service Type', 'value': booking.serviceType, 'icon': Icons.settings_suggest_outlined},
                    {'label': 'Preferred Date', 'value': DateFormat('EEEE, dd MMM yyyy').format(booking.bookingDate), 'icon': Icons.calendar_today_outlined},
                    {'label': 'Preferred Time', 'value': booking.preferredTime, 'icon': Icons.access_time_outlined},
                  ],
                ),

                if (booking.assignedPilotId != null) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle('Assigned Pilot'),
                  _buildInfoCard(
                    items: [
                      if (booking.assignedPilotName != null)
                        {'label': 'Pilot', 'value': booking.assignedPilotName!, 'icon': Icons.person_add_alt_1_outlined},
                    ],
                  ),
                ],

                if (booking.hasCoupon) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle('Coupon & Verification'),
                  _buildInfoCard(
                    items: [
                      {'label': 'Coupon Code', 'value': booking.couponCode!, 'icon': Icons.local_offer_outlined},
                      {'label': 'Retailer', 'value': booking.retailerName ?? 'N/A', 'icon': Icons.storefront_outlined},
                      {'label': 'Verification Status', 'value': booking.couponVerificationStatus ?? 'Pending Verification', 'icon': Icons.verified_user_outlined},
                      if (booking.couponVerified) ...[
                        {'label': 'Verified By', 'value': booking.couponVerifiedBy ?? 'N/A', 'icon': Icons.person_outline},
                        {'label': 'Verified At', 'value': booking.couponVerifiedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(booking.couponVerifiedAt!) : 'N/A', 'icon': Icons.access_time},
                      ],
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                _buildSectionTitle('Booking Timeline'),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: FullBookingTimeline(currentStatus: booking.status),
                ),

                if (booking.status == BookingStatus.issueReported) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle('Reported Issue'),
                  _buildInfoCard(
                    items: [
                      {'label': 'Category', 'value': booking.issueCategory ?? 'N/A', 'icon': Icons.category_outlined},
                      {'label': 'Description', 'value': booking.issueDescription ?? 'N/A', 'icon': Icons.description_outlined},
                      {'label': 'Reported At', 'value': booking.issueReportedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(booking.issueReportedAt!) : 'N/A', 'icon': Icons.access_time},
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                _buildActionSection(booking),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BookingModel booking) {
    final isLoading = ref.watch(operationsViewModelProvider).isLoading;

    switch (booking.status) {
      case BookingStatus.pending:
        return _buildReviewActions(isLoading);
      case BookingStatus.reviewed:
        return _buildPilotAssignment(isLoading);
      case BookingStatus.pilotAssigned:
        return const Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 48),
              SizedBox(height: 8),
              Text('Assignment Complete', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
              Text('Awaiting Pilot Acceptance', style: TextStyle(fontSize: 12)),
            ],
          ),
        );
      case BookingStatus.cancelled:
        return const Center(child: Text('This booking is cancelled.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
      default:
        return const Center(child: Text('Operational flow in progress.'));
    }
  }

  Widget _buildReviewActions(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Review Remarks'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: TextField(
            controller: _remarksController,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Add internal remarks...', border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : () => _handleReviewAction('reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red, 
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Reject Job', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                text: 'Approve Job',
                onPressed: () => _handleReviewAction('approve'), 
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPilotAssignment(bool isLoading) {
    final pilotsAsync = ref.watch(availablePilotsStreamProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Assign Pilot'),
        pilotsAsync.when(
          data: (pilots) => _buildDropdown<OpsPilotResource>(
            value: _selectedPilot,
            items: pilots,
            hint: 'Select available pilot',
            onChanged: (v) => setState(() => _selectedPilot = v),
            labelBuilder: (p) => p.name,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading pilots: $e'),
        ),
        const SizedBox(height: 16),
        PrimaryButton(text: 'Assign Pilot', onPressed: _selectedPilot != null ? _assignPilot : null, isLoading: isLoading),
      ],
    );
  }

  Widget _buildDropdown<T>({required T? value, required List<T> items, required String hint, required void Function(T?) onChanged, required String Function(T) labelBuilder}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          onChanged: onChanged,
          items: items.map((T item) => DropdownMenuItem<T>(value: item, child: Text(labelBuilder(item)))).toList(),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking ID', style: AppTextStyles.bodySmall),
                Text(booking.bookingId, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: StatusChip.fromStatus(booking.status)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark)));
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['label'] as String, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                    Text(item['value'] as String, style: AppTextStyles.labelLarge),
                  ],
                ),
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
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
            onTap: (_, __) => MapsLauncher.launchCoordinates(
              lat,
              lng,
              widget.booking.farmName,
            ),
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

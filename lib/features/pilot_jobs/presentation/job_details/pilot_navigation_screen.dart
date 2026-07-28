import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../booking/models/booking_model.dart';
import '../../models/tracking_models.dart';
import '../../viewmodels/pilot_jobs_viewmodel.dart';
import '../../viewmodels/pilot_tracking_viewmodel.dart';

class PilotNavigationScreen extends ConsumerStatefulWidget {
  final BookingModel job;
  const PilotNavigationScreen({super.key, required this.job});

  @override
  ConsumerState<PilotNavigationScreen> createState() => _PilotNavigationScreenState();
}

class _PilotNavigationScreenState extends ConsumerState<PilotNavigationScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(pilotTrackingViewModelProvider(
      PilotTrackingParams(
        docId: widget.job.docId!,
        farmLocation: LatLng(widget.job.latitude!, widget.job.longitude!),
      ),
    ));
    final jobState = ref.watch(pilotJobDetailsProvider(widget.job.docId!));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Stop tracking when leaving the screen if not en route anymore?
            // Actually, keep it running if status is still enRoute/arrived
            context.pop();
          },
        ),
      ),
      body: jobState.when(
        data: (job) => _buildContent(context, job, trackingState),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BookingModel job, TrackingState tracking) {
    final pilotPos = job.liveLocation != null 
        ? LatLng(job.liveLocation!.latitude, job.liveLocation!.longitude)
        : null;
    final farmPos = LatLng(job.latitude!, job.longitude!);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: pilotPos ?? farmPos,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.lakshya_aerotech.app',
            ),
            if (tracking.routePolyline.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: tracking.routePolyline,
                    color: AppColors.primary,
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: farmPos,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
                if (pilotPos != null)
                  Marker(
                    point: pilotPos,
                    width: 40,
                    height: 40,
                    child: Transform.rotate(
                      angle: (job.liveLocation?.heading ?? 0) * (3.14159 / 180),
                      child: const Icon(Icons.navigation, color: AppColors.primary, size: 30),
                    ),
                  ),
              ],
            ),
          ],
        ),
        
        // Navigation Stats Overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.farmName, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                          Text(job.village ?? '', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'En Route',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Distance', '${(tracking.distanceRemaining / 1000).toStringAsFixed(1)} km'),
                    _buildStatItem('ETA', '${tracking.etaMinutes.toStringAsFixed(0)} mins'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Arrived Button
        Positioned(
          bottom: 32,
          left: 32,
          right: 32,
          child: PrimaryButton(
            text: 'Arrived at Farm',
            onPressed: () {
              ref.read(pilotJobsViewModelProvider.notifier).markArrived(job.docId!);
              context.pop(); // Go back to details
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/booking/models/booking_model.dart';
import '../../features/pilot_jobs/viewmodels/pilot_tracking_viewmodel.dart';

class LiveTrackingMap extends ConsumerWidget {
  final BookingModel booking;
  final double height;

  const LiveTrackingMap({
    super.key,
    required this.booking,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (booking.latitude == null || booking.longitude == null) {
      return const SizedBox.shrink();
    }

    final trackingState = ref.watch(pilotTrackingViewModelProvider(
      PilotTrackingParams(
        docId: booking.docId!,
        farmLocation: LatLng(booking.latitude!, booking.longitude!),
      ),
    ));
    final farmPos = LatLng(booking.latitude!, booking.longitude!);
    final pilotPos = booking.liveLocation != null
        ? LatLng(booking.liveLocation!.latitude, booking.liveLocation!.longitude)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: pilotPos ?? farmPos,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.lakshya_aerotech.app',
                ),
                if (trackingState.routePolyline.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: trackingState.routePolyline,
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
                          angle: (booking.liveLocation?.heading ?? 0) * (3.14159 / 180),
                          child: const Icon(Icons.navigation, color: AppColors.primary, size: 30),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (booking.liveLocation != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Distance', '${(trackingState.distanceRemaining / 1000).toStringAsFixed(1)} km'),
              _buildStatItem('ETA', '${trackingState.etaMinutes.toStringAsFixed(0)} mins'),
            ],
          ),
        ],
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

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/osrm_service.dart';
import '../models/tracking_models.dart';
import 'pilot_jobs_viewmodel.dart';

class PilotTrackingViewModel extends StateNotifier<TrackingState> {
  final OsrmService _osrmService;
  final String _bookingDocId;
  final LatLng _farmLocation;
  final Ref _ref;
  
  Timer? _routeRefreshTimer;
  LatLng? _lastCalculatedLocation;

  PilotTrackingViewModel(this._ref, this._osrmService, this._bookingDocId, this._farmLocation) 
    : super(TrackingState(isLoading: true)) {
    _init();
  }

  void _init() {
    // Watch the live location of the booking
    _ref.listen(pilotJobDetailsProvider(_bookingDocId), (previous, next) {
      next.whenData((booking) {
        if (booking.liveLocation != null) {
          final currentPos = LatLng(booking.liveLocation!.latitude, booking.liveLocation!.longitude);
          _handleLocationUpdate(currentPos);
        }
      });
    });
  }

  Future<void> _handleLocationUpdate(LatLng currentPos) async {
    // Only recalculate if moved significantly or first time
    if (_lastCalculatedLocation == null || 
        _getDistance(_lastCalculatedLocation!, currentPos) > 50) {
      _calculateRoute(currentPos);
    }
  }

  double _getDistance(LatLng p1, LatLng p2) {
    // Simple distance calculation (or use geolocator)
    return const Distance().as(LengthUnit.Meter, p1, p2);
  }

  Future<void> _calculateRoute(LatLng currentPos) async {
    _lastCalculatedLocation = currentPos;
    
    final route = await _osrmService.getRoute(currentPos, _farmLocation);
    if (route != null && mounted) {
      state = state.copyWith(
        routePolyline: route.polyline,
        distanceRemaining: route.distance,
        etaMinutes: route.duration / 60,
        isLoading: false,
      );
    }
  }

  @override
  void dispose() {
    _routeRefreshTimer?.cancel();
    super.dispose();
  }
}

class PilotTrackingParams {
  final String docId;
  final LatLng farmLocation;

  PilotTrackingParams({required this.docId, required this.farmLocation});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PilotTrackingParams &&
          runtimeType == other.runtimeType &&
          docId == other.docId;

  @override
  int get hashCode => docId.hashCode;
}

final pilotTrackingViewModelProvider = StateNotifierProvider.family<PilotTrackingViewModel, TrackingState, PilotTrackingParams>((ref, params) {
  final osrm = ref.read(osrmServiceProvider);
  return PilotTrackingViewModel(ref, osrm, params.docId, params.farmLocation);
});

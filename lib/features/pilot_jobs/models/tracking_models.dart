import 'package:latlong2/latlong.dart';

class TrackingState {
  final List<LatLng> routePolyline;
  final double distanceRemaining; // meters
  final double etaMinutes; // minutes
  final bool isLoading;
  final String? error;

  TrackingState({
    this.routePolyline = const [],
    this.distanceRemaining = 0,
    this.etaMinutes = 0,
    this.isLoading = false,
    this.error,
  });

  TrackingState copyWith({
    List<LatLng>? routePolyline,
    double? distanceRemaining,
    double? etaMinutes,
    bool? isLoading,
    String? error,
  }) {
    return TrackingState(
      routePolyline: routePolyline ?? this.routePolyline,
      distanceRemaining: distanceRemaining ?? this.distanceRemaining,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

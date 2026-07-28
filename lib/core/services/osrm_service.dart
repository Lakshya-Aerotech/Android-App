import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class OsrmRoute {
  final List<LatLng> polyline;
  final double distance; // meters
  final double duration; // seconds

  OsrmRoute({
    required this.polyline,
    required this.distance,
    required this.duration,
  });
}

class OsrmService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  Future<OsrmRoute?> getRoute(LatLng start, LatLng end) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          final List<LatLng> points = geometry
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();

          return OsrmRoute(
            polyline: points,
            distance: (route['distance'] as num).toDouble(),
            duration: (route['duration'] as num).toDouble(),
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

final osrmServiceProvider = Provider((ref) => OsrmService());

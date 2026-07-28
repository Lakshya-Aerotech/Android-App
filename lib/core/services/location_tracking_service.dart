import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationTrackingService {
  StreamSubscription<Position>? _positionSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void startTracking(String bookingDocId) {
    stopTracking(); // Ensure any existing tracking is stopped

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25, // 25 meters as per requirement range 20-30
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _updateFirestore(bookingDocId, position);
      },
      onError: (error) {
        // Handle error if necessary
      },
    );
  }

  Future<void> _updateFirestore(String bookingDocId, Position position) async {
    try {
      await _firestore.collection('bookings').doc(bookingDocId).update({
        'liveLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'speed': position.speed,
          'heading': position.heading,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle error
    }
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}

final locationTrackingServiceProvider = Provider((ref) => LocationTrackingService());

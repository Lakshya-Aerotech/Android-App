import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drone_model.dart';

abstract class DroneRepository {
  Stream<List<DroneModel>> getDronesStream();
  Future<void> populateSampleDrones();
}

final droneRepositoryProvider = Provider<DroneRepository>((ref) {
  return DroneRepositoryImpl();
});

class DroneRepositoryImpl implements DroneRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<DroneModel>> getDronesStream() {
    return _firestore
        .collection('drones')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DroneModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> populateSampleDrones() async {
    try {
      final snapshot = await _firestore.collection('drones').limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      debugPrint('Populating sample drones collection...');
      final List<DroneModel> samples = [
        DroneModel(
          droneId: 'DR-001',
          model: 'DJI Agras T40',
          capacity: 40,
          batteryPercentage: 100,
          status: DroneStatus.available,
          currentLocation: 'Warangal',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        DroneModel(
          droneId: 'DR-002',
          model: 'DJI Agras T30',
          capacity: 30,
          batteryPercentage: 95,
          status: DroneStatus.available,
          currentLocation: 'Hanamkonda',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        DroneModel(
          droneId: 'DR-003',
          model: 'DJI Agras T20',
          capacity: 20,
          batteryPercentage: 60,
          status: DroneStatus.maintenance,
          currentLocation: 'Karimnagar',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        DroneModel(
          droneId: 'DR-004',
          model: 'DJI Agras T50',
          capacity: 50,
          batteryPercentage: 100,
          status: DroneStatus.available,
          currentLocation: 'Warangal',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        DroneModel(
          droneId: 'DR-005',
          model: 'DJI Agras MG-1P',
          capacity: 10,
          batteryPercentage: 80,
          status: DroneStatus.busy,
          currentLocation: 'Hyderabad',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final batch = _firestore.batch();
      for (var drone in samples) {
        final docRef = _firestore.collection('drones').doc();
        final data = drone.toMap();
        // Add extra fields for compatibility with OpsDroneResource
        data['isAvailable'] = drone.status == DroneStatus.available;
        data['operationalStatus'] = drone.status.name;
        data['droneCode'] = drone.droneId;
        data['droneName'] = drone.model;
        batch.set(docRef, data);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error populating drones: $e');
    }
  }
}

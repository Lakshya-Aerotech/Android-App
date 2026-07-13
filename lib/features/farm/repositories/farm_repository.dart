import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farm_model.dart';

abstract class FarmRepository {
  Stream<List<FarmModel>> getFarmsStream(String farmerUid);
  Future<void> addFarm(FarmModel farm);
  Future<void> updateFarm(FarmModel farm);
  Future<void> softDeleteFarm(String docId);
}

class FarmRepositoryImpl implements FarmRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<FarmModel>> getFarmsStream(String farmerUid) {
    // REQUIRED COMPOSITE INDEX:
    // Collection: farms
    // Fields: farmerUid (Ascending), isActive (Ascending), createdAt (Descending)
    return _firestore
        .collection('farms')
        .where('farmerUid', isEqualTo: farmerUid)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FarmModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> addFarm(FarmModel farm) async {
    await _firestore.collection('farms').add(farm.toMap());
  }

  @override
  Future<void> updateFarm(FarmModel farm) async {
    if (farm.docId == null) return;
    await _firestore
        .collection('farms')
        .doc(farm.docId)
        .update(farm.toMap()..['updatedAt'] = FieldValue.serverTimestamp());
  }

  @override
  Future<void> softDeleteFarm(String docId) async {
    await _firestore.collection('farms').doc(docId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

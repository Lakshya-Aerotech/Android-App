import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/notifications/notification_repository.dart';
import '../../../shared/models/activity_model.dart';
import '../../../shared/repositories/activity_repository.dart';
import '../../auth/models/user_model.dart';

abstract class RetailerRepository {
  Stream<List<UserModel>> getRetailerFarmersStream(String retailerUid);
  Future<UserModel> createFarmerForRetailer({
    required String retailerUid,
    required String name,
    required String mobileNumber,
    required String village,
    required String district,
    required String stateName,
    String? email,
  });
  Future<void> updateFarmer(UserModel farmer);
}

class RetailerRepositoryImpl implements RetailerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notifications = NotificationRepository();

  @override
  Stream<List<UserModel>> getRetailerFarmersStream(String retailerUid) {
    return _firestore
        .collection('users')
        .where('createdBy', isEqualTo: retailerUid)
        .snapshots()
        .map((snapshot) {
          final farmers = snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), docId: doc.id))
              .where((farmer) => farmer.role == UserRole.farmer)
              .toList();
          farmers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return farmers;
        });
  }

  @override
  Future<UserModel> createFarmerForRetailer({
    required String retailerUid,
    required String name,
    required String mobileNumber,
    required String village,
    required String district,
    required String stateName,
    String? email,
  }) async {
    final docRef = _firestore.collection('users').doc();
    final now = DateTime.now();
    final farmer = UserModel(
      docId: docRef.id,
      uid: docRef.id,
      phoneNumber: mobileNumber,
      email: email,
      role: UserRole.farmer,
      profileCompleted: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      name: name,
      village: village,
      district: district,
      state: stateName,
      createdBy: retailerUid,
      createdByRetailerId: retailerUid,
      createdByRole: UserRole.retailer.value,
    );

    await docRef.set(farmer.toMap());
    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.farmerRegistered,
        description: 'Retailer registered farmer: $name',
        userId: farmer.uid,
        userName: name,
        timestamp: now,
        metadata: {'createdByRetailerId': retailerUid},
      ),
    );
    await _notifications.createForUser(
      recipientUid: retailerUid,
      eventKey: 'retailer-farmer-created-${docRef.id}',
      title: 'Farmer registered',
      message: '$name has been added to your farmer list.',
      data: {'farmerUid': docRef.id},
      type: 'REGISTRATION_SUBMITTED',
    );
    return farmer;
  }

  @override
  Future<void> updateFarmer(UserModel farmer) async {
    if (farmer.docId == null) return;
    await _firestore.collection('users').doc(farmer.docId).update({
      'name': farmer.name,
      'phoneNumber': farmer.phoneNumber,
      'email': farmer.email,
      'village': farmer.village,
      'district': farmer.district,
      'state': farmer.state,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

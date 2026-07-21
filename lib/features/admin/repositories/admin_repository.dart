import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/notifications/notification_repository.dart';
import '../../../shared/models/activity_model.dart';
import '../../../shared/repositories/activity_repository.dart';
import '../../auth/models/user_model.dart';
import '../models/coupon_model.dart';

abstract class AdminRepository {
  Stream<List<UserModel>> getEmployeesStream();
  Stream<List<UserModel>> getRetailersStream();
  Future<void> createEmployee(UserModel employee);
  Future<bool> checkIfEmailExists(String email, {String? excludingDocId});
  Future<void> updateEmployee({
    required String docId,
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String language,
    required bool isActive,
  });
  Future<void> updateEmployeeStatus(String docId, bool isActive);
  Future<void> updateRetailerStatus({
    required String docId,
    required ApprovalStatus approvalStatus,
    required bool isActive,
  });
  Future<void> deleteEmployee(String docId);
  Stream<Map<String, dynamic>> getDashboardStats();
  Stream<List<CouponModel>> getCouponsStream();
  Future<bool> checkIfCouponCodeExists(String code, {String? excludingDocId});
  Future<void> createCoupon(CouponModel coupon);
  Future<void> updateCoupon(CouponModel coupon);
  Future<void> deleteCoupon(String docId);
  Future<void> updateCouponStatus(String docId, bool isActive);

  // External Pilot Management
  Stream<List<UserModel>> getExternalPilotsStream();
  Future<void> updateExternalPilotApproval({
    required String docId,
    required ApprovalStatus status,
    String? rejectionReason,
  });
  Future<void> updateExternalPilotAccountStatus({
    required String docId,
    required AccountStatus status,
  });
}

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notifications = NotificationRepository();

  @override
  Stream<List<UserModel>> getEmployeesStream() {
    return _firestore
        .collection('users')
        .where(
          'role',
          whereIn: [
            'pilot',
            'operations',
            'admin',
            'externalPilot',
            'retailer',
          ],
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  @override
  Stream<List<UserModel>> getRetailersStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.retailer.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  @override
  Future<void> createEmployee(UserModel employee) async {
    final docRef = await _firestore.collection('users').add(employee.toMap());

    // Log Activity
    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.employeeCreated,
        description:
            'New employee created: ${employee.name} (${employee.role.name})',
        userId: docRef.id,
        userName: employee.name,
        timestamp: DateTime.now(),
      ),
    );

    await _notifications.createForRole(
      role: UserRole.admin,
      eventKey: 'employee-added-${docRef.id}',
      title: 'New employee added',
      message:
          '${employee.name ?? 'An employee'} was added as ${employee.role.name}.',
      employeeId: docRef.id,
    );
  }

  @override
  Future<bool> checkIfEmailExists(
    String email, {
    String? excludingDocId,
  }) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(2)
        .get();
    return query.docs.any((doc) => doc.id != excludingDocId);
  }

  @override
  Future<void> updateEmployee({
    required String docId,
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String language,
    required bool isActive,
  }) async {
    final docRef = _firestore.collection('users').doc(docId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception(
        'Employee record was not found. It may have been deleted.',
      );
    }

    await docRef.update({
      'name': name,
      'email': email,
      'phoneNumber': phone,
      'role': role.name,
      'preferredLanguage': language,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateEmployeeStatus(String docId, bool isActive) async {
    final docRef = _firestore.collection('users').doc(docId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception(
        'Employee record was not found. It may have been deleted.',
      );
    }

    final wasActive = UserModel.fromMap(doc.data()!, docId: doc.id).isActive;

    await docRef.update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (wasActive && !isActive) {
      final employee = UserModel.fromMap(doc.data()!, docId: doc.id);
      await _notifications.createForRole(
        role: UserRole.admin,
        eventKey: 'employee-deactivated-$docId',
        title: 'Employee deactivated',
        message: '${employee.name ?? 'An employee'} was deactivated.',
        employeeId: docId,
      );
    }
  }

  @override
  Future<void> updateRetailerStatus({
    required String docId,
    required ApprovalStatus approvalStatus,
    required bool isActive,
  }) async {
    final docRef = _firestore.collection('users').doc(docId);
    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Retailer record was not found.');
    }

    await docRef.update({
      'approvalStatus': approvalStatus.name,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final retailer = UserModel.fromMap(doc.data()!, docId: doc.id);
    final title = switch (approvalStatus) {
      ApprovalStatus.approved => 'Account approved',
      ApprovalStatus.rejected => 'Account rejected',
      ApprovalStatus.suspended => 'Account suspended',
      ApprovalStatus.pending => 'Account pending',
    };
    await _notifications.createForUser(
      recipientUid: retailer.uid ?? docId,
      eventKey: 'retailer-${approvalStatus.name}-$docId',
      title: title,
      message: 'Your retailer account status is now ${approvalStatus.name}.',
      data: {'retailerUid': retailer.uid ?? docId},
    );
  }

  @override
  Future<void> deleteEmployee(String docId) async {
    await _firestore.collection('users').doc(docId).delete();
  }

  @override
  Stream<List<CouponModel>> getCouponsStream() {
    return _firestore
        .collection('coupons')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CouponModel.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  @override
  Future<bool> checkIfCouponCodeExists(
    String code, {
    String? excludingDocId,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    final query = await _firestore
        .collection('coupons')
        .where('couponCodeNormalized', isEqualTo: normalizedCode)
        .limit(2)
        .get();
    return query.docs.any((doc) => doc.id != excludingDocId);
  }

  @override
  Future<void> createCoupon(CouponModel coupon) async {
    await _firestore.collection('coupons').add(coupon.toMap());
  }

  @override
  Future<void> updateCoupon(CouponModel coupon) async {
    final docId = coupon.docId;
    if (docId == null || docId.isEmpty) {
      throw Exception('Coupon record was not found.');
    }

    await _firestore
        .collection('coupons')
        .doc(docId)
        .update(coupon.toMap(includeCreatedAt: false));
  }

  @override
  Future<void> deleteCoupon(String docId) async {
    await _firestore.collection('coupons').doc(docId).delete();
  }

  @override
  Future<void> updateCouponStatus(String docId, bool isActive) async {
    await _firestore.collection('coupons').doc(docId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<Map<String, dynamic>> getDashboardStats() {
    // Note: In a large production app, these would be aggregated using Cloud Functions
    // or by listening to a dedicated metadata document.
    // For now, we use real-time listeners on filtered collections.

    final employeesStream = _firestore
        .collection('users')
        .where('role', whereIn: ['pilot', 'operations', 'admin'])
        .snapshots();
    final farmersStream = _firestore
        .collection('users')
        .where('role', isEqualTo: 'farmer')
        .snapshots();
    final retailersStream = _firestore
        .collection('users')
        .where('role', isEqualTo: 'retailer')
        .snapshots();
    final bookingsStream = _firestore.collection('bookings').snapshots();
    final dronesStream = _firestore.collection('drones').snapshots();

    return Stream.multi((controller) {
      int totalEmployees = 0;
      int totalFarmers = 0;
      int totalBookings = 0;
      int totalRetailers = 0;
      int completedMissions = 0;
      int pendingBookings = 0;
      int activePilots = 0;
      int activeDrones = 0;

      void emit() {
        if (!controller.isClosed) {
          controller.add({
            'totalEmployees': totalEmployees,
            'totalFarmers': totalFarmers,
            'totalBookings': totalBookings,
            'totalRetailers': totalRetailers,
            'completedMissions': completedMissions,
            'pendingBookings': pendingBookings,
            'activePilots': activePilots,
            'activeDrones': activeDrones,
          });
        }
      }

      final employeesSub = employeesStream.listen((snapshot) {
        totalEmployees = snapshot.docs.length;
        activePilots = snapshot.docs
            .where(
              (doc) =>
                  (doc.data()['role'] == 'pilot' ||
                      doc.data()['role'] == 'externalPilot') &&
                  doc.data()['isActive'] == true,
            )
            .length;
        emit();
      });

      final farmersSub = farmersStream.listen((snapshot) {
        totalFarmers = snapshot.docs.length;
        emit();
      });

      final bookingsSub = bookingsStream.listen((snapshot) {
        totalBookings = snapshot.docs.length;
        completedMissions = snapshot.docs.where((doc) {
          final status = doc.data()['status'];
          return status == 'completed' ||
              status == 'farmerConfirmed' ||
              status == 'closed';
        }).length;
        pendingBookings = snapshot.docs
            .where((doc) => doc.data()['status'] == 'pending')
            .length;
        emit();
      });

      final retailersSub = retailersStream.listen((snapshot) {
        totalRetailers = snapshot.docs.length;
        emit();
      });

      final dronesSub = dronesStream.listen((snapshot) {
        activeDrones = snapshot.docs
            .where((doc) => doc.data()['isActive'] == true)
            .length;
        emit();
      });

      controller.onCancel = () {
        employeesSub.cancel();
        farmersSub.cancel();
        bookingsSub.cancel();
        retailersSub.cancel();
        dronesSub.cancel();
      };
    });
  }

  @override
  Stream<List<UserModel>> getExternalPilotsStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.externalPilot.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  @override
  Future<void> updateExternalPilotApproval({
    required String docId,
    required ApprovalStatus status,
    String? rejectionReason,
  }) async {
    final updates = <String, dynamic>{
      'approvalStatus': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == ApprovalStatus.approved) {
      updates['accountStatus'] = AccountStatus.active.name;
      updates['isActive'] = true;
    } else if (status == ApprovalStatus.rejected) {
      updates['rejectionReason'] = rejectionReason;
      updates['accountStatus'] = AccountStatus.inactive.name;
      updates['isActive'] = false;
    }

    await _firestore.collection('users').doc(docId).update(updates);

    // Notify user
    await _notifications.createForUser(
      recipientUid: docId,
      eventKey: 'external-pilot-approval-$status-$docId',
      title: 'Account ${status.name}',
      message: status == ApprovalStatus.approved
          ? 'Your account has been approved. You can now login.'
          : 'Your registration has been rejected. Reason: $rejectionReason',
    );
  }

  @override
  Future<void> updateExternalPilotAccountStatus({
    required String docId,
    required AccountStatus status,
  }) async {
    await _firestore.collection('users').doc(docId).update({
      'accountStatus': status.name,
      'isActive': status == AccountStatus.active,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (status == AccountStatus.suspended) {
      await _notifications.createForUser(
        recipientUid: docId,
        eventKey: 'external-pilot-suspended-$docId',
        title: 'Account Suspended',
        message: 'Your account has been suspended. Please contact support.',
      );
    }
  }
}

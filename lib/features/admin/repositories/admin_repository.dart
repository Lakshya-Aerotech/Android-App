import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/notifications/notification_repository.dart';
import '../../../shared/models/activity_model.dart';
import '../../../shared/repositories/activity_repository.dart';
import '../../../shared/enums/booking_status.dart';
import '../../auth/models/user_model.dart';
import '../../booking/models/booking_model.dart';
import '../models/coupon_model.dart';
import '../models/system_settings_model.dart';
import '../../wallet/models/wallet_transaction_model.dart';
import '../../wallet/models/salary_payment_model.dart';

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

  // System Settings
  Stream<SystemSettingsModel> getSystemSettingsStream();
  Future<void> updateSystemSettings(SystemSettingsModel settings);

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
  Future<void> confirmPaymentDeposit(String docId, String adminId);
  Future<void> rejectPaymentDeposit(String docId, String adminId, String remarks);
  Stream<List<BookingModel>> getBookingsByPaymentStatus(List<String> statuses);

  // Wallet & Salary
  Future<void> markSalaryAsPaid({
    required String pilotId,
    required double amount,
    required String period,
    required String adminId,
    required String adminName,
    String? remarks,
  });
  Stream<List<WalletTransactionModel>> getWalletTransactionsStream(String userId);
  Stream<List<SalaryPaymentModel>> getSalaryPaymentsStream(String pilotId);
}

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notifications = NotificationRepository();

  @override
  Stream<SystemSettingsModel> getSystemSettingsStream() {
    return _firestore
        .collection('system')
        .doc('settings')
        .snapshots()
        .map((doc) => SystemSettingsModel.fromMap(doc.data() ?? {}));
  }

  @override
  Future<void> updateSystemSettings(SystemSettingsModel settings) async {
    await _firestore.collection('system').doc('settings').set(settings.toMap());
  }

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
        .where('role', isEqualTo: UserRole.retailer.value)
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
            'New employee created: ${employee.name} (${employee.role.value})',
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
          '${employee.name ?? 'An employee'} was added as ${employee.role.value}.',
      employeeId: docRef.id,
      type: 'NEW_PILOT_REGISTERED',
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
      'role': role.value,
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
      'approvalStatus': approvalStatus.value,
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
      eventKey: 'retailer-${approvalStatus.value}-$docId',
      title: title,
      message: 'Your retailer account status is now ${approvalStatus.value}.',
      data: {'retailerUid': retailer.uid ?? docId},
      type: approvalStatus == ApprovalStatus.approved ? 'REGISTRATION_APPROVED' : 'REGISTRATION_REJECTED',
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

    return Stream.multi((controller) {
      int totalEmployees = 0;
      int totalFarmers = 0;
      int totalBookings = 0;
      int totalRetailers = 0;
      int completedMissions = 0;
      int pendingBookings = 0;
      int activePilots = 0;

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

      controller.onCancel = () {
        employeesSub.cancel();
        farmersSub.cancel();
        bookingsSub.cancel();
        retailersSub.cancel();
      };
    });
  }

  @override
  Stream<List<UserModel>> getExternalPilotsStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.externalPilot.value)
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
      'approvalStatus': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == ApprovalStatus.approved) {
      updates['accountStatus'] = AccountStatus.active.value;
      updates['isActive'] = true;
    } else if (status == ApprovalStatus.rejected) {
      updates['rejectionReason'] = rejectionReason;
      updates['accountStatus'] = AccountStatus.inactive.value;
      updates['isActive'] = false;
    }

    await _firestore.collection('users').doc(docId).update(updates);

    // Notify user
    await _notifications.createForUser(
      recipientUid: docId,
      eventKey: 'external-pilot-approval-${status.value}-$docId',
      title: 'Account ${status.value}',
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
      'accountStatus': status.value,
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

  @override
  Future<void> confirmPaymentDeposit(String docId, String adminId) async {
    // 1. Get booking and settings first
    final bookingSnap = await _firestore.collection('bookings').doc(docId).get();
    if (!bookingSnap.exists) return;
    final b = BookingModel.fromMap(bookingSnap.data()!, bookingSnap.id);

    final settingsDoc = await _firestore.collection('system').doc('settings').get();
    final settings = SystemSettingsModel.fromMap(settingsDoc.data() ?? {});

    // 2. Resolve Pilot and Copilot Document IDs (they might be UIDs)
    String? pilotDocId;
    if (b.assignedPilotId != null) {
      final snap = await _firestore.collection('users').where('uid', isEqualTo: b.assignedPilotId).limit(1).get();
      pilotDocId = snap.docs.isNotEmpty ? snap.docs.first.id : b.assignedPilotId;
    }

    String? copilotDocId;
    if (b.copilotId != null) {
      final snap = await _firestore.collection('users').where('uid', isEqualTo: b.copilotId).limit(1).get();
      copilotDocId = snap.docs.isNotEmpty ? snap.docs.first.id : b.copilotId;
    }

    final bookingRef = _firestore.collection('bookings').doc(docId);

    await _firestore.runTransaction((transaction) async {
      // Re-get booking inside transaction to ensure consistency
      final bookingDoc = await transaction.get(bookingRef);
      if (!bookingDoc.exists) return;

      final currentBooking = BookingModel.fromMap(bookingDoc.data()!, bookingDoc.id);
      if (currentBooking.paymentVerifiedByAdmin) return;

      // 1. Update Booking
      transaction.update(bookingRef, {
        'paymentStatus': 'Paid',
        'status': BookingStatus.closed.toFirestore(),
        'paymentVerifiedByAdmin': true,
        'paymentVerifiedAt': FieldValue.serverTimestamp(),
        'verifiedByAdminId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final acres = currentBooking.actualAreaCovered ?? currentBooking.estimatedArea;

      // 2. Credit Pilot
      if (pilotDocId != null) {
        final pilotRef = _firestore.collection('users').doc(pilotDocId);
        final incentive = acres * settings.pilotRatePerAcre;
        
        transaction.update(pilotRef, {
          'walletBalance': FieldValue.increment(incentive),
          'totalEarned': FieldValue.increment(incentive),
          'completedJobs': FieldValue.increment(1),
          'totalAcres': FieldValue.increment(acres),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final pilotTxRef = _firestore.collection('walletTransactions').doc();
        transaction.set(pilotTxRef, {
          'userId': currentBooking.assignedPilotId, // Store UID in transactions for consistency
          'bookingId': docId,
          'type': TransactionType.earning.value,
          'amount': incentive,
          'acres': acres,
          'ratePerAcre': settings.pilotRatePerAcre,
          'description': 'Incentive for booking ${currentBooking.bookingId}',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Credit Copilot
      if (copilotDocId != null) {
        final copilotRef = _firestore.collection('users').doc(copilotDocId);
        final incentive = acres * settings.copilotRatePerAcre;

        transaction.update(copilotRef, {
          'walletBalance': FieldValue.increment(incentive),
          'totalEarned': FieldValue.increment(incentive),
          'completedJobs': FieldValue.increment(1),
          'totalAcres': FieldValue.increment(acres),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final copilotTxRef = _firestore.collection('walletTransactions').doc();
        transaction.set(copilotTxRef, {
          'userId': currentBooking.copilotId,
          'bookingId': docId,
          'type': TransactionType.earning.value,
          'amount': incentive,
          'acres': acres,
          'ratePerAcre': settings.copilotRatePerAcre,
          'description': 'Copilot incentive for booking ${currentBooking.bookingId}',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });

    // Notify users (using the latest data)
    await _notifications.createForUser(
      recipientUid: b.farmerUid,
      eventKey: 'payment-confirmed-farmer-$docId',
      title: 'Payment confirmed',
      message: 'Payment for booking ${b.bookingId} has been confirmed. Thank you!',
      bookingId: docId,
      type: 'PAYMENT_CONFIRMED',
    );
    if (b.assignedPilotId != null) {
      await _notifications.createForUser(
        recipientUid: b.assignedPilotId!,
        eventKey: 'payment-confirmed-pilot-$docId',
        title: 'Deposit confirmed',
        message: 'Admin has confirmed your cash deposit for booking ${b.bookingId}.',
        bookingId: docId,
        type: 'PAYMENT_CONFIRMED',
      );
    }
  }

  @override
  Future<void> markSalaryAsPaid({
    required String pilotId, // This is expected to be the UID
    required double amount,
    required String period,
    required String adminId,
    required String adminName,
    String? remarks,
  }) async {
    // 1. Resolve Pilot Document ID from UID
    final pilotSnap = await _firestore.collection('users').where('uid', isEqualTo: pilotId).limit(1).get();
    final String pilotDocId = pilotSnap.docs.isNotEmpty ? pilotSnap.docs.first.id : pilotId;
    
    final pilotRef = _firestore.collection('users').doc(pilotDocId);
    
    await _firestore.runTransaction((transaction) async {
      final pilotDoc = await transaction.get(pilotRef);
      if (!pilotDoc.exists) throw Exception('Pilot not found');

      // 2. Update Pilot Wallet
      transaction.update(pilotRef, {
        'walletBalance': 0.0,
        'lastSalaryPaidAt': FieldValue.serverTimestamp(),
        'lastSalaryAmount': amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Create Salary Payment Record
      final paymentRef = _firestore.collection('salaryPayments').doc();
      transaction.set(paymentRef, {
        'pilotId': pilotId, // Store UID for consistency
        'amountPaid': amount,
        'salaryPeriod': period,
        'paidBy': adminName,
        'paidAt': FieldValue.serverTimestamp(),
        'remarks': remarks,
      });

      // 4. Create Wallet Transaction
      final txRef = _firestore.collection('walletTransactions').doc();
      transaction.set(txRef, {
        'userId': pilotId, // Store UID for consistency
        'type': TransactionType.salaryPayment.value,
        'amount': -amount,
        'description': 'Incentive paid for period: $period',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    await _notifications.createForUser(
      recipientUid: pilotId,
      eventKey: 'salary-paid-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Incentive Paid',
      message: 'Your incentive has been marked as paid by the Administrator.',
    );
  }

  @override
  Stream<List<WalletTransactionModel>> getWalletTransactionsStream(String userId) {
    return _firestore
        .collection('walletTransactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletTransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<SalaryPaymentModel>> getSalaryPaymentsStream(String pilotId) {
    return _firestore
        .collection('salaryPayments')
        .where('pilotId', isEqualTo: pilotId)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SalaryPaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> rejectPaymentDeposit(
    String docId,
    String adminId,
    String remarks,
  ) async {
    await _firestore.collection('bookings').doc(docId).update({
      'paymentStatus': 'Deposit Rejected',
      'adminRemarks': remarks,
      'verifiedByAdminId': adminId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final booking = await _firestore.collection('bookings').doc(docId).get();
    if (booking.exists) {
      final b = BookingModel.fromMap(booking.data()!, booking.id);
      if (b.assignedPilotId != null) {
        await _notifications.createForUser(
          recipientUid: b.assignedPilotId!,
          eventKey: 'deposit-rejected-pilot-$docId',
          title: 'Deposit rejected',
          message:
              'Your cash deposit for booking ${b.bookingId} was rejected. Reason: $remarks',
          bookingId: docId,
          type: 'PAYMENT_REJECTED',
        );
      }
    }
  }

  @override
  Stream<List<BookingModel>> getBookingsByPaymentStatus(List<String> statuses) {
    return _firestore
        .collection('bookings')
        .where('paymentStatus', whereIn: statuses)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}

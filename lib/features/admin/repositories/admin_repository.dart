import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/notifications/notification_repository.dart';
import '../../../shared/models/activity_model.dart';
import '../../../shared/repositories/activity_repository.dart';
import '../../auth/models/user_model.dart';

abstract class AdminRepository {
  Stream<List<UserModel>> getEmployeesStream();
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
  Future<void> deleteEmployee(String docId);
  Stream<Map<String, dynamic>> getDashboardStats();
}

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notifications = NotificationRepository();

  @override
  Stream<List<UserModel>> getEmployeesStream() {
    return _firestore
        .collection('users')
        .where('role', whereIn: ['pilot', 'operations', 'admin'])
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
  Future<void> deleteEmployee(String docId) async {
    await _firestore.collection('users').doc(docId).delete();
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
    final bookingsStream = _firestore.collection('bookings').snapshots();
    final dronesStream = _firestore.collection('drones').snapshots();

    return Stream.multi((controller) {
      int totalEmployees = 0;
      int totalFarmers = 0;
      int totalBookings = 0;
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
                  doc.data()['role'] == 'pilot' &&
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
        dronesSub.cancel();
      };
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
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
  // Add other methods for stats later
}

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    await _firestore.collection('users').add(employee.toMap());
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

    await docRef.update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteEmployee(String docId) async {
    await _firestore.collection('users').doc(docId).delete();
  }
}

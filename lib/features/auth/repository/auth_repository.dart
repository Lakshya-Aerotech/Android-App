import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/activity_model.dart';
import '../../../shared/repositories/activity_repository.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String, int?) codeSent,
    required void Function(FirebaseAuthException) verificationFailed,
  });
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  });
  Future<UserCredential> loginEmployee({
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<UserModel?> getUserData(String uid);
  Future<void> createFarmerProfile(UserModel user);
  Future<void> updateProfile(String docId, Map<String, dynamic> data);
  Future<UserModel?> findUserByEmail(String email);
  Future<void> linkAuthWithEmployee(String docId, String uid);
  Future<void> updateLastLogin(String docId);
  Future<void> sendPasswordResetEmail(String email);
}

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String, int?) codeSent,
    required void Function(FirebaseAuthException) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // This callback will be invoked in some cases for automatic verification
      },
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  @override
  Future<UserCredential> loginEmployee({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<UserModel?> getUserData(String uid) async {
    final query = await _firestore
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    
    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data(), docId: query.docs.first.id);
    }
    return null;
  }

  @override
  Future<void> createFarmerProfile(UserModel user) async {
    // For farmers, we use the UID as the document ID for simplicity and performance
    await _firestore.collection('users').doc(user.uid).set(user.toMap());

    // Log Activity
    await ActivityRepository.logActivity(ActivityModel(
      type: ActivityType.farmerRegistered,
      description: 'New farmer registered: ${user.name}',
      userId: user.uid,
      userName: user.name,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<void> updateProfile(String docId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(docId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<UserModel?> findUserByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data(), docId: query.docs.first.id);
    }
    return null;
  }

  @override
  Future<void> linkAuthWithEmployee(String docId, String uid) async {
    await _firestore.collection('users').doc(docId).update({
      'uid': uid,
      'authCreated': true,
      'lastLogin': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateLastLogin(String docId) async {
    await _firestore.collection('users').doc(docId).update({
      'lastLogin': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

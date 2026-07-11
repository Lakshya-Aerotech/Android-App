import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<void> updateProfile(String uid, Map<String, dynamic> data);
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
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> createFarmerProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

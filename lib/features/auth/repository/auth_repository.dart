import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/notifications/notification_repository.dart';
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
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<UserModel?> getUserData(String uid);
  Future<void> createFarmerProfile(UserModel user);
  Future<void> createRetailerProfile(UserModel user);
  Future<void> updateProfile(String docId, Map<String, dynamic> data);
  Future<UserModel?> findUserByEmail(String email);
  Future<void> linkAuthWithEmployee(String docId, String uid);
  Future<void> updateLastLogin(String docId);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> registerExternalPilot(UserModel user, String password);
  Future<void> registerFarmer(UserModel user, String password);
}

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notifications = NotificationRepository();

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
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
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
      return UserModel.fromMap(
        query.docs.first.data(),
        docId: query.docs.first.id,
      );
    }
    return null;
  }

  @override
  Future<void> createFarmerProfile(UserModel user) async {
    // For farmers, we use the UID as the document ID for simplicity and performance
    await _firestore.collection('users').doc(user.uid).set(user.toMap());

    // Log Activity
    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.farmerRegistered,
        description: 'New farmer registered: ${user.name}',
        userId: user.uid,
        userName: user.name,
        timestamp: DateTime.now(),
      ),
    );

    await _notifications.createForRole(
      role: UserRole.admin,
      eventKey: 'farmer-registered-${user.uid}',
      title: 'New farmer registered',
      message: '${user.name ?? 'A farmer'} registered with Lakshya Aerotech.',
      data: {'farmerUid': user.uid},
    );
  }

  @override
  Future<void> createRetailerProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());

    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.employeeCreated,
        description: 'New retailer registration submitted: ${user.shopName}',
        userId: user.uid,
        userName: user.ownerName ?? user.name,
        timestamp: DateTime.now(),
      ),
    );

    await _notifications.createForUser(
      recipientUid: user.uid!,
      eventKey: 'retailer-registration-submitted-${user.uid}',
      title: 'Registration submitted',
      message:
          'Your retailer registration has been submitted for admin approval.',
      data: {'retailerUid': user.uid},
    );
    await _notifications.createForRole(
      role: UserRole.admin,
      eventKey: 'retailer-registration-${user.uid}',
      title: 'Retailer approval pending',
      message:
          '${user.shopName ?? 'A retailer'} submitted a registration request.',
      data: {'retailerUid': user.uid},
    );
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
      return UserModel.fromMap(
        query.docs.first.data(),
        docId: query.docs.first.id,
      );
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

  @override
  Future<void> registerExternalPilot(UserModel user, String password) async {
    if (user.email == null) {
      throw FirebaseAuthException(
        code: 'email-required',
        message: 'Email is required for registration.',
      );
    }

    // 1. Create Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: user.email!,
      password: password,
    );

    final uid = credential.user!.uid;

    // 2. Create Firestore user document
    final userWithUid = user.copyWith(uid: uid, docId: uid);
    await _firestore.collection('users').doc(uid).set(userWithUid.toMap());

    // 3. Log Activity
    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.externalPilotRegistered,
        description: 'New external pilot registered: ${user.name}',
        userId: uid,
        userName: user.name,
        timestamp: DateTime.now(),
      ),
    );

    // 4. Notify Admin
    await _notifications.createForRole(
      role: UserRole.admin,
      eventKey: 'external-pilot-registered-$uid',
      title: 'New external pilot registration',
      message: '${user.name} has registered as an external pilot and is awaiting approval.',
      data: {'pilotUid': uid},
    );
  }

  @override
  Future<void> registerFarmer(UserModel user, String password) async {
    if (user.email == null) {
      throw FirebaseAuthException(
        code: 'email-required',
        message: 'Email is required for registration.',
      );
    }

    // 1. Create Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: user.email!,
      password: password,
    );

    final uid = credential.user!.uid;

    // 2. Create Firestore user document
    final userWithUid = user.copyWith(uid: uid, docId: uid);
    await _firestore.collection('users').doc(uid).set(userWithUid.toMap());

    // 3. Log Activity
    await ActivityRepository.logActivity(
      ActivityModel(
        type: ActivityType.farmerRegistered,
        description: 'New farmer registered: ${user.name}',
        userId: uid,
        userName: user.name,
        timestamp: DateTime.now(),
      ),
    );

    // 4. Notify Admin
    await _notifications.createForRole(
      role: UserRole.admin,
      eventKey: 'farmer-registered-$uid',
      title: 'New farmer registration',
      message: '${user.name ?? 'A farmer'} registered with Lakshya Aerotech.',
      data: {'farmerUid': uid},
    );
  }
}

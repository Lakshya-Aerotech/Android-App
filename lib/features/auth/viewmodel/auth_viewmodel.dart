import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repository/auth_repository.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userModelProvider = StateProvider<UserModel?>((ref) => null);

final isAuthInitializingProvider = StateProvider<bool>((ref) => true);

final pendingRetailerRegistrationProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

enum AuthStatus {
  initial,
  loading,
  otpSent,
  authenticated,
  unauthenticated,
  error,
  passwordResetSent,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? verificationId;

  AuthState({required this.status, this.errorMessage, this.verificationId});

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? verificationId,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      verificationId: verificationId ?? this.verificationId,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthViewModel(this._repository, this._ref)
    : super(AuthState(status: AuthStatus.initial));

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.sendOtp(
        phoneNumber: phoneNumber,
        codeSent: (verificationId, resendToken) {
          state = state.copyWith(
            status: AuthStatus.otpSent,
            verificationId: verificationId,
          );
        },
        verificationFailed: (e) {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: e.message,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String smsCode) async {
    if (state.verificationId == null) return;
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final credential = await _repository.verifyOtp(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );
      await _handleUserSignIn(credential.user);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getAuthErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loginEmployee(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final processedEmail = email.trim().toLowerCase();
      final credential = await _repository.loginEmployee(
        email: processedEmail,
        password: password,
      );
      await _handleUserSignIn(credential.user);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getAuthErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loginRetailer(String email, String password) async {
    await loginEmployee(email, password);
  }

  Future<void> registerRetailer({
    required String shopName,
    required String ownerName,
    required String email,
    required String password,
    String? gstNumber,
    String? aadhaarPan,
    required String shopAddress,
    required String state,
    required String district,
    required String mandal,
    required String village,
    required double latitude,
    required double longitude,
  }) async {
    this.state = this.state.copyWith(status: AuthStatus.loading);
    try {
      final credential = await _repository.registerWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Unable to create retailer account.');
      }

      final now = DateTime.now();
      final retailer = UserModel(
        uid: user.uid,
        docId: user.uid,
        email: email.trim().toLowerCase(),
        role: UserRole.retailer,
        profileCompleted: true,
        approvalStatus: ApprovalStatus.pending,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        name: ownerName.trim(),
        shopName: shopName.trim(),
        ownerName: ownerName.trim(),
        gstNumber: gstNumber?.trim().isEmpty ?? true ? null : gstNumber!.trim(),
        aadhaarPan: aadhaarPan?.trim().isEmpty ?? true
            ? null
            : aadhaarPan!.trim(),
        shopAddress: shopAddress.trim(),
        state: state.trim(),
        district: district.trim(),
        mandal: mandal.trim(),
        village: village.trim(),
        latitude: latitude,
        longitude: longitude,
      );

      await _repository.createRetailerProfile(retailer);
      await _repository.logout();
      _ref.read(pendingRetailerRegistrationProvider.notifier).state = null;
      _ref.read(userModelProvider.notifier).state = null;
      this.state = this.state.copyWith(status: AuthStatus.unauthenticated);
    } on FirebaseAuthException catch (e) {
      this.state = this.state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getAuthErrorMessage(e),
      );
    } catch (e) {
      this.state = this.state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _handleUserSignIn(User? user) async {
    if (user == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    // Attempt to find user by UID first
    var userData = await _repository.getUserData(user.uid);

    // First Login Workflow for Employees (Email Login)
    // If not found by UID, try finding by email
    if (userData == null && user.email != null) {
      final employeeRecord = await _repository.findUserByEmail(user.email!);
      if (employeeRecord != null) {
        // Link the Firebase UID to the existing Firestore record using its unique document ID
        await _repository.linkAuthWithEmployee(employeeRecord.docId!, user.uid);
        // Fetch the linked data
        userData = await _repository.getUserData(user.uid);
      }
    }

    if (userData == null) {
      // If it's an email login but still no userData, it's unauthorized
      if (user.email != null) {
        await _repository.logout();
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Unauthorized employee.',
        );
        return;
      }

      final retailerRegistration = _ref.read(
        pendingRetailerRegistrationProvider,
      );
      if (retailerRegistration != null) {
        final now = DateTime.now();
        final newRetailer = UserModel(
          uid: user.uid,
          docId: user.uid,
          phoneNumber: user.phoneNumber,
          email: retailerRegistration['email'],
          role: UserRole.retailer,
          profileCompleted: true,
          approvalStatus: ApprovalStatus.pending,
          isActive: true,
          createdAt: now,
          updatedAt: now,
          name: retailerRegistration['ownerName'],
          village: retailerRegistration['village'],
          district: retailerRegistration['district'],
          state: retailerRegistration['state'],
          shopName: retailerRegistration['shopName'],
          ownerName: retailerRegistration['ownerName'],
          gstNumber: retailerRegistration['gstNumber'],
          aadhaarPan: retailerRegistration['aadhaarPan'],
          shopAddress: retailerRegistration['shopAddress'],
          mandal: retailerRegistration['mandal'],
          latitude: retailerRegistration['latitude'],
          longitude: retailerRegistration['longitude'],
        );
        await _repository.createRetailerProfile(newRetailer);
        _ref.read(pendingRetailerRegistrationProvider.notifier).state = null;
        _ref.read(userModelProvider.notifier).state = newRetailer;
      } else {
        // New Farmer (Phone Login)
        final newUser = UserModel(
          uid: user.uid,
          docId: user.uid, // For farmers, we use UID as DocID
          phoneNumber: user.phoneNumber,
          email: user.email,
          role: UserRole.farmer,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _repository.createFarmerProfile(newUser);
        _ref.read(userModelProvider.notifier).state = newUser;
      }
    } else {
      _ref.read(pendingRetailerRegistrationProvider.notifier).state = null;
      if (!userData.isActive && userData.role != UserRole.retailer) {
        await _repository.logout();
        _ref.read(userModelProvider.notifier).state = null;
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage:
              'Your account has been disabled. Please contact the administrator.',
        );
        return;
      }

      // Update last login for existing user using document ID
      await _repository.updateLastLogin(userData.docId!);

      // Refresh user data to get updated lastLogin
      final refreshedUser = await _repository.getUserData(user.uid);
      _ref.read(userModelProvider.notifier).state = refreshedUser;
    }
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  Future<void> logout() async {
    await _repository.logout();
    _ref.read(userModelProvider.notifier).state = null;
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> completeProfile({
    required String name,
    required String village,
    required String district,
    required String stateName,
    required String language,
  }) async {
    final user = _ref.read(userModelProvider);
    if (user == null || user.docId == null) return;

    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.updateProfile(user.docId!, {
        'name': name,
        'village': village,
        'district': district,
        'state': stateName,
        'preferredLanguage': language,
        'profileCompleted': true,
      });

      // Refresh data using UID
      final updatedUser = await _repository.getUserData(user.uid!);
      _ref.read(userModelProvider.notifier).state = updatedUser;
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.sendPasswordResetEmail(email.trim().toLowerCase());
      state = state.copyWith(status: AuthStatus.passwordResetSent);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getAuthErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? village,
    String? district,
    String? stateName,
    String? language,
  }) async {
    final user = _ref.read(userModelProvider);
    if (user == null || user.docId == null) return;

    state = state.copyWith(status: AuthStatus.loading);
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (village != null) updates['village'] = village;
      if (district != null) updates['district'] = district;
      if (stateName != null) updates['state'] = stateName;
      if (language != null) updates['preferredLanguage'] = language;

      await _repository.updateProfile(user.docId!, updates);

      // Refresh data using UID
      final updatedUser = await _repository.getUserData(user.uid!);
      _ref.read(userModelProvider.notifier).state = updatedUser;
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    debugPrint("Firebase Code: ${e.code}");
    debugPrint("Firebase Message: ${e.message}");

    switch (e.code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'user-disabled':
        return 'Your account has been disabled. Please contact the administrator.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network request failed. Please check your connection.';
      case 'invalid-phone-number':
        return 'The phone number is invalid.';
      case 'invalid-verification-code':
        return 'The OTP entered is incorrect.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthViewModel(repository, ref);
});

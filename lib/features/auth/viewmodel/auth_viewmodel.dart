import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repository/auth_repository.dart';
import '../models/user_model.dart';
import '../../../core/services/file_service.dart';
import '../../../core/services/account_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userModelProvider = StateProvider<UserModel?>((ref) => null);

final isAuthInitializingProvider = StateProvider<bool>((ref) => true);

enum AuthStatus {
  initial,
  loading,
  otpSent,
  authenticated,
  unauthenticated,
  error,
  passwordResetSent,
  awaitingApproval,
  rejected,
  suspended,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? verificationId;

  AuthState({
    required this.status,
    this.errorMessage,
    this.verificationId,
  });

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

  AuthViewModel(this._repository, this._ref) : super(AuthState(status: AuthStatus.initial));

  // Legacy Phone/OTP methods (Optional cleanup)
  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.sendOtp(
        phoneNumber: phoneNumber,
        codeSent: (verificationId, resendToken) {
          state = state.copyWith(status: AuthStatus.otpSent, verificationId: verificationId);
        },
        verificationFailed: (e) {
          state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
        },
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
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
      state = state.copyWith(status: AuthStatus.error, errorMessage: _getAuthErrorMessage(e));
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final processedEmail = email.trim().toLowerCase();
      final credential = await _repository.loginEmployee(
        email: processedEmail,
        password: password,
      );
      await _handleUserSignIn(credential.user);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: _getAuthErrorMessage(e));
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> registerFarmer(UserModel user, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.registerFarmer(user, password);
      final currentUser = FirebaseAuth.instance.currentUser;
      await _handleUserSignIn(currentUser);
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

  Future<void> registerRetailer({
    required String shopName,
    required String ownerName,
    required String email,
    required String password,
    String? gstNumber,
    String? aadhaarPan,
    required String shopAddress,
    required String stateName,
    required String district,
    required String mandal,
    required String village,
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final credential = await _repository.registerWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      
      final user = credential.user;
      if (user == null) throw Exception('User creation failed');

      final retailer = UserModel(
        uid: user.uid,
        docId: user.uid,
        email: email.trim().toLowerCase(),
        role: UserRole.retailer,
        shopName: shopName,
        ownerName: ownerName,
        gstNumber: gstNumber,
        aadhaarPan: aadhaarPan,
        shopAddress: shopAddress,
        state: stateName,
        district: district,
        mandal: mandal,
        village: village,
        latitude: latitude,
        longitude: longitude,
        approvalStatus: ApprovalStatus.pending,
        isActive: false,
        profileCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.createRetailerProfile(retailer);
      await _repository.logout();
      state = state.copyWith(status: AuthStatus.unauthenticated);
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

  Future<void> registerExternalPilot(UserModel user, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.registerExternalPilot(user, password);
      await _repository.logout();
      state = state.copyWith(status: AuthStatus.unauthenticated);
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

  Future<void> registerExternalPilotWithFiles({
    required UserModel user,
    required String password,
    File? profileImage,
    File? pilotCert,
    File? dgcaCert,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.registerExternalPilot(user, password);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User creation failed');
      final uid = currentUser.uid;

      final fileService = _ref.read(fileServiceProvider);
      final Map<String, dynamic> updates = {};

      if (profileImage != null) {
        final profileUrl = await fileService.uploadProfileImage(uid: uid, file: profileImage);
        updates['profilePhotographUrl'] = profileUrl;
        updates['profileImageUrl'] = profileUrl;
      }
      
      if (pilotCert != null) {
        final pilotCertUrl = await fileService.uploadUserDocument(
          uid: uid, 
          file: pilotCert, 
          documentType: 'drone_pilot_certificate',
        );
        updates['dronePilotCertificateUrl'] = pilotCertUrl;
      }

      if (dgcaCert != null) {
        final dgcaCertUrl = await fileService.uploadUserDocument(
          uid: uid, 
          file: dgcaCert, 
          documentType: 'dgca_certificate',
        );
        updates['dgcaCertificateUrl'] = dgcaCertUrl;
      }

      if (updates.isNotEmpty) {
        await _repository.updateProfile(uid, updates);
      }

      await _repository.logout();
      state = state.copyWith(status: AuthStatus.unauthenticated);
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

  Future<void> _handleUserSignIn(User? user) async {
    if (user == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    var userData = await _repository.getUserData(user.uid);
    
    if (userData == null) {
      await _repository.logout();
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage:
            'This account has not been provisioned. Contact an administrator.',
      );
      return;
    } else {
      if (userData.role == UserRole.externalPilot || userData.role == UserRole.retailer) {
        if (userData.approvalStatus == ApprovalStatus.pending) {
          await _repository.logout();
          state = state.copyWith(
            status: AuthStatus.awaitingApproval,
            errorMessage: 'Your account is awaiting administrator approval.',
          );
          return;
        }
        if (userData.approvalStatus == ApprovalStatus.rejected) {
          await _repository.logout();
          state = state.copyWith(
            status: AuthStatus.rejected,
            errorMessage: 'Your registration has been rejected. Please contact Lakshya Smartguard systems.',
          );
          return;
        }
      }

      if (userData.accountStatus == AccountStatus.suspended || !userData.isActive) {
        await _repository.logout();
        _ref.read(userModelProvider.notifier).state = null;
        state = state.copyWith(
          status: AuthStatus.suspended,
          errorMessage: 'Your account has been suspended. Please contact the administrator.',
        );
        return;
      }
      
      await _repository.updateLastLogin(userData.docId!);
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
      
      final updatedUser = await _repository.getUserData(user.uid!);
      _ref.read(userModelProvider.notifier).state = updatedUser;
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
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
    String? email,
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
      if (email != null) updates['email'] = email;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (village != null) updates['village'] = village;
      if (district != null) updates['district'] = district;
      if (stateName != null) updates['state'] = stateName;
      if (language != null) updates['preferredLanguage'] = language;

      await _repository.updateProfile(user.docId!, updates);

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



  Future<void> cancelFarmerRegistration() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _ref.read(accountServiceProvider).deleteCurrentAccount();
      _ref.read(userModelProvider.notifier).state = null;
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      await _repository.logout();
      _ref.read(userModelProvider.notifier).state = null;
      state = state.copyWith(status: AuthStatus.unauthenticated);
      print('Error canceling registration: $e');
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
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

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthViewModel(repository, ref);
});

final userDetailsProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getUserData(uid);
});

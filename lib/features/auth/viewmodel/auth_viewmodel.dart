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

enum AuthStatus { initial, loading, otpSent, authenticated, unauthenticated, error }

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

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.sendOtp(
        phoneNumber: phoneNumber,
        codeSent: (verificationId, resendToken) {
          state = state.copyWith(status: AuthStatus.otpSent, verificationId: verificationId);
        },
        verificationFailed: (e) {
          state = state.copyWith(status: AuthStatus.error, errorMessage: _getAuthErrorMessage(e));
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

  Future<void> loginEmployee(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final credential = await _repository.loginEmployee(email: email, password: password);
      await _handleUserSignIn(credential.user);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: _getAuthErrorMessage(e));
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> _handleUserSignIn(User? user) async {
    if (user == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    final userData = await _repository.getUserData(user.uid);
    if (userData == null) {
      // New Farmer
      final newUser = UserModel(
        uid: user.uid,
        phoneNumber: user.phoneNumber,
        role: UserRole.farmer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repository.createFarmerProfile(newUser);
      _ref.read(userModelProvider.notifier).state = newUser;
    } else {
      if (!userData.isActive) {
        await _repository.logout();
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Your account has been disabled. Please contact the administrator.',
        );
        return;
      }
      _ref.read(userModelProvider.notifier).state = userData;
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
    if (user == null) return;

    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.updateProfile(user.uid, {
        'name': name,
        'village': village,
        'district': district,
        'state': stateName,
        'preferredLanguage': language,
        'profileCompleted': true,
      });
      
      final updatedUser = await _repository.getUserData(user.uid);
      _ref.read(userModelProvider.notifier).state = updatedUser;
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong password provided for that user.';
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

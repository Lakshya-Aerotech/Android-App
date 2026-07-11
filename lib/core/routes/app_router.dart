import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/complete_profile_screen.dart';
import '../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/farmer/home/farmer_home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(userModelProvider);
  final isInitializing = ref.watch(isAuthInitializingProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthPath = state.matchedLocation == '/login' || 
                         state.matchedLocation == '/otp';
      final isSplash = state.matchedLocation == '/splash';

      // 1. If still initializing (checking Firebase + Firestore), stay on splash
      if (isInitializing) return '/splash';

      // 2. If no user is logged in
      if (user == null) {
        // If not on an auth page, go to login
        if (!isAuthPath && !isSplash) return '/login';
        // If on splash after initialization, go to login
        if (isSplash) return '/login';
        return null;
      }

      // 3. If user is logged in and on an auth page or splash, redirect to dashboard
      if (isAuthPath || isSplash || state.matchedLocation == '/') {
        // Check profile completion for farmers
        if (user.role == UserRole.farmer && !user.profileCompleted) {
          return '/complete-profile';
        }
        // Redirect to their respective dashboard
        return _getRoleDashboard(user.role);
      }

      // 4. Farmer profile completion guard
      if (user.role == UserRole.farmer && !user.profileCompleted && state.matchedLocation != '/complete-profile') {
        return '/complete-profile';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String;
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      
      // Farmer Dashboard
      GoRoute(
        path: '/farmer',
        builder: (context, state) => const FarmerHomeScreen(),
      ),
      
      // Pilot Placeholder
      GoRoute(
        path: '/pilot',
        builder: (context, state) => _placeholderDashboard('Pilot Dashboard', context),
      ),
      
      // Operations Placeholder
      GoRoute(
        path: '/operations',
        builder: (context, state) => _placeholderDashboard('Operations Dashboard', context),
      ),
      
      // Admin Placeholder
      GoRoute(
        path: '/admin',
        builder: (context, state) => _placeholderDashboard('Admin Dashboard', context),
      ),
      
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(), // Should be caught by redirect
      ),
    ],
  );
});

String _getRoleDashboard(UserRole role) {
  switch (role) {
    case UserRole.farmer: return '/farmer';
    case UserRole.pilot: return '/pilot';
    case UserRole.operations: return '/operations';
    case UserRole.admin: return '/admin';
  }
}

Widget _placeholderDashboard(String title, BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Placeholder for Developer Implementation'),
          const SizedBox(height: 32),
          // Logout button to test auth flow
          Consumer(
            builder: (context, ref, child) {
              return ElevatedButton(
                onPressed: () {
                  ref.read(authViewModelProvider.notifier).logout();
                  // Router will automatically redirect to login because user becomes null
                },
                child: const Text('Logout'),
              );
            },
          ),
        ],
      ),
    ),
  );
}

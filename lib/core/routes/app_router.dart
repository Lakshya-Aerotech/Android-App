import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/complete_profile_screen.dart';
import '../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../features/auth/models/user_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
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
      
      // Farmer Placeholder
      GoRoute(
        path: '/farmer',
        builder: (context, state) => _placeholderDashboard('Farmer Dashboard', context),
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
      
      // Root redirect logic
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final user = ref.read(userModelProvider);
          if (user == null) return '/splash';
          
          if (user.role == UserRole.farmer && !user.profileCompleted) {
            return '/complete-profile';
          }
          
          switch (user.role) {
            case UserRole.farmer: return '/farmer';
            case UserRole.pilot: return '/pilot';
            case UserRole.operations: return '/operations';
            case UserRole.admin: return '/admin';
          }
        },
      ),
    ],
  );
});

Widget _placeholderDashboard(String title, BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Placeholder for Developer 2\'s Implementation'),
          const SizedBox(height: 32),
          // Logout button to test auth flow
          Consumer(
            builder: (context, ref, child) {
              return ElevatedButton(
                onPressed: () {
                  ref.read(authViewModelProvider.notifier).logout();
                  context.go('/login');
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

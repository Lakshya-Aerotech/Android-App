import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    final repository = ref.read(authRepositoryProvider);
    final userData = await repository.getUserData(user.uid);

    if (userData == null) {
      if (mounted) context.go('/login');
      return;
    }

    ref.read(userModelProvider.notifier).state = userData;

    if (mounted) {
      if (userData.role == UserRole.farmer && !userData.profileCompleted) {
        context.go('/complete-profile');
      } else {
        _navigateToDashboard(userData.role);
      }
    }
  }

  void _navigateToDashboard(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        context.go('/farmer');
        break;
      case UserRole.pilot:
        context.go('/pilot');
        break;
      case UserRole.operations:
        context.go('/operations');
        break;
      case UserRole.admin:
        context.go('/admin');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001B39), // Dark Navy for Splash
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/lakshya_logo.png',
                  height: 140,
                  width: 140,
                ),
                const SizedBox(height: 24),
                Text(
                  'LAKSHYA\nAEROTECH',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                    letterSpacing: 4,
                    height: 1.1,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Smart Drone Solutions\nfor Modern Agriculture',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/login_drone.png',
                width: MediaQuery.of(context).size.width * 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

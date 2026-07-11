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
    // Wait for a second to show the splash logo
    await Future.delayed(const Duration(seconds: 2));
    
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
      case UserRole.farmer: context.go('/farmer'); break;
      case UserRole.pilot: context.go('/pilot'); break;
      case UserRole.operations: context.go('/operations'); break;
      case UserRole.admin: context.go('/admin'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Assuming the logo is in assets. Using a placeholder for now.
            const Icon(Icons.airplanemode_active, size: 80, color: AppColors.accent),
            const SizedBox(height: 24),
            Text(
              'LAKSHYA\nAEROTECH',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayMedium.copyWith(
                letterSpacing: 4,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart Drone Solutions\nfor Modern Agriculture',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

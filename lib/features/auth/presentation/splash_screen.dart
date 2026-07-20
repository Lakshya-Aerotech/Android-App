import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../models/user_model.dart';
import '../../drone/repositories/drone_repository.dart';
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
    _initializeData();
  }

  Future<void> _initializeData() async {
    // 1. Populate sample drones if needed (Non-blocking)
    try {
      ref.read(droneRepositoryProvider).populateSampleDrones();
    } catch (e) {
      debugPrint('Drone population failed: $e');
    }

    // Artificial delay to show logo
    await Future.delayed(const Duration(seconds: 2));
    
    // Wait for the auth state stream to emit at least once
    // and fetch the user data if logged in
    try {
      final authUser = await ref.read(authStateProvider.future);
      
      if (authUser != null) {
        final repository = ref.read(authRepositoryProvider);
        final userData = await repository.getUserData(authUser.uid);
        
        if (userData != null) {
          // Check for Approval/Account Status (Phase 5)
          bool isAllowed = true;
          if (userData.role == UserRole.externalPilot) {
            if (userData.approvalStatus != ApprovalStatus.approved) isAllowed = false;
          }
          if (userData.accountStatus == AccountStatus.suspended || !userData.isActive) isAllowed = false;

          if (isAllowed) {
            ref.read(userModelProvider.notifier).state = userData;
          } else {
            await repository.logout();
            ref.read(userModelProvider.notifier).state = null;
          }
        }
      }
    } catch (e) {
      // Handle potential initialization errors
      debugPrint('Initialization error: $e');
    } finally {
      // Mark initialization as complete regardless of outcome
      if (mounted) {
        ref.read(isAuthInitializingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001B39), // Dark Navy for Splash
      body: Center(
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
    );
  }
}

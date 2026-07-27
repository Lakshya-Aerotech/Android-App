import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';

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
    await _handleStartupLocationFlow();
    
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

  Future<void> _handleStartupLocationFlow() async {
    // 1. Check whether Location Service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    while (!serviceEnabled) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text('Location services/GPS are disabled. Please enable device location to continue using the application.'),
          actions: [
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
      // Wait a moment and check again
      await Future.delayed(const Duration(milliseconds: 500));
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    }

    // 2. Check/Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    
    while (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        bool retry = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text('Location permission is required to detect your location and farms. Please grant the permission to proceed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel & Proceed'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ) ?? false;

        if (!retry) {
          break;
        }
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Location Permission Permanently Denied'),
          content: const Text('Location permission is permanently denied. Please enable it in the app settings to use location features.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Without Location'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      // Recheck once in case they enabled it in settings
      permission = await Geolocator.checkPermission();
    }

    // Store state in session provider
    ref.read(locationPermissionStateProvider.notifier).state = permission;
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
              'LAKSHYA\nSMARTGUARD',
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
              'Smart Guard Systems\nfor Modern Agriculture',
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

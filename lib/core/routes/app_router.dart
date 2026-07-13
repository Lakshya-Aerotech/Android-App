import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/complete_profile_screen.dart';
import '../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/farmer/home/farmer_home_screen.dart';
import '../../features/farm/presentation/my_farms/my_farms_screen.dart';
import '../../features/farm/presentation/add_farm/add_farm_screen.dart';
import '../../features/farm/presentation/farm_details/farm_details_screen.dart';
import '../../features/farm/models/farm_model.dart';
import '../../features/admin/presentation/admin_main_screen.dart';
import '../../features/admin/presentation/employees/employee_list_screen.dart';
import '../../features/admin/presentation/employees/add_employee_screen.dart';
import '../../features/admin/presentation/placeholders/admin_placeholders.dart';
import '../../features/pilot/presentation/pilot_dashboard.dart';
import '../../features/operations/presentation/operations_main_screen.dart';
import '../../features/operations/presentation/placeholders/operations_placeholders.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(userModelProvider);
  final isInitializing = ref.watch(isAuthInitializingProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthPath =
          state.matchedLocation == '/login' || state.matchedLocation == '/otp';
      final isSplash = state.matchedLocation == '/splash';

      // 1. If still initializing (checking Firebase + Firestore), stay on splash
      if (isInitializing) return '/splash';

      // 2. If no user is logged in
      if (user == null) {
        if (!isAuthPath && !isSplash) return '/login';
        if (isSplash) return '/login';
        return null;
      }

      // 3. If user is logged in and on an auth page or splash, redirect to dashboard
      if (isAuthPath || isSplash || state.matchedLocation == '/') {
        if (user.role == UserRole.farmer && !user.profileCompleted) {
          return '/complete-profile';
        }
        return _getRoleDashboard(user.role);
      }

      // 4. Farmer profile completion guard
      if (user.role == UserRole.farmer &&
          !user.profileCompleted &&
          state.matchedLocation != '/complete-profile') {
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

      // Farm Management
      GoRoute(
        path: '/my-farms',
        builder: (context, state) => const MyFarmsScreen(),
      ),
      GoRoute(
        path: '/add-farm',
        builder: (context, state) => const AddFarmScreen(),
      ),
      GoRoute(
        path: '/farm-details',
        builder: (context, state) {
          final farm = state.extra as FarmModel;
          return FarmDetailsScreen(farm: farm);
        },
      ),

      // Pilot Dashboard
      GoRoute(
        path: '/pilot',
        builder: (context, state) => const PilotDashboard(),
      ),

      // Operations Dashboard
      GoRoute(
        path: '/operations',
        builder: (context, state) => const OperationsMainScreen(),
        routes: [
          GoRoute(
            path: 'bookings',
            builder: (context, state) => const OpsBookingsPlaceholder(),
          ),
          GoRoute(
            path: 'assignments',
            builder: (context, state) => const OpsAssignmentsPlaceholder(),
          ),
          GoRoute(
            path: 'track-jobs',
            builder: (context, state) => const OpsTrackJobsPlaceholder(),
          ),
        ],
      ),

      // Admin Module
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminMainScreen(),
        routes: [
          GoRoute(
            path: 'employees',
            builder: (context, state) => const EmployeeListScreen(),
          ),
          GoRoute(
            path: 'add-employee',
            builder: (context, state) => const AddEmployeeScreen(),
          ),
          GoRoute(
            path: 'drones',
            builder: (context, state) => const DronesPlaceholder(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsPlaceholder(),
          ),
        ],
      ),

      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
    ],
  );
});

String _getRoleDashboard(UserRole role) {
  switch (role) {
    case UserRole.farmer:
      return '/farmer';
    case UserRole.pilot:
      return '/pilot';
    case UserRole.operations:
      return '/operations';
    case UserRole.admin:
      return '/admin';
  }
}
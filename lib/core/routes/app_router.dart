import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakshya_aerotech/features/auth/presentation/splash_screen.dart';
import 'package:lakshya_aerotech/features/auth/presentation/login_screen.dart';
import 'package:lakshya_aerotech/features/auth/presentation/forgot_password_screen.dart';
import 'package:lakshya_aerotech/features/profile/presentation/edit_profile_screen.dart';
import 'package:lakshya_aerotech/features/auth/presentation/complete_profile_screen.dart';
import 'package:lakshya_aerotech/features/auth/presentation/external_pilot_registration_screen.dart';
import 'package:lakshya_aerotech/features/auth/presentation/farmer_registration_screen.dart';
import 'package:lakshya_aerotech/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:lakshya_aerotech/features/auth/models/user_model.dart';
import 'package:lakshya_aerotech/features/farmer/home/farmer_home_screen.dart';
import 'package:lakshya_aerotech/features/farm/presentation/my_farms/my_farms_screen.dart';
import 'package:lakshya_aerotech/features/farm/presentation/add_farm/add_farm_screen.dart';
import 'package:lakshya_aerotech/features/farm/presentation/farm_details/farm_details_screen.dart';
import 'package:lakshya_aerotech/features/farm/models/farm_model.dart';
import 'package:lakshya_aerotech/features/booking/presentation/book_service/book_service_screen.dart';
import 'package:lakshya_aerotech/features/booking/presentation/booking_history/my_bookings_screen.dart';
import 'package:lakshya_aerotech/features/booking/presentation/booking_details/booking_details_screen.dart';
import 'package:lakshya_aerotech/features/booking/presentation/success/booking_success_screen.dart';
import 'package:lakshya_aerotech/features/booking/presentation/payment/payment_screen.dart';
import 'package:lakshya_aerotech/features/booking/models/booking_model.dart';
import 'package:lakshya_aerotech/features/payment/presentation/screens/payment_screen.dart' as online_payment;
import 'package:lakshya_aerotech/features/payment/presentation/screens/payment_webview_screen.dart';
import 'package:lakshya_aerotech/features/payment/presentation/screens/payment_success_screen.dart';
import 'package:lakshya_aerotech/features/payment/presentation/screens/payment_failed_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/admin_main_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/activity/admin_recent_activity_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/analytics/admin_analytics_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/employees/employee_list_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/employees/add_employee_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/external_pilots/external_pilot_list_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/external_pilots/external_pilot_details_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/retailers/retailer_management_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/payments/admin_payments_screen.dart';
import 'package:lakshya_aerotech/features/pilot/presentation/pilot_dashboard.dart';
import 'package:lakshya_aerotech/features/pilot_jobs/presentation/job_details/pilot_job_details_screen.dart';
import 'package:lakshya_aerotech/features/operations/presentation/operations_main_screen.dart';
import 'package:lakshya_aerotech/features/operations/presentation/placeholders/operations_placeholders.dart';
import 'package:lakshya_aerotech/features/operations/presentation/pending_bookings/ops_pending_bookings_screen.dart';
import 'package:lakshya_aerotech/features/operations/presentation/booking_details/ops_booking_details_screen.dart';
import 'package:lakshya_aerotech/features/operations/presentation/assignments/ops_assignments_screen.dart';
import 'package:lakshya_aerotech/features/operations/presentation/assignments/ops_assign_booking_screen.dart';
import 'package:lakshya_aerotech/features/retailer/presentation/retailer_dashboard_screen.dart';
import 'package:lakshya_aerotech/features/retailer/presentation/retailer_farmer_details_screen.dart';
import 'package:lakshya_aerotech/features/retailer/presentation/retailer_farmer_form_screen.dart';
import 'package:lakshya_aerotech/features/retailer/presentation/retailer_farmer_list_screen.dart';
import 'package:lakshya_aerotech/features/retailer/presentation/retailer_registration_screen.dart';
import 'package:lakshya_aerotech/features/retailer/presentation/retailer_status_screen.dart';
import 'package:lakshya_aerotech/features/retailer/presentation/retailer_coupons_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/coupons/coupon_management_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/coupons/coupon_history_screen.dart';
import 'package:lakshya_aerotech/core/notifications/notification_screen.dart';
import 'package:lakshya_aerotech/features/wallet/presentation/pilot_wallet_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/earnings/pilot_earnings_list_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/earnings/pilot_earning_details_screen.dart';
import 'package:lakshya_aerotech/features/admin/presentation/settings/system_settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(userModelProvider);
  final isInitializing = ref.watch(isAuthInitializingProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthPath =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/external-pilot-registration' ||
          state.matchedLocation == '/farmer-registration' ||
          state.matchedLocation == '/retailer-registration';
      final isSplash = state.matchedLocation == '/splash';

      if (isInitializing) return '/splash';

      if (user == null) {
        if (!isAuthPath && !isSplash) return '/login';
        if (isSplash) return '/login';
        return null;
      }

      if (isAuthPath || isSplash || state.matchedLocation == '/') {
        if (user.role == UserRole.farmer && !user.profileCompleted) {
          return '/complete-profile';
        }
        if (user.role == UserRole.retailer &&
            user.approvalStatus != ApprovalStatus.approved) {
          return '/retailer-status';
        }
        return _getRoleDashboard(user.role);
      }

      if (user.role == UserRole.farmer &&
          !user.profileCompleted &&
          state.matchedLocation != '/complete-profile') {
        return '/complete-profile';
      }

      if (user.role == UserRole.retailer &&
          user.approvalStatus != ApprovalStatus.approved &&
          state.matchedLocation != '/retailer-status') {
        return '/retailer-status';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/external-pilot-registration',
        builder: (context, state) => const ExternalPilotRegistrationScreen(),
      ),
      GoRoute(
        path: '/farmer-registration',
        builder: (context, state) => const FarmerRegistrationScreen(),
      ),
      GoRoute(
        path: '/retailer-registration',
        builder: (context, state) => const RetailerRegistrationScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
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

      // Booking Module
      GoRoute(
        path: '/book-service',
        builder: (context, state) {
          final farm = state.extra as FarmModel?;
          return BookServiceScreen(initialFarm: farm);
        },
      ),
      GoRoute(
        path: '/my-bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/booking-details',
        builder: (context, state) {
          final booking = state.extra as BookingModel;
          return BookingDetailsScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final booking = state.extra as BookingModel;
          return PaymentScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/online-payment',
        builder: (context, state) {
          final booking = state.extra as BookingModel;
          return online_payment.PaymentScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/payment-webview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final booking = extra['booking'] as BookingModel;
          final paymentUrl = extra['paymentUrl'] as String;
          return PaymentWebViewScreen(booking: booking, paymentUrl: paymentUrl);
        },
      ),
      GoRoute(
        path: '/payment-success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final booking = extra['booking'] as BookingModel;
          final transactionId = extra['transactionId'] as String;
          return PaymentSuccessScreen(booking: booking, transactionId: transactionId);
        },
      ),
      GoRoute(
        path: '/payment-failed',
        builder: (context, state) {
          final booking = state.extra as BookingModel;
          return PaymentFailedScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/booking-success',
        builder: (context, state) {
          final bookingId = state.extra as String;
          return BookingSuccessScreen(bookingId: bookingId);
        },
      ),

      GoRoute(
        path: '/retailer-status',
        builder: (context, state) => const RetailerStatusScreen(),
      ),
      GoRoute(
        path: '/retailer',
        builder: (context, state) => const RetailerDashboardScreen(),
        routes: [
          GoRoute(
            path: 'farmers',
            builder: (context, state) => const RetailerFarmerListScreen(),
          ),
          GoRoute(
            path: 'select-farmer',
            builder: (context, state) =>
                const RetailerFarmerListScreen(selectionMode: true),
          ),
          GoRoute(
            path: 'register-farmer',
            builder: (context, state) => const RetailerFarmerFormScreen(),
          ),
          GoRoute(
            path: 'farmer-details',
            builder: (context, state) {
              final farmer = state.extra as UserModel;
              return RetailerFarmerDetailsScreen(farmer: farmer);
            },
          ),
          GoRoute(
            path: 'book-service',
            builder: (context, state) {
              final farmer = state.extra as UserModel;
              return BookServiceScreen(farmerOverride: farmer);
            },
          ),
          GoRoute(
            path: 'bookings',
            builder: (context, state) =>
                const MyBookingsScreen(retailerMode: true),
          ),
          GoRoute(
            path: 'coupons',
            builder: (context, state) => const RetailerCouponsScreen(),
          ),
          GoRoute(
            path: 'payment-status',
            builder: (context, state) => const _RetailerSimplePage(
              title: 'Payment Status',
              message: 'Payment status will appear with booking records.',
              icon: Icons.payments_outlined,
            ),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const _RetailerSimplePage(
              title: 'Notifications',
              message: 'Retailer notifications are delivered by the app.',
              icon: Icons.notifications_none,
            ),
          ),
        ],
      ),

      // Pilot Dashboard
      GoRoute(
        path: '/pilot',
        builder: (context, state) => const PilotDashboard(),
        routes: [
          GoRoute(
            path: 'job-details',
            builder: (context, state) {
              final job = state.extra as BookingModel;
              return PilotJobDetailsScreen(job: job);
            },
          ),
          GoRoute(
            path: 'wallet',
            builder: (context, state) => const PilotWalletScreen(),
          ),
        ],
      ),

      // Operations Dashboard
      GoRoute(
        path: '/operations',
        builder: (context, state) => const OperationsMainScreen(),
        routes: [
          GoRoute(
            path: 'bookings',
            builder: (context, state) => const OpsPendingBookingsScreen(),
          ),
          GoRoute(
            path: 'assignments',
            builder: (context, state) => const OpsAssignmentsScreen(),
            routes: [
              GoRoute(
                path: 'assign',
                builder: (context, state) {
                  final booking = state.extra as BookingModel;
                  return OpsAssignBookingScreen(booking: booking);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'track-jobs',
            builder: (context, state) => const OpsTrackJobsPlaceholder(),
          ),
        ],
      ),
      GoRoute(
        path: '/ops-booking-details',
        builder: (context, state) {
          final booking = state.extra as BookingModel;
          return OpsBookingDetailsScreen(booking: booking);
        },
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
            path: 'external-pilots',
            builder: (context, state) => const ExternalPilotListScreen(),
          ),
          GoRoute(
            path: 'external-pilot-details',
            builder: (context, state) {
              final pilot = state.extra as UserModel;
              return ExternalPilotDetailsScreen(pilot: pilot);
            },
          ),
          GoRoute(
            path: 'retailers',
            builder: (context, state) => const RetailerManagementScreen(),
          ),
          GoRoute(
            path: 'payments',
            builder: (context, state) => const AdminPaymentsScreen(),
          ),
          GoRoute(
            path: 'pilot-earnings',
            builder: (context, state) => const PilotEarningsListScreen(),
          ),
          GoRoute(
            path: 'pilot-earning-details',
            builder: (context, state) {
              final pilot = state.extra as UserModel;
              return PilotEarningDetailsScreen(pilot: pilot);
            },
          ),
          GoRoute(
            path: 'coupons',
            builder: (context, state) => const CouponManagementScreen(),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) => const CouponHistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AdminAnalyticsScreen(),
          ),
          GoRoute(
            path: 'recent-activity',
            builder: (context, state) => const AdminRecentActivityScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SystemSettingsScreen(),
          ),
        ],
      ),

      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    ],
  );
});

String _getRoleDashboard(UserRole role) {
  switch (role) {
    case UserRole.farmer:
      return '/farmer';
    case UserRole.pilot:
      return '/pilot';
    case UserRole.externalPilot:
      return '/pilot';
    case UserRole.retailer:
      return '/retailer';
    case UserRole.operations:
      return '/operations';
    case UserRole.admin:
      return '/admin';
  }
}

class _RetailerSimplePage extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _RetailerSimplePage({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

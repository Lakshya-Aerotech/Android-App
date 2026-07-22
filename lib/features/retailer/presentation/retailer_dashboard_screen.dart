import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../../features/booking/viewmodels/booking_viewmodel.dart';
import '../../../shared/components/dashboard_header.dart';
import '../../booking/presentation/booking_history/my_bookings_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../viewmodels/retailer_viewmodel.dart';
import 'retailer_farmer_list_screen.dart';

class RetailerDashboardScreen extends ConsumerStatefulWidget {
  const RetailerDashboardScreen({super.key});

  @override
  ConsumerState<RetailerDashboardScreen> createState() =>
      _RetailerDashboardScreenState();
}

class _RetailerDashboardScreenState
    extends ConsumerState<RetailerDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _RetailerHomeContent(),
      const RetailerFarmerListScreen(),
      const MyBookingsScreen(retailerMode: true),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.primary,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: context.tr('Home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people),
            label: context.tr('Farmers'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_outlined),
            activeIcon: const Icon(Icons.assignment),
            label: context.tr('Bookings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: context.tr('Profile'),
          ),
        ],
      ),
    );
  }
}

class _RetailerHomeContent extends ConsumerWidget {
  const _RetailerHomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    final farmersAsync = ref.watch(retailerFarmersStreamProvider);
    final bookingsAsync = ref.watch(retailerBookingsStreamProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            userName: user?.shopName ?? user?.name ?? 'Retailer',
            subtitle: 'Manage farmers and bookings.',
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'My Farmers',
                        value: farmersAsync.maybeWhen(
                          data: (value) => value.length.toString(),
                          orElse: () => '...',
                        ),
                        icon: Icons.people_outline,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        label: 'Bookings',
                        value: bookingsAsync.maybeWhen(
                          data: (value) => value.length.toString(),
                          orElse: () => '...',
                        ),
                        icon: Icons.book_online,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalXl,
                Text(
                  context.tr('Quick Actions'),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalMd,
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.18,
                  children: [
                    _ActionTile(
                      title: 'Register Farmer',
                      icon: Icons.person_add_outlined,
                      onTap: () => context.push('/retailer/register-farmer'),
                    ),
                    _ActionTile(
                      title: 'My Farmers',
                      icon: Icons.people_outline,
                      onTap: () => context.push('/retailer/farmers'),
                    ),
                    _ActionTile(
                      title: 'Search Farmer',
                      icon: Icons.search,
                      onTap: () => context.push('/retailer/farmers'),
                    ),
                    _ActionTile(
                      title: 'Book Service',
                      icon: Icons.add_circle_outline,
                      onTap: () => context.push('/retailer/select-farmer'),
                    ),
                    _ActionTile(
                      title: 'Booking History',
                      icon: Icons.history,
                      onTap: () => context.push('/retailer/bookings'),
                    ),
                    _ActionTile(
                      title: 'Payment Status',
                      icon: Icons.payments_outlined,
                      onTap: () => context.push('/retailer/payment-status'),
                    ),
                    _ActionTile(
                      title: 'My Coupons',
                      icon: Icons.local_offer_outlined,
                      onTap: () => context.push('/retailer/coupons'),
                    ),
                    _ActionTile(
                      title: 'Notifications',
                      icon: Icons.notifications_none,
                      onTap: () => context.push('/notifications'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            Text(
              context.tr(title),
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(context.tr(label), style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

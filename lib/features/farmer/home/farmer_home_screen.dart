import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/booking_card.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../core/widgets/section_header.dart';
import 'farmer_home_data.dart';
import 'widgets/farmer_home_header.dart';
import 'widgets/quick_action_card.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../farm/presentation/my_farms/my_farms_screen.dart';
import '../../booking/presentation/booking_history/my_bookings_screen.dart';
import '../../farm/models/farm_model.dart';
import '../../booking/models/booking_model.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/enums/booking_status.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../booking/viewmodels/booking_viewmodel.dart';
import '../../farm/viewmodels/farm_viewmodel.dart';

class FarmerHomeScreen extends ConsumerStatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  ConsumerState<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends ConsumerState<FarmerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _FarmerHomeContent(),
    const MyBookingsScreen(),
    const MyFarmsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Theme(
          data: Theme.of(context).copyWith(
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: AppColors.primary,
              selectedItemColor: AppColors.accent,
              unselectedItemColor: AppColors.textSecondary,
              selectedLabelStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTextStyles.bodySmall,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
            ),
          ),
          child: CustomBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}

class _FarmerHomeContent extends ConsumerWidget {
  const _FarmerHomeContent();

  String? _quickActionAssetPath(String label) {
    return switch (label) {
      'Book New Service' => 'assets/icons/book_new_service.png',
      'My Bookings' => 'assets/icons/my_bookings.png',
      'My Farms' => 'assets/icons/my_farms.png',
      'Service History' => 'assets/icons/service_history.png',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    final bookingsAsync = ref.watch(farmerBookingsStreamProvider);
    final farmsAsync = ref.watch(farmsStreamProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FarmerHomeHeader(
            farmerName: user?.name ?? 'Farmer',
            onBookNow: () => context.push('/book-service'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSpacing.lg,
              AppSizes.screenPadding,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(bookingsAsync, farmsAsync),
                AppSpacing.verticalXl,
                SectionHeader(
                  title: 'Quick Actions',
                  titleStyle: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalMd,
                GridView.builder(
                  itemCount: farmerQuickActions.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.22,
                      ),
                  itemBuilder: (context, index) {
                    final action = farmerQuickActions[index];
                    return QuickActionCard(
                      label: action.label,
                      icon: action.icon,
                      iconColor: action.iconColor,
                      assetPath: _quickActionAssetPath(action.label),
                      onTap: () {
                        if (action.label == 'My Farms') {
                          context.push('/my-farms');
                        } else if (action.label == 'Book New Service') {
                          context.push('/book-service');
                        } else if (action.label == 'My Bookings') {
                          context.push('/my-bookings');
                        } else {
                          // Service History - Filter completed bookings
                          context.push('/my-bookings');
                        }
                      },
                    );
                  },
                ),
                AppSpacing.verticalXl,
                SectionHeader(
                  title: 'Upcoming Booking',
                  titleStyle: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalMd,
                switch (bookingsAsync) {
                  AsyncData(:final value) =>
                    _buildUpcomingBookingCard(context, value),
                  AsyncError(:final error) => Text('Error: $error'),
                  _ => const LinearProgressIndicator(),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookingCard(
    BuildContext context,
    List<BookingModel> bookings,
  ) {
    final upcoming =
        bookings
            .where(
              (b) =>
                  b.status != BookingStatus.completed &&
                  b.status != BookingStatus.cancelled &&
                  b.status != BookingStatus.closed &&
                  b.status != BookingStatus.farmerConfirmed,
            )
            .toList();

    if (upcoming.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.border, size: 40),
            const SizedBox(height: 12),
            Text('No upcoming bookings', style: AppTextStyles.bodyMedium),
            TextButton(
              onPressed: () => context.push('/book-service'),
              child: const Text('Book a Service Now'),
            ),
          ],
        ),
      );
    }

    final b = upcoming.first;
    return BookingCard(
      dateTime:
          '${DateFormat('dd MMM').format(b.bookingDate)}, ${b.preferredTime}',
      farmName: b.farmName,
      cropInfo: '${b.cropType} • ${b.estimatedArea} Acres',
      status: b.status,
      onTap: () => context.push('/booking-details', extra: b),
    );
  }

  Widget _buildStatsGrid(
    AsyncValue<List<BookingModel>> bookingsAsync,
    AsyncValue<List<FarmModel>> farmsAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _buildStatCard(
              'Total Farms',
              switch (farmsAsync) {
                AsyncData(:final value) => value.length.toString(),
                _ => '...',
              },
              Icons.landscape_outlined,
              Colors.green,
            ),
            _buildStatCard(
              'Total Bookings',
              switch (bookingsAsync) {
                AsyncData(:final value) => value.length.toString(),
                _ => '...',
              },
              Icons.assignment_outlined,
              Colors.blue,
            ),
            _buildStatCard(
              'Completed',
              switch (bookingsAsync) {
                AsyncData(:final value) =>
                  value
                      .where(
                        (e) => [
                          BookingStatus.completed,
                          BookingStatus.farmerConfirmed,
                          BookingStatus.closed,
                        ].contains(e.status),
                      )
                      .length
                      .toString(),
                _ => '...',
              },
              Icons.task_alt,
              Colors.orange,
            ),
            _buildStatCard(
              'Total Acres',
              switch (farmsAsync) {
                AsyncData(:final value) =>
                  value.fold(0.0, (sum, item) => sum + item.area).toStringAsFixed(
                    1,
                  ),
                _ => '0.0',
              },
              Icons.crop_free,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

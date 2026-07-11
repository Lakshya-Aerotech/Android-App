import 'package:flutter/material.dart';

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

class FarmerHomeScreen extends StatelessWidget {
  const FarmerHomeScreen({super.key});

  String? _quickActionAssetPath(String label) {
    return switch (label) {
      'Book New Service' => 'assets/icons/book_new_service.png',
      'My Bookings' => 'assets/icons/my_bookings.png',
      'My Farms' => 'assets/icons/my_farms.png',
      'Service History' => 'assets/icons/service_history.png',
      _ => null,
    };
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FarmerHomeHeader(
                farmerName: mockFarmerName,
                onBookNow: () => _showComingSoon(context, 'Booking feature'),
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
                          onTap: () => _showComingSoon(context, action.label),
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
                    BookingCard(
                      dateTime: mockUpcomingBooking.dateTime,
                      farmName: mockUpcomingBooking.farmName,
                      cropInfo: mockUpcomingBooking.cropInfo,
                      status: mockUpcomingBooking.status,
                      onTap: () => _showComingSoon(context, 'Booking details'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
            currentIndex: 0,
            onTap: (index) {
              if (index == 0) {
                return;
              }
              const labels = ['Home', 'Bookings', 'Farms', 'Profile'];
              _showComingSoon(context, labels[index]);
            },
          ),
        ),
      ),
    );
  }
}

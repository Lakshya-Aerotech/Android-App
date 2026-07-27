import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakshya_aerotech/core/localization/app_localizations.dart';
import 'package:lakshya_aerotech/core/theme/app_colors.dart';
import 'package:lakshya_aerotech/features/operations/presentation/dashboard/operations_dashboard_screen.dart';
import 'package:lakshya_aerotech/features/operations/presentation/pending_bookings/ops_pending_bookings_screen.dart';
import 'package:lakshya_aerotech/features/operations/presentation/assignments/ops_assignments_screen.dart';
import 'package:lakshya_aerotech/features/profile/presentation/profile_screen.dart';

class OperationsMainScreen extends ConsumerStatefulWidget {
  const OperationsMainScreen({super.key});

  @override
  ConsumerState<OperationsMainScreen> createState() =>
      _OperationsMainScreenState();
}

class _OperationsMainScreenState extends ConsumerState<OperationsMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const OperationsDashboardScreen(),
    const OpsPendingBookingsScreen(),
    const OpsAssignmentsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: AppColors.primary,
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.primary,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: AppColors.textSecondary,
          ),
        ),
        child: BottomNavigationBar(
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
              label: context.tr('Dashboard'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_month_outlined),
              activeIcon: const Icon(Icons.calendar_month),
              label: context.tr('Bookings'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_ind_outlined),
              activeIcon: const Icon(Icons.assignment_ind),
              label: context.tr('Assignments'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: context.tr('Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

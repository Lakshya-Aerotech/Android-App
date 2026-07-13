import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'dashboard/operations_dashboard_screen.dart';
import 'placeholders/operations_placeholders.dart';
import '../../profile/presentation/profile_screen.dart';

class OperationsMainScreen extends ConsumerStatefulWidget {
  const OperationsMainScreen({super.key});

  @override
  ConsumerState<OperationsMainScreen> createState() => _OperationsMainScreenState();
}

class _OperationsMainScreenState extends ConsumerState<OperationsMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const OperationsDashboardScreen(),
    const OpsBookingsPlaceholder(),
    const OpsAssignmentsPlaceholder(),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_ind_outlined),
              activeIcon: Icon(Icons.assignment_ind),
              label: 'Assignments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

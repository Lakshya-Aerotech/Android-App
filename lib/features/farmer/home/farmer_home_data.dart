import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class FarmerQuickAction {
  final String label;
  final IconData icon;
  final Color iconColor;

  const FarmerQuickAction({
    required this.label,
    required this.icon,
    required this.iconColor,
  });
}

const farmerQuickActions = [
  FarmerQuickAction(
    label: 'Book New Service',
    icon: Icons.add_circle_outline,
    iconColor: AppColors.accent,
  ),
  FarmerQuickAction(
    label: 'My Bookings',
    icon: Icons.assignment_outlined,
    iconColor: AppColors.primary,
  ),
  FarmerQuickAction(
    label: 'My Farms',
    icon: Icons.landscape_outlined,
    iconColor: AppColors.accent,
  ),
  FarmerQuickAction(
    label: 'Service History',
    icon: Icons.history_outlined,
    iconColor: AppColors.primary,
  ),
];

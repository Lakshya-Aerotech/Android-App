import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_chip.dart';

const mockFarmerName = 'Rahul';

// TODO: Fetch farmer name from users/{currentUserUid}.name.

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

class FarmerUpcomingBooking {
  final String dateTime;
  final String farmName;
  final String cropInfo;
  final BookingStatus status;

  const FarmerUpcomingBooking({
    required this.dateTime,
    required this.farmName,
    required this.cropInfo,
    required this.status,
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

const mockUpcomingBooking = FarmerUpcomingBooking(
  dateTime: 'Tomorrow, 10:00 AM',
  farmName: 'Farm - Green Valley',
  cropInfo: 'Cotton • 5 Acres',
  status: BookingStatus.assigned,
);

// TODO: Replace mockUpcomingBooking with the farmer's nearest active Firestore booking.

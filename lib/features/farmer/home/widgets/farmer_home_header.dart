import 'package:flutter/material.dart';
import '../../../../shared/components/dashboard_header.dart';
import 'farmer_promo_banner.dart';

class FarmerHomeHeader extends StatelessWidget {
  final String farmerName;
  final VoidCallback onBookNow;

  const FarmerHomeHeader({
    super.key,
    required this.farmerName,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardHeader(
      userName: farmerName,
      bottomChild: FarmerPromoBanner(onBookNow: onBookNow),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../shared/components/dashboard_header.dart';

class PilotHomeHeader extends StatelessWidget {
  final String pilotName;

  const PilotHomeHeader({
    super.key,
    required this.pilotName,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardHeader(
      userName: pilotName,
    );
  }
}

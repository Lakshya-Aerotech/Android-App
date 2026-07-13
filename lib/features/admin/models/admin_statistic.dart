import 'package:flutter/material.dart';

class AdminStatistic {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const AdminStatistic({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.onTap,
  });
}

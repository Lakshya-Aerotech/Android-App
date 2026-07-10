import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_radius.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final BorderSide? borderSide;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.lg),
        border: Border.fromBorderSide(borderSide ?? BorderSide(color: AppColors.border, width: 1)),
      ),
      child: child,
    );
  }
}

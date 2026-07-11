import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.accent),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final TextStyle? titleStyle;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.tr(title),
          style:
              titleStyle ??
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        if (action != null) action!,
      ],
    );
  }
}
